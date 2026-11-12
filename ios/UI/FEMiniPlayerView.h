#import <UIKit/UIKit.h>
#import "FETrack.h"

/// 底部迷你播放条
@interface FEMiniPlayerView : UIView

@property (nonatomic, copy) void (^onTap)(void);

- (void)updateWithTrack:(FETrack *)track playing:(BOOL)playing;
- (void)setProgress:(CGFloat)progress;

@end
