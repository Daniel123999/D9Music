#import "FEPlayerManager.h"

@implementation FEPlayerManager

+ (instancetype)sharedManager {
    static FEPlayerManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FEPlayerManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.player = [[AVPlayer alloc] init];
        self.playlist = [NSMutableArray array];
        self.currentIndex = -1;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
    }
    return self;
}

- (void)playTrack:(FETrack *)track {
    self.currentTrack = track;
    if (track.playUrl && track.playUrl.length > 0) {
        NSURL *url = [NSURL URLWithString:track.playUrl];
        if (url) {
            AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
            [self.player replaceCurrentItemWithPlayerItem:item];
            [self.player play];
            self.isPlaying = YES;
        }
    } else if (track.isLocal && track.playUrl) {
        NSURL *url = [NSURL fileURLWithPath:track.playUrl];
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
        [self.player replaceCurrentItemWithPlayerItem:item];
        [self.player play];
        self.isPlaying = YES;
    }
    if ([self.delegate respondsToSelector:@selector(playerDidChangeTrack:)]) {
        [self.delegate playerDidChangeTrack:track];
    }
    if ([self.delegate respondsToSelector:@selector(playerDidChangeState:)]) {
        [self.delegate playerDidChangeState:self.isPlaying];
    }
}

- (void)play {
    [self.player play];
    self.isPlaying = YES;
    if ([self.delegate respondsToSelector:@selector(playerDidChangeState:)]) {
        [self.delegate playerDidChangeState:self.isPlaying];
    }
}

- (void)pause {
    [self.player pause];
    self.isPlaying = NO;
    if ([self.delegate respondsToSelector:@selector(playerDidChangeState:)]) {
        [self.delegate playerDidChangeState:self.isPlaying];
    }
}

- (void)toggle {
    if (self.isPlaying) {
        [self pause];
    } else {
        [self play];
    }
}

- (void)next {
    if (self.playlist.count == 0) return;
    self.currentIndex = (self.currentIndex + 1) % self.playlist.count;
    [self playTrack:self.playlist[self.currentIndex]];
}

- (void)previous {
    if (self.playlist.count == 0) return;
    self.currentIndex = (self.currentIndex - 1 + self.playlist.count) % self.playlist.count;
    [self playTrack:self.playlist[self.currentIndex]];
}

- (void)addToPlaylist:(FETrack *)track {
    [self.playlist addObject:track];
}

@end
