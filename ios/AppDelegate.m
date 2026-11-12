#import "AppDelegate.h"
#import "FERecommendViewController.h"
#import "RootViewController.h"
#import "FEMineViewController.h"
#import "FEProviderManager.h"
#import "FEProviderProtocol.h"
#import "FENeteaseProvider.h"
#import "FEQQProvider.h"
#import "FEBiliProvider.h"
#import "FEPlaylistManager.h"
#import "FERootTabBarController.h"
#import "FETheme.h"
#import "FEIconView.h"
#import "FESettings.h"
#import "PlayerViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [FETheme background];

    [FETheme applyGlobalAppearance];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

    // 注册音源（默认使用网易云）
    [[FEProviderManager sharedManager] registerProvider:[[FENeteaseProvider alloc] init]];
    [[FEProviderManager sharedManager] registerProvider:[[FEQQProvider alloc] init]];
    [[FEProviderManager sharedManager] registerProvider:[[FEBiliProvider alloc] init]];
    [[FEPlaylistManager sharedManager] loadPlaylists];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(settingsDidChange:)
                                                 name:FESettingsDidChangeNotification
                                               object:nil];

    [self buildRootInterface];

    self.window.rootViewController = [self rootTabBarController];
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)buildRootInterface {
    FERootTabBarController *tabBarController = [[FERootTabBarController alloc] init];

    FERecommendViewController *recommendVC = [[FERecommendViewController alloc] init];
    UINavigationController *recommendNav = [self navigationControllerWithRoot:recommendVC];
    recommendNav.tabBarItem = [self tabBarItemWithTitle:@"推荐" icon:FEIconTypeSparkle];

    RootViewController *libraryVC = [[RootViewController alloc] init];
    UINavigationController *libraryNav = [self navigationControllerWithRoot:libraryVC];
    libraryNav.tabBarItem = [self tabBarItemWithTitle:@"音乐库" icon:FEIconTypeLibrary];

    FEMineViewController *mineVC = [[FEMineViewController alloc] init];
    UINavigationController *mineNav = [self navigationControllerWithRoot:mineVC];
    mineNav.tabBarItem = [self tabBarItemWithTitle:@"我的" icon:FEIconTypeUser];

    tabBarController.viewControllers = @[recommendNav, libraryNav, mineNav];
    tabBarController.selectedIndex = 0;
    self.rootTabBarController = tabBarController;
}

- (void)settingsDidChange:(NSNotification *)notification {
    // 夜间模式切换：延迟重建根界面，避免在开关回调中销毁当前页面
    [FETheme applyGlobalAppearance];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        UIViewController *old = strongSelf.window.rootViewController;
        NSInteger selected = 0;
        if ([old isKindOfClass:[UITabBarController class]]) {
            selected = ((UITabBarController *)old).selectedIndex;
        }
        [strongSelf buildRootInterface];
        strongSelf.window.rootViewController = strongSelf.rootTabBarController;
        strongSelf.rootTabBarController.selectedIndex = selected;
        [FETheme showToast:[FESettings sharedSettings].darkMode ? @"已切换到夜间模式" : @"已切换到日间模式"
                    inView:strongSelf.rootTabBarController.view];
    });
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application
  supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    if (![FESettings sharedSettings].landscapePlayer) {
        return UIInterfaceOrientationMaskPortrait;
    }
    UIViewController *presented = self.window.rootViewController.presentedViewController;
    if ([presented isKindOfClass:[UINavigationController class]]) {
        presented = ((UINavigationController *)presented).topViewController;
    }
    if ([presented isKindOfClass:[PlayerViewController class]]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (UINavigationController *)navigationControllerWithRoot:(UIViewController *)root {
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:root];
    nav.navigationBarHidden = YES;
    nav.navigationBar.translucent = NO;
    return nav;
}

- (UITabBarItem *)tabBarItemWithTitle:(NSString *)title icon:(FEIconType)icon {
    UIImage *image = [FEIconView imageWithType:icon size:CGSizeMake(24, 24) color:[UIColor blackColor] lineWidth:1.9];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:title image:image tag:0];
    item.titlePositionAdjustment = UIOffsetMake(0, -1);
    return item;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
