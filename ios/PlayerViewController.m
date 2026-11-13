#import "PlayerViewController.h"
#import "FETheme.h"
#import "FEImageView.h"
#import "FEIconView.h"
#import "FEPlayerManager.h"
#import "FELyricsManager.h"
#import "FELyricLine.h"
#import "FEProviderManager.h"
#import "FEFavoriteManager.h"
#import "FECurrentPlaylistViewController.h"
#import "FESettings.h"
#import <math.h>

@interface PlayerViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) FEGradientView *backgroundView;
@property (nonatomic, strong) FECoverView *coverView;
@property (nonatomic, strong) UIView *vinylRing;
@property (nonatomic, strong) UIView *vinylCenter;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *artistLabel;
@property (nonatomic, strong) UILabel *lyricLabel;
@property (nonatomic, strong) UILabel *sourceLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UISlider *progressSlider;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *qualityButton;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *prevButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *favoriteButton;
@property (nonatomic, strong) UIButton *playlistButton;
@property (nonatomic, assign) BOOL isSeeking;

@property (nonatomic, strong) UIView *lyricsPage;
@property (nonatomic, strong) UIScrollView *lyricsScroll;
@property (nonatomic, strong) NSMutableArray<UILabel *> *lyricsLineLabels;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *lyricsLineIndexes;
@property (nonatomic, strong) UILabel *lyricsHint;
@property (nonatomic, assign) BOOL showingLyrics;
@property (nonatomic, assign) BOOL landscapeLayout;
@property (nonatomic, assign) NSInteger renderedLyricCount;
@property (nonatomic, assign) NSInteger lastHighlightedLyricIndex;
@property (nonatomic, assign) CGFloat lastLyricScrollOffset;

