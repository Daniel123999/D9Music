#import <Foundation/Foundation.h>
#import "FETrack.h"

@interface FEFavoriteManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong) NSMutableArray<FETrack *> *favoriteTracks;

- (void)loadFavorites;
- (void)saveFavorites;
- (BOOL)isFavorite:(FETrack *)track;
- (void)addFavorite:(FETrack *)track;
- (void)removeFavorite:(FETrack *)track;
- (void)toggleFavorite:(FETrack *)track completion:(void (^)(BOOL isFavorite, BOOL success))completion;

@end
