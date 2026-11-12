#import <Foundation/Foundation.h>
#import "FETrack.h"

/// 歌曲缓存（Library/Caches/D9Music）
@interface FECacheManager : NSObject

+ (instancetype)sharedManager;

- (NSString *)cacheDirectory;
- (NSString *)cachedPathForTrack:(FETrack *)track quality:(NSInteger)quality;
- (BOOL)hasCachedTrack:(FETrack *)track quality:(NSInteger)quality;

/// 后台把远程歌曲写入缓存；completion 在完成后回调本地路径（失败为 nil）
- (void)cacheTrack:(FETrack *)track url:(NSString *)urlString quality:(NSInteger)quality
        completion:(void (^)(NSString *localPath))completion;

- (unsigned long long)cacheSize;
- (NSInteger)cachedFileCount;
- (void)clearCache;
- (void)enforceLimit;

+ (NSString *)formatSize:(unsigned long long)bytes;

@end
