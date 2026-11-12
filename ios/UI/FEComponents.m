#import "FEComponents.h"
#import "FETheme.h"
#import "FEImageView.h"
#import "FEPlayerManager.h"

@implementation FECardButton {
    UIView *_iconBadge;
    FECardStyle _style;
}

- (instancetype)initWithFrame:(CGRect)frame
                         icon:(FEIconType)icon
                        title:(NSString *)title
                     subtitle:(NSString *)subtitle
                       accent:(UIColor *)accent
                        style:(FECardStyle)style {
    self = [super initWithFrame:frame];
    if (self) {
        _style = style;
        UIColor *tint = accent ?: [FETheme primary];

        [FETheme applyCardStyle:self radius:18];
        self.backgroundColor = [UIColor whiteColor];

        _iconBadge = [[UIView alloc] initWithFrame:CGRectZero];
        _iconBadge.backgroundColor = [tint colorWithAlphaComponent:0.12];
        _iconBadge.layer.cornerRadius = 12;
        _iconBadge.userInteractionEnabled = NO;
        [self addSubview:_iconBadge];

        _iconView = [[FEIconView alloc] initWithFrame:CGRectZero iconType:icon];
        _iconView.tintColor = tint;
        _iconView.userInteractionEnabled = NO;
        [_iconBadge addSubview:_iconView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.text = title;
        _titleLabel.textColor = [FETheme textPrimary];
        _titleLabel.font = [UIFont boldSystemFontOfSize:(style == FECardStyleTile ? 12.5 : 14.5)];
        _titleLabel.numberOfLines = 1;
        _titleLabel.userInteractionEnabled = NO;
        [self addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subtitleLabel.text = subtitle;
        _subtitleLabel.textColor = [FETheme textSecondary];
        _subtitleLabel.font = [UIFont systemFontOfSize:10.5];
        _subtitleLabel.numberOfLines = 1;
        _subtitleLabel.userInteractionEnabled = NO;
        [self addSubview:_subtitleLabel];
        _subtitleLabel.hidden = (style == FECardStyleTile);
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;

    if (_style == FECardStyleTile) {
        _iconBadge.frame = CGRectMake((width - 36) / 2, 12, 36, 36);
        _iconView.frame = CGRectMake(8, 8, 20, 20);
        _titleLabel.frame = CGRectMake(4, 54, width - 8, 16);
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _subtitleLabel.frame = CGRectZero;
    } else {
        _iconBadge.frame = CGRectMake(14, 12, 38, 38);
        _iconView.frame = CGRectMake(9, 9, 20, 20);
        _titleLabel.frame = CGRectMake(14, 55, width - 24, 19);
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _subtitleLabel.frame = CGRectMake(14, 74, width - 24, 14);
    }

    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:18].CGPath;
    if (height < 1) return;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:0.12 animations:^{
        self.transform = highlighted ? CGAffineTransformMakeScale(0.97, 0.97) : CGAffineTransformIdentity;
        self.alpha = highlighted ? 0.9 : 1.0;
    }];
}

@end

@implementation FESectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title actionTitle:(NSString *)actionTitle {
    self = [super initWithFrame:frame];
    if (self) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.text = title;
        _titleLabel.font = [FETheme sectionFont];
        _titleLabel.textColor = [FETheme textPrimary];
        [self addSubview:_titleLabel];

        _actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _actionButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_actionButton setTitleColor:[FETheme textSecondary] forState:UIControlStateNormal];
        if (actionTitle.length > 0) {
            [_actionButton setTitle:[actionTitle stringByAppendingString:@"  ›"] forState:UIControlStateNormal];
        }
        _actionButton.hidden = (actionTitle.length == 0);
        [self addSubview:_actionButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLabel.frame = CGRectMake(0, 0, self.bounds.size.width - 86, self.bounds.size.height);
    self.actionButton.frame = CGRectMake(self.bounds.size.width - 86, 0, 86, self.bounds.size.height);
    self.actionButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
}

@end

@implementation FETrackCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = [UIColor clearColor];

        _coverView = [[FECoverView alloc] initWithFrame:CGRectZero];
        [_coverView setCornerRadius:12];
        [self.contentView addSubview:_coverView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.textColor = [FETheme textPrimary];
        _titleLabel.font = [UIFont systemFontOfSize:14.5];
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subtitleLabel.textColor = [FETheme textSecondary];
        _subtitleLabel.font = [UIFont systemFontOfSize:11];
        _subtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_subtitleLabel];

        _playIcon = [[FEIconView alloc] initWithFrame:CGRectZero iconType:FEIconTypePlay];
        _playIcon.tintColor = [FETheme primary];
        _playIcon.userInteractionEnabled = NO;
        [self.contentView addSubview:_playIcon];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    self.coverView.frame = CGRectMake(16, (height - 46) / 2, 46, 46);
    self.titleLabel.frame = CGRectMake(74, height / 2 - 20, width - 74 - 48, 20);
    self.subtitleLabel.frame = CGRectMake(74, height / 2 + 2, width - 74 - 48, 16);
    self.playIcon.frame = CGRectMake(width - 40, (height - 20) / 2, 20, 20);
}

- (void)configureWithTrack:(FETrack *)track {
    self.titleLabel.text = track.title ?: @"未知歌曲";
    NSMutableArray *parts = [NSMutableArray array];
    if (track.artist.length > 0) [parts addObject:track.artist];
    if (track.album.length > 0) [parts addObject:track.album];
    if (parts.count == 0) [parts addObject:@"未知艺术家"];
    self.subtitleLabel.text = [parts componentsJoinedByString:@" · "];
    [self.coverView setImageURL:track.coverUrl];
    [self setPlaying:([FEPlayerManager sharedManager].currentTrack.trackId != nil &&
                      [[FEPlayerManager sharedManager].currentTrack.trackId isEqualToString:track.trackId])];
}

- (void)setPlaying:(BOOL)playing {
    self.playIcon.iconType = playing && [FEPlayerManager sharedManager].isPlaying ? FEIconTypePause : FEIconTypePlay;
    self.titleLabel.textColor = playing ? [FETheme primary] : [FETheme textPrimary];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.coverView.imageView.image = nil;
    self.coverView.urlString = nil;
    self.coverView.placeholderView.hidden = NO;
    self.titleLabel.textColor = [FETheme textPrimary];
}

@end
