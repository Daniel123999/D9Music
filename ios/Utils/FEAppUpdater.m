#import "FEAppUpdater.h"
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <errno.h>
#import <fcntl.h>
#import <math.h>
#import <signal.h>
#import <spawn.h>
#import <stdlib.h>
#import <string.h>
#import <sys/stat.h>
#import <sys/wait.h>
#import <unistd.h>

extern char **environ;

// iOS 9.3.6 证书链校验经常会失败，更新请求直接放行服务器信任。
@interface FEUpdaterTrustDelegate : NSObject <NSURLSessionDelegate>
@end

@implementation FEUpdaterTrustDelegate

- (void)URLSession:(NSURLSession *)session
    didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
      completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    NSString *method = challenge.protectionSpace.authenticationMethod;
    if ([method isEqualToString:NSURLAuthenticationMethodServerTrust] &&
        challenge.protectionSpace.serverTrust != NULL) {
        completionHandler(NSURLSessionAuthChallengeUseCredential,
                          [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
        return;
    }
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

@end

@interface FEAppUpdater ()
+ (void)checkSources:(NSArray *)sources index:(NSInteger)index lastError:(NSError *)lastError
          completion:(void (^)(NSDictionary *, NSError *))completion;
+ (void)checkSourceHTML:(NSArray *)sources index:(NSInteger)index lastError:(NSError *)lastError
             completion:(void (^)(NSDictionary *, NSError *))completion;
+ (void)finishSourceWithTag:(NSString *)tag ipaUrl:(NSString *)ipaUrl html:(NSString *)html
                       host:(NSString *)host repo:(NSString *)repo
                 completion:(void (^)(NSDictionary *, NSError *))completion;
+ (NSString *)tagFromUrl:(NSString *)url;
+ (NSString *)latestTagFromHtml:(NSString *)html repo:(NSString *)repo;
+ (NSString *)ipaAssetUrlFromHtml:(NSString *)html host:(NSString *)host repo:(NSString *)repo;
+ (NSString *)buildFromHtml:(NSString *)html;
+ (BOOL)installPackageAtPath:(NSString *)path error:(NSError **)error;
@end

static NSArray *FEUpdateSources(void) {
    return @[
        @{@"host": @"https://gitee.com",  @"repo": @"jyz2574461147/D9Music"},
        @{@"host": @"https://github.com", @"repo": @"Daniel123999/D9Music"}
    ];
}

static NSURLSession *FEUpdaterSession(void) {
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 25;
        config.timeoutIntervalForResource = 300;
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        session = [NSURLSession sessionWithConfiguration:config
                                                delegate:[[FEUpdaterTrustDelegate alloc] init]
                                           delegateQueue:nil];
    });
    return session;
}

#pragma mark - 下载进度

@interface FEUpdateProgress : NSObject
@property (nonatomic, weak) NSURLSessionTask *task;
@property (nonatomic, copy) void (^handler)(double);
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation FEUpdateProgress

