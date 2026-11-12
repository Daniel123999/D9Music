#import "FENeteaseProvider.h"
#import "FEHttpRequest.h"

static id FEDictObject(id dict, NSString *key) {
    if (![dict isKindOfClass:[NSDictionary class]]) return nil;
    id value = [(NSDictionary *)dict objectForKey:key];
    return [value isKindOfClass:[NSNull class]] ? nil : value;
}

static NSString *FEString(id value) {
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [(NSNumber *)value stringValue];
    return nil;
}

@interface FENeteaseProvider ()
@property (nonatomic, copy) NSString *cookieString;
@property (nonatomic, assign) BOOL loggedIn;
@end

@implementation FENeteaseProvider

- (NSString *)providerId { return @"netease"; }
- (NSString *)providerName { return @"网易云音乐"; }
- (BOOL)isLoggedIn { return self.loggedIn; }
- (NSString *)loginUrl { return @"https://music.163.com/"; }

#pragma mark - Headers / Parsing

- (NSDictionary *)fe_headers {
    NSString *cookie = self.cookieString.length > 0 ? self.cookieString : @"os=pc; appver=2.0.2";
    return @{@"Referer": @"https://music.163.com/",
             @"User-Agent": @"Mozilla/5.0 (iPhone; CPU iPhone OS 9_3 like Mac OS X)",
             @"Cookie": cookie};
}

- (NSDictionary *)fe_jsonFromData:(NSData *)data {
    if (data.length == 0) return nil;
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [json isKindOfClass:[NSDictionary class]] ? json : nil;
}

- (FETrack *)fe_trackFromSong:(NSDictionary *)song {
    if (![song isKindOfClass:[NSDictionary class]]) return nil;
    FETrack *track = [[FETrack alloc] init];
    id songId = song[@"id"];
    track.trackId = [songId isKindOfClass:[NSNumber class]] ? [songId stringValue] : ([songId isKindOfClass:[NSString class]] ? songId : @"");
    track.title = FEString(FEDictObject(song, @"name")) ?: FEString(FEDictObject(song, @"songname")) ?: @"";
    NSArray *artists = FEDictObject(song, @"artists") ?: FEDictObject(song, @"ar");
    if ([artists isKindOfClass:[NSArray class]] && artists.count > 0) {
        NSDictionary *artist = artists[0];
        if ([artist isKindOfClass:[NSDictionary class]]) {
            track.artist = FEString(FEDictObject(artist, @"name")) ?: @"";
        }
    }
    if (track.artist.length == 0) {
        track.artist = FEString(FEDictObject(song, @"artist")) ?: FEString(FEDictObject(song, @"singer")) ?: @"";
    }
    NSDictionary *album = FEDictObject(song, @"album") ?: FEDictObject(song, @"al");
    if ([album isKindOfClass:[NSDictionary class]]) {
        track.album = FEString(FEDictObject(album, @"name")) ?: @"";
        track.coverUrl = FEString(FEDictObject(album, @"picUrl")) ?: FEString(FEDictObject(album, @"blurPicUrl")) ?: FEString(FEDictObject(album, @"pic_str")) ?: @"";
    } else {
        track.album = FEString(album) ?: @"";
    }
    if (track.coverUrl.length == 0) {
        track.coverUrl = FEString(FEDictObject(song, @"picUrl")) ?: @"";
    }
    id duration = FEDictObject(song, @"duration") ?: FEDictObject(song, @"dt");
    if ([duration respondsToSelector:@selector(doubleValue)] && [duration doubleValue] > 0) {
        track.duration = [duration doubleValue] / 1000.0;
    }
    track.providerId = @"netease";
    track.isLocal = NO;
    return track;
}

- (NSArray<FETrack *> *)fe_tracksFromSongs:(NSArray *)songs {
    NSMutableArray *tracks = [NSMutableArray array];
    if (![songs isKindOfClass:[NSArray class]]) return tracks;
    for (NSDictionary *song in songs) {
        FETrack *track = [self fe_trackFromSong:song];
        if (track && track.trackId.length > 0) [tracks addObject:track];
    }
    return tracks;
}

