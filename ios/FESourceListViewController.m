#import "FESourceListViewController.h"
#import "FETheme.h"
#import "FEIconView.h"
#import "FEProviderManager.h"
#import "FELoginWebViewController.h"

@interface FESourceCell : UITableViewCell
@property (nonatomic, strong) UIView *badge;
@property (nonatomic, strong) FEIconView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, copy) void (^onAction)(void);
@end

@implementation FESourceCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.badge = [[UIView alloc] initWithFrame:CGRectMake(16, 14, 40, 40)];
        self.badge.layer.cornerRadius = 13;
        [self.contentView addSubview:self.badge];

        self.iconView = [[FEIconView alloc] initWithFrame:CGRectMake(9, 9, 22, 22)];
        [self.badge addSubview:self.iconView];

        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(68, 14, 140, 20)];
        self.nameLabel.font = [UIFont boldSystemFontOfSize:14];
        self.nameLabel.textColor = [FETheme textPrimary];
        [self.contentView addSubview:self.nameLabel];

        self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(68, 34, 160, 16)];
        self.statusLabel.font = [UIFont systemFontOfSize:10.5];
        self.statusLabel.textColor = [FETheme textSecondary];
        [self.contentView addSubview:self.statusLabel];

        self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.actionButton.frame = CGRectMake(self.bounds.size.width - 78, 18, 62, 28);
        self.actionButton.layer.cornerRadius = 14;
        self.actionButton.titleLabel.font = [UIFont boldSystemFontOfSize:10.5];
        [self.actionButton addTarget:self action:@selector(actionTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.actionButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    self.actionButton.frame = CGRectMake(width - 78, 18, 62, 28);
    self.nameLabel.frame = CGRectMake(68, 14, width - 68 - 92, 20);
    self.statusLabel.frame = CGRectMake(68, 34, width - 68 - 92, 16);
}

- (void)actionTapped {
    if (self.onAction) self.onAction();
}

@end

@interface FESourceListViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *headerTitle;
@property (nonatomic, strong) UILabel *headerSubtitle;
@end

@implementation FESourceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"音源与登录";
    self.view.backgroundColor = [FETheme background];
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(doneTapped)];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 68;
    self.tableView.backgroundColor = [FETheme background];
    self.tableView.separatorColor = [FETheme separator];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 80, 0);
    [self.view addSubview:self.tableView];

    [self buildHeader];
    [self refreshHeader];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.tableView reloadData];
    [self refreshHeader];
}

- (void)buildHeader {
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 116)];
    self.headerView.backgroundColor = [UIColor clearColor];

    FEGradientView *card = [[FEGradientView alloc] initWithFrame:CGRectMake(12, 10, self.view.bounds.size.width - 24, 96)];
    card.layer.cornerRadius = 20;
    card.layer.masksToBounds = YES;
    card.colors = [FETheme primaryGradientColors];
    [self.headerView addSubview:card];

    UILabel *caption = [[UILabel alloc] initWithFrame:CGRectMake(18, 14, 200, 16)];
    caption.text = @"当前音源";
    caption.font = [UIFont systemFontOfSize:11];
    caption.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.72];
    [card addSubview:caption];

    self.headerTitle = [[UILabel alloc] initWithFrame:CGRectMake(18, 30, self.view.bounds.size.width - 80, 28)];
    self.headerTitle.font = [UIFont boldSystemFontOfSize:20];
    self.headerTitle.textColor = [UIColor whiteColor];
    [card addSubview:self.headerTitle];

    self.headerSubtitle = [[UILabel alloc] initWithFrame:CGRectMake(18, 62, self.view.bounds.size.width - 80, 18)];
    self.headerSubtitle.font = [UIFont systemFontOfSize:11];
    self.headerSubtitle.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
    [card addSubview:self.headerSubtitle];

    FEIconView *decor = [[FEIconView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 24 - 70, 10, 60, 60) iconType:FEIconTypeHeadphones];
    decor.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.16];
    [card addSubview:decor];

    self.tableView.tableHeaderView = self.headerView;
}

