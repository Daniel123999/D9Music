#import "FEQQProvider.h"
#import "FEHttpRequest.h"
#import "FESettings.h"

static NSString *FECookieUserDefaultsKey = @"d9.cookie.qq";

static NSString *FEQQString(id value) {
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [(NSNumber *)value stringValue];
    return nil;
}

static id FEQQObject(id dict, NSString *key) {
    if (![dict isKindOfClass:[NSDictionary class]]) return nil;
    id value = [(NSDictionary *)dict objectForKey:key];
    return [value isKindOfClass:[NSNull class]] ? nil : value;
}

static NSString *FEQQDecodeEntities(NSString *text) {
    if (text.length == 0) return @"";
    NSString *result = text;
    result = [result stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
    result = [result stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    result = [result stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    result = [result stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    result = [result stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
    result = [result stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    return result;
}

@interface FEQQProvider ()
@property (nonatomic, copy) NSString *cookieString;
@property (nonatomic, copy) NSString *uin;
@property (nonatomic, assign) BOOL loggedIn;
@end

@implementation FEQQProvider

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *cookie = [[NSUserDefaults standardUserDefaults] stringForKey:FECookieUserDefaultsKey];
        if (cookie.length > 0) {
            _cookieString = [cookie copy];
            _uin = [self fe_parseUinFromCookie:cookie];
            _loggedIn = YES;
        }
    }
    return self;
}

- (NSString *)providerId { return @"qq"; }
- (NSString *)providerName { return @"QQ音乐"; }
- (BOOL)isLoggedIn { return self.loggedIn; }
- (NSString *)loginUrl { return @"https://y.qq.com/"; }

- (NSString *)fe_parseUinFromCookie:(NSString *)cookie {
    if (cookie.length == 0) return @"";
    NSString *found = @"";
    for (NSString *pair in [cookie componentsSeparatedByString:@";"]) {
        NSString *item = [pair stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSRange eq = [item rangeOfString:@"="];
        if (eq.location == NSNotFound) continue;
        NSString *key = [item substringToIndex:eq.location];
        NSString *value = [item substringFromIndex:eq.location + 1];
        if ([key isEqualToString:@"uin"] || [key isEqualToString:@"qqmusic_uin"] || [key isEqualToString:@"wxuin"]) {
            found = value;
            break;
        }
    }
    // uin=o0123456789 / o0012345678 → 去掉前缀 o 与补位的 0
    while ([found hasPrefix:@"o"] || [found hasPrefix:@"O"]) {
        found = [found substringFromIndex:1];
    }
    while ([found hasPrefix:@"0"] && found.length > 1) {
        found = [found substringFromIndex:1];
    }
    return found;
}

- (NSDictionary *)fe_headers {
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    headers[@"Referer"] = @"https://y.qq.com/";
    headers[@"User-Agent"] = @"Mozilla/5.0 (iPhone; CPU iPhone OS 9_3 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13G36";
    if (self.cookieString.length > 0) headers[@"Cookie"] = self.cookieString;
    return headers;
}

- (id)fe_jsonFromData:(NSData *)data {
    if (data.length == 0) return nil;
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if ([json isKindOfClass:[NSDictionary class]]) return json;
    if ([json isKindOfClass:[NSArray class]]) return json;
    // 少数接口返回 JSONP（callback({...})）
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSRange start = [text rangeOfString:@"("];
    NSRange end = [text rangeOfString:@")" options:NSBackwardsSearch];
    if (start.location != NSNotFound && end.location != NSNotFound && end.location > start.location) {
        NSString *inner = [text substringWithRange:NSMakeRange(start.location + 1, end.location - start.location - 1)];
        return [NSJSONSerialization JSONObjectWithData:[inner dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    }
    return nil;
}

- (FETrack *)fe_trackFromSong:(NSDictionary *)item {
    if (![item isKindOfClass:[NSDictionary class]]) return nil;
    NSString *songMid = FEQQString(item[@"songmid"]) ?: FEQQString(item[@"mid"]);
    if (songMid.length == 0) return nil;

    FETrack *track = [[FETrack alloc] init];
    track.trackId = songMid;
    track.title = FEQQString(item[@"songname"]) ?: FEQQString(item[@"name"]) ?: @"";
    NSArray *singers = item[@"singer"];
    NSMutableArray *names = [NSMutableArray array];
    if ([singers isKindOfClass:[NSArray class]]) {
        for (NSDictionary *singer in singers) {
            if ([singer isKindOfClass:[NSDictionary class]]) {
                NSString *name = FEQQString(singer[@"name"]);
                if (name.length > 0) [names addObject:name];
            }
        }
    }
    track.artist = names.count > 0 ? [names componentsJoinedByString:@"/"] : @"QQ音乐";
    track.album = FEQQString(item[@"albumname"]) ?: FEQQString(FEQQObject(item[@"album"], @"name")) ?: @"";
    NSString *albumMid = FEQQString(item[@"albummid"]) ?: FEQQString(FEQQObject(item[@"album"], @"mid"));
    if (albumMid.length > 0) {
        track.coverUrl = [NSString stringWithFormat:@"https://y.qq.com/music/photo_new/T002R300x300M000%@.jpg", albumMid];
    }
    id interval = item[@"interval"];
    if ([interval respondsToSelector:@selector(doubleValue)]) track.duration = [interval doubleValue];
    track.providerId = @"qq";
    track.isLocal = NO;
    return track;
}

- (FEPlaylist *)fe_playlistFromDiss:(NSDictionary *)item {
    if (![item isKindOfClass:[NSDictionary class]]) return nil;
    NSString *dissId = FEQQString(item[@"dissid"]) ?: FEQQString(item[@"tid"]) ?: FEQQString(item[@"id"]);
    if (dissId.length == 0) return nil;
    FEPlaylist *playlist = [[FEPlaylist alloc] init];
    playlist.playlistId = dissId;
    playlist.name = FEQQString(item[@"dissname"]) ?: FEQQString(item[@"title"]) ?: @"QQ歌单";
    playlist.coverUrl = FEQQString(item[@"imgurl"]) ?: FEQQString(item[@"diss_cover"]) ?: @"";
    playlist.providerId = @"qq";
    playlist.isLocal = NO;
    playlist.resourceType = @"playlist";
    id count = item[@"song_count"] ?: item[@"songnum"];
    if ([count respondsToSelector:@selector(integerValue)]) playlist.trackCount = [count integerValue];
    return playlist;
}

#pragma mark - Search

- (void)searchWithKeyword:(NSString *)keyword completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    if (keyword.length == 0) {
        if (completion) completion(@[], nil);
        return;
    }
    NSString *url = [NSString stringWithFormat:@"https://c.y.qq.com/soso/fcgi-bin/client_search_cp?format=json&p=1&n=30&cr=1&g_tk=5381&t=0&w=%@",
                     [FEHttpRequest urlEncode:keyword]];
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSMutableArray *tracks = [NSMutableArray array];
        id json = [self fe_jsonFromData:data];
        NSArray *list = FEQQObject(FEQQObject(FEQQObject(json, @"data"), @"song"), @"list");
        if ([list isKindOfClass:[NSArray class]]) {
            for (NSDictionary *item in list) {
                FETrack *track = [self fe_trackFromSong:item];
                if (track) [tracks addObject:track];
            }
        }
        if (completion) completion(tracks, tracks.count > 0 ? nil : error);
    }];
}

#pragma mark - Play URL

- (void)getPlayUrlForTrack:(FETrack *)track completion:(void (^)(NSString *playUrl, NSError *error))completion {
    if (track.trackId.length == 0) {
        if (completion) completion(nil, nil);
        return;
    }
    NSString *uin = self.uin.length > 0 ? self.uin : @"0";
    NSInteger preferred = [FESettings sharedSettings].preferredQuality;
    NSArray *prefixes = preferred == 2 ? @[@"F000", @"M800", @"C400"]
                       : preferred == 0 ? @[@"C400", @"M500"]
                                        : @[@"M800", @"C400"];
    NSMutableArray *filenames = [NSMutableArray array];
    for (NSString *prefix in prefixes) {
        NSString *ext = [prefix isEqualToString:@"F000"] ? @"flac"
                       : ([prefix hasPrefix:@"M"] ? @"mp3" : @"m4a");
        [filenames addObject:[NSString stringWithFormat:@"%@%@.%@", prefix, track.trackId, ext]];
    }
    NSDictionary *payload = @{
        @"req_0": @{
            @"module": @"vkey.GetVkeyServer",
            @"method": @"CgiGetVkey",
            @"param": @{
                @"guid": @"10000",
                @"songmid": @[track.trackId],
                @"songtype": @[@0],
                @"filename": filenames,
                @"uin": uin,
                @"loginflag": @1,
                @"platform": @"20"
            }
        },
        @"comm": @{@"uin": uin, @"format": @"json", @"ct": @24, @"cv": @0}
    };
    NSData *body = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    NSString *urlString = [NSString stringWithFormat:@"https://u.y.qq.com/cgi-bin/musicu.fcg?format=json&data=%@",
                           [FEHttpRequest urlEncode:[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]]];
    [FEHttpRequest GET:urlString headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSString *playUrl = nil;
        id json = [self fe_jsonFromData:data];
        NSDictionary *req = FEQQObject(json, @"req_0");
        NSDictionary *reqData = FEQQObject(req, @"data");
        NSArray *infos = FEQQObject(reqData, @"midurlinfo");
        NSArray *sips = FEQQObject(reqData, @"sip");
        NSString *sip = ([sips isKindOfClass:[NSArray class]] && sips.count > 0) ? FEQQString(sips[0]) : nil;
        if ([infos isKindOfClass:[NSArray class]]) {
            for (NSDictionary *info in infos) {
                if (![info isKindOfClass:[NSDictionary class]]) continue;
                NSString *purl = FEQQString(info[@"purl"]);
                if (purl.length > 0) {
                    playUrl = [NSString stringWithFormat:@"%@%@", sip.length > 0 ? sip : @"https://dl.stream.qqmusic.qq.com/", purl];
                    track.httpHeaders = @{@"Referer": @"https://y.qq.com/",
                                          @"User-Agent": @"Mozilla/5.0 (iPhone; CPU iPhone OS 9_3 like Mac OS X)"};
                    break;
                }
            }
        }
        if (playUrl.length == 0) {
            // 部分老接口返回 http 直链
            NSString *fallback = [NSString stringWithFormat:@"http://ws.stream.qqmusic.qq.com/C400%@.m4a?fromtag=0", track.trackId];
            playUrl = fallback;
        }
        if (completion) completion(playUrl, playUrl.length > 0 ? nil : error);
    }];
}

#pragma mark - Lyrics

- (void)getLyricForTrack:(FETrack *)track completion:(void (^)(NSString *lyric, NSError *error))completion {
    if (track.trackId.length == 0) {
        if (completion) completion(nil, nil);
        return;
    }
    NSString *url = [NSString stringWithFormat:@"https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg?songmid=%@&format=json&nobase64=1&g_tk=5381",
                     track.trackId];
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSString *lyric = nil;
        id json = [self fe_jsonFromData:data];
        if ([json isKindOfClass:[NSDictionary class]]) {
            lyric = FEQQString(json[@"lyric"]);
            if (lyric.length > 0) lyric = FEQQDecodeEntities(lyric);
        }
        if (completion) completion(lyric, error);
    }];
}

#pragma mark - Recommendations

- (void)getPersonalizedPlaylistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion {
    NSString *url = @"https://c.y.qq.com/splcloud/fcgi-bin/fcg_get_diss_by_tag.fcg?categoryId=10000000&sortId=5&sin=0&ein=11&format=json&g_tk=5381";
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSMutableArray *playlists = [NSMutableArray array];
        id json = [self fe_jsonFromData:data];
        NSArray *list = FEQQObject(FEQQObject(json, @"data"), @"list");
        if ([list isKindOfClass:[NSArray class]]) {
            for (NSDictionary *item in list) {
                FEPlaylist *playlist = [self fe_playlistFromDiss:item];
                if (playlist) {
                    id listeners = item[@"listennum"];
                    if ([listeners respondsToSelector:@selector(integerValue)]) playlist.playCount = [listeners integerValue];
                    [playlists addObject:playlist];
                }
            }
        }
        if (completion) completion(playlists, playlists.count > 0 ? nil : error);
    }];
}

