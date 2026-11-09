#import "SearchViewController.h"
#import "PlayerViewController.h"
#import "FEProviderManager.h"
#import "FETrack.h"
#import "FEPlayerManager.h"
#import "FELyricsManager.h"

@interface SearchViewController ()
@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) UIButton *searchBtn;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *results;
@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"搜索";
    self.view.backgroundColor = [UIColor whiteColor];
    self.results = [NSMutableArray array];
    
    self.searchField = [[UITextField alloc] initWithFrame:CGRectMake(20, 80, self.view.frame.size.width - 100, 30)];
    self.searchField.borderStyle = UITextBorderStyleRoundedRect;
    self.searchField.placeholder = [NSString stringWithFormat:@"搜索 - %@", [FEProviderManager sharedManager].currentProvider.providerName];
    self.searchField.delegate = self;
    [self.view addSubview:self.searchField];
    
    self.searchBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.searchBtn.frame = CGRectMake(self.view.frame.size.width - 70, 80, 50, 30);
    [self.searchBtn setTitle:@"搜索" forState:UIControlStateNormal];
    [self.searchBtn addTarget:self action:@selector(doSearch) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.searchBtn];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 130, self.view.frame.size.width, self.view.frame.size.height - 130) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}

- (void)doSearch {
    [self.searchField resignFirstResponder];
    NSString *keyword = self.searchField.text;
    if (keyword.length == 0) return;
    
    id<FEProviderProtocol> provider = [FEProviderManager sharedManager].currentProvider;
    if ([provider respondsToSelector:@selector(searchWithKeyword:completion:)]) {
        [provider searchWithKeyword:keyword completion:^(NSArray<FETrack *> *tracks, NSError *error) {
            [self.results removeAllObjects];
            [self.results addObjectsFromArray:tracks];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self doSearch];
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellId];
    }
    id item = self.results[indexPath.row];
    if ([item isKindOfClass:[FETrack class]]) {
        FETrack *track = (FETrack *)item;
        cell.textLabel.text = track.title;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@", track.artist ?: @"", track.album ?: @""];
    } else if ([item isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = item;
        cell.textLabel.text = dict[@"title"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@", dict[@"artist"], dict[@"album"]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id item = self.results[indexPath.row];
    if ([item isKindOfClass:[FETrack class]]) {
        FETrack *track = (FETrack *)item;
        id<FEProviderProtocol> provider = [FEProviderManager sharedManager].currentProvider;
        if ([provider respondsToSelector:@selector(getPlayUrlForTrack:completion:)]) {
            [provider getPlayUrlForTrack:track completion:^(NSString *playUrl, NSError *error) {
                if (playUrl) {
                    track.playUrl = playUrl;
                }
                if ([provider respondsToSelector:@selector(getLyricForTrack:completion:)]) {
                    [provider getLyricForTrack:track completion:^(NSString *lyric, NSError *error) {
                        if (lyric) {
                            [[FELyricsManager sharedManager] parseLRC:lyric];
                        }
                    }];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[FEPlayerManager sharedManager] playTrack:track];
                    [self.navigationController popToRootViewControllerAnimated:YES];
                });
            }];
        } else {
            [[FEPlayerManager sharedManager] playTrack:track];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    } else {
        PlayerViewController *playerVC = [[PlayerViewController alloc] init];
        playerVC.trackInfo = item;
        [self.navigationController pushViewController:playerVC animated:YES];
    }
}

@end
