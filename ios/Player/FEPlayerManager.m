#import "FEPlayerManager.h"
#import "FEProviderManager.h"

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
        self.autoSwitchSourceOnFailure = YES;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlayerItemFailed:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    }
    return self;
}

- (void)handlePlayerItemFailed:(NSNotification *)notification {
    if (self.autoSwitchSourceOnFailure && self.currentTrack) {
        [self trySwitchSourceForTrack:self.currentTrack];
    }
}

- (void)trySwitchSourceForTrack:(FETrack *)track {
    FEProviderManager *manager = [FEProviderManager sharedManager];
    if (!manager.providers.count) return;
    
    // 尝试其他音源
    for (id<FEProviderProtocol> provider in manager.providers) {
        if ([provider.providerId isEqualToString:track.providerId]) continue;
        if ([provider respondsToSelector:@selector(searchWithKeyword:completion:)]) {
            NSString *keyword = [NSString stringWithFormat:@"%@ %@", track.title ?: @"", track.artist ?: @""];
            [provider searchWithKeyword:keyword completion:^(NSArray<FETrack *> *tracks, NSError *error) {
                if (tracks.count > 0) {
                    FETrack *newTrack = tracks[0];
                    newTrack.title = track.title;
                    newTrack.artist = track.artist;
                    [self playTrack:newTrack];
                }
            }];
            break;
        }
    }
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
