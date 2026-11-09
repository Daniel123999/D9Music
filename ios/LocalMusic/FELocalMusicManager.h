#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "FETrack.h"

@interface FELocalMusicManager : NSObject

+ (instancetype)sharedManager;

- (void)scanLocalMusicWithCompletion:(void (^)(NSArray<FETrack *> *tracks))completion;
- (NSArray<FETrack *> *)getAllTracks;

@end
