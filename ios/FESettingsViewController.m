#import "FESettingsViewController.h"
#import "FETheme.h"
#import "FEIconView.h"
#import "FEWebDAVManager.h"
#import "FEPlaylistManager.h"
#import "FEFavoriteManager.h"
#import "FECacheManager.h"
#import "FESettings.h"
#import "FESourceListViewController.h"
#import "FECloudViewController.h"
#import "FEUpdateUI.h"
#import "FEAppUpdater.h"

typedef NS_ENUM(NSInteger, FESettingsSection) {
    FESettingsSectionAppearance = 0,
    FESettingsSectionPlayback,
    FESettingsSectionSources,
    FESettingsSectionWebDAV,
    FESettingsSectionUpdate,
    FESettingsSectionAbout
};

@interface FESettingsViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *serverField;
@property (nonatomic, strong) UITextField *userField;
@property (nonatomic, strong) UITextField *passField;
@property (nonatomic, strong) UITextField *pathField;
@property (nonatomic, strong) UISwitch *enableSwitch;
@property (nonatomic, strong) UISwitch *darkSwitch;
@property (nonatomic, strong) UISwitch *landscapeSwitch;
@property (nonatomic, strong) UISwitch *cacheSwitch;
@property (nonatomic, strong) UISwitch *autoUpdateSwitch;
@property (nonatomic, assign) BOOL webdavExpanded;
@end

@implementation FESettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";
    self.view.backgroundColor = [FETheme background];
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(saveConfig)];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [FETheme background];
    self.tableView.separatorColor = [FETheme separator];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    // 底部预留迷你播放器高度，避免最后一个分组被遮挡
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 120, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 120, 0);
    [self.view addSubview:self.tableView];

    [self setupFields];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accountChanged:)
                                                 name:FEAccountDidChangeNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)accountChanged:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)setupFields {
    FEWebDAVManager *wd = [FEWebDAVManager sharedManager];
    self.serverField = [[UITextField alloc] init];
    self.serverField.placeholder = @"https://example.com/dav/";
    self.serverField.text = wd.serverURL;
    self.serverField.borderStyle = UITextBorderStyleRoundedRect;
    self.serverField.delegate = self;
    self.serverField.keyboardType = UIKeyboardTypeURL;
    self.serverField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.serverField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.serverField.clearButtonMode = UITextFieldViewModeWhileEditing;

    self.userField = [[UITextField alloc] init];
    self.userField.placeholder = @"用户名";
    self.userField.text = wd.username;
    self.userField.borderStyle = UITextBorderStyleRoundedRect;
    self.userField.delegate = self;
    self.userField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.userField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.userField.clearButtonMode = UITextFieldViewModeWhileEditing;

    self.passField = [[UITextField alloc] init];
    self.passField.placeholder = @"密码";
    self.passField.text = wd.password;
    self.passField.secureTextEntry = YES;
    self.passField.borderStyle = UITextBorderStyleRoundedRect;
    self.passField.delegate = self;

    self.pathField = [[UITextField alloc] init];
    self.pathField.placeholder = @"/D9Music/";
    self.pathField.text = wd.remotePath;
    self.pathField.borderStyle = UITextBorderStyleRoundedRect;
    self.pathField.delegate = self;
    self.pathField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.pathField.autocorrectionType = UITextAutocorrectionTypeNo;

    self.enableSwitch = [[UISwitch alloc] init];
    self.enableSwitch.on = wd.isEnabled;
    [self.enableSwitch addTarget:self action:@selector(webdavSwitchChanged:) forControlEvents:UIControlEventValueChanged];

    self.darkSwitch = [[UISwitch alloc] init];
    self.darkSwitch.on = [FESettings sharedSettings].darkMode;
    [self.darkSwitch addTarget:self action:@selector(darkModeChanged:) forControlEvents:UIControlEventValueChanged];

    self.landscapeSwitch = [[UISwitch alloc] init];
    self.landscapeSwitch.on = [FESettings sharedSettings].landscapePlayer;
    [self.landscapeSwitch addTarget:self action:@selector(landscapeChanged:) forControlEvents:UIControlEventValueChanged];

    self.cacheSwitch = [[UISwitch alloc] init];
    self.cacheSwitch.on = [FESettings sharedSettings].cacheEnabled;
    [self.cacheSwitch addTarget:self action:@selector(cacheSwitchChanged:) forControlEvents:UIControlEventValueChanged];

    self.autoUpdateSwitch = [[UISwitch alloc] init];
    self.autoUpdateSwitch.on = [FEUpdateUI autoCheckEnabled];
    [self.autoUpdateSwitch addTarget:self action:@selector(autoUpdateChanged:) forControlEvents:UIControlEventValueChanged];
}