- (FEPlaylist *)fe_playlistFromDict:(NSDictionary *)item {
    if (![item isKindOfClass:[NSDictionary class]]) return nil;
    FEPlaylist *playlist = [[FEPlaylist alloc] init];
    id playlistId = item[@"id"];
    playlist.playlistId = [playlistId isKindOfClass:[NSNumber class]] ? [playlistId stringValue] : ([playlistId isKindOfClass:[NSString class]] ? playlistId : @"");
    playlist.name = FEString(FEDictObject(item, @"name")) ?: FEString(FEDictObject(item, @"title")) ?: @"";
    playlist.coverUrl = FEString(FEDictObject(item, @"coverImgUrl")) ?: FEString(FEDictObject(item, @"picUrl")) ?: FEString(FEDictObject(item, @"coverUrl")) ?: @"";
    playlist.providerId = @"netease";
    playlist.isLocal = NO;
    playlist.resourceType = @"playlist";
    id playCount = FEDictObject(item, @"playCount") ?: FEDictObject(item, @"playcount");
    if ([playCount respondsToSelector:@selector(integerValue)]) playlist.playCount = [playCount integerValue];
    id trackCount = FEDictObject(item, @"trackCount") ?: FEDictObject(item, @"songCount");
    if ([trackCount respondsToSelector:@selector(integerValue)]) playlist.trackCount = [trackCount integerValue];
    return playlist;
}

- (NSArray<FEPlaylist *> *)fe_playlistsFromArray:(NSArray *)array {
    NSMutableArray *playlists = [NSMutableArray array];
    if (![array isKindOfClass:[NSArray class]]) return playlists;
    for (NSDictionary *item in array) {
        FEPlaylist *playlist = [self fe_playlistFromDict:item];
        if (playlist && playlist.playlistId.length > 0) [playlists addObject:playlist];
    }
    return playlists;
}

#pragma mark - Search

- (void)searchWithKeyword:(NSString *)keyword completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    if (keyword.length == 0) {
        if (completion) completion(@[], nil);
        return;
    }

    NSString *url = @"https://music.163.com/api/search/get/web";
    NSDictionary *parameters = @{@"s": keyword, @"type": @"1", @"offset": @"0", @"total": @"true", @"limit": @"30"};
    [FEHttpRequest POSTForm:url headers:[self fe_headers] parameters:parameters completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSDictionary *json = [self fe_jsonFromData:data];
        NSArray *songs = FEDictObject(FEDictObject(json, @"result"), @"songs");
        NSArray *tracks = [self fe_tracksFromSongs:songs];
        if (tracks.count > 0) {
            if (completion) completion(tracks, nil);
            return;
        }
        [self fe_searchWithGET:keyword completion:completion];
    }];
}

- (void)fe_searchWithGET:(NSString *)keyword completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    NSString *url = [NSString stringWithFormat:@"https://music.163.com/api/search/get?s=%@&type=1&limit=30&offset=0",
                     [FEHttpRequest urlEncode:keyword]];
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSDictionary *json = [self fe_jsonFromData:data];
        NSArray *songs = FEDictObject(FEDictObject(json, @"result"), @"songs");
        NSArray *tracks = [self fe_tracksFromSongs:songs];
        if (completion) completion(tracks, tracks.count > 0 ? nil : error);
    }];
}

#pragma mark - Play URL

- (void)getPlayUrlForTrack:(FETrack *)track completion:(void (^)(NSString *playUrl, NSError *error))completion {
    if (track.trackId.length == 0) {
        if (completion) completion(nil, [NSError errorWithDomain:@"FENetease" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"歌曲 ID 为空"}]);
        return;
    }

    [self fe_requestSongURL:track.trackId br:320000 completion:^(NSString *url) {
        if (url.length > 0) {
            if (completion) completion(url, nil);
            return;
        }
        // 免费歌曲直链兜底：AVPlayer 会自动跟随 302 跳转
        NSString *outer = [NSString stringWithFormat:@"https://music.163.com/song/media/outer/url?id=%@.mp3", track.trackId];
        if (completion) completion(outer, nil);
    }];
}

- (void)fe_requestSongURL:(NSString *)songId br:(NSInteger)br completion:(void (^)(NSString *url))completion {
    NSString *url = @"https://music.163.com/api/song/enhance/player/url";
    NSDictionary *parameters = @{@"ids": [NSString stringWithFormat:@"[%@]", songId],
                                 @"br": [NSString stringWithFormat:@"%ld", (long)br],
                                 @"csrf_token": @""};
    [FEHttpRequest POSTForm:url headers:[self fe_headers] parameters:parameters completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSString *found = nil;
        NSDictionary *json = [self fe_jsonFromData:data];
        NSArray *items = json[@"data"];
        if ([items isKindOfClass:[NSArray class]] && items.count > 0) {
            NSDictionary *item = items[0];
            if ([item isKindOfClass:[NSDictionary class]]) {
                id playUrl = item[@"url"];
                if ([playUrl isKindOfClass:[NSString class]] && [playUrl length] > 0) {
                    found = playUrl;
                }
            }
        }
        if (found.length > 0) {
            if (completion) completion(found);
        } else if (br > 128000) {
            [self fe_requestSongURL:songId br:128000 completion:completion];
        } else {
            if (completion) completion(nil);
        }
    }];
}

