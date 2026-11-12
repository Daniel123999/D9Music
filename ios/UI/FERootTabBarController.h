#import <UIKit/UIKit.h>

/// 主 TabBar（在 TabBar 上方承载迷你播放条）
@interface FERootTabBarController : UITabBarController

- (void)showPlayer;
- (void)refreshMiniPlayer;

@end
