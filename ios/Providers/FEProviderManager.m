#import "FEProviderManager.h"

@implementation FEProviderManager

+ (instancetype)sharedManager {
    static FEProviderManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FEProviderManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.providers = [NSMutableArray array];
    }
    return self;
}

- (void)registerProvider:(id<FEProviderProtocol>)provider {
    [self.providers addObject:provider];
    if (!self.currentProvider) {
        self.currentProvider = provider;
    }
}

- (void)switchToProviderWithId:(NSString *)providerId {
    for (id<FEProviderProtocol> provider in self.providers) {
        if ([provider.providerId isEqualToString:providerId]) {
            self.currentProvider = provider;
            break;
        }
    }
}

@end
