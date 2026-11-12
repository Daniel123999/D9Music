#import <UIKit/UIKit.h>
#import "FEProviderProtocol.h"

/// 手动粘贴 Cookie 登录页（不使用内置网页登录，适配 iPhone 4S）
@interface FELoginViewController : UIViewController

@property (nonatomic, strong) id<FEProviderProtocol> provider;

@end
