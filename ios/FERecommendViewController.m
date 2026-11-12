#import "FERecommendViewController.h"
#import "FETheme.h"
#import "FEComponents.h"
#import "FEIconView.h"
#import "FEImageView.h"
#import "FEProviderManager.h"
#import "FEPlayerManager.h"
#import "FENeteaseProvider.h"
#import "FETrackListViewController.h"
#import "FEPlaylistGridViewController.h"
#import "SearchViewController.h"
#import "FETrack.h"
#import "FEPlaylist.h"
#import "FERootTabBarController.h"

@interface FERecommendViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIScrollView *playlistScroll;
@property (nonatomic, strong) UIView *songsCard;
@property (nonatomic, strong) UILabel *songsHint;
@property (nonatomic, strong) UIActivityIndicatorView *playlistSpinner;
@property (nonatomic, strong) NSArray<FETrack *> *feNewSongs;
@property (nonatomic, strong) NSArray<FEPlaylist *> *recommendPlaylists;
@property (nonatomic, assign) CGFloat contentBottom;
@end

@implementation FERecommendViewController

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
    [self loadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - UI

- (void)buildContent {
    CGFloat width = self.view.bounds.size.width;
    CGFloat cardWidth = width - 24;

    // 顶部渐变 Hero
    FEGradientView *hero = [[FEGradientView alloc] initWithFrame:CGRectMake(12, 0, cardWidth, 118)];
    hero.layer.cornerRadius = 22;
    hero.layer.masksToBounds = YES;
    hero.colors = [FETheme primaryGradientColors];
    [self.scrollView addSubview:hero];

    FEIconView *decor = [[FEIconView alloc] initWithFrame:CGRectMake(cardWidth - 92, 10, 86, 86) iconType:FEIconTypeSparkle];
    decor.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.16];
    decor.lineWidth = 1.2;
    decor.userInteractionEnabled = NO;
    [hero addSubview:decor];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(18, 16, cardWidth - 120, 34)];
    title.text = @"FuoEvolve";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:27];
    [hero addSubview:title];

    UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(18, 52, cardWidth - 120, 18)];
    subtitle.text = @"为 iPhone 4S 而生的音乐播放器";
    subtitle.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.78];
    subtitle.font = [UIFont systemFontOfSize:11.5];
    [hero addSubview:subtitle];

    UIView *searchPill = [[UIView alloc] initWithFrame:CGRectMake(18, 80, cardWidth - 36, 30)];
    searchPill.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.22];
    searchPill.layer.cornerRadius = 15;
    [hero addSubview:searchPill];

    FEIconView *searchIcon = [[FEIconView alloc] initWithFrame:CGRectMake(12, 7, 16, 16) iconType:FEIconTypeSearch];
    searchIcon.tintColor = [UIColor whiteColor];
    searchIcon.lineWidth = 2.0;
    [searchPill addSubview:searchIcon];

    UILabel *searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(36, 0, cardWidth - 80, 30)];
    searchLabel.text = @"搜索歌曲、歌手、专辑";
    searchLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
    searchLabel.font = [UIFont systemFontOfSize:12];
    [searchPill addSubview:searchLabel];

    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    searchButton.frame = searchPill.bounds;
    [searchButton addTarget:self action:@selector(searchTapped) forControlEvents:UIControlEventTouchUpInside];
    [searchPill addSubview:searchButton];

    // 快速入口
    [self addSectionHeader:@"快速发现" action:nil actionTag:-1 y:132];
    NSArray *quick = @[
        @[@"每日推荐", @"每天 6:00 更新", @(FEIconTypeSparkle), [FETheme primary]],
        @[@"私人 FM", @"无限随机播放", @(FEIconTypeRadio), [FETheme secondary]],
        @[@"排行榜", @"热歌 / 新歌榜", @(FEIconTypeChart), [FETheme accent]],
        @[@"歌单广场", @"发现优质歌单", @(FEIconTypePlaylist), [FETheme warning]]
    ];

    CGFloat tileWidth = (width - 24 - 12) / 2.0;
    for (NSInteger i = 0; i < 4; i++) {
        NSInteger column = i % 2;
        NSInteger row = i / 2;
        CGRect frame = CGRectMake(12 + column * (tileWidth + 12), 164 + row * 104, tileWidth, 92);
        NSArray *info = quick[i];
        FECardButton *card = [[FECardButton alloc] initWithFrame:frame
                                                            icon:(FEIconType)[info[2] integerValue]
                                                           title:info[0]
                                                        subtitle:info[1]
                                                          accent:info[3]
                                                           style:FECardStyleWide];
        card.tag = 100 + i;
        [card addTarget:self action:@selector(quickTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:card];
    }

    // 推荐歌单
    [self addSectionHeader:@"推荐歌单" action:@"更多" actionTag:50 y:378];
    self.playlistScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 410, width, 176)];
    self.playlistScroll.showsHorizontalScrollIndicator = NO;
    self.playlistScroll.contentInset = UIEdgeInsetsMake(0, 12, 0, 12);
    [self.scrollView addSubview:self.playlistScroll];

    self.playlistSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.playlistSpinner.center = CGPointMake(width / 2, 480);
    [self.scrollView addSubview:self.playlistSpinner];
    [self.playlistSpinner startAnimating];

    // 新歌速递
    [self addSectionHeader:@"新歌速递" action:@"查看全部" actionTag:60 y:598];
    self.songsHint = [[UILabel alloc] initWithFrame:CGRectMake(12, 632, width - 24, 44)];
    self.songsHint.text = @"正在加载新歌…";
    self.songsHint.textColor = [FETheme textSecondary];
    self.songsHint.font = [UIFont systemFontOfSize:12];
    self.songsHint.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:self.songsHint];

    self.songsCard = [[UIView alloc] initWithFrame:CGRectMake(12, 634, width - 24, 1)];
    self.songsCard.backgroundColor = [UIColor whiteColor];
    self.songsCard.layer.cornerRadius = 18;
    self.songsCard.layer.masksToBounds = YES;
    self.songsCard.hidden = YES;
    [self.scrollView addSubview:self.songsCard];

    self.contentBottom = 700;
    self.scrollView.contentSize = CGSizeMake(width, self.contentBottom);
}

