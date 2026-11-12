#import "FEBiliProvider.h"
#import "FEHttpRequest.h"

@interface FEBiliProvider ()
@property (nonatomic, copy) NSString *cookieString;
@property (nonatomic, assign) BOOL loggedIn;
@end

@implementation FEBiliProvider

- (NSString *)providerId { return @"bilibili"; }
- (NSString *)providerName { return @"哔哩哔哩"; }
- (BOOL)isLoggedIn { return self.loggedIn; }
- (NSString *)loginUrl { return @"https://www.bilibili.com/"; }

- (NSDictionary *)fe_headers {
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    headers[@"Referer"] = @"https://www.bilibili.com/";
    headers[@"User-Agent"] = @"Mozilla/5.0 (iPhone; CPU iPhone OS 9_3 like Mac OS X)";
    if (self.cookieString.length > 0) headers[@"Cookie"] = self.cookieString;
    return headers;
}

- (NSString *)fe_cleanTitle:(NSString *)title {
    if (![title isKindOfClass:[NSString class]]) return @"";
    NSString *cleaned = [title stringByReplacingOccurrencesOfString:@"<[^>]+>"
                                                        withString:@""
                                                           options:NSRegularExpressionSearch
                                                             range:NSMakeRange(0, title.length)];
    return [cleaned stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)fe_coverURL:(NSString *)url {
    if (![url isKindOfClass:[NSString class]] || url.length == 0) return nil;
    if ([url hasPrefix:@"//"]) return [@"https:" stringByAppendingString:url];
    return url;
}

- (void)searchWithKeyword:(NSString *)keyword completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    if (keyword.length == 0) {
        if (completion) completion(@[], nil);
        return;
    }
    NSString *encoded = [FEHttpRequest urlEncode:keyword];
    NSString *url = [NSString stringWithFormat:@"https://api.bilibili.com/x/web-interface/search/type?search_type=video&keyword=%@&page=1&page_size=30", encoded];
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSMutableArray *tracks = [NSMutableArray array];
        id json = data.length > 0 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        if ([json isKindOfClass:[NSDictionary class]]) {
            id payload = json[@"data"];
            NSArray *results = [payload isKindOfClass:[NSDictionary class]] ? payload[@"result"] : nil;
            if ([results isKindOfClass:[NSArray class]]) {
                for (NSDictionary *item in results) {
                    if (![item isKindOfClass:[NSDictionary class]]) continue;
                    NSString *bvid = item[@"bvid"];
                    if (![bvid isKindOfClass:[NSString class]] || bvid.length == 0) continue;
                    FETrack *track = [[FETrack alloc] init];
                    track.trackId = bvid;
                    track.title = [self fe_cleanTitle:item[@"title"]];
                    track.artist = [item[@"author"] isKindOfClass:[NSString class]] ? item[@"author"] : @"哔哩哔哩";
                    track.album = @"B站视频";
                    track.coverUrl = [self fe_coverURL:item[@"pic"]];
                    track.providerId = @"bilibili";
                    track.isLocal = NO;
                    track.duration = [self parseDuration:item[@"duration"]];
                    [tracks addObject:track];
                }
            }
        }
        if (completion) completion(tracks, tracks.count > 0 ? nil : error);
    }];
}

- (NSTimeInterval)parseDuration:(id)duration {
    if ([duration isKindOfClass:[NSNumber class]]) return [duration doubleValue];
    if (![duration isKindOfClass:[NSString class]]) return 0;
    NSArray *parts = [duration componentsSeparatedByString:@":"];
    NSTimeInterval total = 0;
    for (NSString *part in parts) {
        total = total * 60 + [part doubleValue];
    }
    return total;
}

- (void)getPlayUrlForTrack:(FETrack *)track completion:(void (^)(NSString *playUrl, NSError *error))completion {
    if (track.trackId.length == 0) {
        if (completion) completion(nil, nil);
        return;
    }
    NSDictionary *headers = [self fe_headers];
    NSString *url = [NSString stringWithFormat:@"https://api.bilibili.com/x/web-interface/view?bvid=%@", track.trackId];
    [FEHttpRequest GET:url headers:headers completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        id json = data.length > 0 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        NSNumber *cid = nil;
        if ([json isKindOfClass:[NSDictionary class]]) {
            id payload = json[@"data"];
            if ([payload isKindOfClass:[NSDictionary class]]) {
                cid = payload[@"cid"];
            }
        }
        if (![cid isKindOfClass:[NSNumber class]]) {
            if (completion) completion(nil, error);
            return;
        }

        NSString *playUrlApi = [NSString stringWithFormat:@"https://api.bilibili.com/x/player/playurl?bvid=%@&cid=%@&fnval=16&fnver=0&fourk=1&platform=html5&high_quality=1", track.trackId, cid];
        [FEHttpRequest GET:playUrlApi headers:headers completion:^(NSData *playData, NSHTTPURLResponse *playResponse, NSError *playError) {
            NSString *playUrl = nil;
            id playJson = playData.length > 0 ? [NSJSONSerialization JSONObjectWithData:playData options:0 error:nil] : nil;
            if ([playJson isKindOfClass:[NSDictionary class]]) {
                NSDictionary *payload = playJson[@"data"];
                if ([payload isKindOfClass:[NSDictionary class]]) {
                    NSArray *durl = payload[@"durl"];
                    if ([durl isKindOfClass:[NSArray class]] && durl.count > 0) {
                        id u = ((NSDictionary *)durl[0])[@"url"];
                        if ([u isKindOfClass:[NSString class]]) playUrl = u;
                    }
                    if (playUrl.length == 0) {
                        NSDictionary *dash = payload[@"dash"];
                        NSArray *dashAudio = [dash isKindOfClass:[NSDictionary class]] ? dash[@"audio"] : nil;
                        if ([dashAudio isKindOfClass:[NSArray class]] && dashAudio.count > 0) {
                            NSDictionary *audio = dashAudio[0];
                            id baseUrl = audio[@"baseUrl"] ?: audio[@"base_url"];
                            if ([baseUrl isKindOfClass:[NSString class]]) playUrl = baseUrl;
                        }
                    }
                }
            }
            if (playUrl.length > 0) {
                // B 站 CDN 强制校验 Referer，播放时由 AVURLAsset 携带
                track.httpHeaders = @{@"Referer": @"https://www.bilibili.com/",
                                      @"User-Agent": @"Mozilla/5.0 (iPhone; CPU iPhone OS 9_3 like Mac OS X)"};
            }
            if (completion) completion(playUrl, playUrl.length > 0 ? nil : playError);
        }];
    }];
}

- (void)getLyricForTrack:(FETrack *)track completion:(void (^)(NSString *lyric, NSError *error))completion {
    if (completion) completion(nil, nil);
}

- (void)getUserPlaylistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion {
    if (completion) completion(@[], nil);
}

- (void)getPlaylistTracks:(FEPlaylist *)playlist completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    if (completion) completion(@[], nil);
}

- (void)handleLoginCookies:(NSDictionary *)cookies {
    NSMutableString *cookieStr = [NSMutableString string];
    for (NSString *key in cookies) {
        [cookieStr appendFormat:@"%@=%@; ", key, cookies[key]];
    }
    self.cookieString = cookieStr;
    self.loggedIn = cookies.count > 0;
}

@end
