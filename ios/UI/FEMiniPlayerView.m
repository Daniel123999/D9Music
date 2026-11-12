#import "FEMiniPlayerView.h"
#import "FETheme.h"
#import "FEImageView.h"
#import "FEIconView.h"
#import "FEPlayerManager.h"

@implementation FEMiniPlayerView {
    FECoverView *_coverView;
    UILabel *_titleLabel;
    UILabel *_artistLabel;
    UIButton *_playButton;
    UIButton *_nextButton;
    UIView *_progressTrack;
    UIView *_progressFill;
    CGFloat _progress;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.shadowColor = [UIColor colorWithWhite:0.1 alpha:0.12].CGColor;
        self.layer.shadowOpacity = 1.0;
        self.layer.shadowRadius = 8;
        self.layer.shadowOffset = CGSizeMake(0, -2);

        _coverView = [[FECoverView alloc] initWithFrame:CGRectZero];
        [_coverView setCornerRadius:10];
        [self addSubview:_coverView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont boldSystemFontOfSize:13];
        _titleLabel.textColor = [FETheme textPrimary];
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:_titleLabel];

        _artistLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _artistLabel.font = [UIFont systemFontOfSize:10.5];
        _artistLabel.textColor = [FETheme textSecondary];
        _artistLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:_artistLabel];

        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playButton.tintColor = [FETheme primary];
        _playButton.frame = CGRectZero;
        [_playButton addTarget:self action:@selector(playTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_playButton];

        _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _nextButton.tintColor = [FETheme textPrimary];
        [_nextButton addTarget:self action:@selector(nextTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_nextButton];

        _progressTrack = [[UIView alloc] initWithFrame:CGRectZero];
        _progressTrack.backgroundColor = [FETheme separator];
        [self addSubview:_progressTrack];

        _progressFill = [[UIView alloc] initWithFrame:CGRectZero];
        _progressFill.backgroundColor = [FETheme primary];
        [_progressTrack addSubview:_progressFill];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
        [self addGestureRecognizer:tap];

        self.hidden = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;

    _coverView.frame = CGRectMake(12, (height - 40) / 2 - 1, 40, 40);
    _titleLabel.frame = CGRectMake(62, 12, width - 62 - 100, 17);
    _artistLabel.frame = CGRectMake(62, 31, width - 62 - 100, 14);
    _playButton.frame = CGRectMake(width - 84, (height - 38) / 2 - 1, 38, 38);
    _nextButton.frame = CGRectMake(width - 44, (height - 38) / 2 - 1, 38, 38);
    _progressTrack.frame = CGRectMake(12, height - 3, width - 24, 2);
    _progressFill.frame = CGRectMake(0, 0, _progressTrack.bounds.size.width * _progress, 2);
}

- (void)updateWithTrack:(FETrack *)track playing:(BOOL)playing {
    if (track == nil) {
        self.hidden = YES;
        return;
    }
    self.hidden = NO;
    [_coverView setImageURL:track.coverUrl];
    _titleLabel.text = track.title ?: @"未知歌曲";
    _artistLabel.text = track.artist ?: @"未知艺术家";
    [self updatePlayIcon:playing];
    [self setNeedsLayout];
}

- (void)updatePlayIcon:(BOOL)playing {
    UIImage *image = [FEIconView imageWithType:(playing ? FEIconTypePause : FEIconTypePlay)
                                        size:CGSizeMake(20, 20)
                                       color:[FETheme primary] lineWidth:2.0];
    [_playButton setImage:image forState:UIControlStateNormal];
}

- (void)setProgress:(CGFloat)progress {
    _progress = MAX(0.0, MIN(1.0, progress));
    CGRect frame = _progressFill.frame;
    frame.size.width = _progressTrack.bounds.size.width * _progress;
    _progressFill.frame = frame;
}

- (void)playTapped {
    [[FEPlayerManager sharedManager] toggle];
}

- (void)nextTapped {
    [[FEPlayerManager sharedManager] next];
}

- (void)handleTap {
    if (self.onTap) self.onTap();
}

@end
