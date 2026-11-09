#import <Foundation/Foundation.h>

@interface FELyricLine : NSObject

@property (nonatomic, assign) NSTimeInterval time;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *translation;

@end
