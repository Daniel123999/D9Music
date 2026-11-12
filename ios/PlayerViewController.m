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
@property (nonatomic, strong) UILabel *lyricsLabel;
@property (nonatomic, strong) UILabel *lyricsHint;
@property (nonatomic, assign) BOOL showingLyrics;
@property (nonatomic, assign) BOOL landscapeLayout;
@property (nonatomic, assign) NSInteger renderedLyricCount;
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
    self.lyricsPage = [[UIView alloc] initWithFrame:CGRectZero];
    self.lyricsPage.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.06];
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

    self.lyricsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.lyricsLabel.numberOfLines = 0;
    self.lyricsLabel.font = [UIFont systemFontOfSize:13];
    self.lyricsLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.82];
    self.lyricsLabel.textAlignment = NSTextAlignmentCenter;
    self.lyricsLabel.text = @"暂无歌词";
    [self.lyricsScroll addSubview:self.lyricsLabel];
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
        CGFloat coverSide = MIN(height - 108, 200);
        CGFloat coverX = 24;
        CGFloat coverY = MAX(52, (height - coverSide) / 2 - 4);
        self.coverView.frame = CGRectMake(coverX, coverY, coverSide, coverSide);

        CGFloat rightX = coverX + coverSide + 20;
        CGFloat rightWidth = width - rightX - 16;

        self.titleLabel.frame = CGRectMake(rightX, 44, rightWidth, 24);
        self.artistLabel.frame = CGRectMake(rightX, 69, rightWidth, 18);
        self.lyricLabel.frame = CGRectMake(rightX, 90, rightWidth, 34);

        self.progressSlider.frame = CGRectMake(rightX, 138, rightWidth, 24);
        self.timeLabel.frame = CGRectMake(rightX, 164, rightWidth, 14);

        CGFloat rowY = MIN(190, height - 118);
        [self layoutControlRowWithCenterX:rightX + rightWidth / 2 y:rowY compact:YES];

        self.lyricsPage.frame = CGRectMake(16, 46, width - 32, MAX(90, rowY - 54));
        self.scrollView.contentSize = CGSizeMake(width, MAX(height, rowY + 64));
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
    [self layoutLyricsPageContents];
    [self updateRotationState];
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
        self.coverView.layer.cornerRadius = side / 2;
        self.coverView.imageView.layer.cornerRadius = side / 2;
        self.coverView.layer.shadowOpacity = 0.38;
        self.coverView.layer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:self.coverView.bounds].CGPath;
        self.vinylRing.hidden = NO;
        self.vinylCenter.hidden = NO;

        self.vinylRing.frame = CGRectMake(6, 6, side - 12, side - 12);
        self.vinylRing.layer.cornerRadius = (side - 12) / 2;
        self.vinylCenter.frame = CGRectMake((side - 22) / 2, (side - 22) / 2, 22, 22);
        self.vinylCenter.layer.cornerRadius = 11;
    } else {
        self.coverView.layer.cornerRadius = 22;
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
    if (self.showingLyrics == show) return;
    self.showingLyrics = show;

    self.coverView.hidden = show;
    self.titleLabel.hidden = show;
    self.artistLabel.hidden = show;
    self.lyricLabel.hidden = show;
    self.progressSlider.hidden = show && self.landscapeLayout;
    self.timeLabel.hidden = show && self.landscapeLayout;
    self.lyricsPage.hidden = !show;

    if (show) {
        [self layoutLyricsPageContents];
        [self scrollLyricsToCurrentLine:NO];
    }
    [self updateRotationState];
}

- (void)layoutLyricsText {
    NSArray<FELyricLine *> *lines = [FELyricsManager sharedManager].lines;
    NSMutableArray *texts = [NSMutableArray array];
    for (FELyricLine *line in lines) {
        if (line.text.length > 0) [texts addObject:line.text];
    }
    NSString *text = texts.count > 0 ? [texts componentsJoinedByString:@"\n"] : @"暂无歌词";
    self.lyricsLabel.text = text;
    self.lyricsLabel.font = [UIFont systemFontOfSize:self.landscapeLayout ? 14 : 13];

    CGFloat width = MAX(60, self.lyricsScroll.bounds.size.width - 24);
    CGSize fit = [text boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                    options:NSStringDrawingUsesLineFragmentOrigin
                                 attributes:@{NSFontAttributeName: self.lyricsLabel.font}
                                    context:nil].size;
    self.lyricsLabel.frame = CGRectMake(12, 10, width, ceil(fit.height) + 10);
    self.lyricsScroll.contentSize = CGSizeMake(self.lyricsScroll.bounds.size.width, self.lyricsLabel.frame.size.height + 20);
    self.renderedLyricCount = (NSInteger)lines.count;
    self.lastLyricScrollOffset = -1;
}

- (void)scrollLyricsToCurrentLine:(BOOL)animated {
    NSInteger index = [FELyricsManager sharedManager].currentIndex;
    if (index < 0) return;
    CGFloat lineHeight = self.lyricsLabel.font.lineHeight;
    CGFloat offset = index * lineHeight + 10 - self.lyricsScroll.bounds.size.height / 2 + lineHeight / 2;
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

    if (self.showingLyrics) {
        NSInteger count = (NSInteger)[FELyricsManager sharedManager].lines.count;
        if (count != self.renderedLyricCount) {
            [self layoutLyricsText];
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
    [self dismissViewControllerAnimated:YES completion:nil];
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
