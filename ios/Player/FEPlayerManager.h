#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "FETrack.h"

extern NSString *const FEPlayerDidChangeTrackNotification;
extern NSString *const FEPlayerDidChangeStateNotification;
extern NSString *const FEPlayerDidUpdateTimeNotification;
extern NSString *const FEPlayerDidFailNotification; // userInfo[@"message"]

@protocol FEPlayerDelegate <NSObject>
@optional
- (void)playerDidChangeTrack:(FETrack *)track;
- (void)playerDidUpdateTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration;
- (void)playerDidChangeState:(BOOL)isPlaying;
- (void)playerDidFail:(FETrack *)track;
@end

@interface FEPlayerManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) FETrack *currentTrack;
@property (nonatomic, strong) NSMutableArray<FETrack *> *playlist;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, weak) id<FEPlayerDelegate> delegate;
@property (nonatomic, assign) BOOL autoSwitchSourceOnFailure;

@property (nonatomic, readonly) NSTimeInterval currentTime;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, strong, readonly) NSArray<FETrack *> *history;

- (void)playTrack:(FETrack *)track;
- (void)playTracks:(NSArray<FETrack *> *)tracks startIndex:(NSInteger)index;
- (void)play;
- (void)pause;
- (void)toggle;
- (void)next;
- (void)previous;
- (void)addToPlaylist:(FETrack *)track;
- (void)trySwitchSourceForTrack:(FETrack *)track;
- (void)seekToProgress:(double)progress;

@end