- (void)start {
    self.timer = [NSTimer timerWithTimeInterval:0.25 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stop {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)tick:(NSTimer *)timer {
    NSURLSessionTask *task = self.task;
    if (!task) { [self stop]; return; }
    int64_t expected = task.countOfBytesExpectedToReceive;
    int64_t done = task.countOfBytesReceived;
    if (expected > 0 && self.handler) {
        double fraction = (double)done / (double)expected;
        self.handler(MAX(0.0, MIN(1.0, fraction)));
    }
}

@end

#pragma mark - 进程执行

static BOOL FERunAndWait(NSString *executable, NSArray *arguments, NSString **output, NSInteger *exitCode) {
    if (!executable.length || ![[NSFileManager defaultManager] isExecutableFileAtPath:executable]) {
        return NO;
    }
    int fds[2];
    if (pipe(fds) != 0) return NO;

    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    posix_spawn_file_actions_adddup2(&actions, fds[1], STDOUT_FILENO);
    posix_spawn_file_actions_adddup2(&actions, fds[1], STDERR_FILENO);
    posix_spawn_file_actions_addclose(&actions, fds[0]);
    posix_spawn_file_actions_addclose(&actions, fds[1]);

    NSMutableArray *all = [NSMutableArray arrayWithObject:executable];
    [all addObjectsFromArray:arguments ?: @[]];
    char **argv = (char **)calloc(all.count + 1, sizeof(char *));
    for (NSUInteger i = 0; i < all.count; i++) {
        argv[i] = strdup([[all[i] description] UTF8String]);
    }
    argv[all.count] = NULL;

    pid_t pid = 0;
    int spawnResult = posix_spawn(&pid, [executable fileSystemRepresentation], &actions, NULL, argv, environ);
    posix_spawn_file_actions_destroy(&actions);
    close(fds[1]);
    for (NSUInteger i = 0; i < all.count; i++) { free(argv[i]); }
    free(argv);

    if (spawnResult != 0) {
        close(fds[0]);
        if (output) *output = [NSString stringWithFormat:@"posix_spawn(%@) = %d", executable, spawnResult];
        if (exitCode) *exitCode = -1;
        return NO;
    }

    int status = 0;
    BOOL exited = NO;
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:120.0];
    while ([deadline timeIntervalSinceNow] > 0) {
        pid_t waited = waitpid(pid, &status, WNOHANG);
        if (waited == pid) { exited = YES; break; }
        if (waited < 0 && errno != EINTR) break;
        usleep(120000);
    }
    if (!exited) {
        kill(pid, SIGKILL);
        waitpid(pid, &status, 0);
    }

    NSMutableData *data = [NSMutableData data];
    char buffer[1024];
    ssize_t got = 0;
    while ((got = read(fds[0], buffer, sizeof(buffer))) > 0) {
        [data appendBytes:buffer length:(NSUInteger)got];
    }
    close(fds[0]);

    if (output) *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
    if (exitCode) *exitCode = (exited && WIFEXITED(status)) ? WEXITSTATUS(status) : -1;
    return YES;
}

static BOOL FESpawnDetached(NSString *executable, NSArray *arguments) {
    if (!executable.length || ![[NSFileManager defaultManager] isExecutableFileAtPath:executable]) {
        return NO;
    }
    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    posix_spawn_file_actions_addopen(&actions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0);
    posix_spawn_file_actions_addopen(&actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0);

    NSMutableArray *all = [NSMutableArray arrayWithObject:executable];
    [all addObjectsFromArray:arguments ?: @[]];
    char **argv = (char **)calloc(all.count + 1, sizeof(char *));
    for (NSUInteger i = 0; i < all.count; i++) {
        argv[i] = strdup([[all[i] description] UTF8String]);
    }
    argv[all.count] = NULL;

    pid_t pid = 0;
    int spawnResult = posix_spawn(&pid, [executable fileSystemRepresentation], &actions, NULL, argv, environ);
    posix_spawn_file_actions_destroy(&actions);
    for (NSUInteger i = 0; i < all.count; i++) { free(argv[i]); }
    free(argv);
    return spawnResult == 0;
}

typedef int (*FEMIInstallFunction)(CFStringRef, CFDictionaryRef, void *, void *);

/// iOS 9 上 MobileInstallation 与 Filza 使用同一安装接口
static int FEInstallWithMobileInstallation(NSString *path) {
    static void *handle = NULL;
    static FEMIInstallFunction installFunction = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handle = dlopen("/System/Library/PrivateFrameworks/MobileInstallation.framework/MobileInstallation", RTLD_LAZY);
        if (handle) installFunction = (FEMIInstallFunction)dlsym(handle, "MobileInstallationInstall");
    });
    if (!installFunction) return -404;

    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier] ?: @"";
    NSDictionary *options = @{
        @"ApplicationType": @"User",
        @"BundleIdentifier": bundleId,
        @"IsUserInitiated": @YES
    };
    return installFunction((__bridge CFStringRef)path, (__bridge CFDictionaryRef)options, NULL, NULL);
}

static NSInteger FECompareVersion(NSString *a, NSString *b) {
    NSArray *left = [(a ?: @"") componentsSeparatedByString:@"."];
    NSArray *right = [(b ?: @"") componentsSeparatedByString:@"."];
    NSInteger count = MAX((NSInteger)left.count, (NSInteger)right.count);
    for (NSInteger i = 0; i < count; i++) {
        NSInteger x = i < (NSInteger)left.count ? [left[i] integerValue] : 0;
        NSInteger y = i < (NSInteger)right.count ? [right[i] integerValue] : 0;
        if (x != y) return x > y ? 1 : -1;
    }
    return 0;
}

