#import "FEIconView.h"
#import <math.h>

static void FELine(CGContextRef ctx, CGFloat x1, CGFloat y1, CGFloat x2, CGFloat y2) {
    CGContextMoveToPoint(ctx, x1, y1);
    CGContextAddLineToPoint(ctx, x2, y2);
    CGContextStrokePath(ctx);
}

static void FEPolyline(CGContextRef ctx, const CGFloat *points, int count) {
    if (count < 2) return;
    CGContextMoveToPoint(ctx, points[0], points[1]);
    for (int i = 1; i < count; i++) {
        CGContextAddLineToPoint(ctx, points[i * 2], points[i * 2 + 1]);
    }
    CGContextStrokePath(ctx);
}

static void FECircle(CGContextRef ctx, CGFloat cx, CGFloat cy, CGFloat radius) {
    CGContextAddArc(ctx, cx, cy, radius, 0, (CGFloat)M_PI * 2, 0);
    CGContextStrokePath(ctx);
}

static void FEDot(CGContextRef ctx, CGFloat cx, CGFloat cy, CGFloat radius) {
    CGContextAddArc(ctx, cx, cy, radius, 0, (CGFloat)M_PI * 2, 0);
    CGContextFillPath(ctx);
}

static void FERoundedRect(CGContextRef ctx, CGFloat x, CGFloat y, CGFloat w, CGFloat h, CGFloat r) {
    CGContextAddPath(ctx, [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, w, h) cornerRadius:r].CGPath);
    CGContextStrokePath(ctx);
}

static void FEFillRoundedRect(CGContextRef ctx, CGFloat x, CGFloat y, CGFloat w, CGFloat h, CGFloat r) {
    CGContextAddPath(ctx, [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, w, h) cornerRadius:r].CGPath);
    CGContextFillPath(ctx);
}

@implementation FEIconView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.contentMode = UIViewContentModeRedraw;
        self.lineWidth = 2.0;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame iconType:(FEIconType)iconType {
    self = [self initWithFrame:frame];
    if (self) {
        self.iconType = iconType;
    }
    return self;
}

