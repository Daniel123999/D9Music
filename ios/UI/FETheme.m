#import "FETheme.h"
#import <QuartzCore/QuartzCore.h>

@implementation FETheme

+ (UIColor *)colorWithHex:(NSUInteger)hex alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                           green:((hex >> 8) & 0xFF) / 255.0
                            blue:(hex & 0xFF) / 255.0
                           alpha:alpha];
}

+ (UIColor *)primary { return [self colorWithHex:0x6C5CE7 alpha:1.0]; }
+ (UIColor *)primaryDark { return [self colorWithHex:0x4B3FC4 alpha:1.0]; }
+ (UIColor *)secondary { return [self colorWithHex:0xFF6B9D alpha:1.0]; }
+ (UIColor *)accent { return [self colorWithHex:0x14C8B8 alpha:1.0]; }
+ (UIColor *)warning { return [self colorWithHex:0xFF9F43 alpha:1.0]; }
+ (UIColor *)background { return [self colorWithHex:0xF5F6FA alpha:1.0]; }
+ (UIColor *)card { return [UIColor whiteColor]; }
+ (UIColor *)textPrimary { return [self colorWithHex:0x1B1D28 alpha:1.0]; }
+ (UIColor *)textSecondary { return [self colorWithHex:0x8A8FA3 alpha:1.0]; }
+ (UIColor *)textOnDark { return [UIColor whiteColor]; }
+ (UIColor *)separator { return [self colorWithHex:0xE8EAF2 alpha:1.0]; }

+ (UIFont *)titleFont { return [UIFont boldSystemFontOfSize:24]; }
+ (UIFont *)sectionFont { return [UIFont boldSystemFontOfSize:17]; }
+ (UIFont *)bodyFont { return [UIFont systemFontOfSize:14]; }
+ (UIFont *)captionFont { return [UIFont systemFontOfSize:12]; }
+ (UIFont *)tinyFont { return [UIFont systemFontOfSize:10]; }

+ (void)applyCardStyle:(UIView *)view {
    [self applyCardStyle:view radius:18];
}

+ (void)applyCardStyle:(UIView *)view radius:(CGFloat)radius {
    view.backgroundColor = [self card];
    view.layer.cornerRadius = radius;
    view.layer.shadowColor = [UIColor colorWithWhite:0.12 alpha:0.10].CGColor;
    view.layer.shadowOpacity = 1.0;
    view.layer.shadowRadius = 12;
    view.layer.shadowOffset = CGSizeMake(0, 5);
    view.layer.masksToBounds = NO;
}

+ (CAGradientLayer *)addGradientToView:(UIView *)view colors:(NSArray *)colors {
    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.colors = colors;
    layer.frame = view.bounds;
    layer.startPoint = CGPointMake(0, 0);
    layer.endPoint = CGPointMake(1, 1);
    layer.cornerRadius = view.layer.cornerRadius;
    [view.layer insertSublayer:layer atIndex:0];
    return layer;
}

+ (NSArray *)primaryGradientColors {
    return @[(id)[self primary].CGColor, (id)[self secondary].CGColor];
}

+ (NSArray *)darkGradientColors {
    return @[(id)[self colorWithHex:0x1A1130 alpha:1.0].CGColor,
             (id)[self colorWithHex:0x3A1F5C alpha:1.0].CGColor,
             (id)[self colorWithHex:0x1A1130 alpha:1.0].CGColor];
}

+ (void)applyGlobalAppearance {
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTintColor:[self primary]];
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
        NSForegroundColorAttributeName: [self textPrimary],
        NSFontAttributeName: [UIFont boldSystemFontOfSize:17]
    }];
    [[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]];
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];

    [[UITabBar appearance] setBarTintColor:[UIColor whiteColor]];
    [[UITabBar appearance] setTintColor:[self primary]];
    [[UITabBar appearance] setTranslucent:NO];
    [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
    [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
}

+ (void)styleTableView:(UITableView *)tableView {
    tableView.backgroundColor = [self background];
    tableView.separatorColor = [self separator];
    tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

+ (UIButton *)primaryButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [self primary];
    button.layer.cornerRadius = 22;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    return button;
}

+ (void)showToast:(NSString *)message inView:(UIView *)view {
    if (message.length == 0 || view == nil) return;
    UILabel *toast = [[UILabel alloc] init];
    toast.text = message;
    toast.textColor = [UIColor whiteColor];
    toast.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.92];
    toast.font = [UIFont systemFontOfSize:12];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.numberOfLines = 2;
    toast.layer.cornerRadius = 12;
    toast.layer.masksToBounds = YES;
    CGFloat maxWidth = view.bounds.size.width - 48;
    CGSize size = [message boundingRectWithSize:CGSizeMake(maxWidth - 32, 80)
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:@{NSFontAttributeName: toast.font}
                                        context:nil].size;
    CGFloat width = MIN(maxWidth, size.width + 32);
    toast.frame = CGRectMake((view.bounds.size.width - width) / 2, view.bounds.size.height - 150, width, 40);
    toast.alpha = 0;
    [view addSubview:toast];
    [UIView animateWithDuration:0.2 animations:^{
        toast.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:1.8 options:0 animations:^{
            toast.alpha = 0;
        } completion:^(BOOL done) {
            [toast removeFromSuperview];
        }];
    }];
}

@end

@implementation FEGradientView {
    CAGradientLayer *_gradientLayer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _startPoint = CGPointMake(0, 0);
        _endPoint = CGPointMake(1, 1);
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.frame = self.bounds;
        [self.layer insertSublayer:_gradientLayer atIndex:0];
    }
    return self;
}

- (void)setColors:(NSArray *)colors {
    _colors = colors;
    _gradientLayer.colors = colors;
}

- (void)setStartPoint:(CGPoint)startPoint {
    _startPoint = startPoint;
    _gradientLayer.startPoint = startPoint;
}

- (void)setEndPoint:(CGPoint)endPoint {
    _endPoint = endPoint;
    _gradientLayer.endPoint = endPoint;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _gradientLayer.frame = self.bounds;
    _gradientLayer.cornerRadius = self.layer.cornerRadius;
}

@end

@implementation FERoundedView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _corners = UIRectCornerTopLeft | UIRectCornerTopRight;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                               byRoundingCorners:self.corners
                                                     cornerRadii:CGSizeMake(18, 18)];
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.path = path.CGPath;
    self.layer.mask = mask;
}

@end
