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
@property (nonatomic, strong) UIView *sectionsContainer;
@property (nonatomic, strong) NSMutableArray<NSMutableDictionary *> *sections;
@property (nonatomic, assign) CGFloat contentBottom;
@property (nonatomic, strong) UILabel *emptyHint;
@end

@implementation FERecommendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [FETheme background];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.sections = [NSMutableArray array];

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.contentInset = UIEdgeInsetsMake(24, 0, 100, 0);
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
    title.text = @"D9Music";
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
    searchLabel.text = @"多音源搜索歌曲、歌手、专辑";
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

    self.sectionsContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 372, width, 1)];
    self.sectionsContainer.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:self.sectionsContainer];

    self.emptyHint = [[UILabel alloc] initWithFrame:CGRectMake(12, 390, width - 24, 60)];
    self.emptyHint.text = @"登录网易云或 QQ 音乐后，这里会出现对应音源的推荐";
    self.emptyHint.textColor = [FETheme textSecondary];
    self.emptyHint.font = [UIFont systemFontOfSize:12];
    self.emptyHint.textAlignment = NSTextAlignmentCenter;
    self.emptyHint.numberOfLines = 2;
    [self.scrollView addSubview:self.emptyHint];

    self.scrollView.contentSize = CGSizeMake(width, 700);
}

- (void)addSectionHeader:(NSString *)title action:(NSString *)action actionTag:(NSInteger)tag y:(CGFloat)y {
    FESectionHeaderView *header = [[FESectionHeaderView alloc] initWithFrame:CGRectMake(12, y, self.view.bounds.size.width - 24, 26)
                                                                      title:title
                                                                actionTitle:action];
    if (action.length > 0) {
        if (header.actionButton.superview == nil) {
            header.actionButton.tag = tag;
            [header.actionButton addTarget:self action:@selector(sectionActionTapped:) forControlEvents:UIControlEventTouchUpInside];
        }
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

- (NSArray *)recommendationProviders {
    FEProviderManager *manager = [FEProviderManager sharedManager];
    NSMutableArray *result = [NSMutableArray array];
    for (id<FEProviderProtocol> provider in [manager orderedProviders]) {
        if (!provider.isLoggedIn) continue;
        if (![provider respondsToSelector:@selector(getPersonalizedPlaylistsWithCompletion:)] &&
            ![provider respondsToSelector:@selector(getNewSongsWithCompletion:)]) continue;
        [result addObject:provider];
    }
    if (result.count > 0) return result;

    // 都没登录时，用网易云公开推荐兜底，避免页面空白
    FENeteaseProvider *netease = [self neteaseProvider];
    return netease ? @[netease] : @[];
}

- (void)loadData {
    NSArray *providers = [self recommendationProviders];
    if (providers.count == 0) {
        self.emptyHint.hidden = NO;
        return;
    }
    self.emptyHint.hidden = YES;

    for (id<FEProviderProtocol> provider in providers) {
        NSMutableDictionary *section = [@{
            @"provider": provider,
            @"name": [NSString stringWithFormat:@"%@推荐", provider.providerName],
            @"playlists": [NSMutableArray array],
            @"tracks": [NSMutableArray array]
        } mutableCopy];
        [self.sections addObject:section];

        if ([provider respondsToSelector:@selector(getPersonalizedPlaylistsWithCompletion:)]) {
            [provider getPersonalizedPlaylistsWithCompletion:^(NSArray<FEPlaylist *> *playlists, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [section[@"playlists"] setArray:playlists ?: @[]];
                    [self rebuildSections];
                });
            }];
        }
        if ([provider respondsToSelector:@selector(getNewSongsWithCompletion:)]) {
            [provider getNewSongsWithCompletion:^(NSArray<FETrack *> *tracks, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [section[@"tracks"] setArray:tracks ?: @[]];
                    [self rebuildSections];
                });
            }];
        }
    }
}

