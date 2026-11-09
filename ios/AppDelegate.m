#import "AppDelegate.h"
#import "RootViewController.h"
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
    
    RootViewController *rootVC = [[RootViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:rootVC];
    navController.navigationBar.translucent = NO;
    
    self.window.rootViewController = navController;
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
