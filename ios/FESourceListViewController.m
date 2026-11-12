#import "FESourceListViewController.h"
#import "FETheme.h"
#import "FEIconView.h"
#import "FEProviderManager.h"
#import "FELoginWebViewController.h"
#import "FESettings.h"

@interface FESourceCell : UITableViewCell
@property (nonatomic, strong) UIView *badge;
@property (nonatomic, strong) UILabel *priorityLabel;
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
        self.backgroundColor = [FETheme card];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.badge = [[UIView alloc] initWithFrame:CGRectMake(12, 14, 40, 40)];
        self.badge.layer.cornerRadius = 13;
        [self.contentView addSubview:self.badge];

        self.iconView = [[FEIconView alloc] initWithFrame:CGRectMake(9, 9, 22, 22)];
        [self.badge addSubview:self.iconView];

        self.priorityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
        self.priorityLabel.textAlignment = NSTextAlignmentCenter;
        self.priorityLabel.font = [UIFont boldSystemFontOfSize:9];
        self.priorityLabel.textColor = [UIColor whiteColor];
        self.priorityLabel.backgroundColor = [FETheme primary];
        self.priorityLabel.layer.cornerRadius = 8;
        self.priorityLabel.layer.masksToBounds = YES;
        [self.contentView addSubview:self.priorityLabel];

        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 14, 140, 20)];
        self.nameLabel.font = [UIFont boldSystemFontOfSize:14];
        self.nameLabel.textColor = [FETheme textPrimary];
        [self.contentView addSubview:self.nameLabel];

        self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 34, 160, 16)];
        self.statusLabel.font = [UIFont systemFontOfSize:10.5];
        self.statusLabel.textColor = [FETheme textSecondary];
        [self.contentView addSubview:self.statusLabel];

        self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.actionButton.frame = CGRectMake(self.bounds.size.width - 86, 18, 74, 28);
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
    self.actionButton.frame = CGRectMake(width - 86, 18, 74, 28);
    self.nameLabel.frame = CGRectMake(64, 14, width - 64 - 96, 20);
    self.statusLabel.frame = CGRectMake(64, 34, width - 64 - 96, 16);
    self.priorityLabel.frame = CGRectMake(8, 8, 16, 16);
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
@property (nonatomic, strong) UIBarButtonItem *editItem;
@end

@implementation FESourceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"音源与登录";
    self.view.backgroundColor = [FETheme background];
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.editItem = [[UIBarButtonItem alloc] initWithTitle:@"排序"
                                                     style:UIBarButtonItemStylePlain
                                                    target:self
                                                    action:@selector(toggleEditing)];
    self.navigationItem.leftBarButtonItem = self.editItem;
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
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 100, 0);
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
    caption.text = @"当前首选音源";
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
    FEProviderManager *manager = [FEProviderManager sharedManager];
    id<FEProviderProtocol> provider = manager.currentProvider;
    self.headerTitle.text = provider.providerName ?: @"未选择";
    NSInteger enabled = (NSInteger)[manager enabledProviders].count;
    self.headerSubtitle.text = [NSString stringWithFormat:@"已启用 %ld 个音源 · 按下方顺序依次尝试", (long)enabled];
}

