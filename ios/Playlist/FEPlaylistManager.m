#import "FEPlaylistManager.h"

@implementation FEPlaylistManager

+ (instancetype)sharedManager {
    static FEPlaylistManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FEPlaylistManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.localPlaylists = [NSMutableArray array];
        [self loadPlaylists];
    }
    return self;
}

- (NSString *)playlistsPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [paths objectAtIndex:0];
    return [docsDir stringByAppendingPathComponent:@"local_playlists.dat"];
}

- (void)createPlaylistWithName:(NSString *)name {
    FEPlaylist *playlist = [[FEPlaylist alloc] init];
    playlist.name = name;
    playlist.playlistId = [[NSUUID UUID] UUIDString];
    playlist.isLocal = YES;
    playlist.providerId = @"local";
    [self.localPlaylists addObject:playlist];
    [self savePlaylists];
}

- (void)deletePlaylist:(FEPlaylist *)playlist {
    [self.localPlaylists removeObject:playlist];
    [self savePlaylists];
}

- (void)addTrack:(FETrack *)track toPlaylist:(FEPlaylist *)playlist {
    if (![playlist.tracks containsObject:track]) {
        [playlist.tracks addObject:track];
        [self savePlaylists];
    }
}

- (void)removeTrack:(FETrack *)track fromPlaylist:(FEPlaylist *)playlist {
    [playlist.tracks removeObject:track];
    [self savePlaylists];
}

- (void)savePlaylists {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.localPlaylists];
    [data writeToFile:[self playlistsPath] atomically:YES];
}

- (void)loadPlaylists {
    NSData *data = [NSData dataWithContentsOfFile:[self playlistsPath]];
    if (data) {
        NSArray *playlists = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (playlists) {
            self.localPlaylists = [playlists mutableCopy];
        }
    }
}

@end
