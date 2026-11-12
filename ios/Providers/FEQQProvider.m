#import "FEQQProvider.h"
#import "FEHttpRequest.h"

static NSString *FEQQString(id value) {
    return [value isKindOfClass:[NSString class]] ? value : nil;
}

@interface FEQQProvider ()
@property (nonatomic, copy) NSString *cookieString;
@property (nonatomic, assign) BOOL loggedIn;
@end

@implementation FEQQProvider

- (NSString *)providerId { return @"qq"; }
- (NSString *)providerName { return @"QQ音乐"; }
- (BOOL)isLoggedIn { return self.loggedIn; }
- (NSString *)loginUrl { return @"https://y.qq.com/"; }

- (NSDictionary *)fe_headers {
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    headers[@"Referer"] = @"https://y.qq.com/";
    headers[@"User-Agent"] = @"Mozilla/5.0 (iPhone; CPU iPhone OS 9_3 like Mac OS X)";
    if (self.cookieString.length > 0) headers[@"Cookie"] = self.cookieString;
    return headers;
}

- (void)searchWithKeyword:(NSString *)keyword completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    if (keyword.length == 0) {
        if (completion) completion(@[], nil);
        return;
    }
    NSString *url = [NSString stringWithFormat:@"https://c.y.qq.com/soso/fcgi-bin/client_search_cp?format=json&p=1&n=30&cr=1&g_tk=5381&t=0&w=%@",
                     [FEHttpRequest urlEncode:keyword]];
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSMutableArray *tracks = [NSMutableArray array];
        id json = data.length > 0 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        if ([json isKindOfClass:[NSDictionary class]]) {
            id dataObj = json[@"data"];
            id songObj = [dataObj isKindOfClass:[NSDictionary class]] ? dataObj[@"song"] : nil;
            NSArray *list = [songObj isKindOfClass:[NSDictionary class]] ? songObj[@"list"] : nil;
            if ([list isKindOfClass:[NSArray class]]) {
                for (NSDictionary *item in list) {
                    if (![item isKindOfClass:[NSDictionary class]]) continue;
                    NSString *songMid = item[@"songmid"];
                    if (![songMid isKindOfClass:[NSString class]] || songMid.length == 0) continue;

                    FETrack *track = [[FETrack alloc] init];
                    track.trackId = songMid;
                    track.title = [item[@"songname"] isKindOfClass:[NSString class]] ? item[@"songname"] : @"";
                    NSArray *singers = item[@"singer"];
                    if ([singers isKindOfClass:[NSArray class]] && singers.count > 0) {
                        NSDictionary *singer = singers[0];
                        if ([singer isKindOfClass:[NSDictionary class]]) track.artist = FEQQString(singer[@"name"]);
                    }
                    if (track.artist.length == 0) track.artist = @"QQ音乐";
                    track.album = [item[@"albumname"] isKindOfClass:[NSString class]] ? item[@"albumname"] : @"";
                    NSString *albumMid = item[@"albummid"];
                    if ([albumMid isKindOfClass:[NSString class]] && albumMid.length > 0) {
                        track.coverUrl = [NSString stringWithFormat:@"https://y.qq.com/music/photo_new/T002R300x300M000%@.jpg", albumMid];
                    }
                    id interval = item[@"interval"];
                    if ([interval respondsToSelector:@selector(doubleValue)]) track.duration = [interval doubleValue];
                    track.providerId = @"qq";
                    track.isLocal = NO;
                    [tracks addObject:track];
                }
            }
        }
        if (completion) completion(tracks, tracks.count > 0 ? nil : error);
    }];
}

- (void)getPlayUrlForTrack:(FETrack *)track completion:(void (^)(NSString *playUrl, NSError *error))completion {
    if (track.trackId.length == 0) {
        if (completion) completion(nil, nil);
        return;
    }
    NSDictionary *payload = @{
        @"req_0": @{
            @"module": @"vkey.GetVkeyServer",
            @"method": @"CgiGetVkey",
            @"param": @{
                @"guid": @"10000",
                @"songmid": @[track.trackId],
                @"songtype": @[@0],
                @"uin": @"0",
                @"loginflag": @1,
                @"platform": @"20"
            }
        },
        @"comm": @{@"uin": @"0", @"format": @"json", @"ct": @24, @"cv": @0}
    };
    NSError *jsonError = nil;
    NSData *body = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&jsonError];
    NSString *urlString = [NSString stringWithFormat:@"https://u.y.qq.com/cgi-bin/musicu.fcg?format=json&data=%@",
                           [FEHttpRequest urlEncode:[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]]];
    [FEHttpRequest GET:urlString headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSString *playUrl = nil;
        id json = data.length > 0 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        if ([json isKindOfClass:[NSDictionary class]]) {
            NSDictionary *req = json[@"req_0"];
            if ([req isKindOfClass:[NSDictionary class]]) {
                NSDictionary *reqData = req[@"data"];
                if ([reqData isKindOfClass:[NSDictionary class]]) {
                    NSArray *infos = reqData[@"midurlinfo"];
                    NSArray *sips = reqData[@"sip"];
                    if ([infos isKindOfClass:[NSArray class]] && infos.count > 0) {
                        NSDictionary *info = infos[0];
                        NSString *purl = [info isKindOfClass:[NSDictionary class]] ? FEQQString(info[@"purl"]) : nil;
                        NSString *sip = ([sips isKindOfClass:[NSArray class]] && sips.count > 0) ? FEQQString(sips[0]) : nil;
                        if (purl.length > 0) {
                            playUrl = [NSString stringWithFormat:@"%@%@", sip ?: @"https://dl.stream.qqmusic.qq.com/", purl];
                            track.httpHeaders = @{@"Referer": @"https://y.qq.com/",
                                                  @"User-Agent": @"Mozilla/5.0 (iPhone; CPU iPhone OS 9_3 like Mac OS X)"};
                        }
                    }
                }
            }
        }
        if (completion) completion(playUrl, playUrl.length > 0 ? nil : error);
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
