#import "FEWebDAVManager.h"
#import "FEPlaylistManager.h"
#import "FEHttpRequest.h"
#import <Security/Security.h>

@interface FEDAVPropfindParser : NSObject <NSXMLParserDelegate>
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *items;
@property (nonatomic, strong) NSMutableString *textBuffer;
@property (nonatomic, copy) NSString *currentHref;
@property (nonatomic, assign) BOOL currentIsDirectory;
@property (nonatomic, assign) long long currentSize;
@property (nonatomic, assign) BOOL capturing;
@end

@implementation FEDAVPropfindParser

- (instancetype)init {
    self = [super init];
    if (self) {
        _items = [NSMutableArray array];
        _textBuffer = [NSMutableString string];
    }
    return self;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"response"]) {
        self.currentHref = nil;
        self.currentIsDirectory = NO;
        self.currentSize = 0;
    } else if ([elementName isEqualToString:@"collection"]) {
        self.currentIsDirectory = YES;
    } else if ([elementName isEqualToString:@"href"] || [elementName isEqualToString:@"getcontentlength"]) {
        self.capturing = YES;
        [self.textBuffer setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (self.capturing) [self.textBuffer appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"href"]) {
        self.currentHref = [self.textBuffer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.capturing = NO;
    } else if ([elementName isEqualToString:@"getcontentlength"]) {
        self.currentSize = [[self.textBuffer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] longLongValue];
        self.capturing = NO;
    } else if ([elementName isEqualToString:@"response"]) {
        if (self.currentHref.length > 0) {
            [self.items addObject:@{@"href": self.currentHref,
                                    @"isDirectory": @(self.currentIsDirectory),
                                    @"size": @(self.currentSize)}];
        }
        self.currentHref = nil;
    }
}

@end

@implementation FEWebDAVManager

+ (instancetype)sharedManager {
    static FEWebDAVManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FEWebDAVManager alloc] init];
        [instance loadConfig];
    });
    return instance;
}

- (NSString *)configPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [paths objectAtIndex:0];
    return [docsDir stringByAppendingPathComponent:@"webdav_config.plist"];
}

- (BOOL)loadConfig {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[self configPath]];
    if (dict) {
        self.serverURL = dict[@"serverURL"] ?: @"";
        self.username = dict[@"username"] ?: @"";
        self.remotePath = dict[@"remotePath"] ?: @"/D9Music/";
        self.isEnabled = [dict[@"isEnabled"] boolValue];
        self.password = dict[@"password"] ?: @"";
        return YES;
    }
    self.serverURL = @"";
    self.username = @"";
    self.remotePath = @"/D9Music/";
    self.isEnabled = NO;
    self.password = @"";
    return NO;
}

- (void)saveConfig {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.serverURL) dict[@"serverURL"] = self.serverURL;
    if (self.username) dict[@"username"] = self.username;
    if (self.remotePath) dict[@"remotePath"] = self.remotePath;
    dict[@"isEnabled"] = @(self.isEnabled);
    if (self.password) dict[@"password"] = self.password;
    [dict writeToFile:[self configPath] atomically:YES];
}

- (NSDictionary *)authHeaders {
    if (self.username.length == 0) return @{};
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", self.username, self.password ?: @""];
    NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authBase64 = [authData base64EncodedStringWithOptions:0];
    return @{@"Authorization": [NSString stringWithFormat:@"Basic %@", authBase64]};
}

- (void)testConnection:(void (^)(BOOL success, NSString *message))completion {
    if (self.serverURL.length == 0) {
        if (completion) completion(NO, @"请先配置服务器地址");
        return;
    }
    NSString *url = [self.serverURL stringByAppendingString:[self cloudRootPath]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:10];
    [request setHTTPMethod:@"PROPFIND"];
    [request setValue:@"1" forHTTPHeaderField:@"Depth"];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    NSDictionary *headers = [self authHeaders];
    for (NSString *k in headers) [request setValue:headers[k] forHTTPHeaderField:k];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if (http.statusCode == 207 || http.statusCode == 200) {
            if (completion) completion(YES, [NSString stringWithFormat:@"连接成功 (HTTP %ld)", (long)http.statusCode]);
        } else if (connectionError) {
            if (completion) completion(NO, connectionError.localizedDescription);
        } else {
            if (completion) completion(NO, [NSString stringWithFormat:@"连接失败 (HTTP %ld)", (long)http.statusCode]);
        }
    }];
}

