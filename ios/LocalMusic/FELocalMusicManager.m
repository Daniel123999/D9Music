#import "FELocalMusicManager.h"

@implementation FELocalMusicManager

+ (instancetype)sharedManager {
    static FELocalMusicManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FELocalMusicManager alloc] init];
    });
    return instance;
}

- (void)scanLocalMusicWithCompletion:(void (^)(NSArray<FETrack *> *tracks))completion {
    MPMediaQuery *query = [MPMediaQuery songsQuery];
    NSMutableArray *tracks = [NSMutableArray array];
    
    for (MPMediaItem *item in query.items) {
        FETrack *track = [[FETrack alloc] init];
        track.title = [item valueForProperty:MPMediaItemPropertyTitle] ?: @"未知歌曲";
        track.artist = [item valueForProperty:MPMediaItemPropertyArtist] ?: @"未知艺术家";
        track.album = [item valueForProperty:MPMediaItemPropertyAlbumTitle] ?: @"未知专辑";
        track.trackId = [[item valueForProperty:MPMediaItemPropertyPersistentID] stringValue];
        track.duration = [[item valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
        track.isLocal = YES;
        track.providerId = @"local";
        NSURL *url = [item valueForProperty:MPMediaItemPropertyAssetURL];
        if (url) {
            track.playUrl = [url absoluteString];
        }
        [tracks addObject:track];
    }
    
    if (completion) {
        completion(tracks);
    }
}

- (NSArray<FETrack *> *)getAllTracks {
    MPMediaQuery *query = [MPMediaQuery songsQuery];
    NSMutableArray *tracks = [NSMutableArray array];
    for (MPMediaItem *item in query.items) {
        FETrack *track = [[FETrack alloc] init];
        track.title = [item valueForProperty:MPMediaItemPropertyTitle] ?: @"未知歌曲";
        track.artist = [item valueForProperty:MPMediaItemPropertyArtist] ?: @"未知艺术家";
        track.album = [item valueForProperty:MPMediaItemPropertyAlbumTitle] ?: @"未知专辑";
        track.trackId = [[item valueForProperty:MPMediaItemPropertyPersistentID] stringValue];
        track.duration = [[item valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
        track.isLocal = YES;
        track.providerId = @"local";
        [tracks addObject:track];
    }
    return tracks;
}

@end
