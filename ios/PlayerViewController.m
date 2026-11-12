#import "PlayerViewController.h"
#import "FETheme.h"
#import "FEImageView.h"
#import "FEIconView.h"
#import "FEPlayerManager.h"
#import "FELyricsManager.h"
#import "FEProviderManager.h"
#import "FEFavoriteManager.h"
#import "FECurrentPlaylistViewController.h"

@interface PlayerViewController ()

@property (nonatomic, strong) FEGradientView *backgroundView;
@property (nonatomic, strong) FECoverView *coverView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *artistLabel;
@property (nonatomic, strong) UILabel *lyricLabel;
@property (nonatomic, strong) UILabel *sourceLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UISlider *progressSlider;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *prevButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *favoriteButton;
@property (nonatomic, strong) UIButton *playlistButton;
@property (nonatomic, assign) BOOL isSeeking;

@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [FETheme colorWithHex:0x160F2A alpha:1.0];

    self.backgroundView = [[FEGradientView alloc] initWithFrame:self.view.bounds];
    self.backgroundView.colors = [FETheme darkGradientColors];
    [self.view addSubview:self.backgroundView];

    CGFloat width = self.view.bounds.size.width;

    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.frame = CGRectMake(14, 26, 36, 36);
    self.closeButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
    self.closeButton.layer.cornerRadius = 18;
    [self.closeButton setImage:[FEIconView imageWithType:FEIconTypeChevronDown size:CGSizeMake(18, 18) color:[UIColor whiteColor]] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];

    self.sourceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 32, 110, 24)];
    self.sourceLabel.center = CGPointMake(width / 2, 44);
    self.sourceLabel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
    self.sourceLabel.layer.cornerRadius = 12;
    self.sourceLabel.layer.masksToBounds = YES;
    self.sourceLabel.textAlignment = NSTextAlignmentCenter;
    self.sourceLabel.font = [UIFont boldSystemFontOfSize:10.5];
    self.sourceLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.85];
    [self.view addSubview:self.sourceLabel];

    CGFloat coverSide = 190;
    self.coverView = [[FECoverView alloc] initWithFrame:CGRectMake((width - coverSide) / 2, 70, coverSide, coverSide)];
    [self.coverView setCornerRadius:22];
    self.coverView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.coverView.layer.shadowOpacity = 0.5;
    self.coverView.layer.shadowRadius = 24;
    self.coverView.layer.shadowOffset = CGSizeMake(0, 14);
    self.coverView.layer.masksToBounds = NO;
    self.coverView.imageView.layer.cornerRadius = 22;
    self.coverView.imageView.layer.masksToBounds = YES;
    [self.view addSubview:self.coverView];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 276, width - 40, 26)];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:19];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.view addSubview:self.titleLabel];

    self.artistLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 302, width - 40, 18)];
    self.artistLabel.textAlignment = NSTextAlignmentCenter;
    self.artistLabel.font = [UIFont systemFontOfSize:12];
    self.artistLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.62];
    [self.view addSubview:self.artistLabel];

    self.lyricLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 324, width - 48, 34)];
    self.lyricLabel.textAlignment = NSTextAlignmentCenter;
    self.lyricLabel.font = [UIFont systemFontOfSize:12];
    self.lyricLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.85];
    self.lyricLabel.numberOfLines = 2;
    self.lyricLabel.text = @"暂无歌词";
    [self.view addSubview:self.lyricLabel];

    self.progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(32, 362, width - 64, 24)];
    self.progressSlider.minimumTrackTintColor = [FETheme secondary];
    self.progressSlider.maximumTrackTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18];
    [self.progressSlider setThumbImage:[self thumbImage] forState:UIControlStateNormal];
    [self.progressSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.progressSlider addTarget:self action:@selector(sliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [self.view addSubview:self.progressSlider];

    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(32, 386, width - 64, 14)];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.font = [UIFont systemFontOfSize:10];
    self.timeLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.55];
    self.timeLabel.text = @"00:00 / 00:00";
    [self.view addSubview:self.timeLabel];

    self.prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.prevButton.frame = CGRectMake(width / 2 - 108, 408, 48, 48);
    [self.prevButton setImage:[FEIconView imageWithType:FEIconTypePrev size:CGSizeMake(26, 26) color:[[UIColor whiteColor] colorWithAlphaComponent:0.9]] forState:UIControlStateNormal];
    [self.prevButton addTarget:self action:@selector(prevTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.prevButton];

    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playButton.frame = CGRectMake(width / 2 - 32, 400, 64, 64);
    self.playButton.backgroundColor = [UIColor whiteColor];
    self.playButton.layer.cornerRadius = 32;
    [self.playButton addTarget:self action:@selector(playTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playButton];

    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextButton.frame = CGRectMake(width / 2 + 60, 408, 48, 48);
    [self.nextButton setImage:[FEIconView imageWithType:FEIconTypeNext size:CGSizeMake(26, 26) color:[[UIColor whiteColor] colorWithAlphaComponent:0.9]] forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(nextTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];
    
    self.favoriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.favoriteButton.frame = CGRectMake(width / 2 - 88, 464, 40, 40);
    [self.favoriteButton setImage:[FEIconView imageWithType:FEIconTypeHeart size:CGSizeMake(22, 22) color:[[UIColor whiteColor] colorWithAlphaComponent:0.7]] forState:UIControlStateNormal];
    [self.favoriteButton addTarget:self action:@selector(favoriteTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.favoriteButton];
    
    self.playlistButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playlistButton.frame = CGRectMake(width / 2 + 48, 464, 40, 40);
    [self.playlistButton setImage:[FEIconView imageWithType:FEIconTypePlaylist size:CGSizeMake(22, 22) color:[[UIColor whiteColor] colorWithAlphaComponent:0.7]] forState:UIControlStateNormal];
    [self.playlistButton addTarget:self action:@selector(playlistTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playlistButton];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(handleTrackChanged:) name:FEPlayerDidChangeTrackNotification object:nil];
    [center addObserver:self selector:@selector(handleStateChanged:) name:FEPlayerDidChangeStateNotification object:nil];
    [center addObserver:self selector:@selector(handleTimeUpdated:) name:FEPlayerDidUpdateTimeNotification object:nil];

    [self updateUI];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIImage *)thumbImage {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(12, 12), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, 12, 12));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)updateUI {
    FEPlayerManager *manager = [FEPlayerManager sharedManager];
    FETrack *track = manager.currentTrack;
    self.titleLabel.text = track.title ?: @"未知歌曲";
    self.artistLabel.text = track.artist ?: @"未知艺术家";
    [self.coverView setImageURL:track.coverUrl];

    NSString *sourceName = @"本地音乐";
    for (id<FEProviderProtocol> provider in [FEProviderManager sharedManager].providers) {
        if ([provider.providerId isEqualToString:track.providerId]) {
            sourceName = provider.providerName;
            break;
        }
    }
    self.sourceLabel.text = sourceName;
    
    [self updateFavoriteButton];

    [self updatePlayIcon:manager.isPlaying];
    if (track == nil) {
        self.lyricLabel.text = @"暂无歌词";
    }
    [self updateTimeWithCurrent:manager.currentTime duration:manager.duration];
}

- (void)updateFavoriteButton {
    FETrack *track = [FEPlayerManager sharedManager].currentTrack;
    BOOL fav = [[FEFavoriteManager sharedManager] isFavorite:track];
    UIColor *color = fav ? [FETheme secondary] : [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    [self.favoriteButton setImage:[FEIconView imageWithType:FEIconTypeHeart size:CGSizeMake(22, 22) color:color] forState:UIControlStateNormal];
}

- (void)updatePlayIcon:(BOOL)playing {
    UIImage *icon = [FEIconView imageWithType:(playing ? FEIconTypePause : FEIconTypePlay)
                                        size:CGSizeMake(24, 24)
                                       color:[FETheme primary]
                                   lineWidth:2.0];
    [self.playButton setImage:icon forState:UIControlStateNormal];
}

- (void)updateTimeWithCurrent:(NSTimeInterval)current duration:(NSTimeInterval)duration {
    if (duration > 0 && !self.isSeeking) {
        self.progressSlider.value = (float)(current / duration);
    }
    self.timeLabel.text = [NSString stringWithFormat:@"%@ / %@", [self formatTime:current], [self formatTime:duration]];

    FELyricLine *line = [[FELyricsManager sharedManager] currentLineForTime:current];
    if (line.text.length > 0) {
        self.lyricLabel.text = line.text;
    } else if (line == nil) {
        self.lyricLabel.text = @"暂无歌词";
    }
}

- (NSString *)formatTime:(NSTimeInterval)time {
    if (!isfinite(time) || time < 0) time = 0;
    int minutes = (int)time / 60;
    int seconds = (int)time % 60;
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

#pragma mark - Notification

- (void)handleTrackChanged:(NSNotification *)notification {
    [self updateUI];
}

- (void)handleStateChanged:(NSNotification *)notification {
    [self updatePlayIcon:[FEPlayerManager sharedManager].isPlaying];
}

- (void)handleTimeUpdated:(NSNotification *)notification {
    if (self.isSeeking) return;
    NSNumber *current = notification.userInfo[@"currentTime"];
    NSNumber *duration = notification.userInfo[@"duration"];
    [self updateTimeWithCurrent:current.doubleValue duration:duration.doubleValue];
}

#pragma mark - Actions

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)playTapped {
    [[FEPlayerManager sharedManager] toggle];
}

- (void)prevTapped {
    [[FEPlayerManager sharedManager] previous];
}

- (void)nextTapped {
    [[FEPlayerManager sharedManager] next];
}

- (void)favoriteTapped {
    FETrack *track = [FEPlayerManager sharedManager].currentTrack;
    if (track == nil) return;
    [[FEFavoriteManager sharedManager] toggleFavorite:track completion:^(BOOL isFavorite, BOOL success) {
        [self updateFavoriteButton];
        if (success) {
            [FETheme showToast:isFavorite ? @"已收藏" : @"已取消收藏" inView:self.view];
        }
    }];
}

- (void)playlistTapped {
    FECurrentPlaylistViewController *vc = [[FECurrentPlaylistViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)sliderValueChanged:(UISlider *)slider {
    self.isSeeking = YES;
    NSTimeInterval duration = [FEPlayerManager sharedManager].duration;
    NSTimeInterval current = duration * slider.value;
    self.timeLabel.text = [NSString stringWithFormat:@"%@ / %@", [self formatTime:current], [self formatTime:duration]];
}

- (void)sliderTouchEnded:(UISlider *)slider {
    [[FEPlayerManager sharedManager] seekToProgress:slider.value];
    self.isSeeking = NO;
}

@end