@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [FETheme colorWithHex:0x160F2A alpha:1.0];

    self.backgroundView = [[FEGradientView alloc] initWithFrame:self.view.bounds];
    self.backgroundView.colors = [FETheme darkGradientColors];
    [self.view addSubview:self.backgroundView];

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.scrollView];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
    self.closeButton.layer.cornerRadius = 18;
    [self.closeButton setImage:[FEIconView imageWithType:FEIconTypeChevronDown size:CGSizeMake(18, 18) color:[UIColor whiteColor]] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.closeButton];

    self.qualityButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.qualityButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
    self.qualityButton.layer.cornerRadius = 12;
    self.qualityButton.titleLabel.font = [UIFont boldSystemFontOfSize:10.5];
    [self.qualityButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.9] forState:UIControlStateNormal];
    [self.qualityButton addTarget:self action:@selector(qualityTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.qualityButton];
    [self refreshQualityButton];

    self.sourceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.sourceLabel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
    self.sourceLabel.layer.cornerRadius = 12;
    self.sourceLabel.layer.masksToBounds = YES;
    self.sourceLabel.textAlignment = NSTextAlignmentCenter;
    self.sourceLabel.font = [UIFont boldSystemFontOfSize:10.5];
    self.sourceLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.85];
    [self.scrollView addSubview:self.sourceLabel];

    self.coverView = [[FECoverView alloc] initWithFrame:CGRectZero];
    [self.coverView setCornerRadius:22];
    self.coverView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.coverView.layer.shadowOpacity = 0.5;
    self.coverView.layer.shadowRadius = 22;
    self.coverView.layer.shadowOffset = CGSizeMake(0, 12);
    self.coverView.layer.masksToBounds = NO;
    self.coverView.imageView.layer.cornerRadius = 22;
    self.coverView.imageView.layer.masksToBounds = YES;
    [self.scrollView addSubview:self.coverView];

    self.vinylRing = [[UIView alloc] initWithFrame:CGRectZero];
    self.vinylRing.backgroundColor = [UIColor clearColor];
    self.vinylRing.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.28].CGColor;
    self.vinylRing.layer.borderWidth = 2;
    self.vinylRing.userInteractionEnabled = NO;
    self.vinylRing.hidden = YES;
    [self.coverView addSubview:self.vinylRing];

    self.vinylCenter = [[UIView alloc] initWithFrame:CGRectZero];
    self.vinylCenter.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
    self.vinylCenter.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.25].CGColor;
    self.vinylCenter.layer.borderWidth = 3;
    self.vinylCenter.userInteractionEnabled = NO;
    self.vinylCenter.hidden = YES;
    [self.coverView addSubview:self.vinylCenter];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:19];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.scrollView addSubview:self.titleLabel];

    self.artistLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.artistLabel.textAlignment = NSTextAlignmentCenter;
    self.artistLabel.font = [UIFont systemFontOfSize:12];
    self.artistLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.62];
    [self.scrollView addSubview:self.artistLabel];

    self.lyricLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.lyricLabel.textAlignment = NSTextAlignmentCenter;
    self.lyricLabel.font = [UIFont systemFontOfSize:12];
    self.lyricLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.85];
    self.lyricLabel.numberOfLines = 2;
    self.lyricLabel.text = @"暂无歌词";
    [self.scrollView addSubview:self.lyricLabel];

    self.progressSlider = [[UISlider alloc] initWithFrame:CGRectZero];
    self.progressSlider.minimumTrackTintColor = [FETheme secondary];
    self.progressSlider.maximumTrackTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18];
    [self.progressSlider setThumbImage:[self thumbImage] forState:UIControlStateNormal];
    [self.progressSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.progressSlider addTarget:self action:@selector(sliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [self.scrollView addSubview:self.progressSlider];

    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.font = [UIFont systemFontOfSize:10];
    self.timeLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.55];
    self.timeLabel.text = @"00:00 / 00:00";
    [self.scrollView addSubview:self.timeLabel];

    self.favoriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.favoriteButton setImage:[FEIconView imageWithType:FEIconTypeHeart size:CGSizeMake(20, 20) color:[[UIColor whiteColor] colorWithAlphaComponent:0.7]] forState:UIControlStateNormal];
    [self.favoriteButton addTarget:self action:@selector(favoriteTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.favoriteButton];

    self.prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.prevButton setImage:[FEIconView imageWithType:FEIconTypePrev size:CGSizeMake(24, 24) color:[[UIColor whiteColor] colorWithAlphaComponent:0.9]] forState:UIControlStateNormal];
    [self.prevButton addTarget:self action:@selector(prevTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.prevButton];

    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playButton.backgroundColor = [UIColor whiteColor];
    [self.playButton addTarget:self action:@selector(playTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.playButton];

    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.nextButton setImage:[FEIconView imageWithType:FEIconTypeNext size:CGSizeMake(24, 24) color:[[UIColor whiteColor] colorWithAlphaComponent:0.9]] forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(nextTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.nextButton];

    self.playlistButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playlistButton setImage:[FEIconView imageWithType:FEIconTypePlaylist size:CGSizeMake(20, 20) color:[[UIColor whiteColor] colorWithAlphaComponent:0.7]] forState:UIControlStateNormal];
    [self.playlistButton addTarget:self action:@selector(playlistTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.playlistButton];

    [self buildLyricsPage];

    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeft];

    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(handleTrackChanged:) name:FEPlayerDidChangeTrackNotification object:nil];
    [center addObserver:self selector:@selector(handleStateChanged:) name:FEPlayerDidChangeStateNotification object:nil];
    [center addObserver:self selector:@selector(handleTimeUpdated:) name:FEPlayerDidUpdateTimeNotification object:nil];

    [self updateUI];
}

- (void)buildLyricsPage {
    self.lyricsLineLabels = [NSMutableArray array];
    self.lyricsLineIndexes = [NSMutableArray array];
    self.renderedLyricCount = -1;
    self.lastHighlightedLyricIndex = -1;
    self.lastLyricScrollOffset = -1;

    // 歌词区域不再使用半透明底板，直接叠在渐变背景上
    self.lyricsPage = [[UIView alloc] initWithFrame:CGRectZero];
    self.lyricsPage.backgroundColor = [UIColor clearColor];
    self.lyricsPage.layer.cornerRadius = 20;
    self.lyricsPage.layer.masksToBounds = YES;
    self.lyricsPage.hidden = YES;
    [self.scrollView addSubview:self.lyricsPage];

    self.lyricsHint = [[UILabel alloc] initWithFrame:CGRectZero];
    self.lyricsHint.text = @"歌词 · 右滑回到封面";
    self.lyricsHint.font = [UIFont systemFontOfSize:10];
    self.lyricsHint.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.45];
    self.lyricsHint.textAlignment = NSTextAlignmentCenter;
    [self.lyricsPage addSubview:self.lyricsHint];

    self.lyricsScroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.lyricsScroll.showsVerticalScrollIndicator = NO;
    [self.lyricsPage addSubview:self.lyricsScroll];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self layoutForSize:self.view.bounds.size];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Layout