- (void)syncPlaylistsToWebDAV:(void (^)(BOOL success, NSString *message))completion {
    if (!self.isEnabled || self.serverURL.length == 0) {
        if (completion) completion(NO, @"WebDAV 未启用或未配置");
        return;
    }
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[FEPlaylistManager sharedManager].localPlaylists];
    NSString *url = [[self.serverURL stringByAppendingString:[self cloudRootPath]] stringByAppendingString:@"playlists.dat"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30];
    [request setHTTPMethod:@"PUT"];
    [request setHTTPBody:data];
    NSDictionary *headers = [self authHeaders];
    for (NSString *k in headers) [request setValue:headers[k] forHTTPHeaderField:k];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data2, NSError *connectionError) {
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if (http.statusCode >= 200 && http.statusCode < 300) {
            if (completion) completion(YES, @"歌单同步成功");
        } else if (connectionError) {
            if (completion) completion(NO, connectionError.localizedDescription);
        } else {
            if (completion) completion(NO, [NSString stringWithFormat:@"同步失败 (HTTP %ld)", (long)http.statusCode]);
        }
    }];
}

- (void)backupConfigToWebDAV:(void (^)(BOOL success, NSString *message))completion {
    if (!self.isEnabled || self.serverURL.length == 0) {
        if (completion) completion(NO, @"WebDAV 未启用或未配置");
        return;
    }
    NSData *playlistsData = [NSKeyedArchiver archivedDataWithRootObject:[FEPlaylistManager sharedManager].localPlaylists ?: @[]];
    NSDictionary *backup = @{
        @"version": @1,
        @"playlists": playlistsData ?: [NSData data],
        @"timestamp": [NSDate date]
    };
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:backup format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    if (data == nil) return;
    NSString *url = [[self.serverURL stringByAppendingString:[self cloudRootPath]] stringByAppendingString:@"config_backup.plist"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30];
    [request setHTTPMethod:@"PUT"];
    [request setHTTPBody:data];
    NSDictionary *headers = [self authHeaders];
    for (NSString *k in headers) [request setValue:headers[k] forHTTPHeaderField:k];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data2, NSError *connectionError) {
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if (http.statusCode >= 200 && http.statusCode < 300) {
            if (completion) completion(YES, @"配置备份成功");
        } else if (connectionError) {
            if (completion) completion(NO, connectionError.localizedDescription);
        } else {
            if (completion) completion(NO, [NSString stringWithFormat:@"备份失败 (HTTP %ld)", (long)http.statusCode]);
        }
    }];
}

- (void)restoreConfigFromWebDAV:(void (^)(BOOL success, NSString *message))completion {
    if (!self.isEnabled || self.serverURL.length == 0) {
        if (completion) completion(NO, @"WebDAV 未启用或未配置");
        return;
    }
    NSString *url = [[self.serverURL stringByAppendingString:[self cloudRootPath]] stringByAppendingString:@"config_backup.plist"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30];
    [request setHTTPMethod:@"GET"];
    NSDictionary *headers = [self authHeaders];
    for (NSString *k in headers) [request setValue:headers[k] forHTTPHeaderField:k];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if (http.statusCode == 200 && data.length > 0) {
            NSDictionary *backup = [NSPropertyListSerialization propertyListWithData:data
                                                                            options:NSPropertyListImmutable
                                                                             format:NULL
                                                                              error:nil];
            NSData *playlistsData = [backup isKindOfClass:[NSDictionary class]] ? backup[@"playlists"] : nil;
            NSArray *playlists = nil;
            if ([playlistsData isKindOfClass:[NSData class]]) {
                playlists = [NSKeyedUnarchiver unarchiveObjectWithData:playlistsData];
            }
            if ([playlists isKindOfClass:[NSArray class]]) {
                [FEPlaylistManager sharedManager].localPlaylists = [playlists mutableCopy];
                [[FEPlaylistManager sharedManager] savePlaylists];
                if (completion) completion(YES, [NSString stringWithFormat:@"已恢复 %lu 个歌单", (unsigned long)playlists.count]);
            } else {
                if (completion) completion(NO, @"云端备份格式不正确");
            }
        } else if (connectionError) {
            if (completion) completion(NO, connectionError.localizedDescription);
        } else {
            if (completion) completion(NO, [NSString stringWithFormat:@"恢复失败 (HTTP %ld)", (long)http.statusCode]);
        }
    }];
}