- (void)setIconType:(FEIconType)iconType {
    _iconType = iconType;
    [self setNeedsDisplay];
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
    [self setNeedsDisplay];
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    [self setNeedsDisplay];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (ctx == NULL) return;

    CGFloat side = MIN(rect.size.width, rect.size.height);
    if (side <= 0) return;
    CGFloat scale = side / 24.0;

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, rect.origin.x + (rect.size.width - side) / 2.0,
                          rect.origin.y + (rect.size.height - side) / 2.0);
    CGContextScaleCTM(ctx, scale, scale);
    CGContextSetStrokeColorWithColor(ctx, self.tintColor.CGColor);
    CGContextSetFillColorWithColor(ctx, self.tintColor.CGColor);
    CGContextSetLineWidth(ctx, self.lineWidth);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    switch (self.iconType) {
        case FEIconTypeSparkle: {
            CGContextMoveToPoint(ctx, 12, 2.5);
            CGContextAddLineToPoint(ctx, 14.4, 9.6);
            CGContextAddLineToPoint(ctx, 21.5, 12);
            CGContextAddLineToPoint(ctx, 14.4, 14.4);
            CGContextAddLineToPoint(ctx, 12, 21.5);
            CGContextAddLineToPoint(ctx, 9.6, 14.4);
            CGContextAddLineToPoint(ctx, 2.5, 12);
            CGContextAddLineToPoint(ctx, 9.6, 9.6);
            CGContextClosePath(ctx);
            CGContextFillPath(ctx);
            break;
        }
        case FEIconTypeCalendar: {
            FERoundedRect(ctx, 3.5, 5, 17, 16, 3.5);
            FELine(ctx, 3.5, 9.5, 20.5, 9.5);
            FELine(ctx, 8, 2.8, 8, 7);
            FELine(ctx, 16, 2.8, 16, 7);
            FEDot(ctx, 8, 13, 1.2);
            FEDot(ctx, 12, 13, 1.2);
            FEDot(ctx, 16, 13, 1.2);
            FEDot(ctx, 8, 17, 1.2);
            FEDot(ctx, 12, 17, 1.2);
            break;
        }
        case FEIconTypeRadio: {
            FECircle(ctx, 12, 12, 8.5);
            FEDot(ctx, 12, 12, 2.2);
            CGContextAddArc(ctx, 12, 12, 4.6, (CGFloat)M_PI * 0.15, (CGFloat)M_PI * 0.85, 0);
            CGContextStrokePath(ctx);
            CGContextAddArc(ctx, 12, 12, 4.6, (CGFloat)M_PI * 1.15, (CGFloat)M_PI * 1.85, 0);
            CGContextStrokePath(ctx);
            break;
        }
        case FEIconTypeChart: {
            CGContextSetLineWidth(ctx, 3.0);
            FELine(ctx, 5, 20, 5, 13);
            FELine(ctx, 12, 20, 12, 7);
            FELine(ctx, 19, 20, 19, 10);
            CGContextSetLineWidth(ctx, 1.5);
            FELine(ctx, 3, 20.8, 21, 20.8);
            break;
        }
        case FEIconTypeSearch: {
            FECircle(ctx, 10.2, 10.2, 6.4);
            FELine(ctx, 15, 15, 20.5, 20.5);
            break;
        }
        case FEIconTypeLibrary: {
            CGContextSetLineWidth(ctx, 2.4);
            FELine(ctx, 5.5, 4, 5.5, 20.5);
            FELine(ctx, 10.5, 4, 10.5, 20.5);
            CGContextMoveToPoint(ctx, 15.2, 5.2);
            CGContextAddLineToPoint(ctx, 19.5, 19.2);
            CGContextStrokePath(ctx);
            break;
        }
        case FEIconTypeHeadphones: {
            CGContextAddArc(ctx, 12, 12.5, 8, (CGFloat)M_PI, (CGFloat)M_PI * 2, 0);
            CGContextStrokePath(ctx);
            FERoundedRect(ctx, 3.2, 12.2, 4.2, 8, 2.1);
            FERoundedRect(ctx, 16.6, 12.2, 4.2, 8, 2.1);
            break;
        }
        case FEIconTypePlaylist: {
            FERoundedRect(ctx, 3.5, 3.5, 17, 17, 4);
            FELine(ctx, 7.5, 8.5, 16.5, 8.5);
            FELine(ctx, 7.5, 12, 16.5, 12);
            FELine(ctx, 7.5, 15.5, 12.5, 15.5);
            FEDot(ctx, 17, 16, 1.5);
            break;
        }
        case FEIconTypeUser: {
            FECircle(ctx, 12, 8.2, 4);
            CGContextMoveToPoint(ctx, 4.5, 20.2);
            CGContextAddQuadCurveToPoint(ctx, 19.5, 20.2, 12, 13.2);
            CGContextStrokePath(ctx);
            break;
        }
        case FEIconTypeLock: {
            FERoundedRect(ctx, 4.8, 10.5, 14.4, 10, 3);
            CGContextMoveToPoint(ctx, 8, 10.5);
            CGContextAddLineToPoint(ctx, 8, 8);
            CGContextAddArc(ctx, 12, 8, 4, (CGFloat)M_PI, 0, 0);
            CGContextAddLineToPoint(ctx, 16, 10.5);
            CGContextStrokePath(ctx);
            FEDot(ctx, 12, 15, 1.5);
            break;
        }
        case FEIconTypeCloud: {
            CGContextMoveToPoint(ctx, 7, 18.5);
            CGContextAddLineToPoint(ctx, 17.5, 18.5);
            CGContextAddCurveToPoint(ctx, 21.2, 18.5, 21.8, 13.2, 18.5, 11.6);
            CGContextAddCurveToPoint(ctx, 19.2, 7.4, 15.4, 4.2, 12, 6.4);
            CGContextAddCurveToPoint(ctx, 9.6, 3.6, 5.4, 5.6, 5.8, 9.5);
            CGContextAddCurveToPoint(ctx, 2.2, 10.4, 2.4, 18.5, 7, 18.5);
            CGContextStrokePath(ctx);
            break;
        }
        case FEIconTypeHeart: {
            CGContextMoveToPoint(ctx, 12, 20.6);
            CGContextAddCurveToPoint(ctx, 10.4, 19.4, 3.2, 14.4, 3.2, 9.4);
            CGContextAddCurveToPoint(ctx, 3.2, 6.4, 5.6, 4.2, 8.4, 4.2);
            CGContextAddCurveToPoint(ctx, 10.4, 4.2, 11.4, 5.4, 12, 6.6);
            CGContextAddCurveToPoint(ctx, 12.6, 5.4, 13.6, 4.2, 15.6, 4.2);
            CGContextAddCurveToPoint(ctx, 18.4, 4.2, 20.8, 6.4, 20.8, 9.4);
            CGContextAddCurveToPoint(ctx, 20.8, 14.4, 13.6, 19.4, 12, 20.6);
            CGContextClosePath(ctx);
            CGContextFillPath(ctx);
            break;
        }
        case FEIconTypeNote: {
            FECircle(ctx, 7.5, 17.2, 3.3);
            FELine(ctx, 10.8, 17.2, 10.8, 5.2);
            CGContextMoveToPoint(ctx, 10.8, 5.2);
            CGContextAddLineToPoint(ctx, 19.5, 3.2);
            CGContextAddLineToPoint(ctx, 19.5, 6.4);
            CGContextAddLineToPoint(ctx, 10.8, 8.6);
            CGContextStrokePath(ctx);
            break;
        }
        case FEIconTypePlay: {
            CGContextMoveToPoint(ctx, 8.5, 5);
            CGContextAddLineToPoint(ctx, 19, 12);
            CGContextAddLineToPoint(ctx, 8.5, 19);
            CGContextClosePath(ctx);
            CGContextFillPath(ctx);
            break;
        }
        case FEIconTypePause: {
            FEFillRoundedRect(ctx, 6.5, 4.5, 4, 15, 1.6);
            FEFillRoundedRect(ctx, 13.5, 4.5, 4, 15, 1.6);
            break;
        }
        case FEIconTypeNext: {
            CGContextMoveToPoint(ctx, 6, 5);
            CGContextAddLineToPoint(ctx, 16, 12);
            CGContextAddLineToPoint(ctx, 6, 19);
            CGContextClosePath(ctx);
            CGContextFillPath(ctx);
            FEFillRoundedRect(ctx, 17, 5, 2.6, 14, 1.3);
            break;
        }
        case FEIconTypePrev: {
            CGContextMoveToPoint(ctx, 18, 5);
            CGContextAddLineToPoint(ctx, 8, 12);
            CGContextAddLineToPoint(ctx, 18, 19);
            CGContextClosePath(ctx);
            CGContextFillPath(ctx);
            FEFillRoundedRect(ctx, 4.4, 5, 2.6, 14, 1.3);
            break;
        }
        case FEIconTypeSettings: {
            FECircle(ctx, 12, 12, 3.4);
            for (int i = 0; i < 8; i++) {
                CGFloat angle = (CGFloat)M_PI / 4.0 * i;
                CGFloat x1 = 12 + cosf(angle) * 6.2;
                CGFloat y1 = 12 + sinf(angle) * 6.2;
                CGFloat x2 = 12 + cosf(angle) * 8.6;
                CGFloat y2 = 12 + sinf(angle) * 8.6;
                FELine(ctx, x1, y1, x2, y2);
            }
            break;
        }
        case FEIconTypeDisc: {
            FECircle(ctx, 12, 12, 8.6);
            FECircle(ctx, 12, 12, 2.4);
            CGContextAddArc(ctx, 12, 12, 5.4, (CGFloat)M_PI * 0.1, (CGFloat)M_PI * 0.65, 0);
            CGContextStrokePath(ctx);
            break;
        }
        case FEIconTypeMic: {
            FERoundedRect(ctx, 9.4, 2.8, 5.2, 10.4, 2.6);
            CGContextAddArc(ctx, 12, 11, 6, 0, (CGFloat)M_PI, 0);
            CGContextStrokePath(ctx);
            FELine(ctx, 12, 17, 12, 21);
            FELine(ctx, 8.6, 21, 15.4, 21);
            break;
        }
        case FEIconTypeDownload: {
            FELine(ctx, 12, 3, 12, 14.5);
            const CGFloat arrow[] = {6.8, 9.6, 12, 14.8, 17.2, 9.6};
            FEPolyline(ctx, arrow, 3);
            const CGFloat tray[] = {3.8, 17.6, 3.8, 20.8, 20.2, 20.8, 20.2, 17.6};
            FEPolyline(ctx, tray, 4);
            break;
        }
        case FEIconTypeChevronRight: {
            const CGFloat points[] = {9.5, 4.8, 16.5, 12, 9.5, 19.2};
            FEPolyline(ctx, points, 3);
            break;
        }
        case FEIconTypeChevronDown: {
            const CGFloat points[] = {4.8, 9.5, 12, 16.5, 19.2, 9.5};
            FEPolyline(ctx, points, 3);
            break;
        }
        case FEIconTypeClose: {
            FELine(ctx, 5.8, 5.8, 18.2, 18.2);
            FELine(ctx, 18.2, 5.8, 5.8, 18.2);
            break;
        }
        case FEIconTypeMore: {
            FEDot(ctx, 5, 12, 1.7);
            FEDot(ctx, 12, 12, 1.7);
            FEDot(ctx, 19, 12, 1.7);
            break;
        }
        case FEIconTypeHome: {
            const CGFloat roof[] = {3.5, 11, 12, 3.5, 20.5, 11};
            FEPolyline(ctx, roof, 3);
            const CGFloat wall[] = {6, 10.4, 6, 20.5, 18, 20.5, 18, 10.4};
            FEPolyline(ctx, wall, 4);
            FERoundedRect(ctx, 10, 14, 4, 6.5, 1);
            break;
        }
        case FEIconTypeShuffle: {
            const CGFloat top[] = {3.5, 7, 7.5, 7, 16.5, 17};
            FEPolyline(ctx, top, 3);
            const CGFloat arrowTop[] = {16.5, 17, 20.5, 17};
            FEPolyline(ctx, arrowTop, 3);
            const CGFloat arrowHead[] = {17.8, 14.6, 20.6, 17, 17.8, 19.4};
            FEPolyline(ctx, arrowHead, 3);
            const CGFloat bottom[] = {3.5, 17, 7, 17, 10.5, 13.2};
            FEPolyline(ctx, bottom, 3);
            const CGFloat topArrow[] = {16.5, 7, 20.5, 7};
            FEPolyline(ctx, topArrow, 3);
            const CGFloat topArrowHead[] = {17.8, 4.6, 20.6, 7, 17.8, 9.4};
            FEPolyline(ctx, topArrowHead, 3);
            break;
        }
        case FEIconTypeRepeat: {
            FERoundedRect(ctx, 3.2, 5.2, 17.6, 13.6, 4.5);
            const CGFloat topArrow[] = {13, 2.6, 16.6, 5.4, 13, 8.2};
            FEPolyline(ctx, topArrow, 3);
            const CGFloat bottomArrow[] = {11, 15.8, 7.4, 18.6, 11, 21.4};
            FEPolyline(ctx, bottomArrow, 3);
            break;
        }
        case FEIconTypeTV: {
            FERoundedRect(ctx, 2.8, 6.5, 18.4, 13, 2.6);
            FELine(ctx, 8, 3, 12, 6.5);
            FELine(ctx, 16, 3, 12, 6.5);
            FECircle(ctx, 12, 13, 2);
            break;
        }
        default:
            break;
    }

    CGContextRestoreGState(ctx);
}

+ (UIImage *)imageWithType:(FEIconType)type size:(CGSize)size color:(UIColor *)color {
    return [self imageWithType:type size:size color:color lineWidth:2.0];
}

+ (UIImage *)imageWithType:(FEIconType)type size:(CGSize)size color:(UIColor *)color lineWidth:(CGFloat)lineWidth {
    if (size.width <= 0 || size.height <= 0) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    FEIconView *view = [[FEIconView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) iconType:type];
    view.tintColor = color ?: [UIColor blackColor];
    view.lineWidth = lineWidth;
    [view drawRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

@end
