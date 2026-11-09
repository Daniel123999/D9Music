#import "FEPlaylist.h"

@implementation FEPlaylist

- (instancetype)init {
    self = [super init];
    if (self) {
        self.tracks = [NSMutableArray array];
        self.isLocal = YES;
        self.providerId = @"local";
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.playlistId = [aDecoder decodeObjectForKey:@"playlistId"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.coverUrl = [aDecoder decodeObjectForKey:@"coverUrl"];
        self.providerId = [aDecoder decodeObjectForKey:@"providerId"];
        self.tracks = [aDecoder decodeObjectForKey:@"tracks"] ?: [NSMutableArray array];
        self.isLocal = [aDecoder decodeBoolForKey:@"isLocal"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.playlistId forKey:@"playlistId"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.coverUrl forKey:@"coverUrl"];
    [aCoder encodeObject:self.providerId forKey:@"providerId"];
    [aCoder encodeObject:self.tracks forKey:@"tracks"];
    [aCoder encodeBool:self.isLocal forKey:@"isLocal"];
}

@end
