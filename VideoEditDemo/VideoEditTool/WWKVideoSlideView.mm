//
//  WWKVideoFrameView.m
//  VideoEditDemo
//
//  Created by betahuang on 2019/9/3.
//

#import "WWKVideoSlideView.h"

@interface WWKVideoSlideView () <UIScrollViewDelegate>
@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) UIView *topBorderView;
@property(nonatomic, strong) UIView *bottomBorderView;
@property(nonatomic, strong) UIButton *leftBorderView;
@property(nonatomic, strong) UIButton *rightBorderView;
@property(nonatomic, strong) UIPanGestureRecognizer *leftPanGestureRecognizer;
@property(nonatomic, strong) UIPanGestureRecognizer *rightPanGestureRecognizer;
@property(nonatomic, assign) CGFloat anchorLeft;  // 编辑框开始点，左anchor的center
@property(nonatomic, assign) CGFloat anchorRight; //编辑框结束点，右anchor的center
@property(nonatomic, strong) NSMutableArray<UIImageView*>* frameImageViews;
@property(nonatomic, strong) UIView *leftMaskView;
@property(nonatomic, strong) UIView *rightMaskView;
@property(nonatomic, strong) UIView *curTimeView; //当前位置
@property(nonatomic, assign) CGFloat anchorWidth;
@end

#define ANCHOR_MARGIN 50 //编辑框边距
@implementation WWKVideoSlideView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _minDuration = 1.0;
        _maxDuration = 15.0;
        _startTime = 0;
        _endTime = _startTime + _maxDuration - 1;
        [self initUI];
    }
    return self;
}

- (void)setDuration:(CGFloat)duration {
    _duration = duration;
    [self mapValue];
}

-(void)setMaxDuration:(CGFloat)maxDuration {
    _maxDuration = maxDuration;
    _endTime = _startTime + _maxDuration - 1;
    [self mapValue];
}

-(void)setNow:(CGFloat)now {
    _now = now;
    [self moveCurTimeLine];
}

-(void)moveCurTimeLine {
    self.curTimeView.frame = CGRectMake([self timeToPos:self.now] - 1, 0, 2, self.bounds.size.height);
}

-(void)mapValue {
    if (_maxDuration > _duration) {
        _maxDuration = _duration;
    }
    
    if (_endTime > _startTime + _maxDuration - 1) {
        _endTime = _startTime + _maxDuration - 1;
    }
    
    _anchorLeft = ANCHOR_MARGIN + self.anchorWidth / 2 + _startTime / _maxDuration * (self.frame.size.width - 2 * ANCHOR_MARGIN);
    _anchorRight = ANCHOR_MARGIN  + (_endTime + 1) / _maxDuration * (self.frame.size.width - 2 * ANCHOR_MARGIN);
}

-(void)clearFrames {
    for (UIImageView *imgView in self.frameImageViews) {
        [imgView removeFromSuperview];
    }
    
    self.frameImageViews = [[NSMutableArray alloc] init];
}

-(CGFloat)durationLength {
    return MAX(0, self.scrollView.contentSize.width - ANCHOR_MARGIN - ANCHOR_MARGIN);
}

-(CGFloat)secondsPerPixel {
    return MAX(0, self.duration / [self durationLength]);
//    return MAX(0, self.maxDuration / (self.frame.size.width - 2 * self.anchorWidth));
}

-(CGFloat)pixelsPerSeconds {
    if (self.duration <= 0) {
        return 0;
    }
    
    return MAX(0, [self durationLength] / self.duration);
//    if (self.maxDuration == 0) {
//        return 0;
//    }
//    return MAX(0, (self.frame.size.width - 2 * self.anchorWidth ) / self.maxDuration);
}

-(CGFloat)durationToLength:(CGFloat)duration {
    return duration * [self pixelsPerSeconds];
}

-(CGFloat)posToTime:(CGFloat)pos {
    return MAX(0, self.startTime + (pos - self.anchorLeft) * [self secondsPerPixel]);
}