- (void)addSectionHeader:(NSString *)title action:(NSString *)action actionTag:(NSInteger)tag y:(CGFloat)y {
    FESectionHeaderView *header = [[FESectionHeaderView alloc] initWithFrame:CGRectMake(12, y, self.view.bounds.size.width - 24, 26)
                                                                      title:title
                                                                actionTitle:action];
    if (action.length > 0) {
        header.actionButton.tag = tag;
        [header.actionButton addTarget:self action:@selector(sectionActionTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    [self.scrollView addSubview:header];
}

#pragma mark - Data

- (FENeteaseProvider *)neteaseProvider {
    for (id<FEProviderProtocol> provider in [FEProviderManager sharedManager].providers) {
        if ([provider isKindOfClass:[FENeteaseProvider class]]) return (FENeteaseProvider *)provider;
    }
    return nil;
}

- (void)loadData {
    FENeteaseProvider *netease = [self neteaseProvider];
    if (netease == nil) {
        [self.playlistSpinner stopAnimating];
        self.songsHint.text = @"没有可用的音源";
        return;
    }

    __weak typeof(self) weakSelf = self;
    [netease getPersonalizedPlaylistsWithCompletion:^(NSArray<FEPlaylist *> *playlists, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf.playlistSpinner stopAnimating];
        strongSelf.recommendPlaylists = playlists;
        [strongSelf reloadPlaylists];
    }];

    [netease getNewSongsWithCompletion:^(NSArray<FETrack *> *tracks, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.feNewSongs = tracks;
        [strongSelf reloadNewSongs];
    }];
}

- (void)reloadPlaylists {
    for (UIView *view in [self.playlistScroll.subviews copy]) {
        [view removeFromSuperview];
    }
    if (self.recommendPlaylists.count == 0) {
        UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, self.view.bounds.size.width - 24, 120)];
        hint.text = @"推荐歌单加载失败，下拉重试";
        hint.textColor = [FETheme textSecondary];
        hint.font = [UIFont systemFontOfSize:12];
        hint.textAlignment = NSTextAlignmentCenter;
        [self.playlistScroll addSubview:hint];
        return;
    }

    CGFloat itemWidth = 126;
    CGFloat coverSide = 126;
    for (NSInteger i = 0; i < (NSInteger)self.recommendPlaylists.count; i++) {
        FEPlaylist *playlist = self.recommendPlaylists[i];
        CGFloat x = i * (itemWidth + 12);

        FECoverView *cover = [[FECoverView alloc] initWithFrame:CGRectMake(x, 0, coverSide, coverSide)];
        [cover setCornerRadius:16];
        [cover setImageURL:playlist.coverUrl];
        [self.playlistScroll addSubview:cover];

        UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(x, coverSide + 6, itemWidth, 30)];
        name.text = playlist.name;
        name.font = [UIFont systemFontOfSize:11.5];
        name.textColor = [FETheme textPrimary];
        name.numberOfLines = 2;
        [self.playlistScroll addSubview:name];

        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(x, 0, itemWidth, 160);
        button.tag = 5000 + i;
        [button addTarget:self action:@selector(playlistTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.playlistScroll addSubview:button];
    }
    self.playlistScroll.contentSize = CGSizeMake(self.recommendPlaylists.count * (itemWidth + 12) + 12, 176);
}

