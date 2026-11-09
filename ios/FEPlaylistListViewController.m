#import "FEPlaylistListViewController.h"
#import "FEPlaylistManager.h"
#import "FEProviderManager.h"

@interface FEPlaylistListViewController ()
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation FEPlaylistListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"歌单管理";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPlaylist)];
    
    // 尝试读取当前音源歌单
    id<FEProviderProtocol> provider = [FEProviderManager sharedManager].currentProvider;
    if (provider && provider.isLoggedIn) {
        [provider getUserPlaylistsWithCompletion:^(NSArray *playlists, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
    }
}

- (void)addPlaylist {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"新建歌单" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"创建", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        if (textField.text.length > 0) {
            [[FEPlaylistManager sharedManager] createPlaylistWithName:textField.text];
            [self.tableView reloadData];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"本地歌单";
    return @"音源歌单";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return [FEPlaylistManager sharedManager].localPlaylists.count;
    return 0; // 音源歌单需要登录后获取
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId];
    }
    if (indexPath.section == 0) {
        FEPlaylist *playlist = [FEPlaylistManager sharedManager].localPlaylists[indexPath.row];
        cell.textLabel.text = playlist.name;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete && indexPath.section == 0) {
        FEPlaylist *playlist = [FEPlaylistManager sharedManager].localPlaylists[indexPath.row];
        [[FEPlaylistManager sharedManager] deletePlaylist:playlist];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
