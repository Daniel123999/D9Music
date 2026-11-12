#import <Foundation/Foundation.h>
#import "FETrack.h"
#import "FEPlaylist.h"

@protocol FEProviderProtocol <NSObject>

@property (nonatomic, copy, readonly) NSString *providerId;
@property (nonatomic, copy, readonly) NSString *providerName;
@property (nonatomic, assign, readonly) BOOL isLoggedIn;
@property (nonatomic, copy, readonly) NSString *loginUrl;

- (void)searchWithKeyword:(NSString *)keyword completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion;
- (void)getPlayUrlForTrack:(FETrack *)track completion:(void (^)(NSString *playUrl, NSError *error))completion;
- (void)getLyricForTrack:(FETrack *)track completion:(void (^)(NSString *lyric, NSError *error))completion;
- (void)getUserPlaylistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion;
- (void)getPlaylistTracks:(FEPlaylist *)playlist completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion;
- (void)handleLoginCookies:(NSDictionary *)cookies;

@optional
- (void)getDailyRecommendSongsWithCompletion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion;
- (void)getRadioSongsWithCompletion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion;
- (void)getPersonalizedPlaylistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion;
- (void)getToplistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion;
- (void)getNewSongsWithCompletion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion;
- (void)getNewAlbumsWithCompletion:(void (^)(NSArray<FEPlaylist *> *albums, NSError *error))completion;
- (void)getPlaylistSquareWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion;
- (void)getHighQualityPlaylistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion;
- (void)likeTrack:(FETrack *)track like:(BOOL)like completion:(void (^)(BOOL success, NSError *error))completion;
- (void)getLikedSongsWithCompletion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion;

@end
