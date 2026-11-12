#import "FESettingsViewController.h"
#import "FETheme.h"
#import "FEIconView.h"
#import "FEWebDAVManager.h"
#import "FEPlaylistManager.h"
#import "FEFavoriteManager.h"

@interface FESettingsViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *serverField;
@property (nonatomic, strong) UITextField *userField;
@property (nonatomic, strong) UITextField *passField;
@property (nonatomic, strong) UITextField *pathField;
@property (nonatomic, strong) UISwitch *enableSwitch;
@end

@implementation FESettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";
    self.view.backgroundColor = [FETheme background];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [FETheme background];
    self.tableView.separatorColor = [FETheme separator];
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
    
    self.userField = [[UITextField alloc] init];
    self.userField.placeholder = @"用户名";
    self.userField.text = wd.username;
    self.userField.borderStyle = UITextBorderStyleRoundedRect;
    self.userField.delegate = self;
    
    self.passField = [[UITextField alloc] init];
    self.passField.placeholder = @"密码";
    self.passField.text = wd.password;
    self.passField.secureTextEntry = YES;
    self.passField.borderStyle = UITextBorderStyleRoundedRect;
    self.passField.delegate = self;
    
    self.pathField = [[UITextField alloc] init];
    self.pathField.placeholder = @"/FuoEvolve9/";
    self.pathField.text = wd.remotePath;
    self.pathField.borderStyle = UITextBorderStyleRoundedRect;
    self.pathField.delegate = self;
    
    self.enableSwitch = [[UISwitch alloc] init];
    self.enableSwitch.on = wd.isEnabled;
    [self.enableSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)switchChanged:(UISwitch *)sw {
    [FEWebDAVManager sharedManager].isEnabled = sw.on;
    [[FEWebDAVManager sharedManager] saveConfig];
}

- (void)saveConfig {
    FEWebDAVManager *wd = [FEWebDAVManager sharedManager];
    wd.serverURL = [self.serverField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    wd.username = [self.userField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    wd.password = self.passField.text ?: @"";
    wd.remotePath = [self.pathField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (wd.remotePath.length == 0) wd.remotePath = @"/FuoEvolve9/";
    if (![wd.remotePath hasSuffix:@"/"]) wd.remotePath = [wd.remotePath stringByAppendingString:@"/"];
    [wd saveConfig];
    [FETheme showToast:@"配置已保存" inView:self.view];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"WebDAV 设置";
    if (section == 1) return @"连接测试";
    if (section == 2) return @"同步与备份";
    return @"关于";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 5;
    if (section == 1) return 2;
    if (section == 2) return 4;
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"SettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellId];
        cell.backgroundColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.textColor = [FETheme textPrimary];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"启用 WebDAV";
            cell.accessoryView = self.enableSwitch;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"服务器地址";
            self.serverField.frame = CGRectMake(110, 7, self.view.bounds.size.width - 130, 30);
            [cell.contentView addSubview:self.serverField];
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"用户名";
            self.userField.frame = CGRectMake(110, 7, self.view.bounds.size.width - 130, 30);
            [cell.contentView addSubview:self.userField];
        } else if (indexPath.row == 3) {
            cell.textLabel.text = @"密码";
            self.passField.frame = CGRectMake(110, 7, self.view.bounds.size.width - 130, 30);
            [cell.contentView addSubview:self.passField];
        } else if (indexPath.row == 4) {
            cell.textLabel.text = @"远程路径";
            self.pathField.frame = CGRectMake(110, 7, self.view.bounds.size.width - 130, 30);
            [cell.contentView addSubview:self.pathField];
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"保存配置";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"测试连接";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"同步本地歌单到 WebDAV";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"从云端下载歌单";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"备份配置到云端";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        } else if (indexPath.row == 3) {
            cell.textLabel.text = @"从云端恢复配置";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
    } else if (indexPath.section == 3) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"本地歌单数量";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[FEPlaylistManager sharedManager].localPlaylists.count];
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"收藏歌曲数量";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[FEFavoriteManager sharedManager].favoriteTracks.count];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self saveConfig];
        } else if (indexPath.row == 1) {
            [self saveConfig];
            [FETheme showToast:@"正在测试连接..." inView:self.view];
            [[FEWebDAVManager sharedManager] testConnection:^(BOOL success, NSString *message) {
                [FETheme showToast:message inView:self.view];
            }];
        }
    } else if (indexPath.section == 2) {
        [self saveConfig];
        if (indexPath.row == 0) {
            [FETheme showToast:@"正在同步..." inView:self.view];
            [[FEWebDAVManager sharedManager] syncPlaylistsToWebDAV:^(BOOL success, NSString *message) {
                [FETheme showToast:message inView:self.view];
            }];
        } else if (indexPath.row == 1) {
            [FETheme showToast:@"云端下载功能开发中" inView:self.view];
        } else if (indexPath.row == 2) {
            [FETheme showToast:@"正在备份..." inView:self.view];
            [[FEWebDAVManager sharedManager] backupConfigToWebDAV:^(BOOL success, NSString *message) {
                [FETheme showToast:message inView:self.view];
            }];
        } else if (indexPath.row == 3) {
            [FETheme showToast:@"正在恢复..." inView:self.view];
            [[FEWebDAVManager sharedManager] restoreConfigFromWebDAV:^(BOOL success, NSString *message) {
                [FETheme showToast:message inView:self.view];
            }];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
