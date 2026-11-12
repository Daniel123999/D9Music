#import <Foundation/Foundation.h>
#import "FEProviderProtocol.h"

@interface FEProviderManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong) NSMutableArray<id<FEProviderProtocol>> *providers;
@property (nonatomic, strong) id<FEProviderProtocol> currentProvider;

/// 音源优先级（providerId 数组，靠前优先级高）
@property (nonatomic, strong) NSMutableArray<NSString *> *providerOrder;
/// 已启用（“使用中”）的音源 id，可同时启用多个
@property (nonatomic, strong) NSMutableArray<NSString *> *enabledProviderIds;

- (void)registerProvider:(id<FEProviderProtocol>)provider;
- (void)switchToProviderWithId:(NSString *)providerId;

- (id<FEProviderProtocol>)providerWithId:(NSString *)providerId;
- (NSArray<id<FEProviderProtocol>> *)orderedProviders;
- (NSArray<id<FEProviderProtocol>> *)enabledProviders;
- (BOOL)isProviderEnabled:(id<FEProviderProtocol>)provider;
- (void)setProvider:(id<FEProviderProtocol>)provider enabled:(BOOL)enabled;
- (NSInteger)priorityIndexForProvider:(id<FEProviderProtocol>)provider;
- (void)moveProviderAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
- (void)savePreferences;

@end