- (void)layoutForSize:(CGSize)size {
    self.backgroundView.frame = self.view.bounds;
    self.scrollView.frame = self.view.bounds;

    BOOL landscape = size.width > size.height;
    self.landscapeLayout = landscape;
    CGFloat width = size.width;
    CGFloat height = size.height;

    self.closeButton.frame = CGRectMake(10, landscape ? 10 : 18, 36, 36);
    self.qualityButton.frame = CGRectMake(width - 10 - 58, landscape ? 12 : 20, 58, 24);
    self.sourceLabel.frame = CGRectMake((width - 100) / 2, landscape ? 14 : 24, 100, 24);

    if (landscape) {
        // 横屏只保留“黑胶 + 右侧歌词”这一种模式
        if (self.showingLyrics) self.showingLyrics = NO;

        CGFloat coverSide = MIN(height - 132, 190);
        CGFloat coverX = 20;
        CGFloat coverY = MAX(58, (height - coverSide) / 2 - 2);
        self.coverView.frame = CGRectMake(coverX, coverY, coverSide, coverSide);

        CGFloat rightX = coverX + coverSide + 18;
        CGFloat rightWidth = width - rightX - 16;

        self.titleLabel.frame = CGRectMake(rightX, 34, rightWidth, 22);
        self.artistLabel.frame = CGRectMake(rightX, 58, rightWidth, 16);

        CGFloat sliderY = height - 108;
        self.progressSlider.frame = CGRectMake(rightX, sliderY, rightWidth, 22);
        self.timeLabel.frame = CGRectMake(rightX, sliderY + 23, rightWidth, 12);

        CGFloat rowY = height - 62;
        [self layoutControlRowWithCenterX:rightX + rightWidth / 2 y:rowY compact:YES];

        // 歌词面板占满右半屏（进度条以上），可显示 6~8 行
        self.lyricsPage.frame = CGRectMake(rightX - 4, 80, rightWidth + 8, MAX(60, sliderY - 86));
        self.scrollView.contentSize = CGSizeMake(width, height);
    } else {
        CGFloat safeHeight = height > 0 ? height : 480;
        CGFloat coverSide = MIN(width - 130, safeHeight - 300);
        coverSide = MAX(120, coverSide);
        CGFloat coverY = 56;
        self.coverView.frame = CGRectMake((width - coverSide) / 2, coverY, coverSide, coverSide);

        CGFloat y = coverY + coverSide + 6;
        self.titleLabel.frame = CGRectMake(20, y, width - 40, 24);
        self.artistLabel.frame = CGRectMake(20, y + 26, width - 40, 18);
        self.lyricLabel.frame = CGRectMake(20, y + 46, width - 40, 32);

        self.progressSlider.frame = CGRectMake(28, y + 80, width - 56, 24);
        self.timeLabel.frame = CGRectMake(28, y + 106, width - 56, 14);

        CGFloat rowY = y + 124;
        [self layoutControlRowWithCenterX:width / 2 y:rowY compact:NO];

        self.lyricsPage.frame = CGRectMake(12, 52, width - 24, MAX(90, (y + 78) - 58));
        self.scrollView.contentSize = CGSizeMake(width, MAX(height, rowY + 70));
    }

    [self applyCoverShapeForLandscape:landscape];
    [self applyContentVisibilityForLandscape:landscape];
    [self layoutLyricsPageContents];
    [self updateRotationState];
}

