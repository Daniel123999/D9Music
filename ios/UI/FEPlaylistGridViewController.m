#import "FEPlaylistGridViewController.h"
#import "FETheme.h"
#import "FEImageView.h"
#import "FEIconView.h"
#import "FEProviderManager.h"
#import "FENeteaseProvider.h"
#import "FETrackListViewController.h"

@interface FEPlaylistGridViewController ()
@property (nonatomic, assign) FEPlaylistSource source;
@property (nonatomic, copy) NSString *pageTitle;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSArray<FEPlaylist *> *playlists;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UILabel *hintLabel;
@end

@implementation FEPlaylistGridViewController

- (instancetype)initWithSource:(FEPlaylistSource)source title:(NSString *)title {
    self = [super init];
    if (self) {
        _source = source;
        _pageTitle = [title copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.pageTitle ?: @"歌单";
    self.view.backgroundColor = [FETheme background];
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.contentInset = UIEdgeInsetsMake(12, 0, 80, 0);
    [self.view addSubview:self.scrollView];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = CGPointMake(self.view.bounds.size.width / 2, 120);
    [self.view addSubview:self.spinner];
    [self.spinner startAnimating];

    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.textColor = [FETheme textSecondary];
    self.hintLabel.font = [UIFont systemFontOfSize:12];
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    self.hintLabel.numberOfLines = 0;
    self.hintLabel.hidden = YES;
    [self.view addSubview:self.hintLabel];

    [self loadData];
}

- (FENeteaseProvider *)neteaseProvider {
    for (id<FEProviderProtocol> provider in [FEProviderManager sharedManager].providers) {
        if ([provider isKindOfClass:[FENeteaseProvider class]]) {
            return (FENeteaseProvider *)provider;
        }
    }
    return nil;
}

- (void)loadData {
    FENeteaseProvider *provider = [self neteaseProvider];
    if (provider == nil) {
        [self showHint:@"网易云音源未注册"];
        return;
    }

    __weak typeof(self) weakSelf = self;
    void (^handler)(NSArray<FEPlaylist *> *playlists) = ^(NSArray<FEPlaylist *> *playlists) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf.spinner stopAnimating];
        strongSelf.playlists = playlists ?: @[];
        if (strongSelf.playlists.count == 0) {
            [strongSelf showHint:strongSelf.source == FEPlaylistSourceUser ? @"登录网易云后可查看我的歌单" : @"加载失败，请检查网络后重试"];
            return;
        }
        [strongSelf reloadGrid];
    };

    if (self.source == FEPlaylistSourceSquare) {
        [provider getPlaylistSquareWithCompletion:^(NSArray<FEPlaylist *> *playlists, NSError *error) { handler(playlists); }];
    } else if (self.source == FEPlaylistSourceHighQuality) {
        [provider getHighQualityPlaylistsWithCompletion:^(NSArray<FEPlaylist *> *playlists, NSError *error) { handler(playlists); }];
    } else if (self.source == FEPlaylistSourceToplist) {
        [provider getToplistsWithCompletion:^(NSArray<FEPlaylist *> *playlists, NSError *error) { handler(playlists); }];
    } else if (self.source == FEPlaylistSourcePersonalized) {
        [provider getPersonalizedPlaylistsWithCompletion:^(NSArray<FEPlaylist *> *playlists, NSError *error) { handler(playlists); }];
    } else if (self.source == FEPlaylistSourceUser) {
        [provider getUserPlaylistsWithCompletion:^(NSArray<FEPlaylist *> *playlists, NSError *error) { handler(playlists); }];
    } else {
        [self.spinner stopAnimating];
    }
}

- (void)showHint:(NSString *)text {
    [self.spinner stopAnimating];
    self.hintLabel.text = text;
    self.hintLabel.hidden = NO;
    self.hintLabel.frame = CGRectMake(24, 100, self.view.bounds.size.width - 48, 60);
}

- (void)reloadGrid {
    for (UIView *view in [self.scrollView.subviews copy]) {
        [view removeFromSuperview];
    }

    CGFloat width = self.view.bounds.size.width;
    CGFloat side = (width - 24 - 12) / 2.0;
    CGFloat itemHeight = side + 56;
    CGFloat top = 8;

    for (NSInteger i = 0; i < (NSInteger)self.playlists.count; i++) {
        FEPlaylist *playlist = self.playlists[i];
        NSInteger column = i % 2;
        NSInteger row = i / 2;
        CGRect frame = CGRectMake(12 + column * (side + 12), top + row * (itemHeight + 12), side, itemHeight);

        UIView *card = [[UIView alloc] initWithFrame:frame];
        card.backgroundColor = [UIColor whiteColor];
        card.layer.cornerRadius = 16;
        card.layer.masksToBounds = YES;
        [self.scrollView addSubview:card];

        FECoverView *cover = [[FECoverView alloc] initWithFrame:CGRectMake(0, 0, side, side)];
        [cover setCornerRadius:0];
        [cover setImageURL:playlist.coverUrl];
        [card addSubview:cover];

        UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(10, side + 6, side - 20, 32)];
        name.text = playlist.name;
        name.font = [UIFont systemFontOfSize:12.5];
        name.textColor = [FETheme textPrimary];
        name.numberOfLines = 2;
        [card addSubview:name];

        UILabel *meta = [[UILabel alloc] initWithFrame:CGRectMake(10, side + 38, side - 20, 14)];
        if (playlist.playCount > 0) {
            meta.text = [NSString stringWithFormat:@"%ld 万次播放", (long)(playlist.playCount / 10000)];
        } else if (playlist.trackCount > 0) {
            meta.text = [NSString stringWithFormat:@"%ld 首", (long)playlist.trackCount];
        } else {
            meta.text = @"歌单";
        }
        meta.font = [UIFont systemFontOfSize:10];
        meta.textColor = [FETheme textSecondary];
        [card addSubview:meta];

        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = card.bounds;
        button.tag = 3000 + i;
        [button addTarget:self action:@selector(playlistTapped:) forControlEvents:UIControlEventTouchUpInside];
        [card addSubview:button];
    }

    NSInteger rows = (self.playlists.count + 1) / 2;
    self.scrollView.contentSize = CGSizeMake(width, top + rows * (itemHeight + 12) + 12);
}

- (void)playlistTapped:(UIButton *)button {
    NSInteger index = button.tag - 3000;
    if (index < 0 || index >= (NSInteger)self.playlists.count) return;
    FEPlaylist *playlist = self.playlists[index];

    FENeteaseProvider *provider = [self neteaseProvider];
    if (provider == nil) return;

    [FETheme showToast:@"正在加载歌单…" inView:self.view];
    [provider getPlaylistTracks:playlist completion:^(NSArray<FETrack *> *tracks, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (tracks.count == 0) {
                [FETheme showToast:@"这个歌单暂时取不到歌曲" inView:self.view];
                return;
            }
            FETrackListViewController *vc = [[FETrackListViewController alloc] initWithTitle:playlist.name tracks:tracks];
            vc.listSubtitle = [NSString stringWithFormat:@"%@ · %lu 首", provider.providerName, (unsigned long)tracks.count];
            [self.navigationController pushViewController:vc animated:YES];
        });
    }];
}

@end
