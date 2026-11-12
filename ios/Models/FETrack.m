#import "FETrack.h"

@implementation FETrack

+ (instancetype)trackWithTitle:(NSString *)title artist:(NSString *)artist {
    FETrack *track = [[FETrack alloc] init];
    track.title = title;
    track.artist = artist;
    track.providerId = @"local";
    track.isLocal = YES;
    return track;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.trackId = [aDecoder decodeObjectForKey:@"trackId"];
        self.title = [aDecoder decodeObjectForKey:@"title"];
        self.artist = [aDecoder decodeObjectForKey:@"artist"];
        self.album = [aDecoder decodeObjectForKey:@"album"];
        self.coverUrl = [aDecoder decodeObjectForKey:@"coverUrl"];
        self.playUrl = [aDecoder decodeObjectForKey:@"playUrl"];
        self.lyricUrl = [aDecoder decodeObjectForKey:@"lyricUrl"];
        self.providerId = [aDecoder decodeObjectForKey:@"providerId"];
        self.httpHeaders = [aDecoder decodeObjectForKey:@"httpHeaders"];
        self.duration = [aDecoder decodeDoubleForKey:@"duration"];
        self.isLocal = [aDecoder decodeBoolForKey:@"isLocal"];
        self.isFavorite = [aDecoder decodeBoolForKey:@"isFavorite"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.trackId forKey:@"trackId"];
    [aCoder encodeObject:self.title forKey:@"title"];
    [aCoder encodeObject:self.artist forKey:@"artist"];
    [aCoder encodeObject:self.album forKey:@"album"];
    [aCoder encodeObject:self.coverUrl forKey:@"coverUrl"];
    [aCoder encodeObject:self.playUrl forKey:@"playUrl"];
    [aCoder encodeObject:self.lyricUrl forKey:@"lyricUrl"];
    [aCoder encodeObject:self.providerId forKey:@"providerId"];
    [aCoder encodeObject:self.httpHeaders forKey:@"httpHeaders"];
    [aCoder encodeDouble:self.duration forKey:@"duration"];
    [aCoder encodeBool:self.isLocal forKey:@"isLocal"];
    [aCoder encodeBool:self.isFavorite forKey:@"isFavorite"];
}

@end
