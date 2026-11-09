#import "AppDelegate.h"
#import "FERecommendViewController.h"
#import "RootViewController.h"
#import "FEMineViewController.h"
#import "FEProviderManager.h"
#import "FENeteaseProvider.h"
#import "FEQQProvider.h"
#import "FEBiliProvider.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    // 注册音源
    [[FEProviderManager sharedManager] registerProvider:[[FENeteaseProvider alloc] init]];
    [[FEProviderManager sharedManager] registerProvider:[[FEQQProvider alloc] init]];
    [[FEProviderManager sharedManager] registerProvider:[[FEBiliProvider alloc] init]];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    
    FERecommendViewController *recommendVC = [[FERecommendViewController alloc] init];
    UINavigationController *recommendNav = [[UINavigationController alloc] initWithRootViewController:recommendVC];
    recommendNav.tabBarItem.title = @"推荐";
    
    RootViewController *libraryVC = [[RootViewController alloc] init];
    UINavigationController *libraryNav = [[UINavigationController alloc] initWithRootViewController:libraryVC];
    libraryNav.tabBarItem.title = @"音乐库";
    
    FEMineViewController *mineVC = [[FEMineViewController alloc] init];
    UINavigationController *mineNav = [[UINavigationController alloc] initWithRootViewController:mineVC];
    mineNav.tabBarItem.title = @"我的";
    
    tabBarController.viewControllers = @[recommendNav, libraryNav, mineNav];
    
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
    
    return YES;
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