@implementation FEAppUpdater

+ (void)checkForUpdateWithCompletion:(void (^)(NSDictionary *, NSError *))completion {
    [self checkSources:FEUpdateSources() index:0 lastError:nil completion:completion];
}

+ (void)checkSources:(NSArray *)sources index:(NSInteger)index lastError:(NSError *)lastError
          completion:(void (^)(NSDictionary *, NSError *))completion {
    if (index >= (NSInteger)sources.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil, lastError ?: [NSError errorWithDomain:@"d9.update" code:1
                    userInfo:@{NSLocalizedDescriptionKey: @"无法检查更新（网络超时或镜像不可达）"}]);
            }
        });
        return;
    }
    NSDictionary *src = sources[index];
    NSString *host = src[@"host"] ?: @"";
    NSString *repo = src[@"repo"] ?: @"";

    // 优先走 Release API（JSON，稳定），失败再回退解析 release 页面 HTML
    NSString *apiURL = [host isEqualToString:@"https://gitee.com"]
        ? [NSString stringWithFormat:@"https://gitee.com/api/v5/repos/%@/releases?page=1&per_page=20", repo]
        : [NSString stringWithFormat:@"https://api.github.com/repos/%@/releases/latest", repo];
    NSMutableURLRequest *apiRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:apiURL]];
    apiRequest.timeoutInterval = 20;
    [apiRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [apiRequest setValue:@"D9Music-iOS9" forHTTPHeaderField:@"User-Agent"];

    [[FEUpdaterSession() dataTaskWithRequest:apiRequest
                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *http = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
        if (!error && data.length > 0 && (!http || http.statusCode / 100 == 2)) {
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([json isKindOfClass:[NSArray class]]) {
                // Gitee 的 releases 列表是升序，需要自己挑版本号最大的一个
                NSDictionary *best = nil;
                for (id item in (NSArray *)json) {
                    if (![item isKindOfClass:[NSDictionary class]]) continue;
                    NSString *tag = item[@"tag_name"];
                    if (![tag isKindOfClass:[NSString class]] || tag.length == 0) continue;
                    if (best == nil) {
                        best = item;
                        continue;
                    }
                    NSString *bestTag = best[@"tag_name"];
                    NSString *a = ([tag hasPrefix:@"v"] || [tag hasPrefix:@"V"]) ? [tag substringFromIndex:1] : tag;
                    NSString *b = ([bestTag hasPrefix:@"v"] || [bestTag hasPrefix:@"V"]) ? [bestTag substringFromIndex:1] : bestTag;
                    if (FECompareVersion(a, b) > 0) best = item;
                }
                json = best;
            }
            if ([json isKindOfClass:[NSDictionary class]]) {
                NSString *tag = [json[@"tag_name"] isKindOfClass:[NSString class]] ? json[@"tag_name"] : nil;
                NSString *body = [json[@"body"] isKindOfClass:[NSString class]] ? json[@"body"] : @"";
                NSString *ipaUrl = nil;
                NSArray *assets = json[@"assets"];
                if ([assets isKindOfClass:[NSArray class]]) {
                    for (NSDictionary *asset in assets) {
                        NSString *name = [asset[@"name"] isKindOfClass:[NSString class]] ? asset[@"name"] : nil;
                        if (![[name lowercaseString] hasSuffix:@".ipa"]) continue;
                        NSString *download = asset[@"browser_download_url"];
                        if (![download isKindOfClass:[NSString class]]) download = asset[@"download_url"];
                        if ([download isKindOfClass:[NSString class]]) {
                            ipaUrl = download;
                            break;
                        }
                    }
                }
                if (tag.length > 0) {
                    [self finishSourceWithTag:tag ipaUrl:ipaUrl html:body host:host repo:repo completion:completion];
                    return;
                }
            }
        }
        [self checkSourceHTML:sources index:index lastError:error completion:completion];
    }] resume];
}