- (void)uploadTrack:(FETrack *)track completion:(void (^)(BOOL success, NSString *message))completion {
    if (!self.isEnabled || self.serverURL.length == 0) {
        if (completion) completion(NO, @"WebDAV 未启用或未配置");
        return;
    }
    // 简化实现：仅上传元数据
    NSMutableDictionary *meta = [NSMutableDictionary dictionary];
    if (track.trackId) meta[@"trackId"] = track.trackId;
    if (track.title) meta[@"title"] = track.title;
    if (track.artist) meta[@"artist"] = track.artist;
    if (track.album) meta[@"album"] = track.album;
    if (track.coverUrl) meta[@"coverUrl"] = track.coverUrl;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:meta format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSString *shortUuid = [uuid substringToIndex:8];
    NSString *fileName = [NSString stringWithFormat:@"%@-%@.plist", track.trackId ?: @"track", shortUuid];
    NSString *url = [[[self.serverURL stringByAppendingString:[self cloudRootPath]] stringByAppendingString:@"tracks/"] stringByAppendingString:fileName];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30];
    [request setHTTPMethod:@"PUT"];
    [request setHTTPBody:data];
    NSDictionary *headers = [self authHeaders];
    for (NSString *k in headers) [request setValue:headers[k] forHTTPHeaderField:k];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data2, NSError *connectionError) {
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if (http.statusCode >= 200 && http.statusCode < 300) {
            if (completion) completion(YES, @"上传成功");
        } else if (connectionError) {
            if (completion) completion(NO, connectionError.localizedDescription);
        } else {
            if (completion) completion(NO, [NSString stringWithFormat:@"上传失败 (HTTP %ld)", (long)http.statusCode]);
        }
    }];
}

- (void)downloadTrack:(FETrack *)track toPath:(NSString *)localPath completion:(void (^)(BOOL success, NSString *message))completion {
    if (!self.isEnabled || self.serverURL.length == 0) {
        if (completion) completion(NO, @"WebDAV 未启用或未配置");
        return;
    }
    NSString *name = track.title ?: @"track";
    NSString *remote = [[self cloudRootPath] stringByAppendingString:name];
    [self downloadRemoteFile:remote completion:^(NSString *localPath2, NSError *error) {
        if (completion) completion(localPath2.length > 0, localPath2.length > 0 ? @"下载完成" : (error.localizedDescription ?: @"下载失败"));
    }];
}

#pragma mark - 云盘浏览 / 下载

- (NSString *)cloudRootPath {
    NSString *path = self.remotePath.length > 0 ? self.remotePath : @"/D9Music/";
    if (![path hasPrefix:@"/"]) path = [@"/" stringByAppendingString:path];
    if (![path hasSuffix:@"/"]) path = [path stringByAppendingString:@"/"];
    return path;
}

- (NSString *)downloadDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docs = [paths firstObject] ?: NSTemporaryDirectory();
    NSString *dir = [docs stringByAppendingPathComponent:@"CloudMusic"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return dir;
}

- (NSString *)fe_absoluteURLForPath:(NSString *)path {
    NSString *base = self.serverURL ?: @"";
    if (![base hasSuffix:@"/"]) base = [base stringByAppendingString:@"/"];
    NSString *clean = path ?: @"";
    while ([clean hasPrefix:@"/"]) clean = [clean substringFromIndex:1];
    return [base stringByAppendingString:clean];
}

