#import "FEPlayerManager.h"
#import "FEProviderManager.h"
#import "FELyricsManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>
#import <math.h>

NSString *const FEPlayerDidChangeTrackNotification = @"FEPlayerDidChangeTrackNotification";
NSString *const FEPlayerDidChangeStateNotification = @"FEPlayerDidChangeStateNotification";
NSString *const FEPlayerDidUpdateTimeNotification = @"FEPlayerDidUpdateTimeNotification";
NSString *const FEPlayerDidFailNotification = @"FEPlayerDidFailNotification";

static NSString *const FEAVURLAssetHTTPHeaderFieldsKey = @"AVURLAssetHTTPHeaderFieldsKey";

@interface FEPlayerManager ()
@property (nonatomic, strong) id timeObserver;
@property (nonatomic, strong) AVPlayerItem *observedItem;
@property (nonatomic, strong) NSMutableArray<FETrack *> *mutableHistory;
@property (nonatomic, assign) BOOL isSwitchingSource;
@property (nonatomic, assign) NSInteger switchAttempt;
@property (nonatomic, assign) NSTimeInterval lastNowPlayingUpdate;
@end

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
        _player = [[AVPlayer alloc] init];
        _playlist = [NSMutableArray array];
        _mutableHistory = [NSMutableArray array];
        _currentIndex = -1;
        _autoSwitchSourceOnFailure = YES;
        _switchAttempt = 0;

        [self activateAudioSession];
        [self setupRemoteCommands];
        [self setupTimeObserver];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillTerminate:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_timeObserver) {
        [_player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
    [self unobserveCurrentItem];
}

#pragma mark - Audio Session / Remote

- (void)activateAudioSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
}

- (void)applicationWillTerminate:(NSNotification *)note {
    [self saveState];
}

- (void)saveState {
}