- (void)applyContentVisibilityForLandscape:(BOOL)landscape {
    if (landscape) {
        self.coverView.hidden = NO;
        self.titleLabel.hidden = NO;
        self.artistLabel.hidden = NO;
        self.lyricLabel.hidden = YES;
        self.lyricsPage.hidden = NO;
        self.progressSlider.hidden = NO;
        self.timeLabel.hidden = NO;
        self.lyricsHint.text = @"歌词";
    } else {
        BOOL show = self.showingLyrics;
        self.coverView.hidden = show;
        self.titleLabel.hidden = show;
        self.artistLabel.hidden = show;
        self.lyricLabel.hidden = show;
        self.lyricsPage.hidden = !show;
        self.progressSlider.hidden = NO;
        self.timeLabel.hidden = NO;
        self.lyricsHint.text = @"歌词 · 右滑回到封面";
    }
}

- (void)layoutControlRowWithCenterX:(CGFloat)centerX y:(CGFloat)y compact:(BOOL)compact {
    CGFloat small = compact ? 30 : 38;
    CGFloat side = compact ? 34 : 44;
    CGFloat play = compact ? 48 : 60;
    CGFloat gap = compact ? 4 : 8;

    CGFloat total = small + side + play + side + small + gap * 4;
    CGFloat x = centerX - total / 2;

    self.favoriteButton.frame = CGRectMake(x, y + (play - small) / 2, small, small);
    x += small + gap;
    self.prevButton.frame = CGRectMake(x, y + (play - side) / 2, side, side);
    x += side + gap;
    self.playButton.frame = CGRectMake(x, y, play, play);
    self.playButton.layer.cornerRadius = play / 2;
    x += play + gap;
    self.nextButton.frame = CGRectMake(x, y + (play - side) / 2, side, side);
    x += side + gap;
    self.playlistButton.frame = CGRectMake(x, y + (play - small) / 2, small, small);
}

- (void)applyCoverShapeForLandscape:(BOOL)landscape {
    CGFloat side = self.coverView.bounds.size.width;
    if (side <= 1) return;

    if (landscape) {
        // 圆形黑胶：必须 masksToBounds，否则方形的底色会露出来
        [self.coverView setCornerRadius:side / 2];
        self.coverView.layer.masksToBounds = YES;
        self.coverView.imageView.layer.cornerRadius = side / 2;
        self.coverView.layer.shadowOpacity = 0;
        self.vinylRing.hidden = NO;
        self.vinylCenter.hidden = NO;

        self.vinylRing.frame = CGRectMake(5, 5, side - 10, side - 10);
        self.vinylRing.layer.cornerRadius = (side - 10) / 2;
        self.vinylCenter.frame = CGRectMake((side - 22) / 2, (side - 22) / 2, 22, 22);
        self.vinylCenter.layer.cornerRadius = 11;
    } else {
        [self.coverView setCornerRadius:22];
        self.coverView.layer.masksToBounds = NO;
        self.coverView.imageView.layer.cornerRadius = 22;
        self.coverView.layer.shadowOpacity = 0.5;
        self.coverView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.coverView.bounds cornerRadius:22].CGPath;
        self.vinylRing.hidden = YES;
        self.vinylCenter.hidden = YES;
        [self.coverView.layer removeAnimationForKey:@"vinylSpin"];
    }
}

- (void)layoutLyricsPageContents {
    self.lyricsHint.frame = CGRectMake(0, 8, self.lyricsPage.bounds.size.width, 16);
    self.lyricsScroll.frame = CGRectMake(0, 28, self.lyricsPage.bounds.size.width, MAX(40, self.lyricsPage.bounds.size.height - 34));
    [self layoutLyricsText];
}

#pragma mark - Lyrics / Cover switch

- (void)swipeLeft:(UISwipeGestureRecognizer *)gesture {
    [self showLyrics:YES];
}

- (void)swipeRight:(UISwipeGestureRecognizer *)gesture {
    [self showLyrics:NO];
}

- (void)showLyrics:(BOOL)show {
    // 横屏只保留“带封面”的播放模式，不支持纯歌词页
    if (self.landscapeLayout) return;
    if (self.showingLyrics == show) return;
    self.showingLyrics = show;

    [self applyContentVisibilityForLandscape:NO];

    if (show) {
        [self layoutLyricsPageContents];
        [self scrollLyricsToCurrentLine:NO];
    }
    [self updateRotationState];
}

