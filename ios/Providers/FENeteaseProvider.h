#import <Foundation/Foundation.h>
#import "FEProviderProtocol.h"

@interface FENeteaseProvider : NSObject <FEProviderProtocol>

- (void)getDailyRecommendSongsWithCompletion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion;
- (void)getRadioSongsWithCompletion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion;
- (void)getPersonalizedPlaylistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion;
- (void)getToplistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion;
- (void)getNewSongsWithCompletion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion;
- (void)getNewAlbumsWithCompletion:(void (^)(NSArray<FEPlaylist *> *albums, NSError *error))completion;
- (void)getPlaylistSquareWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion;
- (void)getHighQualityPlaylistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion;

@end
