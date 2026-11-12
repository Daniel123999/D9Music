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

#pragma mark - 云盘浏览 / 下载

/// 云端歌曲目录（WebDAV 远程路径根目录）
- (NSString *)cloudRootPath;
/// 本地下载目录（Documents/CloudMusic）
- (NSString *)downloadDirectory;

/// 列出某个远程目录，items 每项包含 name / path / isDirectory / size
- (void)listDirectory:(NSString *)remotePath
           completion:(void (^)(NSArray<NSDictionary *> *items, NSError *error))completion;

/// 下载远程文件到本地目录，返回本地路径
- (void)downloadRemoteFile:(NSString *)remotePath
                completion:(void (^)(NSString *localPath, NSError *error))completion;

@end
