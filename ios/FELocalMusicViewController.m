#import "FELocalMusicViewController.h"
#import "FELocalMusicManager.h"
#import "FEPlayerManager.h"

@interface FELocalMusicViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *tracks;
@end

@implementation FELocalMusicViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"本地音乐";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    [[FELocalMusicManager sharedManager] scanLocalMusicWithCompletion:^(NSArray *tracks) {
        self.tracks = tracks;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tracks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellId];
    }
    FETrack *track = self.tracks[indexPath.row];
    cell.textLabel.text = track.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", track.artist, track.album];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    FETrack *track = self.tracks[indexPath.row];
    [[FEPlayerManager sharedManager] playTrack:track];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