- (void)rebuildLyricLineLabels {
    for (UILabel *label in self.lyricsLineLabels) {
        [label removeFromSuperview];
    }
    [self.lyricsLineLabels removeAllObjects];
    [self.lyricsLineIndexes removeAllObjects];

    NSArray<FELyricLine *> *lines = [FELyricsManager sharedManager].lines;
    for (NSInteger i = 0; i < (NSInteger)lines.count; i++) {
        NSString *text = lines[i].text;
        if (text.length == 0) continue;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.text = text;
        [self.lyricsScroll addSubview:label];
        [self.lyricsLineLabels addObject:label];
        [self.lyricsLineIndexes addObject:@(i)];
    }

    if (self.lyricsLineLabels.count == 0) {
        UILabel *placeholder = [[UILabel alloc] initWithFrame:CGRectZero];
        placeholder.numberOfLines = 0;
        placeholder.textAlignment = NSTextAlignmentCenter;
        placeholder.text = @"暂无歌词";
        placeholder.font = [UIFont systemFontOfSize:13];
        placeholder.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.45];
        [self.lyricsScroll addSubview:placeholder];
        [self.lyricsLineLabels addObject:placeholder];
        [self.lyricsLineIndexes addObject:@(-1)];
    }

    NSInteger current = [FELyricsManager sharedManager].currentIndex;
    self.renderedLyricCount = (NSInteger)lines.count;
    self.lastHighlightedLyricIndex = current;
    self.lastLyricScrollOffset = -1;
    [self applyLyricHighlightForIndex:current];
    [self layoutLyricLineLabels];
}

/// 只改当前行的字体/颜色，其余行保持半透明，确保高亮一定可见
- (void)applyLyricHighlightForIndex:(NSInteger)index {
    CGFloat normalSize = self.landscapeLayout ? 14.0 : 13.5;
    for (NSUInteger k = 0; k < self.lyricsLineLabels.count; k++) {
        UILabel *label = self.lyricsLineLabels[k];
        NSInteger lineIndex = self.lyricsLineIndexes[k].integerValue;
        if (lineIndex < 0) {
            label.font = [UIFont systemFontOfSize:normalSize];
            label.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.45];
            continue;
        }
        if (index >= 0 && lineIndex == index) {
            label.font = [UIFont boldSystemFontOfSize:normalSize + 2];
            label.textColor = [UIColor whiteColor];
        } else {
            label.font = [UIFont systemFontOfSize:normalSize];
            label.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.42];
        }
    }
}

- (void)layoutLyricLineLabels {
    CGFloat scrollWidth = self.lyricsScroll.bounds.size.width;
    if (scrollWidth <= 1) return;
    CGFloat width = MAX(60, scrollWidth - 24);
    CGFloat y = 14;
    for (UILabel *label in self.lyricsLineLabels) {
        CGSize fit = [label sizeThatFits:CGSizeMake(width, MAXFLOAT)];
        CGFloat lineHeight = ceil(fit.height) + 8;
        label.frame = CGRectMake(12, y, width, lineHeight);
        y += lineHeight;
    }
    self.lyricsScroll.contentSize = CGSizeMake(scrollWidth, MAX(y + 14, self.lyricsScroll.bounds.size.height));
}

- (void)layoutLyricsText {
    NSInteger count = (NSInteger)[FELyricsManager sharedManager].lines.count;
    if (count != self.renderedLyricCount || self.lyricsLineLabels.count == 0) {
        [self rebuildLyricLineLabels];
    } else {
        [self applyLyricHighlightForIndex:[FELyricsManager sharedManager].currentIndex];
        [self layoutLyricLineLabels];
    }
}

- (void)updateLyricsHighlightIfNeeded {
    NSInteger current = [FELyricsManager sharedManager].currentIndex;
    if (current == self.lastHighlightedLyricIndex) return;
    self.lastHighlightedLyricIndex = current;
    [self applyLyricHighlightForIndex:current];
    [self layoutLyricLineLabels];
}

