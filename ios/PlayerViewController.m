#import "PlayerViewController.h"
#import "FEPlayerManager.h"
#import "FELyricsManager.h"

@interface PlayerViewController () <FEPlayerDelegate>
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *artistLabel;
@property (nonatomic, strong) UILabel *lyricLabel;
@property (nonatomic, strong) UISlider *progressSlider;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *prevButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *modeButton;
@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"正在播放";
    self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.96 alpha:1.0];
    
    [FEPlayerManager sharedManager].delegate = self;
    
    CGFloat width = self.view.frame.size.width;
    
    self.coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(width/2 - 60, 90, 120, 120)];
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverImageView.clipsToBounds = YES;
    self.coverImageView.layer.cornerRadius = 8;
    self.coverImageView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.coverImageView];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 225, width - 40, 25)];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.view addSubview:self.titleLabel];
    
    self.artistLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 255, width - 40, 20)];
    self.artistLabel.textAlignment = NSTextAlignmentCenter;
    self.artistLabel.font = [UIFont systemFontOfSize:14];
    self.artistLabel.textColor = [UIColor grayColor];
    [self.view addSubview:self.artistLabel];
    
    self.lyricLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 290, width - 40, 40)];
    self.lyricLabel.textAlignment = NSTextAlignmentCenter;
    self.lyricLabel.font = [UIFont systemFontOfSize:13];
    self.lyricLabel.textColor = [UIColor darkGrayColor];
    self.lyricLabel.numberOfLines = 2;
    self.lyricLabel.text = @"暂无歌词";
    [self.view addSubview:self.lyricLabel];
    
    self.progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(30, 345, width - 60, 30)];
    [self.progressSlider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.progressSlider];
    
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 375, width - 60, 20)];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.font = [UIFont systemFontOfSize:12];
    self.timeLabel.textColor = [UIColor grayColor];
    [self.view addSubview:self.timeLabel];
    
    CGFloat btnY = 410;
    self.prevButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.prevButton.frame = CGRectMake(40, btnY, 60, 40);
    [self.prevButton setTitle:@"上一首" forState:UIControlStateNormal];
    [self.prevButton addTarget:self action:@selector(prevTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.prevButton];
    
    self.playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.playButton.frame = CGRectMake(width/2 - 40, btnY, 80, 40);
    [self.playButton setTitle:@"暂停" forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(playTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playButton];
    
    self.nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.nextButton.frame = CGRectMake(width - 100, btnY, 60, 40);
    [self.nextButton setTitle:@"下一首" forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(nextTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];
    
    self.modeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.modeButton.frame = CGRectMake(width/2 - 40, btnY + 50, 80, 30);
    [self.modeButton setTitle:@"列表循环" forState:UIControlStateNormal];
    [self.modeButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
    [self.modeButton addTarget:self action:@selector(modeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.modeButton];
    
    [self updateUI];
}

- (void)updateUI {
    FETrack *track = [FEPlayerManager sharedManager].currentTrack;
    self.titleLabel.text = track.title ?: @"未知歌曲";
    self.artistLabel.text = track.artist ?: @"未知艺术家";
    [self.playButton setTitle:[FEPlayerManager sharedManager].isPlaying ? @"暂停" : @"播放" forState:UIControlStateNormal];
    
    if (track.coverUrl) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:track.coverUrl]];
            if (imageData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.coverImageView.image = [UIImage imageWithData:imageData];
                });
            }
        });
    }
}

- (void)sliderChanged:(UISlider *)slider {
    FEPlayerManager *pm = [FEPlayerManager sharedManager];
    if (pm.player.currentItem) {
        CMTime duration = pm.player.currentItem.duration;
        if (CMTIME_IS_VALID(duration)) {
            Float64 seconds = CMTimeGetSeconds(duration) * slider.value;
            [pm.player seekToTime:CMTimeMakeWithSeconds(seconds, 600)];
        }
    }
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

- (void)modeTapped {
    // 切换播放模式
}

- (void)playerDidChangeTrack:(FETrack *)track {
    [self updateUI];
}

- (void)playerDidChangeState:(BOOL)isPlaying {
    [self.playButton setTitle:isPlaying ? @"暂停" : @"播放" forState:UIControlStateNormal];
}

- (void)playerDidUpdateTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration {
    if (duration > 0) {
        self.progressSlider.value = currentTime / duration;
        self.timeLabel.text = [NSString stringWithFormat:@"%@ / %@", [self formatTime:currentTime], [self formatTime:duration]];
    }
    FELyricLine *line = [[FELyricsManager sharedManager] currentLineForTime:currentTime];
    if (line) {
        self.lyricLabel.text = line.text;
    }
}

- (NSString *)formatTime:(NSTimeInterval)time {
    int minutes = (int)time / 60;
    int seconds = (int)time % 60;
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

@end
