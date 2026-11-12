#import <Foundation/Foundation.h>

typedef void (^FEHttpCompletion)(NSData *data, NSHTTPURLResponse *response, NSError *error);

@interface FEHttpRequest : NSObject

+ (void)GET:(NSString *)url headers:(NSDictionary *)headers completion:(FEHttpCompletion)completion;
+ (void)POST:(NSString *)url headers:(NSDictionary *)headers body:(NSData *)body completion:(FEHttpCompletion)completion;
+ (void)POSTForm:(NSString *)url headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters completion:(FEHttpCompletion)completion;

+ (NSString *)urlEncode:(NSString *)string;

@end