- (void)reloadNewSongs {
    if (self.feNewSongs.count == 0) {
        self.songsHint.text = @"新歌加载失败，请检查网络";
        return;
    }
    self.songsHint.hidden = YES;
    self.songsCard.hidden = NO;
    for (UIView *view in [self.songsCard.subviews copy]) {
        [view removeFromSuperview];
    }

    CGFloat width = self.songsCard.bounds.size.width;
    NSInteger count = MIN((NSInteger)self.feNewSongs.count, 6);
    CGFloat rowHeight = 62;

    for (NSInteger i = 0; i < count; i++) {
        FETrack *track = self.feNewSongs[i];

        FECoverView *cover = [[FECoverView alloc] initWithFrame:CGRectMake(12, i * rowHeight + 9, 44, 44)];
        [cover setCornerRadius:10];
        [cover setImageURL:track.coverUrl];
        [self.songsCard addSubview:cover];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(66, i * rowHeight + 12, width - 66 - 40, 19)];
        title.text = track.title;
        title.font = [UIFont systemFontOfSize:13.5];
        title.textColor = [FETheme textPrimary];
        title.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.songsCard addSubview:title];

        UILabel *artist = [[UILabel alloc] initWithFrame:CGRectMake(66, i * rowHeight + 33, width - 66 - 40, 16)];
        artist.text = track.artist;
        artist.font = [UIFont systemFontOfSize:10.5];
        artist.textColor = [FETheme textSecondary];
        artist.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.songsCard addSubview:artist];

        FEIconView *play = [[FEIconView alloc] initWithFrame:CGRectMake(width - 36, i * rowHeight + 21, 18, 18) iconType:FEIconTypePlay];
        play.tintColor = [FETheme primary];
        play.userInteractionEnabled = NO;
        [self.songsCard addSubview:play];

        if (i < count - 1) {
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(66, (i + 1) * rowHeight - 0.5, width - 78, 0.5)];
            line.backgroundColor = [FETheme separator];
            [self.songsCard addSubview:line];
        }

        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, i * rowHeight, width, rowHeight);
        button.tag = 6000 + i;
        [button addTarget:self action:@selector(newSongTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.songsCard addSubview:button];
    }

    self.songsCard.frame = CGRectMake(12, 634, width, count * rowHeight);
    self.contentBottom = 634 + count * rowHeight + 80;
    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, self.contentBottom);
}