- (void)setupRemoteCommands {
    MPRemoteCommandCenter *center = [MPRemoteCommandCenter sharedCommandCenter];
    __weak typeof(self) weakSelf = self;
    [center.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        [weakSelf play];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [center.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        [weakSelf pause];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [center.togglePlayPauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        [weakSelf toggle];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [center.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        [weakSelf next];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [center.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        [weakSelf previous];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
}

- (void)setupTimeObserver {
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.5, 600)
                                                                  queue:dispatch_get_main_queue()
                                                             usingBlock:^(CMTime time) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        NSTimeInterval current = CMTimeGetSeconds(time);
        if (!isfinite(current)) current = 0;
        NSTimeInterval duration = strongSelf.duration;
        [[NSNotificationCenter defaultCenter] postNotificationName:FEPlayerDidUpdateTimeNotification
                                                            object:strongSelf
                                                          userInfo:@{@"currentTime": @(current), @"duration": @(duration)}];
        if ([strongSelf.delegate respondsToSelector:@selector(playerDidUpdateTime:duration:)]) {
            [strongSelf.delegate playerDidUpdateTime:current duration:duration];
        }
        if (fabs(current - strongSelf.lastNowPlayingUpdate) >= 2.0) {
            strongSelf.lastNowPlayingUpdate = current;
            [strongSelf updateNowPlayingInfo];
        }
    }];
}

#pragma mark - Playback

- (void)playTracks:(NSArray<FETrack *> *)tracks startIndex:(NSInteger)index {
    if (tracks.count == 0) return;
    self.playlist = [tracks mutableCopy];
    if (index < 0 || index >= (NSInteger)tracks.count) index = 0;
    self.currentIndex = index;
    [self playTrack:tracks[index]];
}

- (void)playTrack:(FETrack *)track {
    if (track == nil) return;

    self.currentTrack = track;
    self.switchAttempt = 0;
    [self addHistoryTrack:track];
    [self postTrackChanged];
    [self notifyLyricsForTrack:track];

    if (track.playUrl.length > 0) {
        [self startPlaybackForTrack:track urlString:track.playUrl];
        return;
    }

    // 先向音源请求播放地址，避免搜索到的歌曲“点了没反应”
    [self resolvePlayUrlAndPlay:track];
}

- (void)resolvePlayUrlAndPlay:(FETrack *)track {
    id<FEProviderProtocol> provider = [self providerForTrack:track];
    if (provider == nil || ![provider respondsToSelector:@selector(getPlayUrlForTrack:completion:)]) {
        NSLog(@"[FEPlayer] no provider for track %@ (%@)", track.title, track.providerId);
        [self handlePlaybackFailure];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [provider getPlayUrlForTrack:track completion:^(NSString *playUrl, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            if (strongSelf.currentTrack != track) return;
            if (playUrl.length > 0) {
                track.playUrl = playUrl;
                [strongSelf startPlaybackForTrack:track urlString:playUrl];
            } else {
                NSLog(@"[FEPlayer] resolve failed for %@: %@", track.title, error);
                [strongSelf handlePlaybackFailure];
            }
        });
    }];
}

- (void)startPlaybackForTrack:(FETrack *)track urlString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (url == nil) {
        [self handlePlaybackFailure];
        return;
    }

    [self unobserveCurrentItem];

    AVURLAsset *asset = nil;
    if (track.httpHeaders.count > 0) {
        NSDictionary *options = @{FEAVURLAssetHTTPHeaderFieldsKey: track.httpHeaders,
                                  @"AVURLAssetPreferPreciseDurationAndTimingKey": @(YES)};
        asset = [AVURLAsset URLAssetWithURL:url options:options];
    } else {
        asset = [AVURLAsset URLAssetWithURL:url options:@{@"AVURLAssetPreferPreciseDurationAndTimingKey": @(YES)}];
    }

    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    self.observedItem = item;
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(itemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:item];
    [center addObserver:self selector:@selector(itemFailedToPlayToEnd:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:item];

    [self.player replaceCurrentItemWithPlayerItem:item];
    [self activateAudioSession];
    [self.player play];
    self.isPlaying = YES;
    self.switchAttempt = 0;

    [self postStateChanged];
    [self updateNowPlayingInfo];
}

- (void)play {
    if (self.player.currentItem == nil && self.currentTrack.playUrl.length > 0) {
        [self startPlaybackForTrack:self.currentTrack urlString:self.currentTrack.playUrl];
        return;
    }
    [self activateAudioSession];
    [self.player play];
    self.isPlaying = YES;
    [self postStateChanged];
    [self updateNowPlayingInfo];
}

- (void)pause {
    [self.player pause];
    self.isPlaying = NO;
    [self postStateChanged];
    [self updateNowPlayingInfo];
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
    NSInteger nextIndex = self.currentIndex + 1;
    if (nextIndex >= (NSInteger)self.playlist.count) nextIndex = 0;
    self.currentIndex = nextIndex;
    [self playTrack:self.playlist[nextIndex]];
}

- (void)previous {
    if (self.playlist.count == 0) return;
    NSInteger prevIndex = self.currentIndex - 1;
    if (prevIndex < 0) prevIndex = (NSInteger)self.playlist.count - 1;
    self.currentIndex = prevIndex;
    [self playTrack:self.playlist[prevIndex]];
}

- (void)addToPlaylist:(FETrack *)track {
    if (track == nil) return;
    if (![self.playlist containsObject:track]) {
        [self.playlist addObject:track];
    }
}

- (void)seekToProgress:(double)progress {
    AVPlayerItem *item = self.player.currentItem;
    if (item == nil) return;
    CMTime duration = item.duration;
    if (!CMTIME_IS_VALID(duration)) return;
    double seconds = CMTimeGetSeconds(duration) * MAX(0.0, MIN(1.0, progress));
    [self.player seekToTime:CMTimeMakeWithSeconds(seconds, 600)];
}

#pragma mark - Failure / Source switching

- (void)itemFailedToPlayToEnd:(NSNotification *)notification {
    if (notification.object != self.observedItem) return;
    [self handlePlaybackFailure];
}

- (void)handlePlaybackFailure {
    self.isPlaying = NO;
    [self postStateChanged];

    if (self.autoSwitchSourceOnFailure && self.switchAttempt < 2 && self.currentTrack.isLocal == NO) {
        self.switchAttempt += 1;
        [self trySwitchSourceForTrack:self.currentTrack];
        return;
    }

    NSString *message = @"播放失败，请检查网络或登录状态";
    [[NSNotificationCenter defaultCenter] postNotificationName:FEPlayerDidFailNotification
                                                        object:self
                                                      userInfo:@{@"message": message}];
    if ([self.delegate respondsToSelector:@selector(playerDidFail:)]) {
        [self.delegate playerDidFail:self.currentTrack];
    }
}

- (void)trySwitchSourceForTrack:(FETrack *)track {
    if (track == nil || self.isSwitchingSource) return;

    FEProviderManager *manager = [FEProviderManager sharedManager];
    id<FEProviderProtocol> candidate = nil;
    for (id<FEProviderProtocol> provider in manager.providers) {
        if ([provider.providerId isEqualToString:track.providerId]) continue;
        if (![provider respondsToSelector:@selector(searchWithKeyword:completion:)]) continue;
        candidate = provider;
        break;
    }
    if (candidate == nil) {
        [self handlePlaybackFailure];
        return;
    }

    self.isSwitchingSource = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:FEPlayerDidFailNotification
                                                        object:self
                                                      userInfo:@{@"message": [NSString stringWithFormat:@"当前音源不可用，正在尝试 %@…", candidate.providerName]}];

    NSString *keyword = [NSString stringWithFormat:@"%@ %@", track.title ?: @"", track.artist ?: @""];
    __weak typeof(self) weakSelf = self;
    [candidate searchWithKeyword:keyword completion:^(NSArray<FETrack *> *tracks, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.isSwitchingSource = NO;

        if (tracks.count == 0) {
            [strongSelf handlePlaybackFailure];
            return;
        }

        FETrack *alternative = tracks[0];
        alternative.title = track.title;
        alternative.artist = track.artist;
        alternative.album = track.album;
        if (track.coverUrl.length > 0) alternative.coverUrl = track.coverUrl;
        [strongSelf playTrack:alternative];
    }];
}

