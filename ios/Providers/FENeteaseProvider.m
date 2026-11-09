#import "FENeteaseProvider.h"

@interface FENeteaseProvider ()
@property (nonatomic, copy) NSString *cookies;
@property (nonatomic, assign) BOOL loggedIn;
@end

@implementation FENeteaseProvider

- (NSString *)providerId { return @"netease"; }
- (NSString *)providerName { return @"网易云音乐"; }
- (BOOL)isLoggedIn { return self.loggedIn; }
- (NSString *)loginUrl { return @"https://music.163.com/"; }

- (void)searchWithKeyword:(NSString *)keyword completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    // 简化实现：返回空结果，实际项目中需要调用API
    if (completion) {
        completion(@[], nil);
    }
}

- (void)getPlayUrlForTrack:(FETrack *)track completion:(void (^)(NSString *playUrl, NSError *error))completion {
    if (completion) {
        completion(nil, nil);
    }
}

- (void)getLyricForTrack:(FETrack *)track completion:(void (^)(NSString *lyric, NSError *error))completion {
    if (completion) {
        completion(nil, nil);
    }
}

- (void)getUserPlaylistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion {
    if (completion) {
        completion(@[], nil);
    }
}

- (void)getPlaylistTracks:(FEPlaylist *)playlist completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    if (completion) {
        completion(@[], nil);
    }
}

- (void)handleLoginCookies:(NSDictionary *)cookies {
    self.cookies = [cookies description];
    self.loggedIn = cookies.count > 0;
}

@end
