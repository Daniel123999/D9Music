#import <UIKit/UIKit.h>

extern NSString *const FESettingsDidChangeNotification;
extern NSString *const FEAccountDidChangeNotification;

/// 全局设置：夜间模式、横屏播放、账号头像
@interface FESettings : NSObject

+ (instancetype)sharedSettings;

@property (nonatomic, assign) BOOL darkMode;
@property (nonatomic, assign) BOOL landscapePlayer;

/// 启动时自动检查更新（默认开启）
@property (nonatomic, assign) BOOL autoCheckUpdate;

/// 优先播放音质：0=标准 128k，1=高清 320k，2=无损
@property (nonatomic, assign) NSInteger preferredQuality;

/// 歌曲缓存
@property (nonatomic, assign) BOOL cacheEnabled;
@property (nonatomic, assign) NSInteger maxCacheMB;

+ (NSString *)qualityTitle:(NSInteger)index;
+ (NSString *)qualityDetail:(NSInteger)index;

/// 最近一次成功登录的音源 id（决定“我的”页头像来源）
@property (nonatomic, copy) NSString *lastLoginProviderId;

/// 是否使用自定义头像
@property (nonatomic, assign) BOOL useCustomAvatar;
@property (nonatomic, copy, readonly) NSString *customAvatarPath;

- (void)save;

- (void)setCustomAvatarImage:(UIImage *)image;
- (void)clearCustomAvatar;
- (UIImage *)customAvatarImage;

@end
