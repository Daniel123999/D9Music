#import "SearchViewController.h"
#import "FETheme.h"
#import "FEComponents.h"
#import "FEIconView.h"
#import "FEImageView.h"
#import "FEProviderManager.h"
#import "FETrack.h"
#import "FEPlaylist.h"
#import "FEPlayerManager.h"
#import "FETrackListViewController.h"
#import "FERootTabBarController.h"

static NSArray<NSString *> *FESearchTokens(NSString *keyword) {
    if (keyword.length == 0) return @[];
    static NSCharacterSet *separators = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        separators = [NSCharacterSet characterSetWithCharactersInString:@" \t\r\n-—_/|·,，.。:：()（）[]【】"];
    });
    NSArray *parts = [[keyword lowercaseString] componentsSeparatedByCharactersInSet:separators];
    NSMutableArray<NSString *> *tokens = [NSMutableArray array];
    for (NSString *part in parts) {
        if (part.length > 0) [tokens addObject:part];
    }
    return tokens;
}

static NSInteger FESearchTextScore(NSString *text, NSString *key) {
    if (text.length == 0 || key.length == 0) return 0;
    NSString *lower = [text lowercaseString];
    if ([lower isEqualToString:key]) return 120;
    if ([lower hasPrefix:key]) return 90;
    if ([lower rangeOfString:key].location != NSNotFound) return 60;
    return 0;
}

/// 翻唱/伴奏/改编等标记：用于把“非原唱版本”往后排
static BOOL FESearchIsCoverText(NSString *text) {
    if (text.length == 0) return NO;
    NSString *lower = [text lowercaseString];
    NSArray<NSString *> *markers = @[@"翻唱", @"翻自", @"原唱", @"伴奏", @"改编",
                                     @"纯音乐", @"钢琴版", @"吉他版", @"dj版", @"抖音",
                                     @"女声版", @"男声版", @"童声版", @"现场版", @"演唱会"];
    for (NSString *marker in markers) {
        if ([lower rangeOfString:marker].location != NSNotFound) return YES;
    }
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken2;
    dispatch_once(&onceToken2, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"\\b(cover|karaoke|instrumental|remix|mashup)\\b"
                                                          options:0
                                                            error:nil];
    });
    return [regex firstMatchInString:lower options:0 range:NSMakeRange(0, lower.length)] != nil;
}

static NSInteger FESearchTrackScore(FETrack *track, NSArray<NSString *> *tokens, BOOL wantsCover, NSInteger rank) {
    NSString *title = track.title ?: @"";
    NSString *artist = track.artist ?: @"";

    NSInteger titleScore = 0;
    NSInteger artistScore = 0;
    for (NSString *token in tokens) {
        titleScore = MAX(titleScore, FESearchTextScore(title, token));
        artistScore = MAX(artistScore, FESearchTextScore(artist, token));
    }

    NSInteger score = titleScore;
    // 歌手命中（尤其是搜索词里带歌手名）说明更可能是原唱版本
    if (artistScore > 0) score += 20 + artistScore / 2;

    // 同一音源内越靠前越可信：原唱通常排在翻唱前面
    score += MAX(0, 20 - rank);

    if (!wantsCover && titleScore > 0 && (FESearchIsCoverText(title) || FESearchIsCoverText(artist))) {
        score -= 45;
    }
    return score;
}

static NSString *FESearchTrackKey(FETrack *track) {
    return [NSString stringWithFormat:@"%@|%@",
            track.providerId ?: @"", track.trackId.length > 0 ? track.trackId : (track.title ?: @"")];
}

static NSInteger FESearchNameScore(NSString *name, NSArray<NSString *> *tokens) {
    NSInteger score = 0;
    for (NSString *token in tokens) {
        score = MAX(score, FESearchTextScore(name, token));
    }
    return score;
}

@interface FESearchEntityCell : UITableViewCell
@property (nonatomic, strong) FECoverView *coverView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *metaLabel;
@property (nonatomic, strong) FEIconView *chevron;
@property (nonatomic, assign) BOOL roundCover;
- (void)configureWithTitle:(NSString *)title meta:(NSString *)meta cover:(NSString *)cover round:(BOOL)round;
@end