- (void)getNewSongsWithCompletion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    NSString *url = @"https://c.y.qq.com/v8/fcg-bin/fcg_v8_toplist_cp.fcg?topid=27&song_begin=0&song_num=12&format=json&g_tk=5381&tpl=3&page=detail&type=top&platform=yqq.json&needNewCode=0";
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSMutableArray *tracks = [NSMutableArray array];
        id json = [self fe_jsonFromData:data];
        NSArray *songlist = FEQQObject(json, @"songlist");
        if ([songlist isKindOfClass:[NSArray class]]) {
            for (NSDictionary *item in songlist) {
                NSDictionary *info = [item isKindOfClass:[NSDictionary class]] ? item[@"data"] : nil;
                FETrack *track = [self fe_trackFromSong:info];
                if (track) [tracks addObject:track];
            }
        }
        if (completion) completion(tracks, tracks.count > 0 ? nil : error);
    }];
}

#pragma mark - User playlists

- (void)getUserPlaylistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion {
    if (!self.loggedIn || self.uin.length == 0) {
        if (completion) completion(@[], nil);
        return;
    }
    NSString *url = [NSString stringWithFormat:@"https://c.y.qq.com/rsc/fcgi-bin/fcg_user_created_diss?hostuin=%@&sin=0&size=100&g_tk=5381&format=json",
                     self.uin];
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSMutableArray *playlists = [NSMutableArray array];
        id json = [self fe_jsonFromData:data];
        NSArray *list = FEQQObject(FEQQObject(json, @"data"), @"disslist");
        if ([list isKindOfClass:[NSArray class]]) {
            for (NSDictionary *item in list) {
                FEPlaylist *playlist = [self fe_playlistFromDiss:item];
                if (playlist) [playlists addObject:playlist];
            }
        }
        if (completion) completion(playlists, playlists.count > 0 ? nil : error);
    }];
}

