#import "PlayerViewController.h"

@interface PlayerViewController ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *artistLabel;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"正在播放";
    self.view.backgroundColor = [UIColor whiteColor];
    self.isPlaying = NO;
    
    NSString *title = self.trackInfo[@"title"] ?: @"未知歌曲";
    NSString *artist = self.trackInfo[@"artist"] ?: @"未知艺术家";
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, self.view.frame.size.width - 40, 30)];
    self.titleLabel.text = title;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.titleLabel];
    
    self.artistLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 140, self.view.frame.size.width - 40, 20)];
    self.artistLabel.text = artist;
    self.artistLabel.font = [UIFont systemFontOfSize:16];
    self.artistLabel.textAlignment = NSTextAlignmentCenter;
    self.artistLabel.textColor = [UIColor grayColor];
    [self.view addSubview:self.artistLabel];
    
    self.playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.playButton.frame = CGRectMake((self.view.frame.size.width - 100) / 2, 200, 100, 44);
    [self.playButton setTitle:@"播放" forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(playTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playButton];
}

- (void)playTapped {
    if (self.isPlaying) {
        [self.playButton setTitle:@"播放" forState:UIControlStateNormal];
        self.isPlaying = NO;
    } else {
        [self.playButton setTitle:@"暂停" forState:UIControlStateNormal];
        self.isPlaying = YES;
    }
}

@end
