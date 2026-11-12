#import <UIKit/UIKit.h>
#import "FEIconView.h"
#import "FEImageView.h"
#import "FETrack.h"

typedef NS_ENUM(NSInteger, FECardStyle) {
    FECardStyleWide = 0,
    FECardStyleTile
};

/// 大图标功能卡片（FuoEvolve 风格）
@interface FECardButton : UIControl

@property (nonatomic, strong, readonly) FEIconView *iconView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;

- (instancetype)initWithFrame:(CGRect)frame
                         icon:(FEIconType)icon
                        title:(NSString *)title
                     subtitle:(NSString *)subtitle
                       accent:(UIColor *)accent
                        style:(FECardStyle)style;

@end

/// 分区标题 + 右侧“查看全部”
@interface FESectionHeaderView : UIView

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UIButton *actionButton;

- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title actionTitle:(NSString *)actionTitle;

@end

/// 歌曲行（封面 + 标题 + 副标题 + 播放图标）
@interface FETrackCell : UITableViewCell

@property (nonatomic, strong, readonly) FECoverView *coverView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;
@property (nonatomic, strong, readonly) FEIconView *playIcon;

- (void)configureWithTrack:(FETrack *)track;
- (void)setPlaying:(BOOL)playing;

@end
