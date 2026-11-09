#import "FENeteaseProvider.h"
#import "FEHttpRequest.h"

@interface FENeteaseProvider ()
@property (nonatomic, copy) NSString *cookieString;
@property (nonatomic, assign) BOOL loggedIn;
@end

@implementation FENeteaseProvider

- (NSString *)providerId { return @"netease"; }
- (NSString *)providerName { return @"网易云音乐"; }
- (BOOL)isLoggedIn { return self.loggedIn; }
- (NSString *)loginUrl { return @"https://music.163.com/"; }

- (void)searchWithKeyword:(NSString *)keyword completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    NSString *url = [NSString stringWithFormat:@"https://music.163.com/api/search/get/web?csrf_token="];
    NSDictionary *headers = @{@"Referer": @"https://music.163.com/", @"User-Agent": @"Mozilla/5.0"};
    NSString *bodyStr = [NSString stringWithFormat:@"s=%@&type=1&offset=0&total=true&limit=30", [keyword stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [FEHttpRequest POST:url headers:headers body:[bodyStr dataUsingEncoding:NSUTF8StringEncoding] completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSMutableArray *tracks = [NSMutableArray array];
        if (data) {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            NSArray *songs = json[@"result"][@"songs"];
            for (NSDictionary *song in songs) {
                FETrack *track = [[FETrack alloc] init];
                track.trackId = [song[@"id"] stringValue];
                track.title = song[@"name"];
                NSArray *artists = song[@"artists"];
                if (artists.count > 0) {
                    track.artist = artists[0][@"name"];
                }
                track.album = song[@"album"][@"name"];
                track.providerId = @"netease";
                track.isLocal = NO;
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

- (void)getPlayUrlForTrack:(FETrack *)track completion:(void (^)(NSString *playUrl, NSError *error))completion {
    NSString *url = [NSString stringWithFormat:@"https://music.163.com/api/song/enhance/player/url?ids=[%@]&br=320000", track.trackId];
    NSDictionary *headers = @{@"Referer": @"https://music.163.com/", @"User-Agent": @"Mozilla/5.0"};
    if (self.cookieString) {
        headers = @{@"Referer": @"https://music.163.com/", @"User-Agent": @"Mozilla/5.0", @"Cookie": self.cookieString};
    }
    [FEHttpRequest GET:url headers:headers completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSString *playUrl = nil;
        if (data) {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            NSArray *arr = json[@"data"];
            if (arr.count > 0) {
                playUrl = arr[0][@"url"];
            }
        }
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(playUrl, error);
            });
        }
    }];
}

- (void)getLyricForTrack:(FETrack *)track completion:(void (^)(NSString *lyric, NSError *error))completion {
    NSString *url = [NSString stringWithFormat:@"https://music.163.com/api/song/lyric?os=pc&id=%@&lv=-1&kv=-1&tv=-1", track.trackId];
    NSDictionary *headers = @{@"Referer": @"https://music.163.com/", @"User-Agent": @"Mozilla/5.0"};
    [FEHttpRequest GET:url headers:headers completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSString *lyric = nil;
        if (data) {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            lyric = json[@"lrc"][@"lyric"];
        }
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(lyric, error);
            });
        }
    }];
}

