#import <UIKit/UIKit.h>

/// WebDAV 云盘浏览（浏览 / 下载云端歌曲）
@interface FECloudViewController : UIViewController

- (instancetype)initWithRemotePath:(NSString *)remotePath title:(NSString *)title;

@end
