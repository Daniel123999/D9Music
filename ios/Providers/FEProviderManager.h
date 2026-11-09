#import <Foundation/Foundation.h>
#import "FEProviderProtocol.h"

@interface FEProviderManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong) NSMutableArray<id<FEProviderProtocol>> *providers;
@property (nonatomic, strong) id<FEProviderProtocol> currentProvider;

- (void)registerProvider:(id<FEProviderProtocol>)provider;
- (void)switchToProviderWithId:(NSString *)providerId;

@end
