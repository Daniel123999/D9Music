#import "FELyricsManager.h"

@implementation FELyricsManager

+ (instancetype)sharedManager {
    static FELyricsManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FELyricsManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.lines = [NSMutableArray array];
        self.currentIndex = -1;
    }
    return self;
}

- (void)parseLRC:(NSString *)lrcContent {
    [self.lines removeAllObjects];
    if (!lrcContent) return;
    
    NSArray *linesArr = [lrcContent componentsSeparatedByString:@"\n"];
    for (NSString *lineStr in linesArr) {
        // Match [mm:ss.xx] or [mm:ss]
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[(\\d+):(\\d+)(?:\\.(\\d+))?\\](.*)" options:0 error:nil];
        NSArray *matches = [regex matchesInString:lineStr options:0 range:NSMakeRange(0, lineStr.length)];
        for (NSTextCheckingResult *match in matches) {
            NSString *minStr = [lineStr substringWithRange:[match rangeAtIndex:1]];
            NSString *secStr = [lineStr substringWithRange:[match rangeAtIndex:2]];
            NSString *msStr = @"0";
            if ([match rangeAtIndex:3].location != NSNotFound) {
                msStr = [lineStr substringWithRange:[match rangeAtIndex:3]];
            }
            NSString *text = [lineStr substringWithRange:[match rangeAtIndex:4]];
            text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (text.length == 0) continue;
            
            NSTimeInterval time = [minStr floatValue] * 60 + [secStr floatValue] + [msStr floatValue] / 100.0;
            FELyricLine *lyricLine = [[FELyricLine alloc] init];
            lyricLine.time = time;
            lyricLine.text = text;
            [self.lines addObject:lyricLine];
        }
    }
    [self.lines sortUsingComparator:^NSComparisonResult(FELyricLine *obj1, FELyricLine *obj2) {
        if (obj1.time < obj2.time) return NSOrderedAscending;
        if (obj1.time > obj2.time) return NSOrderedDescending;
        return NSOrderedSame;
    }];
}

- (void)parseWithTranslation:(NSString *)lrcContent translation:(NSString *)transContent {
    [self parseLRC:lrcContent];
    // 简化：翻译行合并到对应行（实际需要更复杂的匹配）
}

- (FELyricLine *)currentLineForTime:(NSTimeInterval)time {
    for (NSInteger i = self.lines.count - 1; i >= 0; i--) {
        if (self.lines[i].time <= time + 0.5) {
            self.currentIndex = i;
            return self.lines[i];
        }
    }
    return nil;
}

@end