- (void)refreshHeader {
    id<FEProviderProtocol> provider = [FEProviderManager sharedManager].currentProvider;
    self.headerTitle.text = provider.providerName ?: @"未选择";
    self.headerSubtitle.text = provider.isLoggedIn ? @"已登录，可以访问歌单与推荐" : @"未登录，搜索与部分歌曲仍可用";
}

- (void)doneTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"选择音源" : @"说明";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return [FEProviderManager sharedManager].providers.count;
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        static NSString *InfoId = @"FEInfoCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:InfoId];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:InfoId];
            cell.backgroundColor = [UIColor whiteColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.textLabel.text = @"登录方式：在设置中手动粘贴 Cookie";
        cell.textLabel.font = [UIFont systemFontOfSize:12];
        cell.textLabel.textColor = [FETheme textSecondary];
        cell.textLabel.numberOfLines = 2;
        return cell;
    }

    static NSString *CellId = @"FESourceCell";
    FESourceCell *cell = (FESourceCell *)[tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[FESourceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId];
    }

    id<FEProviderProtocol> provider = [FEProviderManager sharedManager].providers[indexPath.row];
    BOOL isCurrent = (provider == [FEProviderManager sharedManager].currentProvider);

    FEIconType iconType = FEIconTypeNote;
    if ([provider.providerId isEqualToString:@"bilibili"]) iconType = FEIconTypeTV;
    if ([provider.providerId isEqualToString:@"qq"]) iconType = FEIconTypeHeadphones;

    cell.iconView.iconType = iconType;
    cell.iconView.tintColor = isCurrent ? [FETheme primary] : [FETheme textSecondary];
    cell.badge.backgroundColor = [(isCurrent ? [FETheme primary] : [FETheme textSecondary]) colorWithAlphaComponent:0.10];
    cell.nameLabel.text = provider.providerName;
    cell.statusLabel.text = provider.isLoggedIn ? @"已登录" : @"未登录 · 手动 Cookie";
    cell.statusLabel.textColor = provider.isLoggedIn ? [FETheme accent] : [FETheme textSecondary];

    if (isCurrent) {
        cell.actionButton.backgroundColor = [[FETheme primary] colorWithAlphaComponent:0.12];
        [cell.actionButton setTitle:@"使用中" forState:UIControlStateNormal];
        [cell.actionButton setTitleColor:[FETheme primary] forState:UIControlStateNormal];
        cell.onAction = ^{
            [self openLoginIfNeeded:provider];
        };
    } else {
        cell.actionButton.backgroundColor = [FETheme primary];
        [cell.actionButton setTitle:provider.isLoggedIn ? @"切换" : @"登录" forState:UIControlStateNormal];
        [cell.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        __weak typeof(self) weakSelf = self;
        __weak typeof(provider) weakProvider = provider;
        cell.onAction = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            if (weakProvider.isLoggedIn) {
                [strongSelf switchToProvider:weakProvider];
            } else {
                [strongSelf openLoginForProvider:weakProvider];
            }
        };
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section != 0) return;

    id<FEProviderProtocol> provider = [FEProviderManager sharedManager].providers[indexPath.row];
    if (provider == [FEProviderManager sharedManager].currentProvider) {
        [self openLoginIfNeeded:provider];
        return;
    }
    if (provider.isLoggedIn) {
        [self switchToProvider:provider];
    } else {
        [self openLoginForProvider:provider];
    }
}

- (void)openLoginIfNeeded:(id<FEProviderProtocol>)provider {
    if (!provider.isLoggedIn) {
        [self openLoginForProvider:provider];
    } else {
        [FETheme showToast:@"已经是当前音源" inView:self.view];
    }
}

- (void)openLoginForProvider:(id<FEProviderProtocol>)provider {
    FELoginViewController *loginVC = [[FELoginViewController alloc] init];
    loginVC.provider = provider;
    [self.navigationController pushViewController:loginVC animated:YES];
}

- (void)switchToProvider:(id<FEProviderProtocol>)provider {
    [[FEProviderManager sharedManager] switchToProviderWithId:provider.providerId];
    [self.tableView reloadData];
    [self refreshHeader];
    [FETheme showToast:[NSString stringWithFormat:@"已切换到 %@", provider.providerName] inView:self.view];
}

@end
