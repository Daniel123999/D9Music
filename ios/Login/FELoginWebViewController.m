#import "FELoginWebViewController.h"

@interface FELoginWebViewController ()
@property (nonatomic, strong) UIWebView *webView;
@end

@implementation FELoginWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"登录 - %@", self.provider.providerName];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
    [self.view addSubview:self.webView];
    
    if (self.provider.loginUrl) {
        NSURL *url = [NSURL URLWithString:self.provider.loginUrl];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(doneTapped)];
}

- (void)doneTapped {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSMutableDictionary *cookiesDict = [NSMutableDictionary dictionary];
    for (NSHTTPCookie *cookie in cookieStorage.cookies) {
        cookiesDict[cookie.name] = cookie.value;
    }
    if ([self.provider respondsToSelector:@selector(handleLoginCookies:)]) {
        [self.provider handleLoginCookies:cookiesDict];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}

@end
