#import "RootViewController.h"
#import "SearchViewController.h"
#import "PlayerViewController.h"
#import "FESourceListViewController.h"
#import "FELocalMusicViewController.h"
#import "FEPlaylistListViewController.h"

@interface RootViewController ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *sourceButton;
@property (nonatomic, strong) UIButton *searchButton;
@property (nonatomic, strong) UIButton *localMusicButton;
@property (nonatomic, strong) UIButton *playlistButton;
@property (nonatomic, strong) UIButton *playerButton;
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"FuoEvolve";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 70, self.view.frame.size.width - 40, 40)];
    self.titleLabel.text = @"FeelUOwn";
    self.titleLabel.font = [UIFont boldSystemFontOfSize:28];
    [self.view addSubview:self.titleLabel];
    
    CGFloat y = 130;
    self.sourceButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.sourceButton.frame = CGRectMake(20, y, self.view.frame.size.width - 40, 44);
    [self.sourceButton setTitle:@"音源切换 & 登录" forState:UIControlStateNormal];
    [self.sourceButton addTarget:self action:@selector(sourceTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.sourceButton];
    y += 54;
    
    self.searchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.searchButton.frame = CGRectMake(20, y, self.view.frame.size.width - 40, 44);
    [self.searchButton setTitle:@"搜索音乐" forState:UIControlStateNormal];
    [self.searchButton addTarget:self action:@selector(searchTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.searchButton];
    y += 54;
    
    self.localMusicButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.localMusicButton.frame = CGRectMake(20, y, self.view.frame.size.width - 40, 44);
    [self.localMusicButton setTitle:@"本地音乐" forState:UIControlStateNormal];
    [self.localMusicButton addTarget:self action:@selector(localMusicTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.localMusicButton];
    y += 54;
    
    self.playlistButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.playlistButton.frame = CGRectMake(20, y, self.view.frame.size.width - 40, 44);
    [self.playlistButton setTitle:@"歌单管理" forState:UIControlStateNormal];
    [self.playlistButton addTarget:self action:@selector(playlistTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playlistButton];
    y += 54;
    
    self.playerButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.playerButton.frame = CGRectMake(20, y, self.view.frame.size.width - 40, 44);
    [self.playerButton setTitle:@"正在播放" forState:UIControlStateNormal];
    [self.playerButton addTarget:self action:@selector(playerTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playerButton];
}

- (void)sourceTapped {
    Class cls = NSClassFromString(@"FESourceListViewController");
    if (cls) {
        id vc = [[cls alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)searchTapped {
    SearchViewController *searchVC = [[SearchViewController alloc] init];
    [self.navigationController pushViewController:searchVC animated:YES];
}

- (void)localMusicTapped {
    Class cls = NSClassFromString(@"FELocalMusicViewController");
    if (cls) {
        id vc = [[cls alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)playlistTapped {
    Class cls = NSClassFromString(@"FEPlaylistListViewController");
    if (cls) {
        id vc = [[cls alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)playerTapped {
    PlayerViewController *playerVC = [[PlayerViewController alloc] init];
    [self.navigationController pushViewController:playerVC animated:YES];
}

@end