#pragma mark - Actions

- (void)darkModeChanged:(UISwitch *)sw {
    [FESettings sharedSettings].darkMode = sw.on;
}

- (void)landscapeChanged:(UISwitch *)sw {
    [FESettings sharedSettings].landscapePlayer = sw.on;
    [UIViewController attemptRotationToDeviceOrientation];
    [FETheme showToast:sw.on ? @"已开启横屏播放" : @"已关闭横屏播放" inView:self.view];
}

- (void)cacheSwitchChanged:(UISwitch *)sw {
    [FESettings sharedSettings].cacheEnabled = sw.on;
    [[FESettings sharedSettings] save];
    [FETheme showToast:sw.on ? @"已开启歌曲缓存" : @"已关闭歌曲缓存" inView:self.view];
}

- (void)autoUpdateChanged:(UISwitch *)sw {
    [FEUpdateUI setAutoCheckEnabled:sw.on];
    [FETheme showToast:sw.on ? @"启动时会自动检查更新" : @"已关闭自动检查更新" inView:self.view];
}

- (void)webdavSwitchChanged:(UISwitch *)sw {
    [FEWebDAVManager sharedManager].isEnabled = sw.on;
    [[FEWebDAVManager sharedManager] saveConfig];
}

- (void)saveConfig {
    [self.view endEditing:YES];
    FEWebDAVManager *wd = [FEWebDAVManager sharedManager];
    wd.serverURL = [self.serverField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    wd.username = [self.userField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    wd.password = self.passField.text ?: @"";
    wd.remotePath = [self.pathField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (wd.remotePath.length == 0) wd.remotePath = @"/D9Music/";
    if (![wd.remotePath hasPrefix:@"/"]) wd.remotePath = [@"/" stringByAppendingString:wd.remotePath];
    if (![wd.remotePath hasSuffix:@"/"]) wd.remotePath = [wd.remotePath stringByAppendingString:@"/"];
    [wd saveConfig];
    [FETheme showToast:@"配置已保存" inView:self.view];
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case FESettingsSectionAppearance: return @"外观与播放";
        case FESettingsSectionPlayback: return @"播放与缓存";
        case FESettingsSectionSources: return @"音源";
        case FESettingsSectionWebDAV: return @"WebDAV 云同步";
        case FESettingsSectionUpdate: return @"更新";
        default: return @"关于";
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == FESettingsSectionAppearance) return @"夜间模式会重建界面以应用新配色；横屏播放仅对播放页生效。";
    if (section == FESettingsSectionPlayback) return @"缓存用于离线复听，超过上限会自动清理较早的文件。";
    if (section == FESettingsSectionSources) return @"可同时启用多个音源，并按优先级自动切换。";
    if (section == FESettingsSectionWebDAV) return @"配置与 Cookie 仅保存在本机；云端备份包含歌单。";
    if (section == FESettingsSectionUpdate) return @"更新会从 Gitee / GitHub Release 下载 IPA 并覆盖安装，需要 AppSync Unified。";
    return @"D9Music · iOS 9 / armv7";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case FESettingsSectionAppearance: return 2;
        case FESettingsSectionPlayback: return 4;
        case FESettingsSectionSources: return 1;
        case FESettingsSectionWebDAV: return self.webdavExpanded ? 11 : 1;
        case FESettingsSectionUpdate: return 2;
        default: return 4;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"SettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellId];
        cell.backgroundColor = [FETheme card];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        cell.detailTextLabel.textColor = [FETheme textSecondary];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.textLabel.textColor = [FETheme textPrimary];
    cell.detailTextLabel.text = nil;
    for (UIView *subview in [cell.contentView.subviews copy]) {
        if ([subview isKindOfClass:[UITextField class]]) [subview removeFromSuperview];
    }

    if (indexPath.section == FESettingsSectionAppearance) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"夜间模式";
            cell.accessoryView = self.darkSwitch;
        } else {
            cell.textLabel.text = @"横屏播放";
            cell.accessoryView = self.landscapeSwitch;
        }
        return cell;
    }

    if (indexPath.section == FESettingsSectionPlayback) {
        FESettings *settings = [FESettings sharedSettings];
        if (indexPath.row == 0) {
            cell.textLabel.text = @"优先音质";
            cell.detailTextLabel.text = [FESettings qualityTitle:settings.preferredQuality];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"歌曲缓存";
            cell.accessoryView = self.cacheSwitch;
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"最大缓存容量";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld MB", (long)settings.maxCacheMB];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        } else {
            cell.textLabel.text = @"清理缓存";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %ld 首",
                                         [FECacheManager formatSize:[[FECacheManager sharedManager] cacheSize]],
                                         (long)[[FECacheManager sharedManager] cachedFileCount]];
            cell.textLabel.textColor = [FETheme warning];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
        return cell;
    }

    if (indexPath.section == FESettingsSectionSources) {
        cell.textLabel.text = @"音源与登录优先级";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        return cell;
    }

    if (indexPath.section == FESettingsSectionWebDAV) {
        if (!self.webdavExpanded) {
            cell.textLabel.text = @"WebDAV 云同步";
            cell.detailTextLabel.text = [FEWebDAVManager sharedManager].isEnabled ? @"已启用" : @"未启用";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            return cell;
        }
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"启用 WebDAV";
                cell.accessoryView = self.enableSwitch;
                return cell;
            case 1:
                cell.textLabel.text = @"服务器地址";
                self.serverField.frame = CGRectMake(110, 7, self.view.bounds.size.width - 130, 30);
                [cell.contentView addSubview:self.serverField];
                return cell;
            case 2:
                cell.textLabel.text = @"用户名";
                self.userField.frame = CGRectMake(110, 7, self.view.bounds.size.width - 130, 30);
                [cell.contentView addSubview:self.userField];
                return cell;
            case 3:
                cell.textLabel.text = @"密码";
                self.passField.frame = CGRectMake(110, 7, self.view.bounds.size.width - 130, 30);
                [cell.contentView addSubview:self.passField];
                return cell;
            case 4:
                cell.textLabel.text = @"远程路径";
                self.pathField.frame = CGRectMake(110, 7, self.view.bounds.size.width - 130, 30);
                [cell.contentView addSubview:self.pathField];
                return cell;
            case 5:
                cell.textLabel.text = @"测试连接";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                return cell;
            case 6:
                cell.textLabel.text = @"同步本地歌单到云端";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                return cell;
            case 7:
                cell.textLabel.text = @"浏览云盘音乐";
                cell.detailTextLabel.text = @"浏览 / 下载";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                return cell;
            case 8:
                cell.textLabel.text = @"备份配置到云端";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                return cell;
            case 9:
                cell.textLabel.text = @"从云端恢复配置";
                cell.textLabel.textColor = [FETheme warning];
                cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                return cell;
            default:
                cell.textLabel.text = @"收起 WebDAV 设置";
                cell.textLabel.textColor = [FETheme textSecondary];
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                return cell;
        }
    }

    if (indexPath.section == FESettingsSectionUpdate) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"检查更新";
            cell.detailTextLabel.text = [FEUpdateUI currentVersionText];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        } else {
            cell.textLabel.text = @"自动检查更新";
            cell.accessoryView = self.autoUpdateSwitch;
        }
        return cell;
    }

    if (indexPath.row == 0) {
        cell.textLabel.text = @"版本";
        cell.detailTextLabel.text = [FEUpdateUI currentVersionText];
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"本地歌单数量";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[FEPlaylistManager sharedManager].localPlaylists.count];
    } else if (indexPath.row == 2) {
        cell.textLabel.text = @"收藏歌曲数量";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[FEFavoriteManager sharedManager].favoriteTracks.count];
    } else {
        cell.textLabel.text = @"云盘下载目录";
        cell.detailTextLabel.text = @"Documents/CloudMusic";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == FESettingsSectionPlayback) {
        if (indexPath.row == 0) {
            [self showQualityPicker];
        } else if (indexPath.row == 2) {
            [self showCacheLimitPicker];
        } else if (indexPath.row == 3) {
            [self confirmClearCache];
        }
        return;
    }

    if (indexPath.section == FESettingsSectionSources) {
        [self.navigationController pushViewController:[[FESourceListViewController alloc] init] animated:YES];
        return;
    }

    if (indexPath.section == FESettingsSectionUpdate) {
        if (indexPath.row == 0) {
            [FEUpdateUI checkForUpdatesFrom:self silent:NO];
        }
        return;
    }

    if (indexPath.section != FESettingsSectionWebDAV) return;

    if (!self.webdavExpanded) {
        [self saveConfig];
        self.webdavExpanded = YES;
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:FESettingsSectionWebDAV] withRowAnimation:UITableViewRowAnimationFade];
        return;
    }

    if (indexPath.row == 10) {
        self.webdavExpanded = NO;
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:FESettingsSectionWebDAV] withRowAnimation:UITableViewRowAnimationFade];
        return;
    }

    [self saveConfig];
    if (indexPath.row == 5) {
        [FETheme showToast:@"正在测试连接…" inView:self.view];
        [[FEWebDAVManager sharedManager] testConnection:^(BOOL success, NSString *message) {
            [FETheme showToast:message inView:self.view];
        }];
    } else if (indexPath.row == 6) {
        [FETheme showToast:@"正在同步…" inView:self.view];
        [[FEWebDAVManager sharedManager] syncPlaylistsToWebDAV:^(BOOL success, NSString *message) {
            [FETheme showToast:message inView:self.view];
        }];
    } else if (indexPath.row == 7) {
        if (![FEWebDAVManager sharedManager].isEnabled) {
            [FETheme showToast:@"请先启用 WebDAV" inView:self.view];
            return;
        }
        [self.navigationController pushViewController:[[FECloudViewController alloc] init] animated:YES];
    } else if (indexPath.row == 8) {
        [FETheme showToast:@"正在备份…" inView:self.view];
        [[FEWebDAVManager sharedManager] backupConfigToWebDAV:^(BOOL success, NSString *message) {
            [FETheme showToast:message inView:self.view];
        }];
    } else if (indexPath.row == 9) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"从云端恢复配置"
                                                        message:@"将用云端备份覆盖本地歌单，确定继续？"
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"恢复", nil];
        alert.tag = 9001;
        [alert show];
    }
}

