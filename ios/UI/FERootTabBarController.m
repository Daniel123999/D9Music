#import "FERootTabBarController.h"
#import "FEMiniPlayerView.h"
#import "FETheme.h"
#import "FEPlayerManager.h"
#import "PlayerViewController.h"

@interface FERootTabBarController ()
@property (nonatomic, strong) FEMiniPlayerView *miniPlayer;
@end

@implementation FERootTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [FETheme background];

    self.miniPlayer = [[FEMiniPlayerView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 58)];
    __weak typeof(self) weakSelf = self;
    self.miniPlayer.onTap = ^{
        [weakSelf showPlayer];
    };
    [self.view addSubview:self.miniPlayer];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(handleTrackChanged:) name:FEPlayerDidChangeTrackNotification object:nil];
    [center addObserver:self selector:@selector(handleStateChanged:) name:FEPlayerDidChangeStateNotification object:nil];
    [center addObserver:self selector:@selector(handleTimeUpdated:) name:FEPlayerDidUpdateTimeNotification object:nil];
    [center addObserver:self selector:@selector(handlePlayerFailed:) name:FEPlayerDidFailNotification object:nil];

    [self refreshMiniPlayer];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat tabBarHeight = self.tabBar.bounds.size.height;
    CGFloat y = self.view.bounds.size.height - tabBarHeight - 58;
    self.miniPlayer.frame = CGRectMake(0, y, self.view.bounds.size.width, 58);
    [self.view bringSubviewToFront:self.miniPlayer];
}

- (void)refreshMiniPlayer {
    FEPlayerManager *manager = [FEPlayerManager sharedManager];
    [self.miniPlayer updateWithTrack:manager.currentTrack playing:manager.isPlaying];
    if (manager.duration > 0) {
        [self.miniPlayer setProgress:(CGFloat)(manager.currentTime / manager.duration)];
    }
}

- (void)handleTrackChanged:(NSNotification *)notification {
    [self refreshMiniPlayer];
}

- (void)handleStateChanged:(NSNotification *)notification {
    [self refreshMiniPlayer];
}

- (void)handleTimeUpdated:(NSNotification *)notification {
    NSNumber *current = notification.userInfo[@"currentTime"];
    NSNumber *duration = notification.userInfo[@"duration"];
    if (duration.doubleValue > 0) {
        [self.miniPlayer setProgress:(CGFloat)(current.doubleValue / duration.doubleValue)];
    }
}

- (void)handlePlayerFailed:(NSNotification *)notification {
    NSString *message = notification.userInfo[@"message"];
    if (message.length > 0) {
        [FETheme showToast:message inView:self.view];
    }
}

- (void)showPlayer {
    if (self.presentedViewController != nil) return;
    if ([FEPlayerManager sharedManager].currentTrack == nil) {
        [FETheme showToast:@"还没有正在播放的歌曲" inView:self.view];
        return;
    }
    PlayerViewController *player = [[PlayerViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:player];
    nav.navigationBarHidden = YES;
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

@end
