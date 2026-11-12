#import "FEMineViewController.h"
#import "FETheme.h"
#import "FEComponents.h"
#import "FEIconView.h"
#import "FEImageView.h"
#import "FEProviderManager.h"
#import "FELocalMusicViewController.h"
#import "FEPlaylistListViewController.h"
#import "FESourceListViewController.h"
#import "FEPlayerManager.h"
#import "FERootTabBarController.h"
#import "FESettingsViewController.h"
#import "FECurrentPlaylistViewController.h"
#import "FECloudViewController.h"
#import "FEFavoriteManager.h"
#import "FETrackListViewController.h"
#import "FEPlaylistManager.h"
#import "FEPlaylist.h"
#import "FESettings.h"
#import "FEWebDAVManager.h"

@interface FEMineViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) FEIconView *avatarPlaceholder;
@property (nonatomic, strong) UILabel *profileNameLabel;
@property (nonatomic, strong) UILabel *profileStatusLabel;
@property (nonatomic, strong) UIView *providersCard;
@property (nonatomic, strong) UILabel *statsLabel;
@property (nonatomic, copy) NSString *resolvedAvatarProviderId;
@property (nonatomic, strong) NSDate *lastProfileFetchDate;

@end

@implementation FEMineViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [FETheme background];
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.contentInset = UIEdgeInsetsMake(24, 0, 100, 0);
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];

    [self buildContent];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidChange:) name:FEAccountDidChangeNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self refreshAccount];
    [self refreshAvatarIfNeeded:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)buildContent {
    CGFloat width = self.view.bounds.size.width;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 4, width - 32, 34)];
    title.text = @"我的";
    title.textColor = [FETheme textPrimary];
    title.font = [UIFont boldSystemFontOfSize:27];
    [self.scrollView addSubview:title];

    UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 38, width - 32, 18)];
    subtitle.text = @"账号、收藏与本地内容";
    subtitle.textColor = [FETheme textSecondary];
    subtitle.font = [UIFont systemFontOfSize:11.5];
    [self.scrollView addSubview:subtitle];

    // 个人信息卡
    FEGradientView *profile = [[FEGradientView alloc] initWithFrame:CGRectMake(12, 70, width - 24, 110)];
    profile.layer.cornerRadius = 22;
    profile.layer.masksToBounds = YES;
    profile.colors = @[(id)[FETheme primaryDark].CGColor, (id)[FETheme primary].CGColor, (id)[FETheme secondary].CGColor];
    [self.scrollView addSubview:profile];

    UIView *avatar = [[UIView alloc] initWithFrame:CGRectMake(18, 28, 54, 54)];
    avatar.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.22];
    avatar.layer.cornerRadius = 27;
    avatar.clipsToBounds = YES;
    [profile addSubview:avatar];

    self.avatarView = [[UIImageView alloc] initWithFrame:avatar.bounds];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.layer.cornerRadius = 27;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.hidden = YES;
    [avatar addSubview:self.avatarView];

    self.avatarPlaceholder = [[FEIconView alloc] initWithFrame:CGRectMake(14, 14, 26, 26) iconType:FEIconTypeUser];
    self.avatarPlaceholder.tintColor = [UIColor whiteColor];
    [avatar addSubview:self.avatarPlaceholder];

    UIButton *avatarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    avatarButton.frame = avatar.bounds;
    [avatarButton addTarget:self action:@selector(avatarTapped) forControlEvents:UIControlEventTouchUpInside];
    [avatar addSubview:avatarButton];

    self.profileNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(84, 26, width - 24 - 120, 24)];
    self.profileNameLabel.text = @"本地用户";
    self.profileNameLabel.textColor = [UIColor whiteColor];
    self.profileNameLabel.font = [UIFont boldSystemFontOfSize:18];
    [profile addSubview:self.profileNameLabel];

    self.profileStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(84, 50, width - 24 - 120, 18)];
    self.profileStatusLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.82];
    self.profileStatusLabel.font = [UIFont systemFontOfSize:11];
    [profile addSubview:self.profileStatusLabel];

    UIButton *accountButton = [UIButton buttonWithType:UIButtonTypeCustom];
    accountButton.frame = CGRectMake(84, 70, 120, 26);
    accountButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.24];
    accountButton.layer.cornerRadius = 13;
    accountButton.titleLabel.font = [UIFont boldSystemFontOfSize:11];
    [accountButton setTitle:@"音源与登录  ›" forState:UIControlStateNormal];
    [accountButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [accountButton addTarget:self action:@selector(openSourceList) forControlEvents:UIControlEventTouchUpInside];
    [profile addSubview:accountButton];

    FEIconView *decor = [[FEIconView alloc] initWithFrame:CGRectMake(width - 24 - 66, 14, 62, 62) iconType:FEIconTypeNote];
    decor.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.14];
    decor.lineWidth = 1.4;
    decor.userInteractionEnabled = NO;
    [profile addSubview:decor];

    // 我的内容
    [self addSectionTitle:@"我的内容" y:194];

    NSArray *tiles = @[
        @[@"本地音乐", @(FEIconTypeHeadphones), [FETheme secondary]],
        @[@"我的歌单", @(FEIconTypePlaylist), [FETheme accent]],
        @[@"收藏歌曲", @(FEIconTypeHeart), [FETheme secondary]],
        @[@"云盘歌曲", @(FEIconTypeCloud), [FETheme primary]],
        @[@"当前播放", @(FEIconTypeDisc), [FETheme warning]],
        @[@"设置", @(FEIconTypeSettings), [FETheme primaryDark]]
    ];
    CGFloat gap = 10;
    CGFloat tileWidth = (width - 24 - gap * 2) / 3.0;
    for (NSInteger i = 0; i < (NSInteger)tiles.count; i++) {
        NSInteger column = i % 3;
        NSInteger row = i / 3;
        CGRect frame = CGRectMake(12 + column * (tileWidth + gap), 224 + row * 98, tileWidth, 88);
        NSArray *info = tiles[i];
        FECardButton *tile = [[FECardButton alloc] initWithFrame:frame
                                                           icon:(FEIconType)[info[1] integerValue]
                                                          title:info[0]
                                                       subtitle:nil
                                                         accent:info[2]
                                                          style:FECardStyleTile];
        tile.tag = 300 + i;
        [tile addTarget:self action:@selector(tileTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:tile];
    }

    // 音源
    [self addSectionTitle:@"音源" y:430];
    self.providersCard = [[UIView alloc] initWithFrame:CGRectMake(12, 460, width - 24, 1)];
    self.providersCard.backgroundColor = [FETheme card];
    self.providersCard.layer.cornerRadius = 18;
    self.providersCard.layer.masksToBounds = YES;
    [self.scrollView addSubview:self.providersCard];

    self.statsLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 640, width - 24, 40)];
    self.statsLabel.text = @"D9Music · Objective-C / Theos / iOS 9";
    self.statsLabel.textColor = [FETheme textSecondary];
    self.statsLabel.font = [UIFont systemFontOfSize:10.5];
    self.statsLabel.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:self.statsLabel];

    self.scrollView.contentSize = CGSizeMake(width, 700);
}