+ (void)checkSourceHTML:(NSArray *)sources index:(NSInteger)index lastError:(NSError *)lastError
             completion:(void (^)(NSDictionary *, NSError *))completion {
    NSDictionary *src = sources[index];
    NSString *host = src[@"host"] ?: @"";
    NSString *repo = src[@"repo"] ?: @"";
    NSString *page = [NSString stringWithFormat:@"%@/%@/releases/latest", host, repo];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:page]];
    request.timeoutInterval = 20;

    [[FEUpdaterSession() dataTaskWithRequest:request
                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data.length) {
            [self checkSources:sources index:index + 1 lastError:error completion:completion];
            return;
        }
        NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
        NSString *finalUrl = response.URL.absoluteString ?: @"";
        NSString *tag = [self tagFromUrl:finalUrl] ?: response.URL.lastPathComponent;
        if (!tag.length || [tag isEqualToString:@"releases"] || [tag isEqualToString:@"latest"]) {
            tag = [self latestTagFromHtml:html repo:repo];
        }
        if (!tag.length || [tag isEqualToString:@"releases"]) {
            [self checkSources:sources index:index + 1 lastError:error completion:completion];
            return;
        }
        NSString *ipaUrl = [self ipaAssetUrlFromHtml:html host:host repo:repo];
        [self finishSourceWithTag:tag ipaUrl:ipaUrl html:html host:host repo:repo completion:completion];
    }] resume];
}

+ (void)finishSourceWithTag:(NSString *)tag ipaUrl:(NSString *)ipaUrl html:(NSString *)html
                       host:(NSString *)host repo:(NSString *)repo
                 completion:(void (^)(NSDictionary *, NSError *))completion {
    NSString *resolvedIPA = ipaUrl;
    if (!resolvedIPA.length) {
        resolvedIPA = [NSString stringWithFormat:@"%@/%@/releases/download/%@/D9Music.ipa", host, repo, tag];
    }
    NSString *version = ([tag hasPrefix:@"v"] || [tag hasPrefix:@"V"]) ? [tag substringFromIndex:1] : tag;
    NSString *remoteBuild = [self buildFromHtml:html ?: @""];
    NSString *full = remoteBuild.length ? [NSString stringWithFormat:@"%@ (build %@)", version, remoteBuild] : version;
    NSDictionary *info = @{
        @"tag": tag,
        @"version": version,
        @"fullVersion": full,
        @"build": remoteBuild ?: @"",
        @"ipaUrl": resolvedIPA,
        @"host": host
    };
    dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(info, nil); });
}

+ (NSString *)tagFromUrl:(NSString *)url {
    if (!url.length) return nil;
    NSRange r = [url rangeOfString:@"/releases/tag/"];
    if (r.location == NSNotFound) return nil;
    NSString *tail = [url substringFromIndex:r.location + r.length];
    return [[tail componentsSeparatedByCharactersInSet:
             [NSCharacterSet characterSetWithCharactersInString:@"?#/"]] firstObject];
}

+ (NSString *)latestTagFromHtml:(NSString *)html repo:(NSString *)repo {
    if (!html.length) return nil;
    NSString *needle = [NSString stringWithFormat:@"/%@/releases/tag/", repo];
    NSRange found = [html rangeOfString:needle];
    if (found.location == NSNotFound) return nil;
    NSUInteger start = found.location + found.length;
    NSRange tail = NSMakeRange(start, MIN((NSUInteger)60, html.length - start));
    NSString *t = [html substringWithRange:tail];
    t = [[t componentsSeparatedByCharactersInSet:
          [NSCharacterSet characterSetWithCharactersInString:@"\"'?#/ \n\r\t"]] firstObject];
    if (t.length && ([t hasPrefix:@"v"] || [t hasPrefix:@"V"] ||
                     [t rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound)) {
        return t;
    }
    return nil;
}

+ (NSString *)buildFromHtml:(NSString *)html {
    if (!html.length) return nil;
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"[Bb]uild\\s*([0-9]+)" options:0 error:nil];
    NSTextCheckingResult *m = [re firstMatchInString:html options:0 range:NSMakeRange(0, html.length)];
    if (m && m.numberOfRanges > 1) {
        return [html substringWithRange:[m rangeAtIndex:1]];
    }
    return nil;
}