@implementation FESearchEntityCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [FETheme card];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _coverView = [[FECoverView alloc] initWithFrame:CGRectZero];
        [_coverView setCornerRadius:12];
        [self.contentView addSubview:_coverView];

        _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _nameLabel.font = [UIFont systemFontOfSize:14];
        _nameLabel.textColor = [FETheme textPrimary];
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_nameLabel];

        _metaLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _metaLabel.font = [UIFont systemFontOfSize:10.5];
        _metaLabel.textColor = [FETheme textSecondary];
        _metaLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_metaLabel];

        _chevron = [[FEIconView alloc] initWithFrame:CGRectZero iconType:FEIconTypeNext];
        _chevron.tintColor = [FETheme textSecondary];
        _chevron.userInteractionEnabled = NO;
        [self.contentView addSubview:_chevron];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    CGFloat side = height - 14;
    self.coverView.frame = CGRectMake(16, 7, side, side);
    [self.coverView setCornerRadius:self.roundCover ? side / 2 : 12];
    self.nameLabel.frame = CGRectMake(16 + side + 12, height / 2 - 19, width - (16 + side + 12) - 40, 19);
    self.metaLabel.frame = CGRectMake(16 + side + 12, height / 2 + 2, width - (16 + side + 12) - 40, 15);
    self.chevron.frame = CGRectMake(width - 30, (height - 14) / 2, 14, 14);
}

- (void)configureWithTitle:(NSString *)title meta:(NSString *)meta cover:(NSString *)cover round:(BOOL)round {
    self.nameLabel.text = title;
    self.metaLabel.text = meta;
    self.roundCover = round;
    [self.coverView setCornerRadius:round ? (self.coverView.bounds.size.height / 2) : 12];
    [self.coverView setImageURL:cover];
    [self setNeedsLayout];
}

@end

@interface SearchViewController ()

@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) UIButton *searchButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *retryButton;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, copy) NSString *keyword;

@property (nonatomic, strong) NSMutableArray<FETrack *> *songs;
/// trackKey -> 该歌曲在其音源原始结果里的位置，用于“原唱优先”排序
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *songRanks;
@property (nonatomic, strong) NSMutableArray<FEPlaylist *> *playlists;
@property (nonatomic, strong) NSMutableArray<FEPlaylist *> *albums;
@property (nonatomic, strong) NSMutableArray<FEPlaylist *> *artists;

@property (nonatomic, assign) BOOL searching;
@property (nonatomic, assign) NSInteger pendingRequests;
@property (nonatomic, assign) NSInteger totalRequests;

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"搜索";
    self.view.backgroundColor = [FETheme background];
    self.songs = [NSMutableArray array];
    self.songRanks = [NSMutableDictionary dictionary];
    self.playlists = [NSMutableArray array];
    self.albums = [NSMutableArray array];
    self.artists = [NSMutableArray array];
    self.automaticallyAdjustsScrollViewInsets = NO;

    [self buildSearchBar];

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 58, self.view.bounds.size.width - 100, 18)];
    self.statusLabel.text = @"歌曲 / 歌单 / 专辑 / 歌手，一次搜索所有已启用音源";
    self.statusLabel.textColor = [FETheme textSecondary];
    self.statusLabel.font = [UIFont systemFontOfSize:10.5];
    [self.view addSubview:self.statusLabel];

    self.retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.retryButton.frame = CGRectMake(self.view.bounds.size.width - 78, 54, 62, 24);
    self.retryButton.backgroundColor = [FETheme primary];
    self.retryButton.layer.cornerRadius = 12;
    self.retryButton.titleLabel.font = [UIFont boldSystemFontOfSize:10];
    [self.retryButton setTitle:@"重新搜索" forState:UIControlStateNormal];
    [self.retryButton addTarget:self action:@selector(doSearch) forControlEvents:UIControlEventTouchUpInside];
    self.retryButton.hidden = YES;
    [self.view addSubview:self.retryButton];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 82, self.view.bounds.size.width, self.view.bounds.size.height - 82) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 64;
    self.tableView.estimatedRowHeight = 0;
    self.tableView.contentInset = UIEdgeInsetsMake(2, 0, 100, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.backgroundColor = [FETheme background];
    self.tableView.separatorColor = [FETheme separator];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 74, 0, 16);
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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
    // 搜索条避免使用阴影，4S 上调起键盘会明显掉帧
    UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(12, 12, width - 24, 44)];
    bar.backgroundColor = [FETheme card];
    bar.layer.cornerRadius = 22;
    bar.layer.masksToBounds = YES;
    [self.view addSubview:bar];

    FEIconView *icon = [[FEIconView alloc] initWithFrame:CGRectMake(14, 14, 16, 16) iconType:FEIconTypeSearch];
    icon.tintColor = [FETheme textSecondary];
    icon.lineWidth = 2.0;
    [bar addSubview:icon];

    self.searchField = [[UITextField alloc] initWithFrame:CGRectMake(38, 6, width - 24 - 38 - 66, 32)];
    self.searchField.borderStyle = UITextBorderStyleNone;
    self.searchField.font = [UIFont systemFontOfSize:13.5];
    self.searchField.textColor = [FETheme textPrimary];
    self.searchField.placeholder = @"歌曲 / 歌单 / 专辑 / 歌手";
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