- (void)doneTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)toggleEditing {
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    self.editItem.title = self.tableView.editing ? @"完成排序" : @"排序";
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"音源列表（拖动排序即优先级）";
    return @"说明";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return [FEProviderManager sharedManager].providers.count;
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"开启「使用」后该音源参与播放与搜索的自动切换；同时可开启多个音源。";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        static NSString *InfoId = @"FEInfoCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:InfoId];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:InfoId];
            cell.backgroundColor = [FETheme card];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.textLabel.text = @"登录方式：手动粘贴 Cookie（不内置网页登录）。点按音源可登录或设为首选。";
        cell.textLabel.font = [UIFont systemFontOfSize:11.5];
        cell.textLabel.textColor = [FETheme textSecondary];
        cell.textLabel.numberOfLines = 2;
        return cell;
    }

    static NSString *CellId = @"FESourceCell";
    FESourceCell *cell = (FESourceCell *)[tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[FESourceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId];
    }

    FEProviderManager *manager = [FEProviderManager sharedManager];
    id<FEProviderProtocol> provider = [manager orderedProviders][indexPath.row];
    BOOL isCurrent = (provider == manager.currentProvider);
    BOOL enabled = [manager isProviderEnabled:provider];
    NSInteger priority = [manager priorityIndexForProvider:provider];

    FEIconType iconType = FEIconTypeNote;
    if ([provider.providerId isEqualToString:@"bilibili"]) iconType = FEIconTypeTV;
    if ([provider.providerId isEqualToString:@"qq"]) iconType = FEIconTypeHeadphones;

    cell.iconView.iconType = iconType;
    cell.iconView.tintColor = enabled ? [FETheme primary] : [FETheme textSecondary];
    cell.badge.backgroundColor = [(enabled ? [FETheme primary] : [FETheme textSecondary]) colorWithAlphaComponent:0.10];
    cell.nameLabel.text = provider.providerName;
    cell.statusLabel.text = [NSString stringWithFormat:@"%@%@",
                             provider.isLoggedIn ? @"已登录" : @"未登录",
                             isCurrent ? @" · 首选" : @""];
    cell.statusLabel.textColor = provider.isLoggedIn ? [FETheme accent] : [FETheme textSecondary];
    cell.priorityLabel.text = [NSString stringWithFormat:@"%ld", (long)(priority + 1)];
    cell.priorityLabel.hidden = !enabled;

    if (enabled) {
        cell.actionButton.backgroundColor = [[FETheme primary] colorWithAlphaComponent:0.14];
        [cell.actionButton setTitle:@"使用中" forState:UIControlStateNormal];
        [cell.actionButton setTitleColor:[FETheme primary] forState:UIControlStateNormal];
    } else {
        cell.actionButton.backgroundColor = [FETheme primary];
        [cell.actionButton setTitle:@"使用" forState:UIControlStateNormal];
        [cell.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }

    __weak typeof(self) weakSelf = self;
    __weak typeof(provider) weakProvider = provider;
    cell.onAction = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf toggleProvider:weakProvider];
    };

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    [[FEProviderManager sharedManager] moveProviderAtIndex:sourceIndexPath.row toIndex:destinationIndexPath.row];
    [self refreshHeader];
    // 等移动动画结束后再刷新序号，避免打断 UITableView 的编辑动画
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section != 0) return;
    if (tableView.editing) return;

    FEProviderManager *manager = [FEProviderManager sharedManager];
    id<FEProviderProtocol> provider = [manager orderedProviders][indexPath.row];
    if (!provider.isLoggedIn) {
        [self openLoginForProvider:provider];
        return;
    }
    [manager switchToProviderWithId:provider.providerId];
    [self.tableView reloadData];
    [self refreshHeader];
    [FETheme showToast:[NSString stringWithFormat:@"%@ 已设为首选", provider.providerName] inView:self.view];
}

- (void)toggleProvider:(id<FEProviderProtocol>)provider {
    FEProviderManager *manager = [FEProviderManager sharedManager];
    BOOL enabled = [manager isProviderEnabled:provider];
    [manager setProvider:provider enabled:!enabled];
    [self.tableView reloadData];
    [self refreshHeader];

    if (!enabled && !provider.isLoggedIn) {
        [FETheme showToast:@"已启用，登录后可访问歌单与推荐" inView:self.view];
    } else {
        [FETheme showToast:enabled ? [NSString stringWithFormat:@"%@ 已停用", provider.providerName]
                                  : [NSString stringWithFormat:@"%@ 使用中", provider.providerName]
                      inView:self.view];
    }
}

- (void)openLoginForProvider:(id<FEProviderProtocol>)provider {
    FELoginViewController *loginVC = [[FELoginViewController alloc] init];
    loginVC.provider = provider;
    [self.navigationController pushViewController:loginVC animated:YES];
}

@end
