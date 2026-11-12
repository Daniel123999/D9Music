#import "FELoginWebViewController.h"
#import "FETheme.h"
#import "FEIconView.h"

@interface FELoginViewController () <UITextViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITextView *cookieTextView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UIButton *saveButton;

@end

@implementation FELoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [FETheme background];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.title = [NSString stringWithFormat:@"登录 %@", self.provider.providerName ?: @"音源"];

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.scrollView.contentInset = UIEdgeInsetsMake(12, 0, 300, 0);
    [self.view addSubview:self.scrollView];

    [self buildContent];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)buildContent {
    CGFloat width = self.view.bounds.size.width;
    CGFloat cardWidth = width - 24;

    UIView *tipCard = [[UIView alloc] initWithFrame:CGRectMake(12, 0, cardWidth, 96)];
    [FETheme applyCardStyle:tipCard radius:18];
    [self.scrollView addSubview:tipCard];

    UIView *badge = [[UIView alloc] initWithFrame:CGRectMake(16, 16, 40, 40)];
    badge.backgroundColor = [[FETheme primary] colorWithAlphaComponent:0.12];
    badge.layer.cornerRadius = 13;
    [tipCard addSubview:badge];

    FEIconView *lock = [[FEIconView alloc] initWithFrame:CGRectMake(9, 9, 22, 22) iconType:FEIconTypeLock];
    lock.tintColor = [FETheme primary];
    [badge addSubview:lock];

    UILabel *tipTitle = [[UILabel alloc] initWithFrame:CGRectMake(68, 16, cardWidth - 84, 20)];
    tipTitle.text = @"手动 Cookie 登录";
    tipTitle.font = [UIFont boldSystemFontOfSize:14];
    tipTitle.textColor = [FETheme textPrimary];
    [tipCard addSubview:tipTitle];

    UILabel *tipText = [[UILabel alloc] initWithFrame:CGRectMake(68, 36, cardWidth - 84, 50)];
    tipText.text = @"本应用不内置网页登录（iPhone 4S 性能有限），请从浏览器登录后复制 Cookie 粘贴到下方。";
    tipText.numberOfLines = 0;
    tipText.font = [UIFont systemFontOfSize:11];
    tipText.textColor = [FETheme textSecondary];
    [tipCard addSubview:tipText];

    UIView *inputCard = [[UIView alloc] initWithFrame:CGRectMake(12, 108, cardWidth, 170)];
    [FETheme applyCardStyle:inputCard radius:18];
    [self.scrollView addSubview:inputCard];

    UILabel *inputTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, cardWidth - 32, 18)];
    inputTitle.text = @"Cookie 内容";
    inputTitle.font = [UIFont boldSystemFontOfSize:12];
    inputTitle.textColor = [FETheme textPrimary];
    [inputCard addSubview:inputTitle];

    self.cookieTextView = [[UITextView alloc] initWithFrame:CGRectMake(12, 34, cardWidth - 24, 124)];
    self.cookieTextView.backgroundColor = [FETheme background];
    self.cookieTextView.layer.cornerRadius = 12;
    self.cookieTextView.font = [UIFont systemFontOfSize:11.5];
    self.cookieTextView.textColor = [FETheme textPrimary];
    self.cookieTextView.delegate = self;
    self.cookieTextView.keyboardType = UIKeyboardTypeASCIICapable;
    self.cookieTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.cookieTextView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.cookieTextView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    [inputCard addSubview:self.cookieTextView];

    self.placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 42, cardWidth - 40, 34)];
    self.placeholderLabel.text = @"例如：MUSIC_U=xxxx; __csrf=xxxx;\n格式：key1=value1; key2=value2";
    self.placeholderLabel.numberOfLines = 2;
    self.placeholderLabel.font = [UIFont systemFontOfSize:11];
    self.placeholderLabel.textColor = [FETheme colorWithHex:0xB9BECD alpha:1.0];
    self.placeholderLabel.userInteractionEnabled = NO;
    [inputCard addSubview:self.placeholderLabel];

    self.saveButton = [FETheme primaryButtonWithTitle:@"保存并登录"];
    self.saveButton.frame = CGRectMake(12, 290, cardWidth, 44);
    [self.saveButton addTarget:self action:@selector(saveTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.saveButton];

    UIView *stepsCard = [[UIView alloc] initWithFrame:CGRectMake(12, 350, cardWidth, 150)];
    [FETheme applyCardStyle:stepsCard radius:18];
    [self.scrollView addSubview:stepsCard];

    UILabel *stepsTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 14, cardWidth - 32, 18)];
    stepsTitle.text = @"如何获取 Cookie";
    stepsTitle.font = [UIFont boldSystemFontOfSize:12];
    stepsTitle.textColor = [FETheme textPrimary];
    [stepsCard addSubview:stepsTitle];

    UILabel *steps = [[UILabel alloc] initWithFrame:CGRectMake(16, 38, cardWidth - 32, 100)];
    steps.numberOfLines = 0;
    steps.font = [UIFont systemFontOfSize:11];
    steps.textColor = [FETheme textSecondary];
    steps.text = @"1. 在电脑浏览器登录 music.163.com\n2. 打开开发者工具 → Network → 任意请求\n3. 复制请求头中的 Cookie 整段内容\n4. 粘贴到上方输入框并保存\n\nCookie 仅保存在本机，不会上传。";
    [stepsCard addSubview:steps];

    self.scrollView.contentSize = CGSizeMake(width, 520);
}

- (void)textViewDidChange:(UITextView *)textView {
    self.placeholderLabel.hidden = textView.text.length > 0;
}

- (void)keyboardWillChange:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat overlap = MAX(0, self.view.bounds.size.height - keyboardFrame.origin.y);
    self.scrollView.contentInset = UIEdgeInsetsMake(12, 0, overlap + 20, 0);
}

- (void)saveTapped {
    [self.view endEditing:YES];
    NSString *cookieStr = [self.cookieTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (cookieStr.length == 0) {
        [FETheme showToast:@"请先粘贴 Cookie" inView:self.view];
        return;
    }

    NSMutableDictionary *cookies = [NSMutableDictionary dictionary];
    NSArray *pairs = [cookieStr componentsSeparatedByString:@";"];
    for (NSString *pair in pairs) {
        NSRange eq = [pair rangeOfString:@"="];
        if (eq.location == NSNotFound) continue;
        NSString *key = [[pair substringToIndex:eq.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *value = [[pair substringFromIndex:eq.location + 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (key.length > 0) cookies[key] = value;
    }

    if (cookies.count == 0) {
        [FETheme showToast:@"Cookie 格式不正确，应为 key=value; key2=value2" inView:self.view];
        return;
    }

    if ([self.provider respondsToSelector:@selector(handleLoginCookies:)]) {
        [self.provider handleLoginCookies:cookies];
    }

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"登录信息已保存"
                                                   message:[NSString stringWithFormat:@"已保存 %lu 个 Cookie 字段", (unsigned long)cookies.count]
                                                      delegate:self
                                             cancelButtonTitle:nil
                                             otherButtonTitles:@"完成", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
