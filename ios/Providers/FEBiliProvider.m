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

- (void)searchWithKeyword:(NSString *)keyword completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    NSString *encodedKeyword = [keyword stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *url = [NSString stringWithFormat:@"https://api.bilibili.com/x/web-interface/search/type?search_type=video&keyword=%@&page=1&page_size=30", encodedKeyword];
    NSDictionary *headers = @{@"User-Agent": @"Mozilla/5.0", @"Referer": @"https://www.bilibili.com/"};
    if (self.cookieString) {
        headers = @{@"User-Agent": @"Mozilla/5.0", @"Referer": @"https://www.bilibili.com/", @"Cookie": self.cookieString};
    }
    [FEHttpRequest GET:url headers:headers completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSMutableArray *tracks = [NSMutableArray array];
        if (data) {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            NSArray *results = json[@"data"][@"result"];
            for (NSDictionary *item in results) {
                FETrack *track = [[FETrack alloc] init];
                track.trackId = item[@"bvid"];
                track.title = [item[@"title"] stringByReplacingOccurrencesOfString:@"<[^>]+>" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [item[@"title"] length])];
                track.artist = item[@"author"];
                track.album = @"";
                track.coverUrl = item[@"pic"];
                track.providerId = @"bilibili";
                track.isLocal = NO;
                track.duration = [self parseDuration:item[@"duration"]];
                [tracks addObject:track];
            }
        }
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(tracks, error);
            });
        }
    }];
}

- (NSTimeInterval)parseDuration:(NSString *)duration {
    if (!duration) return 0;
    NSArray *parts = [duration componentsSeparatedByString:@":"];
    NSTimeInterval total = 0;
    for (NSString *part in parts) {
        total = total * 60 + [part doubleValue];
    }
    return total;
}

- (void)getPlayUrlForTrack:(FETrack *)track completion:(void (^)(NSString *playUrl, NSError *error))completion {
    NSString *url = [NSString stringWithFormat:@"https://api.bilibili.com/x/web-interface/view?bvid=%@", track.trackId];
    NSDictionary *headers = @{@"User-Agent": @"Mozilla/5.0", @"Referer": @"https://www.bilibili.com/"};
    if (self.cookieString) {
        headers = @{@"User-Agent": @"Mozilla/5.0", @"Referer": @"https://www.bilibili.com/", @"Cookie": self.cookieString};
    }
    [FEHttpRequest GET:url headers:headers completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSString *playUrl = nil;
        if (data) {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            NSNumber *cid = json[@"data"][@"cid"];
            if (cid) {
                NSString *playUrlApi = [NSString stringWithFormat:@"https://api.bilibili.com/x/player/playurl?bvid=%@&cid=%@&fnval=16&fnver=0&fourk=1", track.trackId, cid];
                [FEHttpRequest GET:playUrlApi headers:headers completion:^(NSData *playData, NSHTTPURLResponse *playResponse, NSError *playError) {
                    if (playData) {
                        NSError *playJsonError;
                        NSDictionary *playJson = [NSJSONSerialization JSONObjectWithData:playData options:0 error:&playJsonError];
                        NSArray *durl = playJson[@"data"][@"durl"];
                        if (durl.count > 0) {
                            playUrl = durl[0][@"url"];
                        }
                    }
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(playUrl, playError);
                        });
                    }
                }];
                return;
            }
        }
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
        }
    }];
}

- (void)getLyricForTrack:(FETrack *)track completion:(void (^)(NSString *lyric, NSError *error))completion {
    // B站音乐歌词通常无标准LRC，返回空
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, nil);
        });
    }
}

- (void)getUserPlaylistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion {
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(@[], nil);
        });
    }
}

- (void)getPlaylistTracks:(FEPlaylist *)playlist completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(@[], nil);
        });
    }
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
