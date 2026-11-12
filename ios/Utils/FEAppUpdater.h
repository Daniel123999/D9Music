#import <Foundation/Foundation.h>

/// 应用内更新：Gitee / GitHub Release 检查 + 下载 IPA + 越狱环境直接安装
@interface FEAppUpdater : NSObject

+ (void)checkForUpdateWithCompletion:(void (^)(NSDictionary *releaseInfo, NSError *error))completion;
+ (BOOL)isReleaseNewer:(NSDictionary *)releaseInfo;

+ (void)installRelease:(NSDictionary *)releaseInfo
              progress:(void (^)(NSString *status))progress
      downloadProgress:(void (^)(double fraction))downloadProgress
            completion:(void (^)(NSError *error))completion;

+ (void)cleanupStalePackages;
+ (void)relaunchApplication;

@end
