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

    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];

    return YES;
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
