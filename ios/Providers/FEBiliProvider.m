#import "FEBiliProvider.h"

@interface FEBiliProvider ()
@property (nonatomic, assign) BOOL loggedIn;
@end

@implementation FEBiliProvider

- (NSString *)providerId { return @"bilibili"; }
- (NSString *)providerName { return @"哔哩哔哩"; }
- (BOOL)isLoggedIn { return self.loggedIn; }
- (NSString *)loginUrl { return @"https://www.bilibili.com/"; }

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
