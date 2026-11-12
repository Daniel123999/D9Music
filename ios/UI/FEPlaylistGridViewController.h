#import <UIKit/UIKit.h>
#import "FEPlaylist.h"

typedef NS_ENUM(NSInteger, FEPlaylistSource) {
    FEPlaylistSourceSquare = 0,
    FEPlaylistSourceHighQuality,
    FEPlaylistSourceToplist,
    FEPlaylistSourcePersonalized,
    FEPlaylistSourceUser
};

/// 歌单网格页（歌单广场 / 排行榜 / 精品歌单 / 我的歌单）
@interface FEPlaylistGridViewController : UIViewController

- (instancetype)initWithSource:(FEPlaylistSource)source title:(NSString *)title;

@end
