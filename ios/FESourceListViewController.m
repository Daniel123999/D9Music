#import "FESourceListViewController.h"
#import "FEProviderManager.h"
#import "FELoginWebViewController.h"

@interface FESourceListViewController ()
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation FESourceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"音源切换 & 登录";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [FEProviderManager sharedManager].providers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellId];
    }
    id<FEProviderProtocol> provider = [FEProviderManager sharedManager].providers[indexPath.row];
    cell.textLabel.text = provider.providerName;
    if (provider.isLoggedIn) {
        cell.detailTextLabel.text = @"已登录";
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.detailTextLabel.text = @"未登录，点击登录";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    if (provider == [FEProviderManager sharedManager].currentProvider) {
        cell.textLabel.textColor = [UIColor blueColor];
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id<FEProviderProtocol> provider = [FEProviderManager sharedManager].providers[indexPath.row];
    if (provider.isLoggedIn) {
        [[FEProviderManager sharedManager] switchToProviderWithId:provider.providerId];
        [self.tableView reloadData];
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        FELoginWebViewController *loginVC = [[FELoginWebViewController alloc] init];
        loginVC.provider = provider;
        [self.navigationController pushViewController:loginVC animated:YES];
    }
}

@end