- (void)scrollLyricsToCurrentLine:(BOOL)animated {
    NSInteger index = [FELyricsManager sharedManager].currentIndex;
    if (index < 0) return;
    NSUInteger position = [self.lyricsLineIndexes indexOfObject:@(index)];
    if (position == NSNotFound || position >= self.lyricsLineLabels.count) return;
    UILabel *label = self.lyricsLineLabels[position];
    CGFloat offset = CGRectGetMidY(label.frame) - self.lyricsScroll.bounds.size.height / 2;
    CGFloat maxOffset = MAX(0, self.lyricsScroll.contentSize.height - self.lyricsScroll.bounds.size.height);
    offset = MAX(0, MIN(offset, maxOffset));
    if (fabs(offset - self.lastLyricScrollOffset) < 4) return;
    self.lastLyricScrollOffset = offset;
    [self.lyricsScroll setContentOffset:CGPointMake(0, offset) animated:animated];
}

#pragma mark - Vinyl rotation

- (void)updateRotationState {
    BOOL shouldSpin = self.landscapeLayout && [FEPlayerManager sharedManager].isPlaying && !self.showingLyrics;
    CALayer *layer = self.coverView.layer;
    if (shouldSpin) {
        if ([layer animationForKey:@"vinylSpin"] == nil) {
            CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
            spin.fromValue = @0;
            spin.toValue = @(M_PI * 2);
            spin.duration = 18.0;
            spin.repeatCount = HUGE_VALF;
            spin.removedOnCompletion = NO;
            [layer addAnimation:spin forKey:@"vinylSpin"];
        }
    } else {
        [layer removeAnimationForKey:@"vinylSpin"];
    }
}

#pragma mark - Rotation

- (BOOL)shouldAutorotate {
    return [FESettings sharedSettings].landscapePlayer;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([FESettings sharedSettings].landscapePlayer) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIImage *)thumbImage {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(12, 12), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, 12, 12));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - UI

- (void)refreshQualityButton {
    NSString *title = [FESettings qualityTitle:[FESettings sharedSettings].preferredQuality];
    [self.qualityButton setTitle:title forState:UIControlStateNormal];
}

- (void)updateUI {
    FEPlayerManager *manager = [FEPlayerManager sharedManager];
    FETrack *track = manager.currentTrack;
    self.titleLabel.text = track.title ?: @"未知歌曲";

    NSString *sourceName = @"本地音乐";
    for (id<FEProviderProtocol> provider in [FEProviderManager sharedManager].providers) {
        if ([provider.providerId isEqualToString:track.providerId]) {
            sourceName = provider.providerName;
            break;
        }
    }
    NSString *artist = track.artist.length > 0 ? track.artist : @"未知艺术家";
    self.artistLabel.text = [NSString stringWithFormat:@"%@ · %@", artist, sourceName];
    self.sourceLabel.text = sourceName;

    [self.coverView setImageURL:track.coverUrl];
    [self refreshQualityButton];
    [self updateFavoriteButton];

    [self updatePlayIcon:manager.isPlaying];
    if (track == nil) {
        self.lyricLabel.text = @"暂无歌词";
    }
    [self updateTimeWithCurrent:manager.currentTime duration:manager.duration];
}

