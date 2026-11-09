#import "PlayerViewController.h"
#import "FEPlayerManager.h"
#import "FELyricsManager.h"

@interface PlayerViewController ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *artistLabel;
@property (nonatomic, strong) UILabel *lyricLabel;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *prevButton;
@property (nonatomic, strong) UIButton *nextButton;
@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"正在播放";
    self.view.backgroundColor = [UIColor whiteColor];
    
    FETrack *track = self.trackInfo ? nil : [FEPlayerManager sharedManager].currentTrack;
    if (self.trackInfo && !track) {
        track = [[FETrack alloc] init];
        track.title = self.trackInfo[@"title"] ?: @"未知歌曲";
        track.artist = self.trackInfo[@"artist"] ?: @"未知艺术家";
        [[FEPlayerManager sharedManager] playTrack:track];
    }
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, self.view.frame.size.width - 40, 30)];
    self.titleLabel.text = track.title ?: [FEPlayerManager sharedManager].currentTrack.title;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.titleLabel];
    
    self.artistLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 120, self.view.frame.size.width - 40, 20)];
    self.artistLabel.text = track.artist ?: [FEPlayerManager sharedManager].currentTrack.artist;
    self.artistLabel.font = [UIFont systemFontOfSize:16];
    self.artistLabel.textAlignment = NSTextAlignmentCenter;
    self.artistLabel.textColor = [UIColor grayColor];
    [self.view addSubview:self.artistLabel];
    
    self.lyricLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 180, self.view.frame.size.width - 40, 60)];
    self.lyricLabel.text = @"歌词加载中...";
    self.lyricLabel.font = [UIFont systemFontOfSize:14];
    self.lyricLabel.textAlignment = NSTextAlignmentCenter;
    self.lyricLabel.numberOfLines = 2;
    self.lyricLabel.textColor = [UIColor darkGrayColor];
    [self.view addSubview:self.lyricLabel];
    
    self.prevButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.prevButton.frame = CGRectMake(40, 260, 60, 44);
    [self.prevButton setTitle:@"上一首" forState:UIControlStateNormal];
    [self.prevButton addTarget:self action:@selector(prevTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.prevButton];
    
    self.playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.playButton.frame = CGRectMake((self.view.frame.size.width - 80) / 2, 260, 80, 44);
    [self.playButton setTitle:[FEPlayerManager sharedManager].isPlaying ? @"暂停" : @"播放" forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(playTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playButton];
    
    self.nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.nextButton.frame = CGRectMake(self.view.frame.size.width - 100, 260, 60, 44);
    [self.nextButton setTitle:@"下一首" forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(nextTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];
}

- (void)playTapped {
    [[FEPlayerManager sharedManager] toggle];
    [self.playButton setTitle:[FEPlayerManager sharedManager].isPlaying ? @"暂停" : @"播放" forState:UIControlStateNormal];
}

- (void)prevTapped {
    [[FEPlayerManager sharedManager] previous];
}

- (void)nextTapped {
    [[FEPlayerManager sharedManager] next];
}

@end
