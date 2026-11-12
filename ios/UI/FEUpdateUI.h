#import <UIKit/UIKit.h>

extern NSString *const FEAutoCheckUpdateKey;

/// 设置页 / 启动时的更新检查与安装提示
@interface FEUpdateUI : NSObject

+ (BOOL)autoCheckEnabled;
+ (void)setAutoCheckEnabled:(BOOL)enabled;
+ (NSString *)currentVersionText;

+ (void)checkForUpdatesFrom:(UIViewController *)host silent:(BOOL)silent;

@end