#pragma mark - Search

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
    self.keyword = keyword;
    self.retryButton.hidden = YES;
    [self.songs removeAllObjects];
    [self.songRanks removeAllObjects];
    [self.playlists removeAllObjects];
    [self.albums removeAllObjects];
    [self.artists removeAllObjects];
    [self.tableView reloadData];
    [self.spinner startAnimating];

    NSInteger total = 0;
    for (id<FEProviderProtocol> provider in providers) {
        total += 1;
        if ([provider respondsToSelector:@selector(searchPlaylistsWithKeyword:completion:)]) total += 1;
        if ([provider respondsToSelector:@selector(searchAlbumsWithKeyword:completion:)]) total += 1;
        if ([provider respondsToSelector:@selector(searchArtistsWithKeyword:completion:)]) total += 1;
    }
    self.pendingRequests = total;
    self.totalRequests = total;
    self.statusLabel.text = [NSString stringWithFormat:@"正在 %ld 个音源搜索「%@」…", (long)providers.count, keyword];

    // 网络挂起时避免一直转圈
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(25.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.searching) return;
        strongSelf.pendingRequests = 0;
        [strongSelf finishOneRequest];
    });
    for (id<FEProviderProtocol> provider in providers) {
        [provider searchWithKeyword:keyword completion:^(NSArray<FETrack *> *tracks, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                NSArray<FETrack *> *list = tracks ?: @[];
                for (NSInteger i = 0; i < (NSInteger)list.count; i++) {
                    FETrack *track = list[i];
                    NSString *key = FESearchTrackKey(track);
                    if (strongSelf.songRanks[key] == nil) strongSelf.songRanks[key] = @(i);
                }
                [strongSelf.songs addObjectsFromArray:list];
                [strongSelf finishOneRequest];
            });
        }];
        if ([provider respondsToSelector:@selector(searchPlaylistsWithKeyword:completion:)]) {
            [provider searchPlaylistsWithKeyword:keyword completion:^(NSArray<FEPlaylist *> *items, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (!strongSelf) return;
                    [strongSelf.playlists addObjectsFromArray:items ?: @[]];
                    [strongSelf finishOneRequest];
                });
            }];
        }
        if ([provider respondsToSelector:@selector(searchAlbumsWithKeyword:completion:)]) {
            [provider searchAlbumsWithKeyword:keyword completion:^(NSArray<FEPlaylist *> *items, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (!strongSelf) return;
                    [strongSelf.albums addObjectsFromArray:items ?: @[]];
                    [strongSelf finishOneRequest];
                });
            }];
        }
        if ([provider respondsToSelector:@selector(searchArtistsWithKeyword:completion:)]) {
            [provider searchArtistsWithKeyword:keyword completion:^(NSArray<FEPlaylist *> *items, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (!strongSelf) return;
                    [strongSelf.artists addObjectsFromArray:items ?: @[]];
                    [strongSelf finishOneRequest];
                });
            }];
        }
    }
}

