#import "FELoginWebViewController.h"

@interface FELoginViewController ()
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UITextView *cookieTextView;
@property (nonatomic, strong) UIButton *saveButton;
@end

@implementation FELoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"手动输入 Cookie - %@", self.provider.providerName];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, self.view.frame.size.width - 40, 60)];
    self.tipLabel.numberOfLines = 0;
    self.tipLabel.font = [UIFont systemFontOfSize:13];
    self.tipLabel.textColor = [UIColor darkGrayColor];
    self.tipLabel.text = @"请在浏览器登录后复制 Cookie 粘贴到下方。\n格式：key1=value1; key2=value2";
    [self.view addSubview:self.tipLabel];
    
    self.cookieTextView = [[UITextView alloc] initWithFrame:CGRectMake(20, 150, self.view.frame.size.width - 40, 150)];
    self.cookieTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.cookieTextView.layer.borderWidth = 1.0;
    self.cookieTextView.font = [UIFont systemFontOfSize:12];
    self.cookieTextView.delegate = self;
    [self.view addSubview:self.cookieTextView];
    
    self.saveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.saveButton.frame = CGRectMake(20, 320, self.view.frame.size.width - 40, 44);
    [self.saveButton setTitle:@"保存并登录" forState:UIControlStateNormal];
    [self.saveButton addTarget:self action:@selector(saveTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.saveButton];
}

- (void)saveTapped {
    NSString *cookieStr = self.cookieTextView.text;
    NSMutableDictionary *cookiesDict = [NSMutableDictionary dictionary];
    NSArray *pairs = [cookieStr componentsSeparatedByString:@";"];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        if (kv.count == 2) {
            NSString *key = [[kv[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            NSString *value = [[kv[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            if (key.length > 0) {
                cookiesDict[key] = value;
            }
        }
    }
    if ([self.provider respondsToSelector:@selector(handleLoginCookies:)]) {
        [self.provider handleLoginCookies:cookiesDict];
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"登录信息已保存" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