- (void)addSectionTitle:(NSString *)text y:(CGFloat)y {
    FESectionHeaderView *header = [[FESectionHeaderView alloc] initWithFrame:CGRectMake(12, y, self.view.bounds.size.width - 24, 26)
                                                                      title:text
                                                                actionTitle:nil];
    [self.scrollView addSubview:header];
}

#pragma mark - Account / Avatar

- (id<FEProviderProtocol>)avatarProvider {
    FEProviderManager *manager = [FEProviderManager sharedManager];
    NSString *lastId = [FESettings sharedSettings].lastLoginProviderId;
    id<FEProviderProtocol> last = [manager providerWithId:lastId];
    if (last.isLoggedIn) return last;

    // 没有记录时退回到第一个已登录的音源
    for (id<FEProviderProtocol> provider in [manager orderedProviders]) {
        if (provider.isLoggedIn) return provider;
    }
    return nil;
}

- (NSString *)avatarCacheKey {
    return [NSString stringWithFormat:@"d9.account.avatar.%@", self.resolvedAvatarProviderId ?: @""];
}

- (void)refreshAvatarIfNeeded:(BOOL)force {
    if ([FESettings sharedSettings].useCustomAvatar) {
        UIImage *image = [[FESettings sharedSettings] customAvatarImage];
        if (image) {
            self.avatarView.image = image;
            self.avatarView.hidden = NO;
            self.avatarPlaceholder.hidden = YES;
        }
        self.resolvedAvatarProviderId = nil;
        return;
    }

    id<FEProviderProtocol> provider = [self avatarProvider];
    if (provider == nil) {
        self.avatarView.hidden = YES;
        self.avatarPlaceholder.hidden = NO;
        self.resolvedAvatarProviderId = nil;
        return;
    }

    BOOL providerChanged = ![self.resolvedAvatarProviderId isEqualToString:provider.providerId];
    BOOL stale = self.lastProfileFetchDate == nil || [[NSDate date] timeIntervalSinceDate:self.lastProfileFetchDate] > 300;
    if (!force && !providerChanged && !stale) return;

    self.resolvedAvatarProviderId = provider.providerId;
    self.lastProfileFetchDate = [NSDate date];

    // 先用缓存显示，避免头像闪烁
    NSString *cached = [[NSUserDefaults standardUserDefaults] stringForKey:[self avatarCacheKey]];
    if (cached.length > 0) {
        [self setAvatarImageWithURL:cached];
    }

    if (![provider respondsToSelector:@selector(getUserProfileWithCompletion:)]) return;
    __weak typeof(self) weakSelf = self;
    [provider getUserProfileWithCompletion:^(NSString *nickname, NSString *avatarURL, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            if (nickname.length > 0) {
                strongSelf.profileNameLabel.text = nickname;
            }
            if (avatarURL.length > 0) {
                [[NSUserDefaults standardUserDefaults] setObject:avatarURL forKey:[strongSelf avatarCacheKey]];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [strongSelf setAvatarImageWithURL:avatarURL];
            }
        });
    }];
}

