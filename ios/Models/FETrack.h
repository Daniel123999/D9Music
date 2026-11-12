#import <Foundation/Foundation.h>

@interface FETrack : NSObject <NSCoding>

@property (nonatomic, copy) NSString *trackId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *artist;
@property (nonatomic, copy) NSString *album;
@property (nonatomic, copy) NSString *coverUrl;
@property (nonatomic, copy) NSString *playUrl;
@property (nonatomic, copy) NSString *lyricUrl;
@property (nonatomic, copy) NSString *providerId; // netease/qq/bilibili/local
@property (nonatomic, strong) NSDictionary *httpHeaders; // 播放时附加的请求头（如 B 站 Referer）
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) BOOL isLocal;
@property (nonatomic, assign) BOOL isFavorite;

+ (instancetype)trackWithTitle:(NSString *)title artist:(NSString *)artist;

@end