#pragma mark - Actions

- (void)searchTapped {
    SearchViewController *vc = [[SearchViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)sectionActionTapped:(UIButton *)button {
    if (button.tag == 50) {
        [self pushPlaylistGrid:FEPlaylistSourcePersonalized title:@"推荐歌单"];
    } else if (button.tag == 60) {
        if (self.feNewSongs.count == 0) {
            [FETheme showToast:@"新歌还在加载中" inView:self.view];
            return;
        }
        FETrackListViewController *vc = [[FETrackListViewController alloc] initWithTitle:@"新歌速递" tracks:self.feNewSongs];
        vc.listSubtitle = @"网易云音乐 · 新歌速递";
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)quickTapped:(FECardButton *)card {
    NSInteger index = card.tag - 100;
    if (index == 2) {
        [self pushPlaylistGrid:FEPlaylistSourceToplist title:@"排行榜"];
        return;
    }
    if (index == 3) {
        [self pushPlaylistGrid:FEPlaylistSourceSquare title:@"歌单广场"];
        return;
    }

    FENeteaseProvider *netease = [self neteaseProvider];
    if (netease == nil) return;

    [FETheme showToast:(index == 0 ? @"正在拉取每日推荐…" : @"正在开启私人 FM…") inView:self.view];
    if (index == 0) {
        [netease getDailyRecommendSongsWithCompletion:^(NSArray<FETrack *> *tracks, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (tracks.count == 0) {
                    [FETheme showToast:@"每日推荐需要登录网易云账号" inView:self.view];
                    return;
                }
                FETrackListViewController *vc = [[FETrackListViewController alloc] initWithTitle:@"每日推荐" tracks:tracks];
                vc.listSubtitle = @"根据你的口味生成，每天更新";
                [self.navigationController pushViewController:vc animated:YES];
            });
        }];
    } else {
        [netease getRadioSongsWithCompletion:^(NSArray<FETrack *> *tracks, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (tracks.count == 0) {
                    [FETheme showToast:@"私人 FM 需要登录网易云账号" inView:self.view];
                    return;
                }
                FETrackListViewController *vc = [[FETrackListViewController alloc] initWithTitle:@"私人 FM" tracks:tracks];
                vc.listSubtitle = @"无限随机播放";
                [self.navigationController pushViewController:vc animated:YES];
            });
        }];
    }
}

- (void)pushPlaylistGrid:(FEPlaylistSource)source title:(NSString *)title {
    FEPlaylistGridViewController *vc = [[FEPlaylistGridViewController alloc] initWithSource:source title:title];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)playlistTapped:(UIButton *)button {
    NSInteger index = button.tag - 5000;
    if (index < 0 || index >= (NSInteger)self.recommendPlaylists.count) return;
    FEPlaylist *playlist = self.recommendPlaylists[index];
    FENeteaseProvider *netease = [self neteaseProvider];
    if (netease == nil) return;

    [FETheme showToast:@"正在加载歌单…" inView:self.view];
    [netease getPlaylistTracks:playlist completion:^(NSArray<FETrack *> *tracks, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (tracks.count == 0) {
                [FETheme showToast:@"歌单暂时取不到歌曲" inView:self.view];
                return;
            }
            FETrackListViewController *vc = [[FETrackListViewController alloc] initWithTitle:playlist.name tracks:tracks];
            vc.listSubtitle = @"网易云音乐 · 推荐歌单";
            [self.navigationController pushViewController:vc animated:YES];
        });
    }];
}

- (void)newSongTapped:(UIButton *)button {
    NSInteger index = button.tag - 6000;
    if (index < 0 || index >= (NSInteger)self.feNewSongs.count) return;
    [[FEPlayerManager sharedManager] playTracks:self.feNewSongs startIndex:index];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        id root = self.tabBarController;
        if ([root respondsToSelector:@selector(showPlayer)]) [(id)root showPlayer];
    });
}

@end