#pragma mark - Item lifecycle

- (void)itemDidPlayToEnd:(NSNotification *)notification {
    if (notification.object != self.observedItem) return;
    if (self.playlist.count > 0) {
        [self next];
    } else {
        self.isPlaying = NO;
        [self postStateChanged];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"] && object == self.observedItem) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        if (item.status == AVPlayerItemStatusReadyToPlay) {
            self.switchAttempt = 0;
            if (self.isPlaying == NO) {
                [self.player play];
                self.isPlaying = YES;
                [self postStateChanged];
            }
            [self updateNowPlayingInfo];
        } else if (item.status == AVPlayerItemStatusFailed) {
            NSLog(@"[FEPlayer] item failed: %@", item.error);
            [self handlePlaybackFailure];
        }
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)unobserveCurrentItem {
    if (self.observedItem == nil) return;
    @try {
        [self.observedItem removeObserver:self forKeyPath:@"status"];
    } @catch (NSException *exception) {
        NSLog(@"[FEPlayer] remove observer failed: %@", exception);
    }
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.observedItem];
    [center removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:self.observedItem];
    self.observedItem = nil;
}

#pragma mark - Helpers

- (id<FEProviderProtocol>)providerForTrack:(FETrack *)track {
    FEProviderManager *manager = [FEProviderManager sharedManager];
    if (track.providerId.length > 0) {
        for (id<FEProviderProtocol> provider in manager.providers) {
            if ([provider.providerId isEqualToString:track.providerId]) return provider;
        }
    }
    return manager.currentProvider;
}

- (void)notifyLyricsForTrack:(FETrack *)track {
    id<FEProviderProtocol> provider = [self providerForTrack:track];
    if (provider == nil || ![provider respondsToSelector:@selector(getLyricForTrack:completion:)]) return;
    if (track.isLocal) return;

    __weak typeof(self) weakSelf = self;
    [provider getLyricForTrack:track completion:^(NSString *lyric, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.currentTrack != track) return;
        if (lyric.length > 0) {
            [[FELyricsManager sharedManager] parseLRC:lyric];
        } else {
            [[FELyricsManager sharedManager] parseLRC:nil];
        }
    }];
}

- (void)addHistoryTrack:(FETrack *)track {
    if (track == nil || track.isLocal) return;
    NSMutableArray *filtered = [NSMutableArray array];
    for (FETrack *item in self.mutableHistory) {
        if (![item.trackId isEqualToString:track.trackId]) [filtered addObject:item];
    }
    [filtered insertObject:track atIndex:0];
    if (filtered.count > 20) {
        [filtered removeObjectsInRange:NSMakeRange(20, filtered.count - 20)];
    }
    self.mutableHistory = filtered;
}

- (NSArray<FETrack *> *)history {
    return [self.mutableHistory copy];
}

- (NSTimeInterval)currentTime {
    CMTime time = self.player.currentTime;
    if (!CMTIME_IS_VALID(time)) return 0;
    NSTimeInterval seconds = CMTimeGetSeconds(time);
    return isfinite(seconds) ? seconds : 0;
}

- (NSTimeInterval)duration {
    AVPlayerItem *item = self.player.currentItem;
    if (item) {
        CMTime time = item.duration;
        if (CMTIME_IS_VALID(time)) {
            NSTimeInterval seconds = CMTimeGetSeconds(time);
            if (isfinite(seconds) && seconds > 0) return seconds;
        }
    }
    return self.currentTrack.duration;
}

- (void)postTrackChanged {
    [[NSNotificationCenter defaultCenter] postNotificationName:FEPlayerDidChangeTrackNotification
                                                        object:self
                                                      userInfo:self.currentTrack ? @{@"track": self.currentTrack} : nil];
    if ([self.delegate respondsToSelector:@selector(playerDidChangeTrack:)]) {
        [self.delegate playerDidChangeTrack:self.currentTrack];
    }
}

- (void)postStateChanged {
    [[NSNotificationCenter defaultCenter] postNotificationName:FEPlayerDidChangeStateNotification
                                                        object:self
                                                      userInfo:@{@"isPlaying": @(self.isPlaying)}];
    if ([self.delegate respondsToSelector:@selector(playerDidChangeState:)]) {
        [self.delegate playerDidChangeState:self.isPlaying];
    }
}

- (void)updateNowPlayingInfo {
    FETrack *track = self.currentTrack;
    if (track == nil) return;

    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[MPMediaItemPropertyTitle] = track.title ?: @"未知歌曲";
    info[MPMediaItemPropertyArtist] = track.artist ?: @"未知艺术家";
    info[MPMediaItemPropertyAlbumTitle] = track.album ?: @"";
    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(self.currentTime);
    info[MPNowPlayingInfoPropertyPlaybackRate] = @(self.isPlaying ? 1.0 : 0.0);
    NSTimeInterval duration = self.duration;
    if (duration > 0) info[MPMediaItemPropertyPlaybackDuration] = @(duration);
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = info;
}

@end
