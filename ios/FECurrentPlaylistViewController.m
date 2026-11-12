#import "FECurrentPlaylistViewController.h"
#import "FETheme.h"
#import "FEComponents.h"
#import "FEPlayerManager.h"
#import "FETrack.h"

@interface FECurrentPlaylistViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;
@end

@implementation FECurrentPlaylistViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"当前播放列表";
    self.view.backgroundColor = [FETheme background];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"清空"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(clearPlaylist)];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 68;
    self.tableView.backgroundColor = [FETheme background];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 74, 0, 16);
    [FETheme styleTableView:self.tableView];
    [self.view addSubview:self.tableView];
    
    self.emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 200, self.view.bounds.size.width - 48, 40)];
    self.emptyLabel.text = @"播放列表为空";
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.textColor = [FETheme textSecondary];
    self.emptyLabel.font = [UIFont systemFontOfSize:14];
    self.emptyLabel.hidden = YES;
    [self.view addSubview:self.emptyLabel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:FEPlayerDidChangeTrackNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reload];
}

- (void)reload {
    [self.tableView reloadData];
    NSArray *playlist = [FEPlayerManager sharedManager].playlist;
    self.emptyLabel.hidden = playlist.count > 0;
    self.navigationItem.rightBarButtonItem.enabled = playlist.count > 0;
}

- (void)clearPlaylist {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"清空播放列表"
                                                    message:@"确定要清空当前播放列表吗？"
                                                   delegate:self
                                          cancelButtonTitle:@"取消"
                                          otherButtonTitles:@"清空", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        FEPlayerManager *pm = [FEPlayerManager sharedManager];
        [pm.playlist removeAllObjects];
        pm.currentIndex = -1;
        [pm pause];
        [self reload];
        [FETheme showToast:@"播放列表已清空" inView:self.view];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [FEPlayerManager sharedManager].playlist.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"CurrentPlaylistCell";
    FETrackCell *cell = (FETrackCell *)[tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[FETrackCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId];
    }
    FETrack *track = [FEPlayerManager sharedManager].playlist[indexPath.row];
    [cell configureWithTrack:track];
    if ([FEPlayerManager sharedManager].currentIndex == indexPath.row) {
        [cell setPlaying:YES];
    } else {
        [cell setPlaying:NO];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FEPlayerManager *pm = [FEPlayerManager sharedManager];
    if (indexPath.row >= 0 && indexPath.row < (NSInteger)pm.playlist.count) {
        [pm playTracks:pm.playlist startIndex:indexPath.row];
        [self reload];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        FEPlayerManager *pm = [FEPlayerManager sharedManager];
        if (indexPath.row < (NSInteger)pm.playlist.count) {
            [pm.playlist removeObjectAtIndex:indexPath.row];
            if (pm.currentIndex == indexPath.row) {
                if (pm.playlist.count > 0) {
                    pm.currentIndex = MIN(indexPath.row, (NSInteger)pm.playlist.count - 1);
                    [pm playTrack:pm.playlist[pm.currentIndex]];
                } else {
                    pm.currentIndex = -1;
                    [pm pause];
                }
            } else if (pm.currentIndex > indexPath.row) {
                pm.currentIndex--;
            }
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self reload];
        }
    }
}

@end
