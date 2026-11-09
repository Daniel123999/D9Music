#import "FELoginWebViewController.h"
#import "FEProviderProtocol.h"

@interface FELoginViewController : UIViewController <UITextViewDelegate>

@property (nonatomic, strong) id<FEProviderProtocol> provider;

@end