- (void)listDirectory:(NSString *)remotePath
           completion:(void (^)(NSArray<NSDictionary *> *items, NSError *error))completion {
    if (!self.isEnabled || self.serverURL.length == 0) {
        if (completion) completion(@[], [NSError errorWithDomain:@"FEWebDAV" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"WebDAV 未启用或未配置"}]);
        return;
    }
    NSString *dirPath = remotePath.length > 0 ? remotePath : [self cloudRootPath];
    if (![dirPath hasSuffix:@"/"]) dirPath = [dirPath stringByAppendingString:@"/"];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self fe_absoluteURLForPath:dirPath]]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:15];
    [request setHTTPMethod:@"PROPFIND"];
    [request setValue:@"1" forHTTPHeaderField:@"Depth"];
    [request setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    NSString *body = @"<?xml version=\"1.0\" encoding=\"utf-8\" ?><d:propfind xmlns:d=\"DAV:\"><d:prop><d:resourcetype/><d:getcontentlength/></d:prop></d:propfind>";
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    NSDictionary *headers = [self authHeaders];
    for (NSString *k in headers) [request setValue:headers[k] forHTTPHeaderField:k];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if (connectionError || (http.statusCode != 207 && http.statusCode != 200)) {
            NSString *message = connectionError.localizedDescription ?: [NSString stringWithFormat:@"列目录失败 (HTTP %ld)", (long)http.statusCode];
            if (completion) completion(@[], [NSError errorWithDomain:@"FEWebDAV" code:http.statusCode userInfo:@{NSLocalizedDescriptionKey: message}]);
            return;
        }

        FEDAVPropfindParser *parser = [[FEDAVPropfindParser alloc] init];
        NSXMLParser *xml = [[NSXMLParser alloc] initWithData:data];
        xml.shouldProcessNamespaces = YES;
        xml.delegate = parser;
        [xml parse];

        NSString *normalizedDir = [dirPath stringByRemovingPercentEncoding] ?: dirPath;
        if (![normalizedDir hasSuffix:@"/"]) normalizedDir = [normalizedDir stringByAppendingString:@"/"];

        NSMutableArray *items = [NSMutableArray array];
        for (NSDictionary *raw in parser.items) {
            NSString *href = raw[@"href"];
            NSString *clean = href;
            if ([clean hasPrefix:@"http://"] || [clean hasPrefix:@"https://"]) {
                NSURL *url = [NSURL URLWithString:clean];
                clean = url.path ?: clean;
            }
            clean = [clean stringByRemovingPercentEncoding] ?: clean;
            BOOL isDir = [raw[@"isDirectory"] boolValue];

            NSString *name = [clean lastPathComponent];
            if (name.length == 0) continue;

            NSString *compare = isDir ? [clean hasSuffix:@"/"] ? clean : [clean stringByAppendingString:@"/"] : clean;
            if ([compare isEqualToString:normalizedDir]) continue;
            if ([clean isEqualToString:@"/"]) continue;

            NSString *encodedName = [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]] ?: name;
            NSString *childPath = [dirPath stringByAppendingString:encodedName];
            if (isDir) childPath = [childPath stringByAppendingString:@"/"];
            [items addObject:@{@"name": name,
                               @"path": childPath,
                               @"isDirectory": @(isDir),
                               @"size": raw[@"size"] ?: @0}];
        }

        [items sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            BOOL da = [a[@"isDirectory"] boolValue];
            BOOL db = [b[@"isDirectory"] boolValue];
            if (da != db) return da ? NSOrderedAscending : NSOrderedDescending;
            return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
        }];
        if (completion) completion(items, nil);
    }];
}

- (void)downloadRemoteFile:(NSString *)remotePath
                completion:(void (^)(NSString *localPath, NSError *error))completion {
    if (!self.isEnabled || self.serverURL.length == 0) {
        if (completion) completion(nil, [NSError errorWithDomain:@"FEWebDAV" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"WebDAV 未启用或未配置"}]);
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self fe_absoluteURLForPath:remotePath]]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:120];
    [request setHTTPMethod:@"GET"];
    NSDictionary *headers = [self authHeaders];
    for (NSString *k in headers) [request setValue:headers[k] forHTTPHeaderField:k];

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                    completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *http = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
        if (location == nil || error != nil || (http && http.statusCode >= 300)) {
            NSString *message = error.localizedDescription ?: [NSString stringWithFormat:@"下载失败 (HTTP %ld)", (long)(http ? http.statusCode : 0)];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(nil, [NSError errorWithDomain:@"FEWebDAV" code:http ? http.statusCode : -1 userInfo:@{NSLocalizedDescriptionKey: message}]);
            });
            return;
        }

        NSString *name = [[remotePath lastPathComponent] stringByRemovingPercentEncoding] ?: @"download";
        NSString *dest = [[self downloadDirectory] stringByAppendingPathComponent:name];
        if ([[NSFileManager defaultManager] fileExistsAtPath:dest]) {
            NSString *base = [name stringByDeletingPathExtension];
            NSString *ext = [name pathExtension];
            NSInteger counter = 1;
            while ([[NSFileManager defaultManager] fileExistsAtPath:dest]) {
                NSString *candidate = [NSString stringWithFormat:@"%@-%ld", base, (long)counter++];
                if (ext.length > 0) candidate = [candidate stringByAppendingPathExtension:ext];
                dest = [[self downloadDirectory] stringByAppendingPathComponent:candidate];
            }
        }
        [[NSFileManager defaultManager] removeItemAtPath:dest error:nil];
        NSError *moveError = nil;
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:dest] error:&moveError];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (moveError) {
                if (completion) completion(nil, moveError);
            } else {
                if (completion) completion(dest, nil);
            }
        });
    }];
    [task resume];
}

@end