- (void)finishOneRequest {
    if (self.pendingRequests > 0) self.pendingRequests -= 1;
    if (self.pendingRequests > 0) return;

    self.searching = NO;
    [self.spinner stopAnimating];
    [self sortResults];
    [self.tableView reloadData];

    NSInteger total = self.songs.count + self.playlists.count + self.albums.count + self.artists.count;
    if (total > 0) {
        self.statusLabel.text = [NSString stringWithFormat:@"歌曲 %ld · 歌单 %ld · 专辑 %ld · 歌手 %ld",
                                 (long)self.songs.count, (long)self.playlists.count,
                                 (long)self.albums.count, (long)self.artists.count];
        self.retryButton.hidden = YES;
    } else {
        self.statusLabel.text = @"所有已启用音源都没有找到结果";
        self.retryButton.hidden = NO;
    }
}

- (void)sortResults {
    NSString *keyword = self.keyword ?: @"";
    NSArray<NSString *> *tokens = FESearchTokens(keyword);
    BOOL wantsCover = FESearchIsCoverText(keyword);
    NSDictionary<NSString *, NSNumber *> *ranks = self.songRanks;

    [self.songs sortUsingComparator:^NSComparisonResult(FETrack *a, FETrack *b) {
        NSInteger rankA = [ranks[FESearchTrackKey(a)] integerValue];
        NSInteger rankB = [ranks[FESearchTrackKey(b)] integerValue];
        NSInteger sa = FESearchTrackScore(a, tokens, wantsCover, rankA);
        NSInteger sb = FESearchTrackScore(b, tokens, wantsCover, rankB);
        if (sa != sb) return sa > sb ? NSOrderedAscending : NSOrderedDescending;
        NSComparisonResult titleResult = [(a.title ?: @"") localizedCaseInsensitiveCompare:(b.title ?: @"")];
        if (titleResult != NSOrderedSame) return titleResult;
        return [(a.artist ?: @"") localizedCaseInsensitiveCompare:(b.artist ?: @"")];
    }];

    [self.playlists sortUsingComparator:^NSComparisonResult(FEPlaylist *a, FEPlaylist *b) {
        NSInteger sa = FESearchNameScore(a.name, tokens);
        NSInteger sb = FESearchNameScore(b.name, tokens);
        if (sa != sb) return sa > sb ? NSOrderedAscending : NSOrderedDescending;
        return [(a.name ?: @"") localizedCaseInsensitiveCompare:(b.name ?: @"")];
    }];
    [self.albums sortUsingComparator:^NSComparisonResult(FEPlaylist *a, FEPlaylist *b) {
        NSInteger sa = FESearchNameScore(a.name, tokens);
        NSInteger sb = FESearchNameScore(b.name, tokens);
        if (sa != sb) return sa > sb ? NSOrderedAscending : NSOrderedDescending;
        return [(a.name ?: @"") localizedCaseInsensitiveCompare:(b.name ?: @"")];
    }];
    [self.artists sortUsingComparator:^NSComparisonResult(FEPlaylist *a, FEPlaylist *b) {
        NSInteger sa = FESearchNameScore(a.name, tokens);
        NSInteger sb = FESearchNameScore(b.name, tokens);
        if (sa != sb) return sa > sb ? NSOrderedAscending : NSOrderedDescending;
        return [(a.name ?: @"") localizedCaseInsensitiveCompare:(b.name ?: @"")];
    }];
}

