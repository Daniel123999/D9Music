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
