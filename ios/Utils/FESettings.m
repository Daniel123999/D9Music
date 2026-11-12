#import "FESettings.h"

NSString *const FESettingsDidChangeNotification = @"FESettingsDidChangeNotification";
NSString *const FEAccountDidChangeNotification = @"FEAccountDidChangeNotification";

static NSString *const FEDarkModeKey = @"d9.settings.darkMode";
static NSString *const FELandscapeKey = @"d9.settings.landscapePlayer";
static NSString *const FELastLoginKey = @"d9.account.lastLoginProvider";
static NSString *const FECustomAvatarKey = @"d9.account.useCustomAvatar";
static NSString *const FEAutoUpdateKey = @"d9.settings.autoCheckUpdate";
static NSString *const FEQualityKey = @"d9.settings.preferredQuality";
static NSString *const FECacheEnabledKey = @"d9.settings.cacheEnabled";
static NSString *const FEMaxCacheKey = @"d9.settings.maxCacheMB";

@interface FESettings ()
@property (nonatomic, copy) NSString *customAvatarPath;
@end

@implementation FESettings

+ (instancetype)sharedSettings {
    static FESettings *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FESettings alloc] init];
        [instance load];
    });
    return instance;
}

- (void)load {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _darkMode = [defaults boolForKey:FEDarkModeKey];
    _landscapePlayer = [defaults boolForKey:FELandscapeKey];
    _lastLoginProviderId = [defaults stringForKey:FELastLoginKey] ?: @"";
    _useCustomAvatar = [defaults boolForKey:FECustomAvatarKey];

    // 新安装默认值：自动检查更新、开启缓存、200MB、标准音质
    _autoCheckUpdate = [defaults objectForKey:FEAutoUpdateKey] ? [defaults boolForKey:FEAutoUpdateKey] : YES;
    _preferredQuality = [defaults objectForKey:FEQualityKey] ? [defaults integerForKey:FEQualityKey] : 1;
    _cacheEnabled = [defaults objectForKey:FECacheEnabledKey] ? [defaults boolForKey:FECacheEnabledKey] : YES;
    _maxCacheMB = [defaults objectForKey:FEMaxCacheKey] ? [defaults integerForKey:FEMaxCacheKey] : 200;
    if (_maxCacheMB < 50) _maxCacheMB = 200;

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docs = [paths firstObject] ?: NSTemporaryDirectory();
    _customAvatarPath = [docs stringByAppendingPathComponent:@"d9_avatar.jpg"];
}

- (void)save {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.darkMode forKey:FEDarkModeKey];
    [defaults setBool:self.landscapePlayer forKey:FELandscapeKey];
    [defaults setObject:self.lastLoginProviderId ?: @"" forKey:FELastLoginKey];
    [defaults setBool:self.useCustomAvatar forKey:FECustomAvatarKey];
    [defaults setBool:self.autoCheckUpdate forKey:FEAutoUpdateKey];
    [defaults setInteger:self.preferredQuality forKey:FEQualityKey];
    [defaults setBool:self.cacheEnabled forKey:FECacheEnabledKey];
    [defaults setInteger:self.maxCacheMB forKey:FEMaxCacheKey];
    [defaults synchronize];
}

- (void)notifyChange {
    [self save];
    [[NSNotificationCenter defaultCenter] postNotificationName:FESettingsDidChangeNotification
                                                        object:self
                                                      userInfo:@{@"darkMode": @(self.darkMode),
                                                                 @"landscape": @(self.landscapePlayer)}];
}

- (void)setDarkMode:(BOOL)darkMode {
    if (_darkMode == darkMode) return;
    _darkMode = darkMode;
    [self notifyChange];
}

- (void)setLandscapePlayer:(BOOL)landscapePlayer {
    if (_landscapePlayer == landscapePlayer) return;
    _landscapePlayer = landscapePlayer;
    [self save];
}

- (void)setLastLoginProviderId:(NSString *)lastLoginProviderId {
    _lastLoginProviderId = [lastLoginProviderId copy] ?: @"";
    [self save];
}

- (void)setCustomAvatarImage:(UIImage *)image {
    if (image == nil) return;
    // 统一裁成正方形，避免圆角头像被拉伸
    CGFloat side = MIN(image.size.width, image.size.height);
    if (side <= 0) return;
    CGRect cropRect = CGRectMake((image.size.width - side) / 2.0,
                                 (image.size.height - side) / 2.0,
                                 side, side);
    CGImageRef cropped = CGImageCreateWithImageInRect(image.CGImage, cropRect);
    UIImage *square = cropped ? [UIImage imageWithCGImage:cropped] : image;
    if (cropped) CGImageRelease(cropped);

    NSData *data = UIImageJPEGRepresentation(square, 0.85);
    if (data.length == 0) return;
    [data writeToFile:self.customAvatarPath atomically:YES];
    _useCustomAvatar = data.length > 0;
    [self save];
    [[NSNotificationCenter defaultCenter] postNotificationName:FEAccountDidChangeNotification object:self];
}

- (void)clearCustomAvatar {
    [[NSFileManager defaultManager] removeItemAtPath:self.customAvatarPath error:nil];
    _useCustomAvatar = NO;
    [self save];
    [[NSNotificationCenter defaultCenter] postNotificationName:FEAccountDidChangeNotification object:self];
}

- (UIImage *)customAvatarImage {
    if (!self.useCustomAvatar) return nil;
    return [UIImage imageWithContentsOfFile:self.customAvatarPath];
}

+ (NSString *)qualityTitle:(NSInteger)index {
    if (index == 2) return @"无损";
    if (index == 1) return @"高清";
    return @"标准";
}

+ (NSString *)qualityDetail:(NSInteger)index {
    if (index == 2) return @"FLAC / 尽可能无损";
    if (index == 1) return @"320 kbps";
    return @"128 kbps";
}

@end
