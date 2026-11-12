#import "FEUpdateUI.h"
#import "FEAppUpdater.h"
#import "FETheme.h"

NSString *const FEAutoCheckUpdateKey = @"d9.settings.autoCheckUpdate";

@implementation FEUpdateUI

+ (BOOL)autoCheckEnabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:FEAutoCheckUpdateKey]) return YES;
    return [defaults boolForKey:FEAutoCheckUpdateKey];
}

+ (void)setAutoCheckEnabled:(BOOL)enabled {
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:FEAutoCheckUpdateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)currentVersionText {
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *version = info[@"CFBundleShortVersionString"] ?: @"";
    NSString *build = info[@"CFBundleVersion"] ?: @"";
    if (version.length && build.length) return [NSString stringWithFormat:@"%@ (build %@)", version, build];
    return version.length ? version : build;
}

+ (UIViewController *)topControllerFrom:(UIViewController *)controller {
    UIViewController *top = controller;
    while (top.presentedViewController) top = top.presentedViewController;
    return top;
}

+ (void)showMessage:(NSString *)message title:(NSString *)title from:(UIViewController *)host {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title ?: @"提示"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];
    [[self topControllerFrom:host] presentViewController:alert animated:YES completion:nil];
}

+ (void)checkForUpdatesFrom:(UIViewController *)host silent:(BOOL)silent {
    if (!host) return;
    UIAlertController *busy = nil;
    if (!silent) {
        busy = [UIAlertController alertControllerWithTitle:@"检查更新"
                                                  message:@"正在查询 Gitee / GitHub…"
                                           preferredStyle:UIAlertControllerStyleAlert];
        [host presentViewController:busy animated:YES completion:nil];
    }

    __weak UIViewController *weakHost = host;
    [FEAppUpdater checkForUpdateWithCompletion:^(NSDictionary *info, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController *strongHost = weakHost;
            if (!strongHost) return;
            void (^afterDismiss)(void) = ^{
                if (error) {
                    if (silent) {
                        NSLog(@"[update] 自动检查失败: %@", error.localizedDescription);
                    } else {
                        [self showMessage:error.localizedDescription title:@"检查更新失败" from:strongHost];
                    }
                    return;
                }
                if ([FEAppUpdater isReleaseNewer:info]) {
                    [self promptInstall:info from:strongHost];
                } else if (!silent) {
                    [self showMessage:[NSString stringWithFormat:@"当前已是最新版本 %@", [self currentVersionText]]
                                title:@"检查更新" from:strongHost];
                }
            };
            if (busy.presentingViewController) {
                [busy dismissViewControllerAnimated:NO completion:afterDismiss];
            } else {
                afterDismiss();
            }
        });
    }];
}

+ (void)promptInstall:(NSDictionary *)info from:(UIViewController *)host {
    NSString *latestVersion = [info[@"version"] description] ?: @"";
    NSString *latestBuild = [info[@"build"] description] ?: @"";
    if ([latestBuild isEqualToString:@"(null)"]) latestBuild = @"";
    NSString *latest = latestBuild.length ? [NSString stringWithFormat:@"%@ (build %@)", latestVersion, latestBuild] : latestVersion;

    NSString *message = [NSString stringWithFormat:
        @"当前版本 %@ → 最新 %@\n\n"
         "将下载 IPA 并直接在本机安装（覆盖当前版本，歌单、缓存和设置都会保留），"
         "安装完成后删除安装包并自动重启。\n需要已安装 AppSync Unified。",
        [self currentVersionText], latest];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"发现新版本 %@", latestVersion]
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    __weak UIViewController *weakHost = host;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"下载并安装" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        __strong UIViewController *strongHost = weakHost;
        if (strongHost) [self installRelease:info from:strongHost];
    }]];
    [[self topControllerFrom:host] presentViewController:alert animated:YES completion:nil];
}

+ (void)installRelease:(NSDictionary *)info from:(UIViewController *)host {
    UIAlertController *status = [UIAlertController alertControllerWithTitle:@"正在更新"
                                                                   message:@"准备下载…"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    __block UIProgressView *progressBar = nil;
    [host presentViewController:status animated:YES completion:^{
        CGFloat width = status.view.bounds.size.width - 44;
        if (width < 120) width = 220;
        progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(22, status.view.bounds.size.height - 30, width, 4)];
        progressBar.progressTintColor = [FETheme primary];
        [status.view addSubview:progressBar];
    }];

    __weak UIViewController *weakHost = host;
    [FEAppUpdater installRelease:info
                        progress:^(NSString *stage) {
        dispatch_async(dispatch_get_main_queue(), ^{ status.message = stage; });
    }
                downloadProgress:^(double fraction) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressBar) progressBar.progress = (float)MAX(0.0, MIN(1.0, fraction));
        });
    }
                      completion:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController *strongHost = weakHost;
            [status dismissViewControllerAnimated:NO completion:^{
                if (!strongHost) return;
                if (error) {
                    [self showMessage:error.localizedDescription title:@"更新失败" from:strongHost];
                    return;
                }
                UIAlertController *done = [UIAlertController alertControllerWithTitle:@"安装完成"
                                                                              message:@"更新已安装，安装包已删除。\n应用将在 2 秒后自动重启；如果没有自动打开，请点桌面图标。"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
                [done addAction:[UIAlertAction actionWithTitle:@"立即重启" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [FEAppUpdater relaunchApplication];
                }]];
                [strongHost presentViewController:done animated:YES completion:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{ [FEAppUpdater relaunchApplication]; });
            }];
        });
    }];
}

@end
