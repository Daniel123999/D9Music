#import "FESettingsViewController.h"
#import "FETheme.h"
#import "FEIconView.h"
#import "FEWebDAVManager.h"
#import "FEPlaylistManager.h"
#import "FEFavoriteManager.h"
#import "FESettings.h"
#import "FESourceListViewController.h"
#import "FECloudViewController.h"

@interface FESettingsViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *serverField;
@property (nonatomic, strong) UITextField *userField;
@property (nonatomic, strong) UITextField *passField;
@property (nonatomic, strong) UITextField *pathField;
@property (nonatomic, strong) UISwitch *enableSwitch;
@property (nonatomic, strong) UISwitch *darkSwitch;
@property (nonatomic, strong) UISwitch *landscapeSwitch;
@property (nonatomic, assign) BOOL webdavExpanded;
@property (nonatomic, assign) BOOL didExpandOnce;
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
    // 底部预留迷你播放器高度，避免“关于”分组被遮挡
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 120, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 120, 0);
    [self.view addSubview:self.tableView];

    [self setupFields];
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
}

#pragma mark - Actions

- (void)darkModeChanged:(UISwitch *)sw {
    // AppDelegate 收到通知后会延迟重建界面，这里只负责写入设置
    [FESettings sharedSettings].darkMode = sw.on;
}

- (void)landscapeChanged:(UISwitch *)sw {
    [FESettings sharedSettings].landscapePlayer = sw.on;
    [UIViewController attemptRotationToDeviceOrientation];
    [FETheme showToast:sw.on ? @"已开启横屏播放" : @"已关闭横屏播放" inView:self.view];
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
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"外观与播放";
    if (section == 1) return @"音源";
    if (section == 2) return @"WebDAV 云同步";
    return @"关于";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) return @"夜间模式会重建界面以应用新配色；横屏播放仅对播放页生效。";
    if (section == 1) return @"可同时启用多个音源，并按优先级自动切换。";
    if (section == 2) return @"配置与 Cookie 仅保存在本机；云端备份包含歌单。";
    return @"D9Music · iOS 9 / armv7";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 2;
    if (section == 1) return 1;
    if (section == 2) return self.webdavExpanded ? 11 : 1;
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"SettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellId];
        cell.backgroundColor = [FETheme card];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.textColor = [FETheme textPrimary];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        cell.detailTextLabel.textColor = [FETheme textSecondary];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.textLabel.textColor = [FETheme textPrimary];
    for (UIView *subview in [cell.contentView.subviews copy]) {
        if ([subview isKindOfClass:[UITextField class]]) [subview removeFromSuperview];
    }

    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"夜间模式";
            cell.accessoryView = self.darkSwitch;
        } else {
            cell.textLabel.text = @"横屏播放";
            cell.accessoryView = self.landscapeSwitch;
        }
        return cell;
    }

    if (indexPath.section == 1) {
        cell.textLabel.text = @"音源与登录优先级";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        return cell;
    }

    if (indexPath.section == 2) {
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
            case 9: {
                // 恢复配置：按钮样式，而不是开关
                cell.textLabel.text = @"从云端恢复配置";
                cell.textLabel.textColor = [FETheme warning];
                cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                return cell;
            }
            default:
                cell.textLabel.text = @"收起 WebDAV 设置";
                cell.textLabel.textColor = [FETheme textSecondary];
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                return cell;
        }
    }

    if (indexPath.row == 0) {
        cell.textLabel.text = @"版本";
        cell.detailTextLabel.text = @"1.3.0 (5)";
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

    if (indexPath.section == 1) {
        [self.navigationController pushViewController:[[FESourceListViewController alloc] init] animated:YES];
        return;
    }

    if (indexPath.section != 2) return;

    if (!self.webdavExpanded) {
        [self saveConfig];
        self.webdavExpanded = YES;
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
        return;
    }

    if (indexPath.row == 10) {
        self.webdavExpanded = NO;
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
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
        FECloudViewController *vc = [[FECloudViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
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
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
