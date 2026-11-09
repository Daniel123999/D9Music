#import "FERecommendViewController.h"
#import "FEProviderManager.h"
#import "FEPlayerManager.h"

@interface FERecommendViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *features;
@end

@implementation FERecommendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"推荐";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.features = @[
        @{@"title": @"每日推荐歌曲", @"icon": @"🎵", @"id": @"daily_songs"},
        @{@"title": @"每日推荐歌单", @"icon": @"📋", @"id": @"daily_playlists"},
        @{@"title": @"私人FM", @"icon": @"📻", @"id": @"radio"},
        @{@"title": @"推荐新歌", @"icon": @"🆕", @"id": @"new_songs"},
        @{@"title": @"推荐MV", @"icon": @"🎬", @"id": @"mvs"},
        @{@"title": @"排行榜", @"icon": @"🏆", @"id": @"toplists"},
        @{@"title": @"歌单广场", @"icon": @"🎼", @"id": @"playlist_square"},
        @{@"title": @"歌手广场", @"icon": @"🎤", @"id": @"artist_square"},
        @{@"title": @"新歌速递", @"icon": @"🚀", @"id": @"new_songs_fast"},
        @{@"title": @"新碟上架", @"icon": @"💿", @"id": @"new_albums"},
        @{@"title": @"热门歌手", @"icon": @"⭐", @"id": @"top_artists"},
        @{@"title": @"精品歌单", @"icon": @"💎", @"id": @"highquality"}
    ];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 60;
    [self.view addSubview:self.tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.features.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId];
    }
    NSDictionary *feature = self.features[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", feature[@"icon"], feature[@"title"]];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    // 根据功能加载内容
}

@end
