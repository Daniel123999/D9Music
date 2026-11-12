#import <UIKit/UIKit.h>
#import "FEIconView.h"

/// 简易封面图异步加载 + 内存缓存
@interface FEImageLoader : NSObject

+ (void)loadImageWithURLString:(NSString *)urlString
                    completion:(void (^)(UIImage *image, NSError *error))completion;
+ (void)clearMemoryCache;

@end

/// 圆角封面图（带占位图标与淡入）
@interface FECoverView : UIView

@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) FEIconView *placeholderView;
@property (nonatomic, copy) NSString *urlString;

- (void)setImageURL:(NSString *)urlString;
- (void)setCornerRadius:(CGFloat)radius;

@end
