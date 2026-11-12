#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, FEIconType) {
    FEIconTypeSparkle = 0,
    FEIconTypeCalendar,
    FEIconTypeRadio,
    FEIconTypeChart,
    FEIconTypeSearch,
    FEIconTypeLibrary,
    FEIconTypeHeadphones,
    FEIconTypePlaylist,
    FEIconTypeUser,
    FEIconTypeLock,
    FEIconTypeCloud,
    FEIconTypeHeart,
    FEIconTypeNote,
    FEIconTypePlay,
    FEIconTypePause,
    FEIconTypeNext,
    FEIconTypePrev,
    FEIconTypeSettings,
    FEIconTypeDisc,
    FEIconTypeMic,
    FEIconTypeDownload,
    FEIconTypeChevronRight,
    FEIconTypeChevronDown,
    FEIconTypeClose,
    FEIconTypeMore,
    FEIconTypeHome,
    FEIconTypeShuffle,
    FEIconTypeRepeat,
    FEIconTypeTV
};

/// 纯代码矢量图标（iOS 9 没有 SF Symbols）
@interface FEIconView : UIView

@property (nonatomic, assign) FEIconType iconType;
@property (nonatomic, assign) CGFloat lineWidth; // 默认 2.0（24pt 坐标系内）

- (instancetype)initWithFrame:(CGRect)frame iconType:(FEIconType)iconType;

+ (UIImage *)imageWithType:(FEIconType)type size:(CGSize)size color:(UIColor *)color;
+ (UIImage *)imageWithType:(FEIconType)type size:(CGSize)size color:(UIColor *)color lineWidth:(CGFloat)lineWidth;

@end
