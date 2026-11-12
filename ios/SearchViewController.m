#import "SearchViewController.h"
#import "FETheme.h"
#import "FEComponents.h"
#import "FEIconView.h"
#import "FEProviderManager.h"
#import "FETrack.h"
#import "FEPlayerManager.h"
#import "FERootTabBarController.h"

@interface SearchViewController ()

@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) UIButton *searchButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *retryButton;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSMutableArray<NSMutableDictionary *> *groups;
@property (nonatomic, assign) BOOL searching;
@property (nonatomic, assign) NSInteger pendingRequests;

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"搜索";
    self.view.backgroundColor = [FETheme background];
    self.groups = [NSMutableArray array];
    self.automaticallyAdjustsScrollViewInsets = NO;

    [self buildSearchBar];

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 66, self.view.bounds.size.width - 32, 20)];
    self.statusLabel.text = @"输入关键词，一次搜索所有已启用音源";
    self.statusLabel.textColor = [FETheme textSecondary];
    self.statusLabel.font = [UIFont systemFontOfSize:11.5];
    [self.view addSubview:self.statusLabel];

    self.retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.retryButton.frame = CGRectMake(16, 90, 108, 28);
    self.retryButton.backgroundColor = [FETheme primary];
    self.retryButton.layer.cornerRadius = 14;
    self.retryButton.titleLabel.font = [UIFont boldSystemFontOfSize:11];
    [self.retryButton setTitle:@"重新搜索" forState:UIControlStateNormal];
    [self.retryButton addTarget:self action:@selector(doSearch) forControlEvents:UIControlEventTouchUpInside];
    self.retryButton.hidden = YES;
    [self.view addSubview:self.retryButton];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 124, self.view.bounds.size.width, self.view.bounds.size.height - 124) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 68;
    self.tableView.contentInset = UIEdgeInsetsMake(4, 0, 100, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [FETheme styleTableView:self.tableView];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 74, 0, 16);
    [self.view addSubview:self.tableView];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = CGPointMake(self.view.bounds.size.width / 2, 150);
    [self.view addSubview:self.spinner];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)buildSearchBar {
    CGFloat width = self.view.bounds.size.width;
    UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(12, 12, width - 24, 44)];
    [FETheme applyCardStyle:bar radius:22];
    [self.view addSubview:bar];

    FEIconView *icon = [[FEIconView alloc] initWithFrame:CGRectMake(14, 14, 16, 16) iconType:FEIconTypeSearch];
    icon.tintColor = [FETheme textSecondary];
    icon.lineWidth = 2.0;
    [bar addSubview:icon];

    self.searchField = [[UITextField alloc] initWithFrame:CGRectMake(38, 6, width - 24 - 38 - 66, 32)];
    self.searchField.borderStyle = UITextBorderStyleNone;
    self.searchField.font = [UIFont systemFontOfSize:13.5];
    self.searchField.textColor = [FETheme textPrimary];
    self.searchField.placeholder = @"歌曲 / 歌手 / 专辑";
    self.searchField.returnKeyType = UIReturnKeySearch;
    self.searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.searchField.delegate = self;
    [bar addSubview:self.searchField];

    self.searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.searchButton.frame = CGRectMake(width - 24 - 60, 6, 54, 32);
    self.searchButton.backgroundColor = [FETheme primary];
    self.searchButton.layer.cornerRadius = 16;
    self.searchButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [self.searchButton setTitle:@"搜索" forState:UIControlStateNormal];
    [self.searchButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.searchButton addTarget:self action:@selector(doSearch) forControlEvents:UIControlEventTouchUpInside];
    [bar addSubview:self.searchButton];
}

