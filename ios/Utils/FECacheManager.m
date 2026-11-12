#import "FECacheManager.h"
#import "FESettings.h"

@interface FECacheManager ()
@property (nonatomic, strong) NSMutableSet *downloading;
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation FECacheManager

+ (instancetype)sharedManager {
    static FECacheManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FECacheManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _downloading = [NSMutableSet set];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 30;
        config.timeoutIntervalForResource = 300;
        _session = [NSURLSession sessionWithConfiguration:config];
        [[NSFileManager defaultManager] createDirectoryAtPath:[self cacheDirectory]
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    return self;
}

- (NSString *)cacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *caches = [paths firstObject] ?: NSTemporaryDirectory();
    return [caches stringByAppendingPathComponent:@"D9Music"];
}

- (NSString *)fe_keyForTrack:(FETrack *)track quality:(NSInteger)quality {
    NSString *raw = [NSString stringWithFormat:@"%@_%@_%ld",
                     track.providerId ?: @"unknown", track.trackId ?: track.title ?: @"track", (long)quality];
    NSMutableString *safe = [NSMutableString string];
    NSCharacterSet *allowed = [NSCharacterSet alphanumericCharacterSet];
    for (NSUInteger i = 0; i < raw.length; i++) {
        unichar c = [raw characterAtIndex:i];
        [safe appendFormat:@"%@", [allowed characterIsMember:c] ? [NSString stringWithCharacters:&c length:1] : @"_"];
    }
    return safe;
}

- (NSString *)fe_extensionForURL:(NSString *)urlString {
    NSString *path = [[NSURL URLWithString:urlString] path] ?: @"";
    NSString *ext = [[path pathExtension] lowercaseString];
    NSArray *valid = @[@"mp3", @"m4a", @"aac", @"flac", @"wav", @"ogg"];
    if ([valid containsObject:ext]) return ext;
    return @"mp3";
}

- (NSString *)cachedPathForTrack:(FETrack *)track quality:(NSInteger)quality {
    if (track == nil || track.isLocal) return nil;
    NSString *base = [self fe_keyForTrack:track quality:quality];
    for (NSString *ext in @[@"mp3", @"m4a", @"aac", @"flac", @"wav", @"ogg"]) {
        NSString *path = [[self cacheDirectory] stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"%@.%@", base, ext]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    }
    return nil;
}

- (BOOL)hasCachedTrack:(FETrack *)track quality:(NSInteger)quality {
    return [self cachedPathForTrack:track quality:quality].length > 0;
}

- (void)cacheTrack:(FETrack *)track url:(NSString *)urlString quality:(NSInteger)quality
        completion:(void (^)(NSString *))completion {
    if (![FESettings sharedSettings].cacheEnabled) {
        if (completion) completion(nil);
        return;
    }
    if (track == nil || track.isLocal || urlString.length == 0 || ![urlString hasPrefix:@"http"]) {
        if (completion) completion(nil);
        return;
    }

    NSString *key = [self fe_keyForTrack:track quality:quality];
    NSString *existing = [self cachedPathForTrack:track quality:quality];
    if (existing.length > 0) {
        if (completion) completion(existing);
        return;
    }
    if ([self.downloading containsObject:key]) {
        if (completion) completion(nil);
        return;
    }
    [self.downloading addObject:key];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                         timeoutInterval:60];
    NSString *dest = [[self cacheDirectory] stringByAppendingPathComponent:
                      [NSString stringWithFormat:@"%@.%@", key, [self fe_extensionForURL:urlString]]];

    __weak typeof(self) weakSelf = self;
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithRequest:request
                                                        completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf.downloading removeObject:key];

        NSHTTPURLResponse *http = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
        if (error != nil || location == nil || (http && http.statusCode >= 300)) {
            if (completion) completion(nil);
            return;
        }
        [[NSFileManager defaultManager] removeItemAtPath:dest error:nil];
        NSError *moveError = nil;
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:dest] error:&moveError];
        if (moveError) {
            if (completion) completion(nil);
            return;
        }
        [strongSelf enforceLimit];
        if (completion) completion(dest);
    }];
    [task resume];
}

- (unsigned long long)cacheSize {
    unsigned long long total = 0;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *files = [fm contentsOfDirectoryAtPath:[self cacheDirectory] error:nil];
    for (NSString *name in files) {
        NSString *path = [[self cacheDirectory] stringByAppendingPathComponent:name];
        NSDictionary *attrs = [fm attributesOfItemAtPath:path error:nil];
        total += [attrs fileSize];
    }
    return total;
}

- (NSInteger)cachedFileCount {
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self cacheDirectory] error:nil];
    return (NSInteger)files.count;
}

- (void)clearCache {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *files = [fm contentsOfDirectoryAtPath:[self cacheDirectory] error:nil];
    for (NSString *name in files) {
        [fm removeItemAtPath:[[self cacheDirectory] stringByAppendingPathComponent:name] error:nil];
    }
}

- (void)enforceLimit {
    NSInteger maxMB = [FESettings sharedSettings].maxCacheMB;
    if (maxMB <= 0) maxMB = 200;
    unsigned long long limit = (unsigned long long)maxMB * 1024ULL * 1024ULL;
    if ([self cacheSize] <= limit) return;

    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dir = [self cacheDirectory];
    NSArray *files = [fm contentsOfDirectoryAtPath:dir error:nil];
    NSMutableArray *entries = [NSMutableArray array];
    for (NSString *name in files) {
        NSString *path = [dir stringByAppendingPathComponent:name];
        NSDictionary *attrs = [fm attributesOfItemAtPath:path error:nil];
        if (attrs) {
            [entries addObject:@{@"path": path, @"date": attrs[NSFileModificationDate] ?: [NSDate distantPast], @"size": attrs[NSFileSize]}];
        }
    }
    [entries sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [a[@"date"] compare:b[@"date"]];
    }];

    unsigned long long total = [self cacheSize];
    unsigned long long target = (unsigned long long)(limit * 0.9);
    for (NSDictionary *entry in entries) {
        if (total <= target) break;
        unsigned long long size = [entry[@"size"] unsignedLongLongValue];
        if ([fm removeItemAtPath:entry[@"path"] error:nil]) {
            total = total > size ? total - size : 0;
        }
    }
}

+ (NSString *)formatSize:(unsigned long long)bytes {
    if (bytes < 1024) return [NSString stringWithFormat:@"%llu B", bytes];
    double kb = bytes / 1024.0;
    if (kb < 1024) return [NSString stringWithFormat:@"%.0f KB", kb];
    double mb = kb / 1024.0;
    if (mb < 1024) return [NSString stringWithFormat:@"%.1f MB", mb];
    return [NSString stringWithFormat:@"%.2f GB", mb / 1024.0];
}

@end
