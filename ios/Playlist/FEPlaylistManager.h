#import <Foundation/Foundation.h>
#import "FEPlaylist.h"

@interface FEPlaylistManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong) NSMutableArray<FEPlaylist *> *localPlaylists;

- (void)createPlaylistWithName:(NSString *)name;
- (void)deletePlaylist:(FEPlaylist *)playlist;
- (void)addTrack:(FETrack *)track toPlaylist:(FEPlaylist *)playlist;
- (void)removeTrack:(FETrack *)track fromPlaylist:(FEPlaylist *)playlist;
- (void)savePlaylists;
- (void)loadPlaylists;

@end
