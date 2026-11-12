#import "FELocalMusicViewController.h"
#import "FETheme.h"
#import "FEComponents.h"
#import "FEImageView.h"
#import "FEIconView.h"
#import "FELocalMusicManager.h"
#import "FEPlayerManager.h"
#import "FERootTabBarController.h"

@interface FELocalMusicViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<FETrack *> *tracks;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@end

@implementation FELocalMusicViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"本地音乐";
    self.view.backgroundColor = [FETheme background];
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 68;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 80, 0);
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 74, 0, 16);
    [FETheme styleTableView:self.tableView];
    [self.view addSubview:self.tableView];

    [self buildHeader];

    self.emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 220, self.view.bounds.size.width - 48, 60)];
    self.emptyLabel.text = @"系统音乐库中还没有歌曲\n请在「音乐」App 中同步后重新扫描";
    self.emptyLabel.numberOfLines = 0;
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.textColor = [FETheme textSecondary];
    self.emptyLabel.font = [UIFont systemFontOfSize:12];
    self.emptyLabel.hidden = YES;
    [self.view addSubview:self.emptyLabel];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = CGPointMake(self.view.bounds.size.width / 2, 180);
    [self.view addSubview:self.spinner];

    [self scan];
}

- (void)buildHeader {
    CGFloat width = self.view.bounds.size.width;
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 126)];
    container.backgroundColor = [UIColor clearColor];

    FEGradientView *card = [[FEGradientView alloc] initWithFrame:CGRectMake(12, 12, width - 24, 102)];
    card.layer.cornerRadius = 20;
    card.layer.masksToBounds = YES;
    card.colors = @[(id)[FETheme secondary].CGColor, (id)[FETheme primary].CGColor];
    [container addSubview:card];

    FEIconView *decor = [[FEIconView alloc] initWithFrame:CGRectMake(width - 24 - 86, 8, 80, 80) iconType:FEIconTypeHeadphones];
    decor.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.16];
    decor.userInteractionEnabled = NO;
    [card addSubview:decor];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(18, 18, width - 24 - 110, 26)];
    title.text = @"本地音乐";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:20];
    [card addSubview:title];

    self.countLabel = [[UILabel alloc] initWithFrame:CGRectMake(18, 46, width - 24 - 110, 18)];
    self.countLabel.text = @"正在扫描…";
    self.countLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.82];
    self.countLabel.font = [UIFont systemFontOfSize:11];
    [card addSubview:self.countLabel];

    UIButton *rescan = [UIButton buttonWithType:UIButtonTypeCustom];
    rescan.frame = CGRectMake(18, 68, 84, 24);
    rescan.backgroundColor = [UIColor whiteColor];
    rescan.layer.cornerRadius = 12;
    rescan.titleLabel.font = [UIFont boldSystemFontOfSize:10.5];
    [rescan setTitle:@"重新扫描" forState:UIControlStateNormal];
    [rescan setTitleColor:[FETheme secondary] forState:UIControlStateNormal];
    [rescan addTarget:self action:@selector(scan) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:rescan];

    self.tableView.tableHeaderView = container;
}

- (void)scan {
    [self.spinner startAnimating];
    self.countLabel.text = @"正在扫描…";
    __weak typeof(self) weakSelf = self;
    [[FELocalMusicManager sharedManager] scanLocalMusicWithCompletion:^(NSArray<FETrack *> *tracks) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            [strongSelf.spinner stopAnimating];
            strongSelf.tracks = tracks ?: @[];
            strongSelf.countLabel.text = [NSString stringWithFormat:@"共 %lu 首 · 来自系统音乐库", (unsigned long)strongSelf.tracks.count];
            strongSelf.emptyLabel.hidden = strongSelf.tracks.count > 0;
            [strongSelf.tableView reloadData];
        });
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tracks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"FELocalTrackCell";
    FETrackCell *cell = (FETrackCell *)[tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[FETrackCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId];
    }
    [cell configureWithTrack:self.tracks[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= (NSInteger)self.tracks.count) return;
    [[FEPlayerManager sharedManager] playTracks:self.tracks startIndex:indexPath.row];
    [tableView reloadData];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        id root = self.tabBarController;
        if ([root respondsToSelector:@selector(showPlayer)]) [(id)root showPlayer];
    });
}

@end