#pragma mark - Lyrics

- (void)getLyricForTrack:(FETrack *)track completion:(void (^)(NSString *lyric, NSError *error))completion {
    if (track.trackId.length == 0) {
        if (completion) completion(nil, nil);
        return;
    }
    NSString *url = [NSString stringWithFormat:@"https://music.163.com/api/song/lyric?os=pc&id=%@&lv=-1&kv=-1&tv=-1", track.trackId];
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSDictionary *json = [self fe_jsonFromData:data];
        NSString *lyric = json[@"lrc"][@"lyric"];
        if (completion) completion([lyric isKindOfClass:[NSString class]] ? lyric : nil, error);
    }];
}

#pragma mark - Recommendations

- (void)getDailyRecommendSongsWithCompletion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    NSString *url = @"https://music.163.com/api/v3/discovery/recommend/songs";
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSDictionary *json = [self fe_jsonFromData:data];
        NSArray *songs = FEDictObject(FEDictObject(json, @"data"), @"dailySongs");
        if (![songs isKindOfClass:[NSArray class]]) songs = json[@"recommend"];
        NSArray *tracks = [self fe_tracksFromSongs:songs];
        if (tracks.count > 0 || completion == nil) {
            if (completion) completion(tracks, tracks.count > 0 ? nil : error);
            return;
        }
        NSString *legacy = @"https://music.163.com/api/v1/discovery/recommend/songs";
        [FEHttpRequest GET:legacy headers:[self fe_headers] completion:^(NSData *legacyData, NSHTTPURLResponse *legacyResponse, NSError *legacyError) {
            NSDictionary *legacyJson = [self fe_jsonFromData:legacyData];
            NSArray *legacySongs = legacyJson[@"recommend"];
            if (![legacySongs isKindOfClass:[NSArray class]]) legacySongs = FEDictObject(FEDictObject(legacyJson, @"data"), @"dailySongs");
            NSArray *legacyTracks = [self fe_tracksFromSongs:legacySongs];
            if (completion) completion(legacyTracks, legacyTracks.count > 0 ? nil : legacyError);
        }];
    }];
}

- (void)getRadioSongsWithCompletion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    NSString *url = @"https://music.163.com/api/v1/radio/get";
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSDictionary *json = [self fe_jsonFromData:data];
        NSArray *songs = json[@"data"];
        NSArray *tracks = [self fe_tracksFromSongs:songs];
        if (completion) completion(tracks, tracks.count > 0 ? nil : error);
    }];
}

- (void)getPersonalizedPlaylistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion {
    [FEHttpRequest GET:@"https://music.163.com/api/personalized/playlist?limit=12" headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSDictionary *json = [self fe_jsonFromData:data];
        NSArray *playlists = [self fe_playlistsFromArray:FEDictObject(json, @"result")];
        if (completion) completion(playlists, playlists.count > 0 ? nil : error);
    }];
}

- (void)getToplistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion {
    [FEHttpRequest GET:@"https://music.163.com/api/toplist" headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSDictionary *json = [self fe_jsonFromData:data];
        NSArray *playlists = [self fe_playlistsFromArray:json[@"list"]];
        if (completion) completion(playlists, playlists.count > 0 ? nil : error);
    }];
}

- (void)getNewSongsWithCompletion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    [FEHttpRequest GET:@"https://music.163.com/api/personalized/newsong?limit=12" headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSDictionary *json = [self fe_jsonFromData:data];
        NSArray *items = FEDictObject(json, @"result");
        NSMutableArray *tracks = [NSMutableArray array];
        if ([items isKindOfClass:[NSArray class]]) {
            for (NSDictionary *item in items) {
                if (![item isKindOfClass:[NSDictionary class]]) continue;
                NSDictionary *song = item[@"song"] ?: item;
                FETrack *track = [self fe_trackFromSong:song];
                if (track && track.trackId.length > 0) [tracks addObject:track];
            }
        }
        if (completion) completion(tracks, tracks.count > 0 ? nil : error);
    }];
}