- (void)doSearch {
    [self.searchField resignFirstResponder];
    NSString *keyword = [self.searchField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (keyword.length == 0) {
        [FETheme showToast:@"请输入搜索关键词" inView:self.view];
        return;
    }
    if (self.searching) return;

    NSArray *providers = [self searchProviders];
    if (providers.count == 0) {
        [FETheme showToast:@"没有可用的音源" inView:self.view];
        return;
    }

    self.searching = YES;
    self.retryButton.hidden = YES;
    [self.groups removeAllObjects];
    [self.tableView reloadData];
    [self.spinner startAnimating];

    NSMutableArray *names = [NSMutableArray array];
    for (id<FEProviderProtocol> provider in providers) {
        [names addObject:provider.providerName ?: provider.providerId];
        NSMutableDictionary *group = [@{
            @"provider": provider,
            @"name": provider.providerName ?: provider.providerId,
            @"tracks": [NSMutableArray array]
        } mutableCopy];
        [self.groups addObject:group];
    }
    self.statusLabel.text = [NSString stringWithFormat:@"正在 %@ 搜索…", [names componentsJoinedByString:@" / "]];
    self.pendingRequests = (NSInteger)providers.count;

    __weak typeof(self) weakSelf = self;
    for (NSInteger i = 0; i < (NSInteger)providers.count; i++) {
        id<FEProviderProtocol> provider = providers[i];
        NSMutableDictionary *group = self.groups[i];
        [provider searchWithKeyword:keyword completion:^(NSArray<FETrack *> *tracks, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                [group[@"tracks"] setArray:tracks ?: @[]];
                [strongSelf finishOneRequest];
            });
        }];
    }
}

- (void)finishOneRequest {
    self.pendingRequests -= 1;
    [self.tableView reloadData];
    if (self.pendingRequests > 0) return;

    self.searching = NO;
    [self.spinner stopAnimating];
    NSInteger total = [self totalResultCount];
    if (total > 0) {
        NSMutableArray *parts = [NSMutableArray array];
        for (NSDictionary *group in self.groups) {
            NSArray *tracks = group[@"tracks"];
            if (tracks.count > 0) {
                [parts addObject:[NSString stringWithFormat:@"%@ %lu", group[@"name"], (unsigned long)tracks.count]];
            }
        }
        self.statusLabel.text = [NSString stringWithFormat:@"共 %ld 首（%@）", (long)total, [parts componentsJoinedByString:@" · "]];
        self.retryButton.hidden = YES;
    } else {
        self.statusLabel.text = @"所有已启用音源都没有找到结果";
        self.retryButton.hidden = NO;
    }
}

- (NSArray *)searchProviders {
    FEProviderManager *manager = [FEProviderManager sharedManager];
    NSArray *enabled = [manager enabledProviders];
    if (enabled.count > 0) return enabled;
    if (manager.currentProvider) return @[manager.currentProvider];
    return manager.providers;
}

- (NSInteger)totalResultCount {
    NSInteger total = 0;
    for (NSDictionary *group in self.groups) {
        total += [group[@"tracks"] count];
    }
    return total;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger count = 0;
    for (NSDictionary *group in self.groups) {
        if ([group[@"tracks"] count] > 0) count += 1;
    }
    return count;
}

- (NSDictionary *)groupForSection:(NSInteger)section {
    NSInteger current = -1;
    for (NSDictionary *group in self.groups) {
        if ([group[@"tracks"] count] == 0) continue;
        current += 1;
        if (current == section) return group;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *group = [self groupForSection:section];
    if (group == nil) return nil;
    NSArray *tracks = group[@"tracks"];
    return [NSString stringWithFormat:@"%@ · %lu 首", group[@"name"], (unsigned long)tracks.count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *group = [self groupForSection:section];
    return group ? [group[@"tracks"] count] : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"FESearchTrackCell";
    FETrackCell *cell = (FETrackCell *)[tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[FETrackCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId];
    }
    NSDictionary *group = [self groupForSection:indexPath.section];
    NSArray *tracks = group[@"tracks"];
    if (indexPath.row < (NSInteger)tracks.count) {
        [cell configureWithTrack:tracks[indexPath.row]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *group = [self groupForSection:indexPath.section];
    NSArray *tracks = group[@"tracks"];
    if (indexPath.row >= (NSInteger)tracks.count) return;
    [[FEPlayerManager sharedManager] playTracks:tracks startIndex:indexPath.row];
    [tableView reloadData];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        id root = self.tabBarController;
        if ([root respondsToSelector:@selector(showPlayer)]) [(id)root showPlayer];
    });
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.searchField resignFirstResponder];
}

@end
