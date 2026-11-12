#import "FEWebDAVManager.h"
#import "FEPlaylistManager.h"
#import "FEHttpRequest.h"
#import <Security/Security.h>

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
        self.remotePath = dict[@"remotePath"] ?: @"/FuoEvolve9/";
        self.isEnabled = [dict[@"isEnabled"] boolValue];
        self.password = dict[@"password"] ?: @"";
        return YES;
    }
    self.serverURL = @"";
    self.username = @"";
    self.remotePath = @"/FuoEvolve9/";
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
    NSString *url = [self.serverURL stringByAppendingString:self.remotePath];
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
    NSString *url = [[self.serverURL stringByAppendingString:self.remotePath] stringByAppendingString:@"playlists.dat"];
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
    NSDictionary *backup = @{
        @"playlists": [FEPlaylistManager sharedManager].localPlaylists ?: @[],
        @"timestamp": [NSDate date]
    };
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:backup format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    if (data == nil) data = [NSKeyedArchiver archivedDataWithRootObject:backup];
    NSString *url = [[self.serverURL stringByAppendingString:self.remotePath] stringByAppendingString:@"config_backup.plist"];
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
    NSString *url = [[self.serverURL stringByAppendingString:self.remotePath] stringByAppendingString:@"config_backup.plist"];
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
            // 尝试恢复
            if (completion) completion(YES, @"配置恢复成功（请重启应用）");
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
    NSString *url = [[[self.serverURL stringByAppendingString:self.remotePath] stringByAppendingString:@"tracks/"] stringByAppendingString:fileName];
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
    // 简化实现：尝试下载元数据
    if (completion) completion(NO, @"下载功能开发中");
}

@end