- (void)setAvatarImageWithURL:(NSString *)urlString {
    __weak typeof(self) weakSelf = self;
    [FEImageLoader loadImageWithURLString:urlString completion:^(UIImage *image, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || image == nil) return;
        strongSelf.avatarView.image = image;
        strongSelf.avatarView.hidden = NO;
        strongSelf.avatarPlaceholder.hidden = YES;
    }];
}

- (void)avatarTapped {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"头像"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [sheet addAction:[UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf pickCustomAvatar];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"使用音源头像" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [[FESettings sharedSettings] clearCustomAvatar];
        [strongSelf refreshAvatarIfNeeded:YES];
        [FETheme showToast:@"已切换为音源头像" inView:strongSelf.view];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)pickCustomAvatar {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [FETheme showToast:@"当前设备无法访问相册" inView:self.view];
        return;
    }
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.allowsEditing = YES;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        if (image == nil) return;
        [[FESettings sharedSettings] setCustomAvatarImage:image];
        [self refreshAvatarIfNeeded:YES];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)accountDidChange:(NSNotification *)notification {
    [self refreshAccount];
    [self refreshAvatarIfNeeded:YES];
}

#pragma mark - Refresh

- (void)refreshAccount {
    FEProviderManager *manager = [FEProviderManager sharedManager];
    id<FEProviderProtocol> provider = manager.currentProvider;
    NSInteger enabledCount = (NSInteger)[manager enabledProviders].count;
    self.profileStatusLabel.text = [NSString stringWithFormat:@"当前音源：%@ · 已启用 %ld 个",
                                    provider.providerName ?: @"未选择", (long)enabledCount];

    for (UIView *view in [self.providersCard.subviews copy]) {
        [view removeFromSuperview];
    }

    CGFloat width = self.providersCard.bounds.size.width;
    NSArray *providers = [manager orderedProviders];
    CGFloat rowHeight = 64;
    for (NSInteger i = 0; i < (NSInteger)providers.count; i++) {
        id<FEProviderProtocol> item = providers[i];
        FEIconType iconType = FEIconTypeNote;
        if ([item.providerId isEqualToString:@"bilibili"]) iconType = FEIconTypeTV;
        if ([item.providerId isEqualToString:@"qq"]) iconType = FEIconTypeHeadphones;

        BOOL enabled = [manager isProviderEnabled:item];
        BOOL isCurrent = (item == provider);

        UIView *badge = [[UIView alloc] initWithFrame:CGRectMake(12, i * rowHeight + 14, 36, 36)];
        badge.backgroundColor = [(enabled ? [FETheme primary] : [FETheme textSecondary]) colorWithAlphaComponent:0.10];
        badge.layer.cornerRadius = 12;
        [self.providersCard addSubview:badge];

        FEIconView *icon = [[FEIconView alloc] initWithFrame:CGRectMake(8, 8, 20, 20) iconType:iconType];
        icon.tintColor = enabled ? [FETheme primary] : [FETheme textSecondary];
        [badge addSubview:icon];

        UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(60, i * rowHeight + 13, width - 120, 20)];
        name.text = item.providerName;
        name.font = [UIFont systemFontOfSize:14];
        name.textColor = [FETheme textPrimary];
        [self.providersCard addSubview:name];

        UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(60, i * rowHeight + 33, width - 120, 16)];
        status.text = [NSString stringWithFormat:@"%@%@",
                       item.isLoggedIn ? @"已登录" : @"未登录",
                       isCurrent ? @" · 首选" : (enabled ? @" · 使用中" : @"")];
        status.font = [UIFont systemFontOfSize:10.5];
        status.textColor = enabled ? [FETheme accent] : [FETheme textSecondary];
        [self.providersCard addSubview:status];

        if (i < (NSInteger)providers.count - 1) {
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(60, (i + 1) * rowHeight - 0.5, width - 72, 0.5)];
            line.backgroundColor = [FETheme separator];
            [self.providersCard addSubview:line];
        }

        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, i * rowHeight, width, rowHeight);
        [button addTarget:self action:@selector(openSourceList) forControlEvents:UIControlEventTouchUpInside];
        [self.providersCard addSubview:button];
    }

    self.providersCard.frame = CGRectMake(12, 460, width, MAX(1, providers.count) * rowHeight);
    CGFloat bottom = 460 + MAX(1, providers.count) * rowHeight + 20;
    self.statsLabel.frame = CGRectMake(12, bottom, width, 40);
    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, bottom + 100);
}

