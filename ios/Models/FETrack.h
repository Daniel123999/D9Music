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
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) BOOL isLocal;

+ (instancetype)trackWithTitle:(NSString *)title artist:(NSString *)artist;

@end