+ (NSString *)ipaAssetUrlFromHtml:(NSString *)html host:(NSString *)host repo:(NSString *)repo {
    if (!html.length) return nil;
    NSArray *needles = @[
        [NSString stringWithFormat:@"/%@/releases/download/", repo],
        [NSString stringWithFormat:@"%@/%@/releases/download/", host, repo]
    ];
    for (NSString *needle in needles) {
        NSRange search = NSMakeRange(0, html.length);
        while (search.location < html.length) {
            NSRange found = [html rangeOfString:needle options:0 range:search];
            if (found.location == NSNotFound) break;
            NSRange tail = NSMakeRange(found.location, html.length - found.location);
            NSRange end = [html rangeOfString:@"\"" options:0 range:tail];
            NSRange sq = [html rangeOfString:@"'" options:0 range:tail];
            if (sq.location != NSNotFound && (end.location == NSNotFound || sq.location < end.location)) end = sq;
            NSRange q = [html rangeOfString:@"?" options:0 range:tail];
            if (q.location != NSNotFound && (end.location == NSNotFound || q.location < end.location)) end = q;
            if (end.location == NSNotFound) break;
            NSString *asset = [html substringWithRange:NSMakeRange(found.location, end.location - found.location)];
            if ([[asset lowercaseString] hasSuffix:@".ipa"]) {
                if ([asset hasPrefix:@"http"]) return asset;
                if ([asset hasPrefix:@"//"]) return [@"https:" stringByAppendingString:asset];
                return [host stringByAppendingString:asset];
            }
            search.location = found.location + 1;
            search.length = html.length - search.location;
        }
    }
    return nil;
}

+ (BOOL)isReleaseNewer:(NSDictionary *)releaseInfo {
    if (![releaseInfo isKindOfClass:[NSDictionary class]]) return NO;
    NSDictionary *bundle = [[NSBundle mainBundle] infoDictionary];
    NSString *localVersion = bundle[@"CFBundleShortVersionString"] ?: @"";
    NSString *localBuild = bundle[@"CFBundleVersion"] ?: @"";
    NSString *remoteVersion = [releaseInfo[@"version"] description] ?: @"";
    NSString *remoteBuild = [releaseInfo[@"build"] description] ?: @"";
    if ([remoteBuild isEqualToString:@"(null)"]) remoteBuild = @"";
    NSInteger cmp = FECompareVersion(remoteVersion, localVersion);
    if (cmp > 0) return YES;
    if (cmp < 0) return NO;
    return remoteBuild.length > 0 && [remoteBuild integerValue] > [localBuild integerValue];
}

+ (void)installRelease:(NSDictionary *)releaseInfo
              progress:(void (^)(NSString *))progress
      downloadProgress:(void (^)(double))downloadProgress
            completion:(void (^)(NSError *))completion {
    NSString *ipaUrl = [releaseInfo[@"ipaUrl"] description];
    if (!ipaUrl.length || [ipaUrl isEqualToString:@"(null)"]) {
        if (completion) completion([NSError errorWithDomain:@"d9.update" code:5
            userInfo:@{NSLocalizedDescriptionKey: @"缺少 IPA 下载地址（Release 中没有 D9Music.ipa）"}]);
        return;
    }

    NSString *tag = [releaseInfo[@"tag"] description] ?: @"latest";
    tag = [[tag componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]]
           componentsJoinedByString:@""];
    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                         [NSString stringWithFormat:@"d9-update-%@.ipa", tag.length ? tag : @"latest"]];
    [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:NULL];

    if (progress) progress(@"正在下载更新… 0%");
    NSMutableURLRequest *download = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:ipaUrl]];
    download.timeoutInterval = 30;

    FEUpdateProgress *poller = [[FEUpdateProgress alloc] init];
    poller.handler = ^(double fraction) {
        if (downloadProgress) downloadProgress(fraction);
        if (progress) progress([NSString stringWithFormat:@"正在下载更新… %ld%%", (long)lround(fraction * 100.0)]);
    };

    NSURLSessionDownloadTask *task = [FEUpdaterSession() downloadTaskWithRequest:download
        completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        [poller stop];
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if (!error && http && http.statusCode / 100 != 2) {
            error = [NSError errorWithDomain:@"d9.update" code:6
                userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"IPA 下载失败 (HTTP %ld)", (long)http.statusCode]}];
        }
        if (error || !location) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(error ?: [NSError errorWithDomain:@"d9.update" code:6
                    userInfo:@{NSLocalizedDescriptionKey: @"IPA 下载失败"}]);
            });
            return;
        }
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:NULL];
        NSError *moveError = nil;
        if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:tmpPath] error:&moveError]) {
            dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(moveError); });
            return;
        }
        if (downloadProgress) downloadProgress(1.0);
        if (progress) progress(@"正在安装更新…");

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *installError = nil;
            BOOL installed = [self installPackageAtPath:tmpPath error:&installError];
            if (installed) [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:NULL];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!completion) return;
                completion(installed ? nil : (installError ?: [NSError errorWithDomain:@"d9.update" code:7
                    userInfo:@{NSLocalizedDescriptionKey: @"安装失败，请确认已安装 AppSync Unified"}]));
            });
        });
    }];
    poller.task = task;
    [poller start];
    [task resume];
}