#pragma mark - Pickers

- (void)showQualityPicker {
    NSInteger current = [FESettings sharedSettings].preferredQuality;
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"优先播放音质"
                                                                   message:@"音源支持时会优先使用该音质，否则自动降级"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSInteger i = 0; i < 3; i++) {
        NSString *title = [NSString stringWithFormat:@"%@ · %@", [FESettings qualityTitle:i], [FESettings qualityDetail:i]];
        if (i == current) title = [title stringByAppendingString:@" ✓"];
        __weak typeof(self) weakSelf = self;
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            [FESettings sharedSettings].preferredQuality = i;
            [[FESettings sharedSettings] save];
            [strongSelf.tableView reloadData];
            [FETheme showToast:[NSString stringWithFormat:@"优先音质：%@", [FESettings qualityTitle:i]] inView:strongSelf.view];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showCacheLimitPicker {
    NSArray *options = @[@100, @200, @500, @1024];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"最大缓存容量"
                                                                   message:@"超出后自动清理较早的缓存"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSNumber *option in options) {
        NSString *title = [option integerValue] >= 1024 ? @"1 GB" : [NSString stringWithFormat:@"%@ MB", option];
        if ([option integerValue] == [FESettings sharedSettings].maxCacheMB) {
            title = [title stringByAppendingString:@" ✓"];
        }
        __weak typeof(self) weakSelf = self;
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            [FESettings sharedSettings].maxCacheMB = [option integerValue];
            [[FESettings sharedSettings] save];
            [[FECacheManager sharedManager] enforceLimit];
            [strongSelf.tableView reloadData];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)confirmClearCache {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"清理缓存"
                                                    message:[NSString stringWithFormat:@"将删除 %@ 缓存，确定继续？",
                                                             [FECacheManager formatSize:[[FECacheManager sharedManager] cacheSize]]]
                                                   delegate:self
                                          cancelButtonTitle:@"取消"
                                          otherButtonTitles:@"清理", nil];
    alert.tag = 9003;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 9001 && buttonIndex == 1) {
        [FETheme showToast:@"正在恢复…" inView:self.view];
        __weak typeof(self) weakSelf = self;
        [[FEWebDAVManager sharedManager] restoreConfigFromWebDAV:^(BOOL success, NSString *message) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            [FETheme showToast:message inView:strongSelf.view];
            [strongSelf.tableView reloadData];
        }];
    } else if (alertView.tag == 9003 && buttonIndex == 1) {
        [[FECacheManager sharedManager] clearCache];
        [self.tableView reloadData];
        [FETheme showToast:@"缓存已清理" inView:self.view];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
