#import <UIKit/UIKit.h>
#import "FETrack.h"

/// 通用歌曲列表页（歌单 / 排行榜 / 每日推荐 / 新歌）
@interface FETrackListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, copy) NSString *listSubtitle;

- (instancetype)initWithTitle:(NSString *)title tracks:(NSArray<FETrack *> *)tracks;

@end