- (NSArray *)searchProviders {
    FEProviderManager *manager = [FEProviderManager sharedManager];
    NSArray *enabled = [manager enabledProviders];
    if (enabled.count > 0) return enabled;
    if (manager.currentProvider) return @[manager.currentProvider];
    return manager.providers;
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0 && self.songs.count > 0) return [NSString stringWithFormat:@"歌曲 · %lu", (unsigned long)self.songs.count];
    if (section == 1 && self.playlists.count > 0) return [NSString stringWithFormat:@"歌单 · %lu", (unsigned long)self.playlists.count];
    if (section == 2 && self.albums.count > 0) return [NSString stringWithFormat:@"专辑 · %lu", (unsigned long)self.albums.count];
    if (section == 3 && self.artists.count > 0) return [NSString stringWithFormat:@"歌手 · %lu", (unsigned long)self.artists.count];
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return self.songs.count;
    if (section == 1) return self.playlists.count;
    if (section == 2) return self.albums.count;
    if (section == 3) return self.artists.count;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *CellId = @"FESearchTrackCell";
        FETrackCell *cell = (FETrackCell *)[tableView dequeueReusableCellWithIdentifier:CellId];
        if (cell == nil) {
            cell = [[FETrackCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId];
        }
        if (indexPath.row < (NSInteger)self.songs.count) {
            [cell configureWithTrack:self.songs[indexPath.row]];
        }
        return cell;
    }

    static NSString *EntityId = @"FESearchEntityCell";
    FESearchEntityCell *cell = (FESearchEntityCell *)[tableView dequeueReusableCellWithIdentifier:EntityId];
    if (cell == nil) {
        cell = [[FESearchEntityCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:EntityId];
    }

    if (indexPath.section == 1 && indexPath.row < (NSInteger)self.playlists.count) {
        FEPlaylist *item = self.playlists[indexPath.row];
        [cell configureWithTitle:item.name meta:[NSString stringWithFormat:@"歌单 · %@", [self providerNameForId:item.providerId]] cover:item.coverUrl round:NO];
    } else if (indexPath.section == 2 && indexPath.row < (NSInteger)self.albums.count) {
        FEPlaylist *item = self.albums[indexPath.row];
        [cell configureWithTitle:item.name meta:[NSString stringWithFormat:@"专辑 · %@", [self providerNameForId:item.providerId]] cover:item.coverUrl round:NO];
    } else if (indexPath.section == 3 && indexPath.row < (NSInteger)self.artists.count) {
        FEPlaylist *item = self.artists[indexPath.row];
        [cell configureWithTitle:item.name meta:[NSString stringWithFormat:@"歌手 · %@", [self providerNameForId:item.providerId]] cover:item.coverUrl round:YES];
    }
    return cell;
}

- (NSString *)providerNameForId:(NSString *)providerId {
    id<FEProviderProtocol> provider = [[FEProviderManager sharedManager] providerWithId:providerId];
    return provider.providerName ?: @"音源";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0) {
        if (indexPath.row >= (NSInteger)self.songs.count) return;
        [[FEPlayerManager sharedManager] playTracks:self.songs startIndex:indexPath.row];
        [tableView reloadData];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            id root = self.tabBarController;
            if ([root respondsToSelector:@selector(showPlayer)]) [(id)root showPlayer];
        });
        return;
    }

    FEPlaylist *item = nil;
    if (indexPath.section == 1 && indexPath.row < (NSInteger)self.playlists.count) item = self.playlists[indexPath.row];
    if (indexPath.section == 2 && indexPath.row < (NSInteger)self.albums.count) item = self.albums[indexPath.row];
    if (indexPath.section == 3 && indexPath.row < (NSInteger)self.artists.count) item = self.artists[indexPath.row];
    if (item == nil) return;

    id<FEProviderProtocol> provider = [[FEProviderManager sharedManager] providerWithId:item.providerId];
    if (provider == nil) {
        [FETheme showToast:@"对应音源未注册" inView:self.view];
        return;
    }

    [FETheme showToast:@"正在加载…" inView:self.view];
    __weak typeof(self) weakSelf = self;
    BOOL isArtist = indexPath.section == 3;
    if (isArtist) {
        if (![provider respondsToSelector:@selector(getArtistTracks:completion:)]) {
            [FETheme showToast:@"该音源暂不支持歌手详情" inView:self.view];
            return;
        }
        [(id<FEProviderProtocol>)provider getArtistTracks:item completion:^(NSArray<FETrack *> *tracks, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf showTracks:tracks title:item.name provider:provider]; });
        }];
    } else {
        [provider getPlaylistTracks:item completion:^(NSArray<FETrack *> *tracks, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf showTracks:tracks title:item.name provider:provider]; });
        }];
    }
}

- (void)showTracks:(NSArray<FETrack *> *)tracks title:(NSString *)title provider:(id<FEProviderProtocol>)provider {
    if (tracks.count == 0) {
        [FETheme showToast:@"暂时取不到内容" inView:self.view];
        return;
    }
    FETrackListViewController *vc = [[FETrackListViewController alloc] initWithTitle:title tracks:tracks];
    vc.listSubtitle = [NSString stringWithFormat:@"%@ · %lu 首", provider.providerName, (unsigned long)tracks.count];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.searchField resignFirstResponder];
}

@end
