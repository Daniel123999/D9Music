#import "FEProviderManager.h"

static NSString *const FEProviderOrderKey = @"d9.providers.order";
static NSString *const FEProviderEnabledKey = @"d9.providers.enabled";

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

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *order = [defaults arrayForKey:FEProviderOrderKey];
        NSArray *enabled = [defaults arrayForKey:FEProviderEnabledKey];
        self.providerOrder = order ? [order mutableCopy] : [NSMutableArray array];
        // 未配置过时，默认只启用网易云，其余音源需手动开启
        self.enabledProviderIds = enabled ? [enabled mutableCopy] : [NSMutableArray arrayWithObject:@"netease"];
    }
    return self;
}

- (void)registerProvider:(id<FEProviderProtocol>)provider {
    if (provider == nil) return;
    [self.providers addObject:provider];

    if (![self.providerOrder containsObject:provider.providerId]) {
        [self.providerOrder addObject:provider.providerId];
    }
    if (!self.currentProvider) {
        self.currentProvider = provider;
    }
    [self savePreferences];
}

- (id<FEProviderProtocol>)providerWithId:(NSString *)providerId {
    for (id<FEProviderProtocol> provider in self.providers) {
        if ([provider.providerId isEqualToString:providerId]) return provider;
    }
    return nil;
}

- (NSArray<id<FEProviderProtocol>> *)orderedProviders {
    NSMutableArray *result = [NSMutableArray array];
    NSMutableSet *seen = [NSMutableSet set];
    for (NSString *providerId in self.providerOrder) {
        id<FEProviderProtocol> provider = [self providerWithId:providerId];
        if (provider && ![seen containsObject:provider.providerId]) {
            [result addObject:provider];
            [seen addObject:provider.providerId];
        }
    }
    for (id<FEProviderProtocol> provider in self.providers) {
        if (![seen containsObject:provider.providerId]) {
            [result addObject:provider];
            [seen addObject:provider.providerId];
        }
    }
    return result;
}

- (NSArray<id<FEProviderProtocol>> *)enabledProviders {
    NSMutableArray *result = [NSMutableArray array];
    for (id<FEProviderProtocol> provider in [self orderedProviders]) {
        if ([self.enabledProviderIds containsObject:provider.providerId]) {
            [result addObject:provider];
        }
    }
    return result;
}

- (BOOL)isProviderEnabled:(id<FEProviderProtocol>)provider {
    if (provider == nil) return NO;
    return [self.enabledProviderIds containsObject:provider.providerId];
}

- (void)setProvider:(id<FEProviderProtocol>)provider enabled:(BOOL)enabled {
    if (provider == nil) return;
    BOOL contains = [self.enabledProviderIds containsObject:provider.providerId];
    if (enabled && !contains) {
        [self.enabledProviderIds addObject:provider.providerId];
    } else if (!enabled && contains) {
        [self.enabledProviderIds removeObject:provider.providerId];
        if (self.currentProvider == provider) {
            self.currentProvider = [[self enabledProviders] firstObject] ?: nil;
        }
    }
    [self savePreferences];
}

- (NSInteger)priorityIndexForProvider:(id<FEProviderProtocol>)provider {
    NSArray *ordered = [self orderedProviders];
    NSInteger index = [ordered indexOfObject:provider];
    return index == NSNotFound ? 0 : index;
}

- (void)moveProviderAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    NSArray *ordered = [self orderedProviders];
    if (fromIndex < 0 || fromIndex >= (NSInteger)ordered.count) return;
    if (toIndex < 0 || toIndex >= (NSInteger)ordered.count) return;
    if (fromIndex == toIndex) return;
    id<FEProviderProtocol> moved = ordered[fromIndex];
    [self.providerOrder removeObject:moved.providerId];
    NSInteger target = toIndex;
    if (target > (NSInteger)self.providerOrder.count) target = self.providerOrder.count;
    [self.providerOrder insertObject:moved.providerId atIndex:target];
    [self savePreferences];
}

- (void)switchToProviderWithId:(NSString *)providerId {
    id<FEProviderProtocol> provider = [self providerWithId:providerId];
    if (provider == nil) return;
    self.currentProvider = provider;
    if (![self.enabledProviderIds containsObject:provider.providerId]) {
        [self.enabledProviderIds addObject:provider.providerId];
    }
    [self.providerOrder removeObject:provider.providerId];
    [self.providerOrder insertObject:provider.providerId atIndex:0];
    [self savePreferences];
}

- (void)savePreferences {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.providerOrder forKey:FEProviderOrderKey];
    [defaults setObject:self.enabledProviderIds forKey:FEProviderEnabledKey];
    [defaults synchronize];
}

@end