- (void)getPlaylistTracks:(FEPlaylist *)playlist completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    if (playlist.playlistId.length == 0) {
        if (completion) completion(@[], nil);
        return;
    }
    NSString *url = [NSString stringWithFormat:@"https://c.y.qq.com/qzone/fcg-bin/fcg_ucc_getcdinfo_byids_cp.fcg?type=1&json=1&utf8=1&onlysong=0&new_format=1&disstid=%@&g_tk=5381&loginUin=0&hostUin=0&format=json&inCharset=utf8&outCharset=utf-8&notice=0&platform=yqq.json&needNewCode=0",
                     playlist.playlistId];
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSMutableArray *tracks = [NSMutableArray array];
        id json = [self fe_jsonFromData:data];
        NSArray *cdlist = FEQQObject(json, @"cdlist");
        if ([cdlist isKindOfClass:[NSArray class]] && cdlist.count > 0) {
            NSDictionary *cd = cdlist[0];
            NSArray *songs = [cd isKindOfClass:[NSDictionary class]] ? cd[@"songlist"] : nil;
            if ([songs isKindOfClass:[NSArray class]]) {
                for (NSDictionary *item in songs) {
                    FETrack *track = [self fe_trackFromSong:item];
                    if (track) [tracks addObject:track];
                }
            }
        }
        if (completion) completion(tracks, tracks.count > 0 ? nil : error);
    }];
}

