#import "SearchViewController.h"
#import "PlayerViewController.h"

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
    self.searchField.placeholder = @"搜索网易云音乐";
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
    [self.results removeAllObjects];
    
    // 模拟搜索结果
    [self.results addObject:@{@"title": @"晴天", @"artist": @"周杰伦", @"album": @"叶惠美"}];
    [self.results addObject:@{@"title": @"稻香", @"artist": @"周杰伦", @"album": @"魔杰座"}];
    [self.results addObject:@{@"title": @"青花瓷", @"artist": @"周杰伦", @"album": @"我很忙"}];
    
    [self.tableView reloadData];
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
    NSDictionary *item = self.results[indexPath.row];
    cell.textLabel.text = item[@"title"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@", item[@"artist"], item[@"album"]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    PlayerViewController *playerVC = [[PlayerViewController alloc] init];
    playerVC.trackInfo = self.results[indexPath.row];
    [self.navigationController pushViewController:playerVC animated:YES];
}

@end