#pragma mark - Tiles

- (void)tileTapped:(FECardButton *)tile {
    NSInteger index = tile.tag - 300;
    switch (index) {
        case 0:
            [self.navigationController pushViewController:[[FELocalMusicViewController alloc] init] animated:YES];
            break;
        case 1:
            [self.navigationController pushViewController:[[FEPlaylistListViewController alloc] init] animated:YES];
            break;
        case 2: {
            // 跳转到我喜欢歌单
            FEPlaylistManager *pm = [FEPlaylistManager sharedManager];
            FEPlaylist *favPlaylist = nil;
            for (FEPlaylist *p in pm.localPlaylists) {
                if ([p.name isEqualToString:@"我喜欢"]) {
                    favPlaylist = p;
                    break;
                }
            }
            if (favPlaylist == nil) {
                [pm createPlaylistWithName:@"我喜欢"];
                favPlaylist = pm.localPlaylists.lastObject;
            }
            if (favPlaylist.tracks.count == 0) {
                [FETheme showToast:@"收藏夹为空，去播放页收藏歌曲吧" inView:self.view];
                return;
            }
            FETrackListViewController *vc = [[FETrackListViewController alloc] initWithTitle:@"我喜欢" tracks:favPlaylist.tracks];
            vc.listSubtitle = @"本地收藏";
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 3: {
            if (![FEWebDAVManager sharedManager].isEnabled) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"云盘歌曲"
                                                                message:@"请先在设置中启用 WebDAV，云盘会读取远程路径下的歌曲目录。"
                                                               delegate:self
                                                      cancelButtonTitle:@"取消"
                                                      otherButtonTitles:@"去设置", nil];
                alert.tag = 9002;
                [alert show];
                return;
            }
            FECloudViewController *vc = [[FECloudViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 4: {
            FECurrentPlaylistViewController *vc = [[FECurrentPlaylistViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 5: {
            FESettingsViewController *vc = [[FESettingsViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        default:
            break;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 9002 && buttonIndex == 1) {
        UIViewController *top = self;
        while (top.presentingViewController) top = top.presentingViewController;
        UITabBarController *tab = [top isKindOfClass:[UITabBarController class]] ? (UITabBarController *)top : nil;
        if (tab) tab.selectedIndex = 2;
        UINavigationController *nav = (UINavigationController *)tab.selectedViewController;
        [nav pushViewController:[[FESettingsViewController alloc] init] animated:YES];
    }
}

- (void)openSourceList {
    FESourceListViewController *vc = [[FESourceListViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