#pragma mark - Login / Profile

- (void)handleLoginCookies:(NSDictionary *)cookies {
    NSMutableString *cookieStr = [NSMutableString string];
    for (NSString *key in cookies) {
        [cookieStr appendFormat:@"%@=%@; ", key, cookies[key]];
    }
    self.cookieString = cookieStr;
    self.uin = [self fe_parseUinFromCookie:cookieStr];
    self.loggedIn = cookies.count > 0;
    if (self.loggedIn) {
        [[NSUserDefaults standardUserDefaults] setObject:cookieStr forKey:FECookieUserDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)getUserProfileWithCompletion:(void (^)(NSString *nickname, NSString *avatarURL, NSError *error))completion {
    if (!self.loggedIn || self.uin.length == 0) {
        if (completion) completion(nil, nil, nil);
        return;
    }
    NSString *url = [NSString stringWithFormat:@"https://c.y.qq.com/rsc/fcgi-bin/fcg_get_profile_homepage.fcg?cid=205360838&userid=%@&reqfrom=1&g_tk=5381&format=json",
                     self.uin];
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSString *nickname = nil;
        NSString *avatar = nil;
        id json = [self fe_jsonFromData:data];
        NSDictionary *creator = FEQQObject(FEQQObject(json, @"data"), @"creator");
        if ([creator isKindOfClass:[NSDictionary class]]) {
            nickname = FEQQString(creator[@"nick"]);
            avatar = FEQQString(creator[@"headpic"]);
        }
        if (avatar.length == 0) {
            avatar = [NSString stringWithFormat:@"https://q1.qlogo.cn/g?b=sdk&s=100&nk=%@", self.uin];
        }
        if (completion) completion(nickname, avatar, error);
    }];
}

@end
