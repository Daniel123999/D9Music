#import "FEFavoriteManager.h"
#import "FEPlaylistManager.h"
#import "FEProviderManager.h"
#import "FENeteaseProvider.h"
#import "FEWebDAVManager.h"

@implementation FEFavoriteManager

+ (instancetype)sharedManager {
    static FEFavoriteManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FEFavoriteManager alloc] init];
        [instance loadFavorites];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.favoriteTracks = [NSMutableArray array];
    }
    return self;
}

- (NSString *)favoritesPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [paths objectAtIndex:0];
    return [docsDir stringByAppendingPathComponent:@"favorites.dat"];
}

- (void)loadFavorites {
    NSData *data = [NSData dataWithContentsOfFile:[self favoritesPath]];
    if (data) {
        NSArray *tracks = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (tracks) {
            self.favoriteTracks = [tracks mutableCopy];
        }
    }
}

- (void)saveFavorites {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.favoriteTracks];
    [data writeToFile:[self favoritesPath] atomically:YES];
}

- (BOOL)isFavorite:(FETrack *)track {
    if (track == nil || track.trackId.length == 0) return NO;
    for (FETrack *t in self.favoriteTracks) {
        if ([t.trackId isEqualToString:track.trackId] && [t.providerId isEqualToString:track.providerId]) {
            return YES;
        }
    }
    return NO;
}

- (void)addFavorite:(FETrack *)track {
    if (track == nil || [self isFavorite:track]) return;
    FETrack *copy = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:track]];
    if (copy == nil) copy = track;
    copy.isFavorite = YES;
    [self.favoriteTracks insertObject:copy atIndex:0];
    [self saveFavorites];
    
    // 同步到本地歌单"我喜欢"
    FEPlaylistManager *pm = [FEPlaylistManager sharedManager];
    FEPlaylist *favPlaylist = nil;
    for (FEPlaylist *p in pm.localPlaylists) {
        if ([p.name isEqualToString:@"我喜欢"]) {
            favPlaylist = p;
            break;
        }
    }
    if (favPlaylist == nil) {
        [pm createPlaylistWithName:@"我喜欢"];
        favPlaylist = pm.localPlaylists.lastObject;
    }
    [pm addTrack:copy toPlaylist:favPlaylist];
}

- (void)removeFavorite:(FETrack *)track {
    if (track == nil) return;
    NSMutableArray *toRemove = [NSMutableArray array];
    for (FETrack *t in self.favoriteTracks) {
        if ([t.trackId isEqualToString:track.trackId] && [t.providerId isEqualToString:track.providerId]) {
            [toRemove addObject:t];
            break;
        }
    }
    [self.favoriteTracks removeObjectsInArray:toRemove];
    [self saveFavorites];
    
    // 从本地"我喜欢"歌单移除
    FEPlaylistManager *pm = [FEPlaylistManager sharedManager];
    for (FEPlaylist *p in pm.localPlaylists) {
        if ([p.name isEqualToString:@"我喜欢"]) {
            for (FETrack *t in toRemove) {
                [pm removeTrack:t fromPlaylist:p];
            }
            break;
        }
    }
}

- (void)toggleFavorite:(FETrack *)track completion:(void (^)(BOOL isFavorite, BOOL success))completion {
    if (track == nil) {
        if (completion) completion(NO, NO);
        return;
    }
    
    BOOL currentlyFavorite = [self isFavorite:track];
    
    // 如果登录网易云，优先收藏到网易云
    id<FEProviderProtocol> provider = [FEProviderManager sharedManager].currentProvider;
    if ([provider isKindOfClass:[FENeteaseProvider class]] && provider.isLoggedIn && [provider respondsToSelector:@selector(likeTrack:like:completion:)]) {
        FENeteaseProvider *netease = (FENeteaseProvider *)provider;
        [netease likeTrack:track like:!currentlyFavorite completion:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    if (!currentlyFavorite) {
                        [self addFavorite:track];
                    } else {
                        [self removeFavorite:track];
                    }
                    // 同步到 WebDAV
                    if ([FEWebDAVManager sharedManager].isEnabled) {
                        [[FEWebDAVManager sharedManager] syncPlaylistsToWebDAV:nil];
                    }
                    if (completion) completion(!currentlyFavorite, YES);
                } else {
                    // 失败则降级到本地收藏
                    if (!currentlyFavorite) {
                        [self addFavorite:track];
                    } else {
                        [self removeFavorite:track];
                    }
                    if ([FEWebDAVManager sharedManager].isEnabled) {
                        [[FEWebDAVManager sharedManager] syncPlaylistsToWebDAV:nil];
                    }
                    if (completion) completion(!currentlyFavorite, YES);
                }
            });
        }];
        return;
    }
    
    // 未登录或非网易云，收藏到本地
    if (!currentlyFavorite) {
        [self addFavorite:track];
    } else {
        [self removeFavorite:track];
    }
    if ([FEWebDAVManager sharedManager].isEnabled) {
        [[FEWebDAVManager sharedManager] syncPlaylistsToWebDAV:nil];
    }
    if (completion) completion(!currentlyFavorite, YES);
}

@end
