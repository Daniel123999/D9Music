#import "FEImageView.h"
#import "FETheme.h"

static NSCache *FEImageMemoryCache(void) {
    static NSCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.countLimit = 120;
        cache.totalCostLimit = 24 * 1024 * 1024;
    });
    return cache;
}

static NSURLSession *FEImageSession(void) {
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 15;
        config.timeoutIntervalForResource = 30;
        config.HTTPMaximumConnectionsPerHost = 4;
        config.URLCache = [NSURLCache sharedURLCache];
        session = [NSURLSession sessionWithConfiguration:config];
    });
    return session;
}

@implementation FEImageLoader

+ (NSString *)fe_normalizedURLString:(NSString *)urlString {
    if (![urlString isKindOfClass:[NSString class]] || urlString.length == 0) return nil;
    NSString *result = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([result hasPrefix:@"//"]) {
        result = [@"https:" stringByAppendingString:result];
    } else if ([result hasPrefix:@"http://"]) {
        result = [@"https://" stringByAppendingString:[result substringFromIndex:7]];
    }
    return result;
}

+ (void)loadImageWithURLString:(NSString *)urlString
                    completion:(void (^)(UIImage *image, NSError *error))completion {
    NSString *normalized = [self fe_normalizedURLString:urlString];
    if (normalized.length == 0) {
        if (completion) completion(nil, nil);
        return;
    }

    UIImage *cached = [FEImageMemoryCache() objectForKey:normalized];
    if (cached) {
        if (completion) completion(cached, nil);
        return;
    }

    NSURL *url = [NSURL URLWithString:normalized];
    if (!url) {
        if (completion) completion(nil, nil);
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                       timeoutInterval:15];
    [request setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 9_3 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13G37" forHTTPHeaderField:@"User-Agent"];
    if ([normalized rangeOfString:@"126.net"].location != NSNotFound ||
        [normalized rangeOfString:@"163.com"].location != NSNotFound) {
        [request setValue:@"https://music.163.com/" forHTTPHeaderField:@"Referer"];
    }

    NSURLSessionDataTask *task = [FEImageSession() dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        UIImage *image = nil;
        if (data.length > 0) {
            image = [UIImage imageWithData:data];
        }
        if (image) {
            [FEImageMemoryCache() setObject:image forKey:normalized cost:data.length];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(image, error);
        });
    }];
    [task resume];
}

+ (void)clearMemoryCache {
    [FEImageMemoryCache() removeAllObjects];
}

@end

@implementation FECoverView {
    CGFloat _cornerRadius;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _cornerRadius = 12;
        self.backgroundColor = [FETheme colorWithHex:0xEEF0F7 alpha:1.0];
        self.layer.cornerRadius = _cornerRadius;
        self.layer.masksToBounds = YES;

        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.backgroundColor = [UIColor clearColor];
        [self addSubview:_imageView];

        _placeholderView = [[FEIconView alloc] initWithFrame:CGRectZero iconType:FEIconTypeNote];
        _placeholderView.tintColor = [FETheme colorWithHex:0xB9BECD alpha:1.0];
        _placeholderView.userInteractionEnabled = NO;
        [self addSubview:_placeholderView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = _cornerRadius;
    self.imageView.frame = self.bounds;
    CGFloat side = MIN(self.bounds.size.width, self.bounds.size.height) * 0.42;
    self.placeholderView.frame = CGRectMake((self.bounds.size.width - side) / 2,
                                            (self.bounds.size.height - side) / 2,
                                            side, side);
}

- (void)setCornerRadius:(CGFloat)radius {
    _cornerRadius = radius;
    self.layer.cornerRadius = radius;
    [self setNeedsLayout];
}

- (void)setImageURL:(NSString *)urlString {
    _urlString = [urlString copy];
    self.imageView.image = nil;
    self.placeholderView.hidden = NO;

    if (urlString.length == 0) return;

    __weak typeof(self) weakSelf = self;
    NSString *requested = [urlString copy];
    [FEImageLoader loadImageWithURLString:urlString completion:^(UIImage *image, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (![strongSelf.urlString isEqualToString:requested]) return;
        if (image) {
            strongSelf.imageView.alpha = 0;
            strongSelf.imageView.image = image;
            strongSelf.placeholderView.hidden = YES;
            [UIView animateWithDuration:0.22 animations:^{
                strongSelf.imageView.alpha = 1;
            }];
        }
    }];
}

@end