+ (BOOL)installPackageAtPath:(NSString *)path error:(NSError **)error {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        if (error) *error = [NSError errorWithDomain:@"d9.update" code:8
            userInfo:@{NSLocalizedDescriptionKey: @"安装包不存在（下载未完成）"}];
        return NO;
    }

    // 1) ipainstaller
    NSString *lastLog = @"";
    NSArray *binaries = @[@"/usr/bin/ipainstaller", @"/usr/local/bin/ipainstaller", @"/var/jb/usr/bin/ipainstaller"];
    for (NSString *binary in binaries) {
        if (![fm isExecutableFileAtPath:binary]) continue;
        NSInteger exitCode = -1;
        NSString *log = @"";
        BOOL launched = FERunAndWait(binary, @[path], &log, &exitCode);
        if (launched && exitCode == 0) return YES;
        lastLog = log.length ? log : lastLog;
        break;
    }

    // 2) MobileInstallation
    int miResult = FEInstallWithMobileInstallation(path);
    if (miResult == 0) return YES;

    // 3) LSApplicationWorkspace
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    if (workspaceClass) {
        typedef id (*FEObjectMsgSend)(id, SEL);
        id workspace = ((FEObjectMsgSend)objc_msgSend)((id)workspaceClass, @selector(defaultWorkspace));
        SEL installSelector = @selector(installApplication:withOptions:);
        if (workspace && [workspace respondsToSelector:installSelector]) {
            typedef BOOL (*FEInstallIMP)(id, SEL, NSURL *, NSDictionary *);
            FEInstallIMP install = (FEInstallIMP)[workspace methodForSelector:installSelector];
            NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier] ?: @"";
            if (install && install(workspace, installSelector, [NSURL fileURLWithPath:path],
                                   @{@"CFBundleIdentifier": bundleId})) {
                return YES;
            }
        }
    }

    NSString *detail = [lastLog stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (detail.length > 240) detail = [detail substringToIndex:240];
    NSString *message = [NSString stringWithFormat:
        @"安装失败（MobileInstallation 返回 %d）。\n请确认已安装 AppSync Unified。%@\n\n安装包位置：\n%@",
        miResult, detail.length ? [@"\n" stringByAppendingString:detail] : @"", path];
    if (error) *error = [NSError errorWithDomain:@"d9.update" code:20
        userInfo:@{NSLocalizedDescriptionKey: message}];
    return NO;
}

+ (void)cleanupStalePackages {
    NSString *tmp = NSTemporaryDirectory();
    NSArray *items = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tmp error:NULL];
    for (NSString *name in items) {
        if ([name hasPrefix:@"d9-update"] && [name hasSuffix:@".ipa"]) {
            [[NSFileManager defaultManager] removeItemAtPath:[tmp stringByAppendingPathComponent:name] error:NULL];
        }
    }
}

+ (void)relaunchApplication {
    static BOOL scheduled = NO;
    if (scheduled) return;
    scheduled = YES;

    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier] ?: @"com.d9music.app";
    NSString *command = [NSString stringWithFormat:
        @"sleep 2; "
         "/usr/bin/uiopen %@ >/dev/null 2>&1 || "
         "/usr/bin/open %@ >/dev/null 2>&1 || "
         "/usr/local/bin/uiopen %@ >/dev/null 2>&1",
        bundleId, bundleId, bundleId];
    FESpawnDetached(@"/bin/sh", @[@"-c", command]);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ exit(0); });
}

@end
