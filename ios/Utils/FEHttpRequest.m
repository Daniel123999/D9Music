#import "FEHttpRequest.h"

@implementation FEHttpRequest

+ (void)GET:(NSString *)url headers:(NSDictionary *)headers completion:(FEHttpCompletion)completion {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"GET"];
    for (NSString *key in headers) {
        [request setValue:headers[key] forHTTPHeaderField:key];
    }
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (completion) {
            completion(data, (NSHTTPURLResponse *)response, connectionError);
        }
    }];
}

+ (void)POST:(NSString *)url headers:(NSDictionary *)headers body:(NSData *)body completion:(FEHttpCompletion)completion {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    for (NSString *key in headers) {
        [request setValue:headers[key] forHTTPHeaderField:key];
    }
    [request setHTTPBody:body];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (completion) {
            completion(data, (NSHTTPURLResponse *)response, connectionError);
        }
    }];
}

@end