- (void)updateFavoriteButton {
    FETrack *track = [FEPlayerManager sharedManager].currentTrack;
    BOOL fav = [[FEFavoriteManager sharedManager] isFavorite:track];
    UIColor *color = fav ? [FETheme secondary] : [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    [self.favoriteButton setImage:[FEIconView imageWithType:FEIconTypeHeart size:CGSizeMake(20, 20) color:color] forState:UIControlStateNormal];
}

- (void)updatePlayIcon:(BOOL)playing {
    UIImage *icon = [FEIconView imageWithType:(playing ? FEIconTypePause : FEIconTypePlay)
                                        size:CGSizeMake(24, 24)
                                       color:[FETheme primary]
                                   lineWidth:2.0];
    [self.playButton setImage:icon forState:UIControlStateNormal];
}

- (void)updateTimeWithCurrent:(NSTimeInterval)current duration:(NSTimeInterval)duration {
    if (duration > 0 && !self.isSeeking) {
        self.progressSlider.value = (float)(current / duration);
    }
    self.timeLabel.text = [NSString stringWithFormat:@"%@ / %@", [self formatTime:current], [self formatTime:duration]];

    FELyricLine *line = [[FELyricsManager sharedManager] currentLineForTime:current];
    if (line.text.length > 0) {
        self.lyricLabel.text = line.text;
    } else if (line == nil) {
        self.lyricLabel.text = @"暂无歌词";
    }

    if (self.showingLyrics || self.landscapeLayout) {
        NSInteger count = (NSInteger)[FELyricsManager sharedManager].lines.count;
        if (count != self.renderedLyricCount) {
            [self layoutLyricsText];
        } else {
            [self updateLyricsHighlightIfNeeded];
        }
        [self scrollLyricsToCurrentLine:NO];
    }
}

- (NSString *)formatTime:(NSTimeInterval)time {
    if (!isfinite(time) || time < 0) time = 0;
    int minutes = (int)time / 60;
    int seconds = (int)time % 60;
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

#pragma mark - Notification

- (void)handleTrackChanged:(NSNotification *)notification {
    self.renderedLyricCount = -1;
    [self updateUI];
    [self updateRotationState];
}

- (void)handleStateChanged:(NSNotification *)notification {
    [self updatePlayIcon:[FEPlayerManager sharedManager].isPlaying];
    [self updateRotationState];
}

- (void)handleTimeUpdated:(NSNotification *)notification {
    if (self.isSeeking) return;
    NSNumber *current = notification.userInfo[@"currentTime"];
    NSNumber *duration = notification.userInfo[@"duration"];
    [self updateTimeWithCurrent:current.doubleValue duration:duration.doubleValue];
}

#pragma mark - Actions

- (void)closeTapped {
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        // 退出播放页后回到竖屏，避免外部页面停留在横屏
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
        [UIViewController attemptRotationToDeviceOrientation];
    }];
}

- (void)playTapped {
    [[FEPlayerManager sharedManager] toggle];
}

- (void)prevTapped {
    [[FEPlayerManager sharedManager] previous];
}

- (void)nextTapped {
    [[FEPlayerManager sharedManager] next];
}

- (void)favoriteTapped {
    FETrack *track = [FEPlayerManager sharedManager].currentTrack;
    if (track == nil) return;
    [[FEFavoriteManager sharedManager] toggleFavorite:track completion:^(BOOL isFavorite, BOOL success) {
        [self updateFavoriteButton];
        if (success) {
            [FETheme showToast:isFavorite ? @"已收藏" : @"已取消收藏" inView:self.view];
        }
    }];
}

- (void)playlistTapped {
    FECurrentPlaylistViewController *vc = [[FECurrentPlaylistViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)qualityTapped {
    NSInteger current = [FESettings sharedSettings].preferredQuality;
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"优先播放音质"
                                                                   message:@"有该音质时优先播放，否则自动降级（下一首生效）"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSInteger i = 0; i < 3; i++) {
        NSString *title = [NSString stringWithFormat:@"%@ · %@", [FESettings qualityTitle:i], [FESettings qualityDetail:i]];
        if (i == current) title = [title stringByAppendingString:@" ✓"];
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [FESettings sharedSettings].preferredQuality = i;
            [[FESettings sharedSettings] save];
            [self refreshQualityButton];
            [FETheme showToast:[NSString stringWithFormat:@"优先音质：%@", [FESettings qualityTitle:i]] inView:self.view];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)sliderValueChanged:(UISlider *)slider {
    self.isSeeking = YES;
    NSTimeInterval duration = [FEPlayerManager sharedManager].duration;
    NSTimeInterval current = duration * slider.value;
    self.timeLabel.text = [NSString stringWithFormat:@"%@ / %@", [self formatTime:current], [self formatTime:duration]];
}

- (void)sliderTouchEnded:(UISlider *)slider {
    [[FEPlayerManager sharedManager] seekToProgress:slider.value];
    self.isSeeking = NO;
}

@end
