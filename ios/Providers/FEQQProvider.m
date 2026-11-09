#import "FEQQProvider.h"

@interface FEQQProvider ()
@property (nonatomic, assign) BOOL loggedIn;
@end

@implementation FEQQProvider

- (NSString *)providerId { return @"qq"; }
- (NSString *)providerName { return @"QQ音乐"; }
- (BOOL)isLoggedIn { return self.loggedIn; }
- (NSString *)loginUrl { return @"https://y.qq.com/"; }

- (void)searchWithKeyword:(NSString *)keyword completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    if (completion) completion(@[], nil);
}
- (void)getPlayUrlForTrack:(FETrack *)track completion:(void (^)(NSString *playUrl, NSError *error))completion {
    if (completion) completion(nil, nil);
}
- (void)getLyricForTrack:(FETrack *)track completion:(void (^)(NSString *lyric, NSError *error))completion {
    if (completion) completion(nil, nil);
}
- (void)getUserPlaylistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion {
    if (completion) completion(@[], nil);
}
- (void)getPlaylistTracks:(FEPlaylist *)playlist completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    if (completion) completion(@[], nil);
}
- (void)handleLoginCookies:(NSDictionary *)cookies {
    self.loggedIn = cookies.count > 0;
}

@end
