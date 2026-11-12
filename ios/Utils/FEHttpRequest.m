#import "FEHttpRequest.h"

@implementation FEHttpRequest

+ (NSString *)urlEncode:(NSString *)string {
    if (![string isKindOfClass:[NSString class]]) return @"";
    NSMutableCharacterSet *allowed = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [allowed addCharactersInString:@"-._~"];
    NSString *encoded = [string stringByAddingPercentEncodingWithAllowedCharacters:allowed];
    return encoded ?: @"";
}

+ (NSMutableURLRequest *)fe_requestWithURL:(NSString *)url method:(NSString *)method headers:(NSDictionary *)headers {
    NSURL *u = [NSURL URLWithString:url];
    if (u == nil) return nil;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:u
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:15];
    [request setHTTPMethod:method];
    [request setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 9_3 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13G37"
   forHTTPHeaderField:@"User-Agent"];
    for (NSString *key in headers) {
        id value = headers[key];
        if ([value isKindOfClass:[NSString class]]) {
            [request setValue:value forHTTPHeaderField:key];
        }
    }
    return request;
}

+ (void)fe_sendRequest:(NSMutableURLRequest *)request completion:(FEHttpCompletion)completion {
    if (request == nil) {
        if (completion) completion(nil, nil, [NSError errorWithDomain:@"FEHttpRequest" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"无效的请求地址"}]);
        return;
    }
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSHTTPURLResponse *httpResponse = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
        if (completion) {
            completion(data, httpResponse, connectionError);
        }
    }];
}

+ (void)GET:(NSString *)url headers:(NSDictionary *)headers completion:(FEHttpCompletion)completion {
    NSMutableURLRequest *request = [self fe_requestWithURL:url method:@"GET" headers:headers];
    [self fe_sendRequest:request completion:completion];
}

+ (void)POST:(NSString *)url headers:(NSDictionary *)headers body:(NSData *)body completion:(FEHttpCompletion)completion {
    NSMutableURLRequest *request = [self fe_requestWithURL:url method:@"POST" headers:headers];
    if (request && body) {
        [request setHTTPBody:body];
    }
    if (request && [request valueForHTTPHeaderField:@"Content-Type"] == nil) {
        [request setValue:@"application/x-www-form-urlencoded; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    }
    [self fe_sendRequest:request completion:completion];
}

+ (void)POSTForm:(NSString *)url headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters completion:(FEHttpCompletion)completion {
    NSMutableArray *pairs = [NSMutableArray array];
    for (NSString *key in parameters) {
        id value = parameters[key];
        NSString *stringValue = [value isKindOfClass:[NSString class]] ? value : [value description];
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", [self urlEncode:key], [self urlEncode:stringValue]]];
    }
    NSString *bodyString = [pairs componentsJoinedByString:@"&"];
    [self POST:url
       headers:headers
          body:[bodyString dataUsingEncoding:NSUTF8StringEncoding]
    completion:completion];
}

@end
