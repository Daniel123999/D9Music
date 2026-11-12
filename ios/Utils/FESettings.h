#import <UIKit/UIKit.h>

extern NSString *const FESettingsDidChangeNotification;
extern NSString *const FEAccountDidChangeNotification;

/// 全局设置：夜间模式、横屏播放、账号头像
@interface FESettings : NSObject

+ (instancetype)sharedSettings;

@property (nonatomic, assign) BOOL darkMode;
@property (nonatomic, assign) BOOL landscapePlayer;

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