-(CGFloat)timeToPos:(CGFloat)time {
    return MAX(0, self.anchorLeft + (time - self.startTime) * [self pixelsPerSeconds]);
    //    return ANCHOR_MARGIN + time * [self pixelsPerSeconds];
}

-(void)addFrame:(UIImage*)frameImage {
    CGFloat imgWidth = ([UIScreen mainScreen].bounds.size.width - 2 * self.anchorWidth) / (self.maxDuration + 1);;
    CGFloat imgHeight = self.frame.size.height;
    UIImageView *imgView = [[UIImageView alloc] initWithImage:frameImage];
    imgView.frame = CGRectMake(ANCHOR_MARGIN + self.frameImageViews.count * imgWidth, 0, imgWidth, imgHeight);
    [self.frameImageViews addObject:imgView];
    [self.scrollView addSubview:imgView];
    CGFloat contentWidth = MAX(ANCHOR_MARGIN + self.scrollView.frame.size.width, ANCHOR_MARGIN + self.frameImageViews.count * imgWidth + ANCHOR_MARGIN);
    self.scrollView.contentSize = CGSizeMake(contentWidth, imgHeight);
}

-(void)initUI {
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.delegate = self;
    [self addSubview:self.scrollView];
    
    self.curTimeView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 3, 50)];
    self.curTimeView.backgroundColor = [UIColor colorWithRed:214/255.0 green:230/255.0 blue:247/255.0 alpha:1.0];
    [self addSubview:self.curTimeView];
    
    self.topBorderView = [[UIView alloc] initWithFrame:CGRectZero];
    self.topBorderView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.topBorderView];
    self.bottomBorderView = [[UIView alloc] initWithFrame:CGRectZero];
    self.bottomBorderView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.bottomBorderView];
    self.leftBorderView = [[UIButton alloc] init];
    [self.leftBorderView setImage:[UIImage imageNamed:@"crop_video_grip"] forState:UIControlStateNormal];
    self.leftBorderView.adjustsImageWhenHighlighted = NO;
    [self.leftBorderView sizeToFit];
    
    [self addSubview:self.leftBorderView];
    self.rightBorderView = [[UIButton alloc] init];
    [self.rightBorderView setImage:[UIImage imageNamed:@"crop_video_grip"] forState:UIControlStateNormal];
    self.rightBorderView.adjustsImageWhenHighlighted = NO;
    [self.rightBorderView sizeToFit];
    [self addSubview:self.self.rightBorderView];
    self.anchorWidth = self.rightBorderView.frame.size.width;
    
    self.leftMaskView = [[UIView alloc] init];
    self.leftMaskView.backgroundColor = [UIColor blackColor];
    self.leftMaskView.alpha = 0.6;
    [self addSubview:self.leftMaskView];
    
    self.rightMaskView = [[UIView alloc] init];
    self.rightMaskView.backgroundColor = [UIColor blackColor];
    self.rightMaskView.alpha = 0.6;
    [self addSubview:self.rightMaskView];
    
    self.leftPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLeftAnchor:)];
    [self.leftBorderView addGestureRecognizer:self.leftPanGestureRecognizer];
    self.rightPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveRightAnchor:)];
    [self.rightBorderView addGestureRecognizer:self.rightPanGestureRecognizer];
}

- (void)layoutSubviews {
    self.scrollView.frame = self.bounds;
    self.topBorderView.frame = CGRectMake(self.anchorLeft, 0, self.anchorRight - self.anchorLeft, 2);
    self.bottomBorderView.frame = CGRectMake(self.anchorLeft, self.bounds.size.height - 2, self.anchorRight - self.anchorLeft, 2);
    self.leftBorderView.frame = CGRectMake(self.anchorLeft - self.anchorWidth / 2, 0, self.anchorWidth, self.bounds.size.height);
    self.rightBorderView.frame = CGRectMake(self.anchorRight - self.anchorWidth / 2, 0, self.anchorWidth, self.bounds.size.height);
    self.leftMaskView.frame = CGRectMake(0, 0, CGRectGetMinX(self.leftBorderView.frame), self.bounds.size.height);
    self.rightMaskView.frame = CGRectMake(CGRectGetMaxX(self.rightBorderView.frame), 0, self.bounds.size.width - CGRectGetMaxX(self.rightBorderView.frame), self.bounds.size.height);
    [self moveCurTimeLine];
}

