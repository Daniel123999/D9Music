#import "FECloudViewController.h"
#import "FETheme.h"
#import "FEIconView.h"
#import "FEWebDAVManager.h"
#import "FEPlayerManager.h"

@interface FECloudViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, copy) NSString *remotePath;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *items;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, assign) BOOL loading;

@end

@implementation FECloudViewController

- (instancetype)initWithRemotePath:(NSString *)remotePath title:(NSString *)title {
    self = [super init];
    if (self) {
        _remotePath = [remotePath copy];
        self.title = title.length > 0 ? title : @"云盘音乐";
    }
    return self;
}

- (instancetype)init {
    return [self initWithRemotePath:[[FEWebDAVManager sharedManager] cloudRootPath] title:@"云盘音乐"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [FETheme background];
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 60;
    self.tableView.backgroundColor = [FETheme background];
    self.tableView.separatorColor = [FETheme separator];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 100, 0);
    [self.view addSubview:self.tableView];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"刷新"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(reload)];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = CGPointMake(self.view.bounds.size.width / 2, 100);
    [self.view addSubview:self.spinner];

    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.textColor = [FETheme textSecondary];
    self.hintLabel.font = [UIFont systemFontOfSize:12];
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    self.hintLabel.numberOfLines = 0;
    self.hintLabel.hidden = YES;
    [self.view addSubview:self.hintLabel];

    [self reload];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.hintLabel.frame = CGRectMake(24, 80, self.view.bounds.size.width - 48, 80);
}

- (void)reload {
    if (self.loading) return;
    self.loading = YES;
    [self.spinner startAnimating];
    self.hintLabel.hidden = YES;

    __weak typeof(self) weakSelf = self;
    [[FEWebDAVManager sharedManager] listDirectory:self.remotePath completion:^(NSArray<NSDictionary *> *items, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.loading = NO;
        [strongSelf.spinner stopAnimating];
        strongSelf.items = items ?: @[];
        [strongSelf.tableView reloadData];

        if (error != nil) {
            [strongSelf showHint:[NSString stringWithFormat:@"加载失败：%@\n请先在设置中启用 WebDAV", error.localizedDescription]];
        } else if (strongSelf.items.count == 0) {
            [strongSelf showHint:@"云端目录为空\n把歌曲上传到 WebDAV 的云盘目录后即可在这里看到"];
        }
    }];
}

- (void)showHint:(NSString *)text {
    self.hintLabel.text = text;
    self.hintLabel.hidden = NO;
    self.hintLabel.frame = CGRectMake(24, 80, self.view.bounds.size.width - 48, 90);
}

#pragma mark - Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"FECloudCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellId];
        cell.backgroundColor = [FETheme card];
        cell.textLabel.font = [UIFont systemFontOfSize:13.5];
        cell.textLabel.textColor = [FETheme textPrimary];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:10.5];
        cell.detailTextLabel.textColor = [FETheme textSecondary];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NSDictionary *item = self.items[indexPath.row];
    BOOL isDir = [item[@"isDirectory"] boolValue];
    cell.textLabel.text = item[@"name"];
    if (isDir) {
        cell.detailTextLabel.text = @"文件夹";
        cell.imageView.image = [FEIconView imageWithType:FEIconTypeLibrary size:CGSizeMake(24, 24) color:[FETheme primary]];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        long long size = [item[@"size"] longLongValue];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · 点按下载并播放",
                                     size > 0 ? [NSString stringWithFormat:@"%.1f MB", size / 1024.0 / 1024.0] : @"音频文件"];
        cell.imageView.image = [FEIconView imageWithType:FEIconTypeNote size:CGSizeMake(24, 24) color:[FETheme accent]];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row >= (NSInteger)self.items.count) return;
    NSDictionary *item = self.items[indexPath.row];

    if ([item[@"isDirectory"] boolValue]) {
        FECloudViewController *vc = [[FECloudViewController alloc] initWithRemotePath:item[@"path"] title:item[@"name"]];
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }

    NSString *name = item[@"name"] ?: @"";
    NSString *ext = [[name pathExtension] lowercaseString];
    NSArray *audioExts = @[@"mp3", @"m4a", @"aac", @"flac", @"wav", @"ogg", @"wma", @"ape"];
    if (ext.length > 0 && ![audioExts containsObject:ext]) {
        [FETheme showToast:@"只支持音频文件（mp3/m4a/flac/wav 等）" inView:self.view];
        return;
    }

    [FETheme showToast:@"正在下载…" inView:self.view];
    __weak typeof(self) weakSelf = self;
    [[FEWebDAVManager sharedManager] downloadRemoteFile:item[@"path"] completion:^(NSString *localPath, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (localPath.length == 0) {
            [FETheme showToast:error.localizedDescription ?: @"下载失败" inView:strongSelf.view];
            return;
        }

        FETrack *track = [[FETrack alloc] init];
        track.trackId = localPath;
        track.title = [name stringByDeletingPathExtension];
        track.artist = @"WebDAV 云盘";
        track.album = @"云盘音乐";
        track.playUrl = localPath;
        track.isLocal = YES;
        track.providerId = @"local";
        [[FEPlayerManager sharedManager] playTracks:@[track] startIndex:0];
        [FETheme showToast:@"下载完成，开始播放" inView:strongSelf.view];
    }];
}

@end
