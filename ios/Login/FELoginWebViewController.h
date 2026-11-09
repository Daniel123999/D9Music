#import <UIKit/UIKit.h>
#import "FEProviderProtocol.h"

@interface FELoginWebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) id<FEProviderProtocol> provider;

@end
