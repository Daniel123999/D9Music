#import "FETrackListViewController.h"
#import "FETheme.h"
#import "FEComponents.h"
#import "FEIconView.h"
#import "FEImageView.h"
#import "FEPlayerManager.h"
#import "FERootTabBarController.h"

@interface FETrackListViewController ()
@property (nonatomic, copy) NSString *listTitle;
@property (nonatomic, strong) NSArray<FETrack *> *tracks;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) FEGradientView *headerCard;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@end

@implementation FETrackListViewController

- (instancetype)initWithTitle:(NSString *)title tracks:(NSArray<FETrack *> *)tracks {
    self = [super init];
    if (self) {
        _listTitle = [title copy];
        _tracks = [tracks copy];
        _listSubtitle = @"";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.listTitle ?: @"歌曲";
    self.view.backgroundColor = [FETheme background];
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 68;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 78, 0);
    [FETheme styleTableView:self.tableView];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 74, 0, 16);
    [self.view addSubview:self.tableView];

    [self buildHeader];
}

- (void)buildHeader {
    CGFloat width = self.view.bounds.size.width;
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 136)];
    container.backgroundColor = [UIColor clearColor];

    self.headerCard = [[FEGradientView alloc] initWithFrame:CGRectMake(12, 12, width - 24, 112)];
    self.headerCard.layer.cornerRadius = 20;
    self.headerCard.layer.masksToBounds = YES;
    self.headerCard.colors = [FETheme primaryGradientColors];
    [container addSubview:self.headerCard];

    FEIconView *decor = [[FEIconView alloc] initWithFrame:CGRectMake(width - 24 - 92, 10, 92, 92) iconType:FEIconTypeDisc];
    decor.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.16];
    decor.lineWidth = 1.4;
    decor.userInteractionEnabled = NO;
    [self.headerCard addSubview:decor];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(18, 18, width - 24 - 120, 24)];
    label.text = self.listTitle ?: @"歌曲";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:20];
    [self.headerCard addSubview:label];

    self.countLabel = [[UILabel alloc] initWithFrame:CGRectMake(18, 44, width - 24 - 120, 18)];
    self.countLabel.text = [NSString stringWithFormat:@"共 %lu 首", (unsigned long)self.tracks.count];
    self.countLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.82];
    self.countLabel.font = [UIFont systemFontOfSize:12];
    [self.headerCard addSubview:self.countLabel];

    self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(18, 64, width - 24 - 100, 16)];
    self.subtitleLabel.text = self.listSubtitle;
    self.subtitleLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    self.subtitleLabel.font = [UIFont systemFontOfSize:11];
    [self.headerCard addSubview:self.subtitleLabel];

    UIButton *playAll = [UIButton buttonWithType:UIButtonTypeCustom];
    playAll.frame = CGRectMake(18, 80, 104, 26);
    playAll.backgroundColor = [UIColor whiteColor];
    playAll.layer.cornerRadius = 13;
    playAll.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [playAll setTitleColor:[FETheme primary] forState:UIControlStateNormal];
    [playAll setTitle:@"▶  播放全部" forState:UIControlStateNormal];
    [playAll addTarget:self action:@selector(playAllTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.headerCard addSubview:playAll];

    self.tableView.tableHeaderView = container;
}

- (void)playAllTapped {
    if (self.tracks.count == 0) {
        [FETheme showToast:@"列表还没有歌曲" inView:self.view];
        return;
    }
    [[FEPlayerManager sharedManager] playTracks:self.tracks startIndex:0];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self openPlayer];
    });
}

- (void)openPlayer {
    id root = self.tabBarController;
    if ([root respondsToSelector:@selector(showPlayer)]) {
        [(id)root showPlayer];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tracks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"FETrackCell";
    FETrackCell *cell = (FETrackCell *)[tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[FETrackCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId];
    }
    [cell configureWithTrack:self.tracks[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[FEPlayerManager sharedManager] playTracks:self.tracks startIndex:indexPath.row];
    [tableView reloadData];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self openPlayer];
    });
}

@end
