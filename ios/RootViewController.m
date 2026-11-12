#import "RootViewController.h"
#import "FETheme.h"
#import "FEComponents.h"
#import "FEIconView.h"
#import "FEImageView.h"
#import "SearchViewController.h"
#import "FESourceListViewController.h"
#import "FELocalMusicViewController.h"
#import "FEPlaylistListViewController.h"
#import "FEPlayerManager.h"
#import "FEProviderManager.h"
#import "FERootTabBarController.h"

static void FEShowPlayer(UIViewController *controller) {
    id root = controller.tabBarController;
    if ([root respondsToSelector:@selector(showPlayer)]) {
        [(id)root showPlayer];
    }
}

@interface RootViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *recentCard;
@property (nonatomic, strong) UILabel *recentHint;
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [FETheme background];
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.contentInset = UIEdgeInsetsMake(24, 0, 80, 0);
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];

    [self buildContent];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self reloadRecent];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)buildContent {
    CGFloat width = self.view.bounds.size.width;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 4, width - 32, 34)];
    title.text = @"音乐库";
    title.textColor = [FETheme textPrimary];
    title.font = [UIFont boldSystemFontOfSize:27];
    [self.scrollView addSubview:title];

    UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 38, width - 32, 18)];
    id<FEProviderProtocol> provider = [FEProviderManager sharedManager].currentProvider;
    subtitle.text = [NSString stringWithFormat:@"当前音源：%@", provider.providerName ?: @"未选择"];
    subtitle.textColor = [FETheme textSecondary];
    subtitle.font = [UIFont systemFontOfSize:11.5];
    [self.scrollView addSubview:subtitle];

    NSArray *items = @[
        @[@"搜索音乐", @"全网找歌", @(FEIconTypeSearch), [FETheme primary]],
        @[@"本地音乐", @"来自系统曲库", @(FEIconTypeHeadphones), [FETheme secondary]],
        @[@"歌单管理", @"整理你的收藏", @(FEIconTypePlaylist), [FETheme accent]],
        @[@"音源管理", @"切换与登录", @(FEIconTypeSettings), [FETheme warning]]
    ];
    CGFloat tileWidth = (width - 24 - 12) / 2.0;
    for (NSInteger i = 0; i < 4; i++) {
        NSInteger column = i % 2;
        NSInteger row = i / 2;
        CGRect frame = CGRectMake(12 + column * (tileWidth + 12), 72 + row * 104, tileWidth, 92);
        NSArray *info = items[i];
        FECardButton *card = [[FECardButton alloc] initWithFrame:frame
                                                            icon:(FEIconType)[info[2] integerValue]
                                                           title:info[0]
                                                        subtitle:info[1]
                                                          accent:info[3]
                                                           style:FECardStyleWide];
        card.tag = 200 + i;
        [card addTarget:self action:@selector(cardTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:card];
    }

    FESectionHeaderView *header = [[FESectionHeaderView alloc] initWithFrame:CGRectMake(12, 286, width - 24, 26)
                                                                      title:@"最近播放"
                                                                actionTitle:nil];
    [self.scrollView addSubview:header];

    self.recentHint = [[UILabel alloc] initWithFrame:CGRectMake(12, 320, width - 24, 66)];
    self.recentHint.text = @"还没有播放记录，去搜索一首歌吧";
    self.recentHint.textColor = [FETheme textSecondary];
    self.recentHint.font = [UIFont systemFontOfSize:12];
    self.recentHint.textAlignment = NSTextAlignmentCenter;
    self.recentHint.backgroundColor = [UIColor whiteColor];
    self.recentHint.layer.cornerRadius = 18;
    self.recentHint.layer.masksToBounds = YES;
    [self.scrollView addSubview:self.recentHint];

    self.recentCard = [[UIView alloc] initWithFrame:CGRectMake(12, 320, width - 24, 1)];
    self.recentCard.backgroundColor = [UIColor whiteColor];
    self.recentCard.layer.cornerRadius = 18;
    self.recentCard.layer.masksToBounds = YES;
    self.recentCard.hidden = YES;
    [self.scrollView addSubview:self.recentCard];

    self.scrollView.contentSize = CGSizeMake(width, 460);
}

- (void)reloadRecent {
    NSArray<FETrack *> *history = [FEPlayerManager sharedManager].history;
    for (UIView *view in [self.recentCard.subviews copy]) {
        [view removeFromSuperview];
    }

    if (history.count == 0) {
        self.recentHint.hidden = NO;
        self.recentCard.hidden = YES;
        self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 460);
        return;
    }

    self.recentHint.hidden = YES;
    self.recentCard.hidden = NO;

    CGFloat width = self.view.bounds.size.width - 24;
    NSInteger count = MIN((NSInteger)history.count, 6);
    CGFloat rowHeight = 60;
    for (NSInteger i = 0; i < count; i++) {
        FETrack *track = history[i];

        FECoverView *cover = [[FECoverView alloc] initWithFrame:CGRectMake(12, i * rowHeight + 10, 40, 40)];
        [cover setCornerRadius:10];
        [cover setImageURL:track.coverUrl];
        [self.recentCard addSubview:cover];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(64, i * rowHeight + 12, width - 64 - 32, 18)];
        title.text = track.title;
        title.font = [UIFont systemFontOfSize:13];
        title.textColor = [FETheme textPrimary];
        title.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.recentCard addSubview:title];

        UILabel *artist = [[UILabel alloc] initWithFrame:CGRectMake(64, i * rowHeight + 31, width - 64 - 32, 15)];
        artist.text = track.artist;
        artist.font = [UIFont systemFontOfSize:10.5];
        artist.textColor = [FETheme textSecondary];
        artist.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.recentCard addSubview:artist];

        if (i < count - 1) {
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(64, (i + 1) * rowHeight - 0.5, width - 76, 0.5)];
            line.backgroundColor = [FETheme separator];
            [self.recentCard addSubview:line];
        }

        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, i * rowHeight, width, rowHeight);
        button.tag = 700 + i;
        [button addTarget:self action:@selector(recentTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.recentCard addSubview:button];
    }

    self.recentCard.frame = CGRectMake(12, 320, width, count * rowHeight);
    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 320 + count * rowHeight + 80);
}

- (void)cardTapped:(FECardButton *)card {
    NSInteger index = card.tag - 200;
    switch (index) {
        case 0: {
            SearchViewController *vc = [[SearchViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 1: {
            FELocalMusicViewController *vc = [[FELocalMusicViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 2: {
            FEPlaylistListViewController *vc = [[FEPlaylistListViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 3: {
            FESourceListViewController *vc = [[FESourceListViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        default:
            break;
    }
}

- (void)recentTapped:(UIButton *)button {
    NSArray<FETrack *> *history = [FEPlayerManager sharedManager].history;
    NSInteger index = button.tag - 700;
    if (index < 0 || index >= (NSInteger)history.count) return;
    [[FEPlayerManager sharedManager] playTracks:history startIndex:index];
    FEShowPlayer(self);
}

@end