//todo : can gesture
- (void)moveLeftAnchor:(UIPanGestureRecognizer *)gesture{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:{
            if (self.delegate && [self.delegate respondsToSelector:@selector(slideAnchorStart:)]) {
                [self.delegate slideAnchorStart:self];
            }
        }
            break;
            
        case UIGestureRecognizerStateChanged:{
            CGPoint translation = [gesture translationInView:[self superview]];
            CGFloat anchorLeft = self.anchorLeft + translation.x;
            NSLog(@"translation.x = %f, left = %f, right = %f", translation.x, anchorLeft, self.anchorRight);
            if (anchorLeft < ANCHOR_MARGIN) {
                anchorLeft = ANCHOR_MARGIN;
            } else if (anchorLeft + self.anchorWidth + [self durationToLength:self.minDuration]> self.anchorRight) {
                anchorLeft = self.anchorRight - self.anchorWidth - [self durationToLength:self.minDuration];
            }
            
            //posToTime内部实现依赖了self.anchorLeft，
            _startTime = [self posToTime:anchorLeft];
            self.anchorLeft = anchorLeft;
            
            [self notifyNewTime];
            [self setNeedsLayout];
            [gesture setTranslation:(CGPoint){0, 0} inView:[self superview]];
        }
            break;
            
        case UIGestureRecognizerStateEnded:{
            if (self.delegate && [self.delegate respondsToSelector:@selector(slideAnchorStop:)]) {
                [self.delegate slideAnchorStop:self];
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)moveRightAnchor:(UIPanGestureRecognizer *)gesture{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:{
            if (self.delegate && [self.delegate respondsToSelector:@selector(slideAnchorStart:)]) {
                [self.delegate slideAnchorStart:self];
            }
            
        }
            break;
            
        case UIGestureRecognizerStateChanged:{
            CGPoint translation = [gesture translationInView:[self superview]];
            CGFloat anchorRight = self.anchorRight + translation.x;
            NSLog(@"translation.x = %f, left = %f, right = %f", translation.x, self.anchorLeft, self.anchorRight);
            if (anchorRight < self.anchorLeft + self.anchorWidth + [self durationToLength:self.minDuration]) {
                anchorRight = self.anchorLeft + self.anchorWidth + [self durationToLength:self.minDuration];
            } else if (anchorRight > self.frame.size.width - ANCHOR_MARGIN) {
                anchorRight = self.frame.size.width - ANCHOR_MARGIN;
            }
            _endTime = [self posToTime:anchorRight];
            self.anchorRight = anchorRight;
            [self notifyNewTime];
            [self setNeedsLayout];
            [gesture setTranslation:(CGPoint){0, 0} inView:[self superview]];
        }
            break;
            
        case UIGestureRecognizerStateEnded:{
            if (self.delegate && [self.delegate respondsToSelector:@selector(slideAnchorStop:)]) {
                [self.delegate slideAnchorStop:self];
            }
        }
            break;
            
        default:
            break;
    }
}

-(void)notifyNewTime {
    if (self.delegate && [self.delegate respondsToSelector:@selector(slide:toStartTime:andEndTime:)]) {
        [self.delegate slide:self toStartTime:self.startTime andEndTime:self.endTime];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (self.delegate && [self.delegate respondsToSelector:@selector(slideStart:)]) {
        [self.delegate slideStart:self];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (self.delegate && [self.delegate respondsToSelector:@selector(slideStop:)]) {
        [self.delegate slideStop:self];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGFloat span = self.endTime - self.startTime;
    _startTime = (self.scrollView.contentOffset.x - ANCHOR_MARGIN) * [self secondsPerPixel];
    if (_startTime < 0) {
        _startTime = 0;
    }
    _endTime = _startTime + span;
    [self notifyNewTime];
}

@end