- (void)getDailyRecommendSongsWithCompletion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    NSString *url = @"https://music.163.com/api/v3/discovery/recommend/songs";
    NSDictionary *headers = @{@"Referer": @"https://music.163.com/", @"User-Agent": @"Mozilla/5.0"};
    if (self.cookieString) {
        headers = @{@"Referer": @"https://music.163.com/", @"User-Agent": @"Mozilla/5.0", @"Cookie": self.cookieString};
    }
    [FEHttpRequest GET:url headers:headers completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSMutableArray *tracks = [NSMutableArray array];
        if (data) {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            NSArray *songs = json[@"data"][@"dailySongs"];
            for (NSDictionary *song in songs) {
                FETrack *track = [[FETrack alloc] init];
                track.trackId = [song[@"id"] stringValue];
                track.title = song[@"name"];
                NSArray *artists = song[@"artists"];
                if (artists.count > 0) {
                    track.artist = artists[0][@"name"];
                }
                track.album = song[@"album"][@"name"];
                track.providerId = @"netease";
                track.isLocal = NO;
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

- (void)getRadioSongsWithCompletion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    NSString *url = @"https://music.163.com/api/v1/radio/get";
    NSDictionary *headers = @{@"Referer": @"https://music.163.com/", @"User-Agent": @"Mozilla/5.0"};
    if (self.cookieString) {
        headers = @{@"Referer": @"https://music.163.com/", @"User-Agent": @"Mozilla/5.0", @"Cookie": self.cookieString};
    }
    [FEHttpRequest GET:url headers:headers completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSMutableArray *tracks = [NSMutableArray array];
        if (data) {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            NSArray *songs = json[@"data"];
            for (NSDictionary *song in songs) {
                FETrack *track = [[FETrack alloc] init];
                track.trackId = [song[@"id"] stringValue];
                track.title = song[@"name"];
                track.artist = song[@"artists"][0][@"name"];
                track.album = song[@"album"][@"name"];
                track.providerId = @"netease";
                track.isLocal = NO;
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

- (void)getUserPlaylistsWithCompletion:(void (^)(NSArray<FEPlaylist *> *playlists, NSError *error))completion {
    NSString *url = [NSString stringWithFormat:@"https://music.163.com/api/user/playlist"];
    NSDictionary *headers = @{@"Referer": @"https://music.163.com/", @"User-Agent": @"Mozilla/5.0"};
    if (self.cookieString) {
        headers = @{@"Referer": @"https://music.163.com/", @"User-Agent": @"Mozilla/5.0", @"Cookie": self.cookieString};
    }
    [FEHttpRequest GET:url headers:headers completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSMutableArray *playlists = [NSMutableArray array];
        if (data) {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            NSArray *list = json[@"playlist"];
            for (NSDictionary *item in list) {
                FEPlaylist *playlist = [[FEPlaylist alloc] init];
                playlist.playlistId = [item[@"id"] stringValue];
                playlist.name = item[@"name"];
                playlist.coverUrl = item[@"coverImgUrl"];
                playlist.providerId = @"netease";
                playlist.isLocal = NO;
                [playlists addObject:playlist];
            }
        }
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(playlists, error);
            });
        }
    }];
}

- (void)getPlaylistTracks:(FEPlaylist *)playlist completion:(void (^)(NSArray<FETrack *> *tracks, NSError *error))completion {
    NSString *url = [NSString stringWithFormat:@"https://music.163.com/api/playlist/detail?id=%@", playlist.playlistId];
    NSDictionary *headers = @{@"Referer": @"https://music.163.com/", @"User-Agent": @"Mozilla/5.0"};
    if (self.cookieString) {
        headers = @{@"Referer": @"https://music.163.com/", @"User-Agent": @"Mozilla/5.0", @"Cookie": self.cookieString};
    }
    [FEHttpRequest GET:url headers:headers completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSMutableArray *tracks = [NSMutableArray array];
        if (data) {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            NSArray *songs = json[@"result"][@"tracks"];
            for (NSDictionary *song in songs) {
                FETrack *track = [[FETrack alloc] init];
                track.trackId = [song[@"id"] stringValue];
                track.title = song[@"name"];
                NSArray *artists = song[@"artists"];
                if (artists.count > 0) {
                    track.artist = artists[0][@"name"];
                }
                track.album = song[@"album"][@"name"];
                track.providerId = @"netease";
                track.isLocal = NO;
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

- (void)handleLoginCookies:(NSDictionary *)cookies {
    NSMutableString *cookieStr = [NSMutableString string];
    for (NSString *key in cookies) {
        [cookieStr appendFormat:@"%@=%@; ", key, cookies[key]];
    }
    self.cookieString = cookieStr;
    self.loggedIn = cookies.count > 0;
}

@end