- (void)rebuildSections {
    for (UIView *view in [self.sectionsContainer.subviews copy]) {
        [view removeFromSuperview];
    }

    CGFloat width = self.view.bounds.size.width;
    CGFloat y = 0;

    for (NSInteger s = 0; s < (NSInteger)self.sections.count; s++) {
        NSDictionary *section = self.sections[s];
        NSArray *playlists = section[@"playlists"];
        NSArray<FETrack *> *tracks = section[@"tracks"];
        if (playlists.count == 0 && tracks.count == 0) continue;

        UILabel *header = [[UILabel alloc] initWithFrame:CGRectMake(12, y, width - 24, 24)];
        header.text = section[@"name"];
        header.font = [UIFont boldSystemFontOfSize:16];
        header.textColor = [FETheme textPrimary];
        [self.sectionsContainer addSubview:header];
        y += 30;

        if (playlists.count > 0) {
            UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y, width, 170)];
            scroll.showsHorizontalScrollIndicator = NO;
            scroll.contentInset = UIEdgeInsetsMake(0, 12, 0, 12);
            [self.sectionsContainer addSubview:scroll];

            CGFloat itemWidth = 122;
            for (NSInteger i = 0; i < (NSInteger)playlists.count; i++) {
                FEPlaylist *playlist = playlists[i];
                CGFloat x = i * (itemWidth + 12);

                FECoverView *cover = [[FECoverView alloc] initWithFrame:CGRectMake(x, 0, itemWidth, itemWidth)];
                [cover setCornerRadius:14];
                [cover setImageURL:playlist.coverUrl];
                [scroll addSubview:cover];

                UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(x, itemWidth + 5, itemWidth, 30)];
                name.text = playlist.name;
                name.font = [UIFont systemFontOfSize:11];
                name.textColor = [FETheme textPrimary];
                name.numberOfLines = 2;
                [scroll addSubview:name];

                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.frame = CGRectMake(x, 0, itemWidth, 158);
                button.tag = s * 1000 + i;
                [button addTarget:self action:@selector(playlistTapped:) forControlEvents:UIControlEventTouchUpInside];
                [scroll addSubview:button];
            }
            scroll.contentSize = CGSizeMake(playlists.count * (itemWidth + 12) + 12, 170);
            y += 180;
        }

        if (tracks.count > 0) {
            NSInteger count = MIN((NSInteger)tracks.count, 5);
            CGFloat rowHeight = 58;
            UIView *card = [[UIView alloc] initWithFrame:CGRectMake(12, y, width - 24, count * rowHeight)];
            card.backgroundColor = [FETheme card];
            card.layer.cornerRadius = 18;
            card.layer.masksToBounds = YES;
            [self.sectionsContainer addSubview:card];

            for (NSInteger i = 0; i < count; i++) {
                FETrack *track = tracks[i];

                FECoverView *cover = [[FECoverView alloc] initWithFrame:CGRectMake(10, i * rowHeight + 7, 42, 42)];
                [cover setCornerRadius:9];
                [cover setImageURL:track.coverUrl];
                [card addSubview:cover];

                UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(60, i * rowHeight + 9, width - 24 - 60 - 40, 19)];
                title.text = track.title;
                title.font = [UIFont systemFontOfSize:13];
                title.textColor = [FETheme textPrimary];
                title.lineBreakMode = NSLineBreakByTruncatingTail;
                [card addSubview:title];

                UILabel *artist = [[UILabel alloc] initWithFrame:CGRectMake(60, i * rowHeight + 29, width - 24 - 60 - 40, 16)];
                artist.text = track.artist;
                artist.font = [UIFont systemFontOfSize:10.5];
                artist.textColor = [FETheme textSecondary];
                artist.lineBreakMode = NSLineBreakByTruncatingTail;
                [card addSubview:artist];

                if (i < count - 1) {
                    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(60, (i + 1) * rowHeight - 0.5, width - 96, 0.5)];
                    line.backgroundColor = [FETheme separator];
                    [card addSubview:line];
                }

                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.frame = CGRectMake(0, i * rowHeight, width - 24, rowHeight);
                button.tag = s * 1000 + 500 + i;
                [button addTarget:self action:@selector(trackTapped:) forControlEvents:UIControlEventTouchUpInside];
                [card addSubview:button];
            }
            y += count * rowHeight + 16;
        }
        y += 8;
    }

    CGFloat top = 372;
    self.sectionsContainer.frame = CGRectMake(0, top, width, MAX(1, y));
    self.emptyHint.hidden = self.sections.count > 0 && y > 0;
    if (self.emptyHint.hidden == NO) {
        self.emptyHint.frame = CGRectMake(12, top + 20, width - 24, 60);
    }
    self.contentBottom = top + y + 90;
    self.scrollView.contentSize = CGSizeMake(width, MAX(self.contentBottom, 700));
}

#pragma mark - Actions

- (void)searchTapped {
    [self.navigationController pushViewController:[[SearchViewController alloc] init] animated:YES];
}

- (void)sectionActionTapped:(UIButton *)button {
    if (button.tag == 50) {
        [self pushPlaylistGrid:FEPlaylistSourcePersonalized title:@"推荐歌单"];
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
    NSInteger sectionIndex = button.tag / 1000;
    NSInteger index = button.tag % 1000;
    if (sectionIndex < 0 || sectionIndex >= (NSInteger)self.sections.count) return;
    NSDictionary *section = self.sections[sectionIndex];
    NSArray *playlists = section[@"playlists"];
    if (index < 0 || index >= (NSInteger)playlists.count) return;

    FEPlaylist *playlist = playlists[index];
    id<FEProviderProtocol> provider = section[@"provider"];
    if (provider == nil) return;

    [FETheme showToast:@"正在加载歌单…" inView:self.view];
    [provider getPlaylistTracks:playlist completion:^(NSArray<FETrack *> *tracks, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (tracks.count == 0) {
                [FETheme showToast:@"歌单暂时取不到歌曲" inView:self.view];
                return;
            }
            FETrackListViewController *vc = [[FETrackListViewController alloc] initWithTitle:playlist.name tracks:tracks];
            vc.listSubtitle = [NSString stringWithFormat:@"%@ · 推荐歌单", provider.providerName];
            [self.navigationController pushViewController:vc animated:YES];
        });
    }];
}

- (void)trackTapped:(UIButton *)button {
    NSInteger sectionIndex = button.tag / 1000;
    NSInteger index = (button.tag % 1000) - 500;
    if (sectionIndex < 0 || sectionIndex >= (NSInteger)self.sections.count) return;
    NSDictionary *section = self.sections[sectionIndex];
    NSArray *tracks = section[@"tracks"];
    if (index < 0 || index >= (NSInteger)tracks.count) return;

    [[FEPlayerManager sharedManager] playTracks:tracks startIndex:index];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        id root = self.tabBarController;
        if ([root respondsToSelector:@selector(showPlayer)]) [(id)root showPlayer];
    });
}

@end
