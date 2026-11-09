#import "RootViewController.h"
#import "SearchViewController.h"
#import "PlayerViewController.h"

@interface RootViewController ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *searchButton;
@property (nonatomic, strong) UIButton *playerButton;
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"FuoEvolve";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, self.view.frame.size.width - 40, 40)];
    self.titleLabel.text = @"FeelUOwn";
    self.titleLabel.font = [UIFont boldSystemFontOfSize:28];
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:self.titleLabel];
    
    self.searchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.searchButton.frame = CGRectMake(20, 140, self.view.frame.size.width - 40, 44);
    [self.searchButton setTitle:@"搜索音乐" forState:UIControlStateNormal];
    [self.searchButton addTarget:self action:@selector(searchTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.searchButton];
    
    self.playerButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.playerButton.frame = CGRectMake(20, 200, self.view.frame.size.width - 40, 44);
    [self.playerButton setTitle:@"播放器" forState:UIControlStateNormal];
    [self.playerButton addTarget:self action:@selector(playerTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playerButton];
}

- (void)searchTapped {
    SearchViewController *searchVC = [[SearchViewController alloc] init];
    [self.navigationController pushViewController:searchVC animated:YES];
}

- (void)playerTapped {
    PlayerViewController *playerVC = [[PlayerViewController alloc] init];
    [self.navigationController pushViewController:playerVC animated:YES];
}

@end
