#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface FETheme : NSObject

// 主色板（参考 FuoEvolve 的 Material 风格：紫罗兰 + 粉 + 青）
+ (UIColor *)primary;
+ (UIColor *)primaryDark;
+ (UIColor *)secondary;
+ (UIColor *)accent;
+ (UIColor *)warning;
+ (UIColor *)background;
+ (UIColor *)card;
+ (UIColor *)textPrimary;
+ (UIColor *)textSecondary;
+ (UIColor *)textOnDark;
+ (UIColor *)separator;
+ (UIColor *)colorWithHex:(NSUInteger)hex alpha:(CGFloat)alpha;

+ (UIFont *)titleFont;
+ (UIFont *)sectionFont;
+ (UIFont *)bodyFont;
+ (UIFont *)captionFont;
+ (UIFont *)tinyFont;

+ (void)applyCardStyle:(UIView *)view;
+ (void)applyCardStyle:(UIView *)view radius:(CGFloat)radius;
+ (CAGradientLayer *)addGradientToView:(UIView *)view colors:(NSArray *)colors;
+ (NSArray *)primaryGradientColors;
+ (NSArray *)darkGradientColors;

+ (void)applyGlobalAppearance;
+ (void)styleTableView:(UITableView *)tableView;
+ (UIButton *)primaryButtonWithTitle:(NSString *)title;

+ (void)showToast:(NSString *)message inView:(UIView *)view;

@end

/// 自适应尺寸的渐变视图
@interface FEGradientView : UIView
@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) CGPoint endPoint;
@end

/// 顶部圆角卡片（用于列表内容容器）
@interface FERoundedView : UIView
@property (nonatomic, assign) UIRectCorner corners;
@end
