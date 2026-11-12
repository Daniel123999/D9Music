#import "FEPlaylistListViewController.h"
#import "FETheme.h"
#import "FEIconView.h"
#import "FEPlaylistManager.h"
#import "FEProviderManager.h"
#import "FENeteaseProvider.h"
#import "FETrackListViewController.h"

@interface FEPlaylistListViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<FEPlaylist *> *sourcePlaylists;
@end

@implementation FEPlaylistListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"歌单管理";
    self.view.backgroundColor = [FETheme background];
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 60;
    self.tableView.backgroundColor = [FETheme background];
    self.tableView.separatorColor = [FETheme separator];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 80, 0);
    [self.view addSubview:self.tableView];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(addPlaylist)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"编辑"
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(toggleEdit)];

    [self loadSourcePlaylists];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)loadSourcePlaylists {
    id<FEProviderProtocol> provider = [FEProviderManager sharedManager].currentProvider;
    if (provider == nil || !provider.isLoggedIn) {
        self.sourcePlaylists = @[];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [provider getUserPlaylistsWithCompletion:^(NSArray<FEPlaylist *> *playlists, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            strongSelf.sourcePlaylists = playlists ?: @[];
            [strongSelf.tableView reloadData];
        });
    }];
}

- (void)toggleEdit {
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    self.navigationItem.leftBarButtonItem.title = self.tableView.editing ? @"完成" : @"编辑";
}

- (void)addPlaylist {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"新建歌单"
                                                   message:@"给歌单取一个名字"
                                                  delegate:self
                                         cancelButtonTitle:@"取消"
                                         otherButtonTitles:@"创建", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"本地歌单" : @"音源歌单";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1 && ![FEProviderManager sharedManager].currentProvider.isLoggedIn) {
        return @"登录网易云后可查看账号歌单";
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [FEPlaylistManager sharedManager].localPlaylists.count;
    }
    return self.sourcePlaylists.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"FEPlaylistRowCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellId];
        cell.backgroundColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.textColor = [FETheme textPrimary];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:10.5];
        cell.detailTextLabel.textColor = [FETheme textSecondary];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    if (indexPath.section == 0) {
        FEPlaylist *playlist = [FEPlaylistManager sharedManager].localPlaylists[indexPath.row];
        cell.textLabel.text = playlist.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu 首 · 本地歌单", (unsigned long)playlist.tracks.count];
        cell.imageView.image = [FEIconView imageWithType:FEIconTypePlaylist size:CGSizeMake(24, 24) color:[FETheme accent]];
    } else {
        FEPlaylist *playlist = self.sourcePlaylists[indexPath.row];
        cell.textLabel.text = playlist.name;
        cell.detailTextLabel.text = playlist.trackCount > 0 ? [NSString stringWithFormat:@"%ld 首 · 音源歌单", (long)playlist.trackCount] : @"音源歌单";
        cell.imageView.image = [FEIconView imageWithType:FEIconTypeCloud size:CGSizeMake(24, 24) color:[FETheme primary]];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0) {
        FEPlaylist *playlist = [FEPlaylistManager sharedManager].localPlaylists[indexPath.row];
        if (playlist.tracks.count == 0) {
            [FETheme showToast:@"这个歌单还没有歌曲" inView:self.view];
            return;
        }
        FETrackListViewController *vc = [[FETrackListViewController alloc] initWithTitle:playlist.name tracks:playlist.tracks];
        vc.listSubtitle = @"本地歌单";
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }

    if (indexPath.row >= (NSInteger)self.sourcePlaylists.count) {
        return;
    }
    FEPlaylist *playlist = self.sourcePlaylists[indexPath.row];
    id<FEProviderProtocol> provider = [FEProviderManager sharedManager].currentProvider;
    if (provider == nil) return;

    [FETheme showToast:@"正在加载歌单..." inView:self.view];
    [provider getPlaylistTracks:playlist completion:^(NSArray<FETrack *> *tracks, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (tracks.count == 0) {
                [FETheme showToast:@"歌单暂时取不到歌曲" inView:self.view];
                return;
            }
            FETrackListViewController *vc = [[FETrackListViewController alloc] initWithTitle:playlist.name tracks:tracks];
            vc.listSubtitle = provider.providerName;
            [self.navigationController pushViewController:vc animated:YES];
        });
    }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0 ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != 0) return nil;
    __weak typeof(self) weakSelf = self;
    UITableViewRowAction *rename = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                     title:@"重命名"
                                                                   handler:^(UITableViewRowAction *action, NSIndexPath *path) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf promptRenameAtIndex:path.row];
    }];
    rename.backgroundColor = [FETheme accent];
    UITableViewRowAction *delete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                                     title:@"删除"
                                                                   handler:^(UITableViewRowAction *action, NSIndexPath *path) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf confirmDeleteAtIndex:path.row];
    }];
    return @[delete, rename];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete && indexPath.section == 0) {
        FEPlaylist *playlist = [FEPlaylistManager sharedManager].localPlaylists[indexPath.row];
        [[FEPlaylistManager sharedManager] deletePlaylist:playlist];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [FETheme showToast:@"歌单已删除" inView:self.view];
    }
}

#pragma mark - Actions

- (void)promptRenameAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)[FEPlaylistManager sharedManager].localPlaylists.count) return;
    FEPlaylist *playlist = [FEPlaylistManager sharedManager].localPlaylists[index];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"重命名歌单"
                                                   message:playlist.name
                                                  delegate:self
                                         cancelButtonTitle:@"取消"
                                         otherButtonTitles:@"保存", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = 2000 + index;
    UITextField *field = [alert textFieldAtIndex:0];
    field.text = playlist.name;
    [alert show];
}

- (void)confirmDeleteAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)[FEPlaylistManager sharedManager].localPlaylists.count) return;
    FEPlaylist *playlist = [FEPlaylistManager sharedManager].localPlaylists[index];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"删除歌单"
                                                   message:[NSString stringWithFormat:@"确定删除「%@」吗？", playlist.name]
                                                  delegate:self
                                         cancelButtonTitle:@"取消"
                                         otherButtonTitles:@"删除", nil];
    alert.tag = 1000 + index;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag >= 1000 && alertView.tag < 2000) {
        if (buttonIndex == 1) {
            NSInteger index = alertView.tag - 1000;
            if (index >= 0 && index < (NSInteger)[FEPlaylistManager sharedManager].localPlaylists.count) {
                FEPlaylist *playlist = [FEPlaylistManager sharedManager].localPlaylists[index];
                [[FEPlaylistManager sharedManager] deletePlaylist:playlist];
                [self.tableView reloadData];
                [FETheme showToast:@"歌单已删除" inView:self.view];
            }
        }
        return;
    }
    if (alertView.tag >= 2000) {
        if (buttonIndex == 1) {
            NSInteger index = alertView.tag - 2000;
            UITextField *tf = [alertView textFieldAtIndex:0];
            NSString *name = [tf.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (name.length > 0 && index >= 0 && index < (NSInteger)[FEPlaylistManager sharedManager].localPlaylists.count) {
                FEPlaylist *playlist = [FEPlaylistManager sharedManager].localPlaylists[index];
                playlist.name = name;
                [[FEPlaylistManager sharedManager] savePlaylists];
                [self.tableView reloadData];
                [FETheme showToast:@"重命名成功" inView:self.view];
            }
        }
        return;
    }
    if (buttonIndex == 1) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        NSString *name = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (name.length > 0) {
            [[FEPlaylistManager sharedManager] createPlaylistWithName:name];
            [self.tableView reloadData];
            [FETheme showToast:@"歌单已创建" inView:self.view];
        }
    }
}

@end
