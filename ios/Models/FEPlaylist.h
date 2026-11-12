#import <Foundation/Foundation.h>
#import "FETrack.h"

@interface FEPlaylist : NSObject <NSCoding>

@property (nonatomic, copy) NSString *playlistId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *coverUrl;
@property (nonatomic, copy) NSString *providerId;
@property (nonatomic, copy) NSString *resourceType;
@property (nonatomic, assign) NSInteger playCount;
@property (nonatomic, assign) NSInteger trackCount;
@property (nonatomic, strong) NSMutableArray<FETrack *> *tracks;
@property (nonatomic, assign) BOOL isLocal;

@end
