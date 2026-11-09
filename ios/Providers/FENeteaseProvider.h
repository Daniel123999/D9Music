#import <Foundation/Foundation.h>
#import "FEProviderProtocol.h"

@interface FENeteaseProvider : NSObject <FEProviderProtocol>

- (void)getDailyRecommendSongsWithCompletion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion;
- (void)getRadioSongsWithCompletion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion;

@end