- (void)getNewAlbumsWithCompletion:(void (^)(NSArray<FEPlaylist *> *albums, NSError *error))completion {
    [FEHttpRequest GET:@"https://music.163.com/api/album/new?area=ALL&limit=12" headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSDictionary *json = [self fe_jsonFromData:data];
        NSMutableArray *albums = [NSMutableArray array];
        NSArray *items = FEDictObject(json, @"albums");
        if ([items isKindOfClass:[NSArray class]]) {
            for (NSDictionary *item in items) {
                if (![item isKindOfClass:[NSDictionary class]]) continue;
                FEPlaylist *album = [self fe_playlistFromDict:item];
                if (album) {
                    album.resourceType = @"album";
                    [albums addObject:album];
                }
            }
        }
        if (completion) completion(albums, albums.count > 0 ? nil : error);
    }];
}

- (void)getPlaylistSquareWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion {
    NSString *url = @"https://music.163.com/api/playlist/list?order=hot&limit=30";
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSDictionary *json = [self fe_jsonFromData:data];
        NSArray *playlists = [self fe_playlistsFromArray:json[@"playlists"]];
        if (completion) completion(playlists, playlists.count > 0 ? nil : error);
    }];
}

- (void)getHighQualityPlaylistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion {
    NSString *url = @"https://music.163.com/api/playlist/highquality/list?limit=30";
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSDictionary *json = [self fe_jsonFromData:data];
        NSArray *playlists = [self fe_playlistsFromArray:json[@"playlists"]];
        if (completion) completion(playlists, playlists.count > 0 ? nil : error);
    }];
}

#pragma mark - User playlists / playlist detail

- (void)getUserPlaylistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion {
    NSString *url = @"https://music.163.com/api/user/playlist";
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSDictionary *json = [self fe_jsonFromData:data];
        NSArray *playlists = [self fe_playlistsFromArray:json[@"playlist"]];
        if (completion) completion(playlists, playlists.count > 0 ? nil : error);
    }];
}

- (void)getPlaylistTracks:(FEPlaylist *)playlist completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    if (playlist.playlistId.length == 0) {
        if (completion) completion(@[], nil);
        return;
    }

    BOOL isAlbum = [playlist.resourceType isEqualToString:@"album"];
    NSString *url = isAlbum
        ? [NSString stringWithFormat:@"https://music.163.com/api/album/%@", playlist.playlistId]
        : [NSString stringWithFormat:@"https://music.163.com/api/playlist/detail?id=%@", playlist.playlistId];

    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSDictionary *json = [self fe_jsonFromData:data];
        NSArray *songs = nil;
        if (isAlbum) {
            songs = FEDictObject(FEDictObject(json, @"album"), @"songs");
            if (![songs isKindOfClass:[NSArray class]]) songs = FEDictObject(json, @"songs");
        } else {
            songs = FEDictObject(FEDictObject(json, @"result"), @"tracks");
        }
        NSArray *tracks = [self fe_tracksFromSongs:songs];
        if (completion) completion(tracks, tracks.count > 0 ? nil : error);
    }];
}

#pragma mark - Login

- (void)handleLoginCookies:(NSDictionary *)cookies {
    NSMutableString *cookieStr = [NSMutableString string];
    for (NSString *key in cookies) {
        [cookieStr appendFormat:@"%@=%@; ", key, cookies[key]];
    }
    self.cookieString = cookieStr;
    self.loggedIn = cookies.count > 0;
}

- (void)likeTrack:(FETrack *)track like:(BOOL)like completion:(void (^)(BOOL success, NSError *error))completion {
    if (track.trackId.length == 0) {
        if (completion) completion(NO, nil);
        return;
    }
    NSString *url = [NSString stringWithFormat:@"https://music.163.com/api/v1/radio/like?alg=id_based&trackId=%@&like=%@&time=25", track.trackId, like ? @"true" : @"false"];
    [FEHttpRequest GET:url headers:[self fe_headers] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSDictionary *json = [self fe_jsonFromData:data];
        BOOL success = [json[@"code"] integerValue] == 200;
        if (completion) completion(success, error);
    }];
}

- (void)getLikedSongsWithCompletion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    [self getUserPlaylistsWithCompletion:^(NSArray<FEPlaylist *> *playlists, NSError *error) {
        if (playlists.count == 0) {
            if (completion) completion(@[], error);
            return;
        }
        FEPlaylist *liked = playlists[0];
        [self getPlaylistTracks:liked completion:completion];
    }];
}

@end
