#import "FEMineViewController.h"
#import "FEProviderManager.h"
#import "FELocalMusicViewController.h"
#import "FEPlaylistListViewController.h"
#import "FESourceListViewController.h"
#import "FELoginWebViewController.h"

@interface FEMineViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *sections;
@end

@implementation FEMineViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"我的";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.sections = @[
        @{@"title": @"账号", @"items": @[@{@"title": @"音源切换 & 登录", @"icon": @"🔐"}]},
        @{@"title": @"本地", @"items": @[
            @{@"title": @"本地音乐", @"icon": @"🎵"},
            @{@"title": @"本地歌单", @"icon": @"📋"}
        ]},
        @{@"title": @"音源歌单", @"items": @[
            @{@"title": @"我的歌单", @"icon": @"🎼"},
            @{@"title": @"收藏歌曲", @"icon": @"❤️"},
            @{@"title": @"收藏歌单", @"icon": @"💿"},
            @{@"title": @"收藏歌手", @"icon": @"⭐"},
            @{@"title": @"收藏专辑", @"icon": @"📀"},
            @{@"title": @"云盘歌曲", @"icon": @"☁️"}
        ]}
    ];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section][@"title"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *items = self.sections[section][@"items"];
    return items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId];
    }
    NSDictionary *item = self.sections[indexPath.section][@"items"][indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", item[@"icon"], item[@"title"]];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *title = self.sections[indexPath.section][@"items"][indexPath.row][@"title"];
    
    if ([title isEqualToString:@"音源切换 & 登录"]) {
        FESourceListViewController *vc = [[FESourceListViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([title isEqualToString:@"本地音乐"]) {
        FELocalMusicViewController *vc = [[FELocalMusicViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([title isEqualToString:@"本地歌单"] || [title isEqualToString:@"我的歌单"]) {
        FEPlaylistListViewController *vc = [[FEPlaylistListViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        // 其他功能需要登录后加载
        id<FEProviderProtocol> provider = [FEProviderManager sharedManager].currentProvider;
        if (provider && !provider.isLoggedIn) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请先登录音源账号" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
        }
    }
}

@end
