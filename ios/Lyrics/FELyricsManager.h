#import <Foundation/Foundation.h>
#import "FELyricLine.h"

@interface FELyricsManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong) NSMutableArray<FELyricLine *> *lines;
@property (nonatomic, assign) NSInteger currentIndex;

- (void)parseLRC:(NSString *)lrcContent;
- (void)parseWithTranslation:(NSString *)lrcContent translation:(NSString *)transContent;
- (FELyricLine *)currentLineForTime:(NSTimeInterval)time;

@end
