#import <Foundation/Foundation.h>
#import "FETrack.h"

@interface FEWebDAVManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, copy) NSString *serverURL;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *remotePath;
@property (nonatomic, assign) BOOL isEnabled;

- (BOOL)loadConfig;
- (void)saveConfig;

- (void)testConnection:(void (^)(BOOL success, NSString *message))completion;

- (void)syncPlaylistsToWebDAV:(void (^)(BOOL success, NSString *message))completion;
- (void)backupConfigToWebDAV:(void (^)(BOOL success, NSString *message))completion;
- (void)restoreConfigFromWebDAV:(void (^)(BOOL success, NSString *message))completion;

- (void)uploadTrack:(FETrack *)track completion:(void (^)(BOOL success, NSString *message))completion;
- (void)downloadTrack:(FETrack *)track toPath:(NSString *)localPath completion:(void (^)(BOOL success, NSString *message))completion;

@end
