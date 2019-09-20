//
//  WWKVideoFrameView.m
//  VideoEditDemo
//
//  Created by betahuang on 2019/9/3.
//

#import "WWKVideoSlideView.h"
#import <AVFoundation/AVFoundation.h>
@interface WWKVideoFrameCell : UICollectionViewCell
@property(nonatomic, strong) UIImageView* imageView;
@end

@implementation WWKVideoFrameCell
-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:_imageView];
    }
    return self;
}

- (void)layoutSubviews {
    self.imageView.frame = self.bounds;
}
@end

@interface WWKVideoSlideView () <UICollectionViewDataSource, UICollectionViewDelegate>
@property(nonatomic, strong) UICollectionView *collectionView;
@property(nonatomic, strong) UIView *topBorderView;
@property(nonatomic, strong) UIView *bottomBorderView;
@property(nonatomic, strong) UIButton *leftBorderView;
@property(nonatomic, strong) UIButton *rightBorderView;
@property(nonatomic, strong) UIPanGestureRecognizer *leftPanGestureRecognizer;
@property(nonatomic, strong) UIPanGestureRecognizer *rightPanGestureRecognizer;
@property(nonatomic, assign) CGFloat anchorLeft;  // 编辑框开始点，左anchor的center
@property(nonatomic, assign) CGFloat anchorRight; //编辑框结束点，右anchor的center
@property(nonatomic, strong) UIView *leftMaskView;
@property(nonatomic, strong) UIView *rightMaskView;
@property(nonatomic, strong) UIView *curTimeView; //当前位置
@property(nonatomic, assign) CGFloat anchorWidth;
@property(nonatomic, assign) CGFloat timeOffset;
@property(nonatomic, strong) AVAssetImageGenerator *frameGenerator;
@property(nonatomic, strong) NSMutableDictionary<NSNumber*, UIImage*> *frameImages;
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
        _timeOffset = 0;
        _endTime = _startTime + _maxDuration;
        [self initUI];
    }
    return self;
}

-(void)initUI {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(0, ANCHOR_MARGIN, 0, ANCHOR_MARGIN);
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
    [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:WWKVideoFrameCell.class forCellWithReuseIdentifier:NSStringFromClass(WWKVideoFrameCell.class)];
    [self addSubview:self.collectionView];
    
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
    self.leftMaskView.userInteractionEnabled = NO;
    [self addSubview:self.leftMaskView];
    
    self.rightMaskView = [[UIView alloc] init];
    self.rightMaskView.backgroundColor = [UIColor blackColor];
    self.rightMaskView.alpha = 0.6;
    self.rightMaskView.userInteractionEnabled = NO;
    [self addSubview:self.rightMaskView];
    
    self.leftPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLeftAnchor:)];
    [self.leftBorderView addGestureRecognizer:self.leftPanGestureRecognizer];
    self.rightPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveRightAnchor:)];
    [self.rightBorderView addGestureRecognizer:self.rightPanGestureRecognizer];
}

- (void)setDuration:(CGFloat)duration {
    _duration = duration;
    [self mapValue];
}

-(void)setMaxDuration:(CGFloat)maxDuration {
    _maxDuration = maxDuration;
    _endTime = _startTime + _maxDuration;
    [self mapValue];
}

- (void)setVideoUrl:(NSURL *)videoUrl {
    _videoUrl = videoUrl;
    
    AVURLAsset *videoAsset = [[AVURLAsset alloc]initWithURL:_videoUrl options:nil];
    self.duration = CMTimeGetSeconds(videoAsset.duration);
    self.maxDuration = MIN(self.maxDuration, self.duration);
    self.frameGenerator = [[AVAssetImageGenerator alloc]initWithAsset:videoAsset];
    self.frameGenerator.maximumSize = CGSizeMake(self.frame.size.width * [UIScreen mainScreen].scale, self.frame.size.height * [UIScreen mainScreen].scale);
    self.frameGenerator.appliesPreferredTrackTransform = YES;
    self.frameGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    self.frameGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    
    self.frameImages = [[NSMutableDictionary alloc] init];
    [self.collectionView reloadData];
}

-(CGSize)frameSize {
    CGFloat imgWidth = (self.frame.size.width - 2 * self.anchorWidth) / (self.maxDuration + 1);;
    CGFloat imgHeight = self.frame.size.height;
    return CGSizeMake(imgWidth, imgHeight);
}

- (void)getFrameAtSeconds:(NSInteger)seconds completion:(void (^ __nullable)(BOOL success, UIImage* frame))completion {
    NSNumber *frameKey = @(seconds);
    UIImage *frame = [self.frameImages objectForKey:frameKey];
    if (frame) {
        if (completion) {
            completion(YES, frame);
        }
    } else {
        
        __weak __typeof(self) weakSelf = self;
                CMTime time = CMTimeMake(seconds, 1);
            [self.frameGenerator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:time]] completionHandler:^(CMTime requestedTime, CGImageRef img, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
                if (result == AVAssetImageGeneratorSucceeded) {
                    UIImage *image = [UIImage imageWithCGImage:img];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.frameImages setObject:image forKey:frameKey];
                        if (completion) {
                            completion(YES, image);
                        }
                    });
                } else {
                    if (result == AVAssetImageGeneratorFailed) {
                        NSLog(@"Failed with error: %@", [error localizedDescription]);
                    } else if (result == AVAssetImageGeneratorCancelled) {
                        NSLog(@"AVAssetImageGeneratorCancelled");
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) {
                            completion(NO, nil);
                        }
                    });
                }
            }];
    }
}

-(void)setNow:(CGFloat)now {
    if (_now > now) {
        NSLog(@"_now = %f, now = %f, now_pos = %f, right = %f, start = %f, end = %f", _now, now, [self timeToPos:self.now], self.anchorRight, self.startTime, self.endTime);
    }
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
    
    if (_endTime > _startTime + _maxDuration) {
        _endTime = _startTime + _maxDuration;
    }
    
    _anchorLeft = [self timeToPos:_startTime];
    _anchorRight = [self timeToPos:_endTime];
}


-(CGFloat)durationPixels {
    return MAX(0, self.collectionView.contentSize.width - ANCHOR_MARGIN - ANCHOR_MARGIN);
}

-(CGFloat)secondsPerPixel {
    return MAX(0, self.maxDuration / (self.frame.size.width - 2 * ANCHOR_MARGIN));
}

-(CGFloat)pixelsPerSeconds {
    if (self.maxDuration == 0) {
        return 0;
    }
    return MAX(0, (self.frame.size.width - 2 * ANCHOR_MARGIN ) / self.maxDuration);
}

-(CGFloat)durationToLength:(CGFloat)duration {
    return duration * [self pixelsPerSeconds];
}

//posToTime和timeToPos中的pos是指在self中的位置
-(CGFloat)posToTime:(CGFloat)pos {
    return (pos - ANCHOR_MARGIN) * [self secondsPerPixel] + _timeOffset;
}

-(CGFloat)timeToPos:(CGFloat)time {
    return ANCHOR_MARGIN + (time - _timeOffset) * [self pixelsPerSeconds];
}

- (void)layoutSubviews {
    self.collectionView.frame = self.bounds;
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
            CGFloat time = [self posToTime:anchorLeft];
            if (time < _timeOffset) {
                _startTime = _timeOffset;
                self.anchorLeft = ANCHOR_MARGIN;
            } else if (time + self.minDuration > _endTime) {
                _startTime = _endTime - 1;
                self.anchorLeft = self.anchorRight - [self durationToLength:self.minDuration];
            } else {
                _startTime = time;
                self.anchorLeft = anchorLeft;
            }
            
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
            CGFloat time = [self posToTime:anchorRight];
            
            if (time < _startTime + self.minDuration) {
                _endTime = _startTime + self.minDuration;
                _anchorRight = _anchorLeft + [self durationToLength:self.minDuration];
            } else if (time > _startTime + _maxDuration) {
                _endTime = _startTime + _maxDuration;
                _anchorRight = _anchorLeft + [self durationToLength:_maxDuration];
            } else {
                _endTime = time;
                _anchorRight = anchorRight;
            }
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

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (self.delegate && [self.delegate respondsToSelector:@selector(slideStart:)]) {
        [self.delegate slideStart:self];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(slideStop:)]) {
            [self.delegate slideStop:self];
        }
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(slideStop:)]) {
        [self.delegate slideStop:self];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGFloat span = self.startTime - self.timeOffset;
    CGFloat maxTimeOffset = self.duration - self.maxDuration;
    CGFloat maxOffset = self.collectionView.contentSize.width - self.collectionView.frame.size.width;
    self.timeOffset = self.collectionView.contentOffset.x / maxOffset * maxTimeOffset;
    if (self.timeOffset < 0) {
        self.timeOffset = 0;
    } else if (self.timeOffset > maxTimeOffset) {
        self.timeOffset = maxTimeOffset;
    }
    CGFloat span2 = _endTime - _startTime;
    _startTime = self.timeOffset + span;
    _endTime = _startTime + span2;
    [self notifyNewTime];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.duration;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WWKVideoFrameCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(WWKVideoFrameCell.class) forIndexPath:indexPath];
    [self getFrameAtSeconds:indexPath.row completion:^(BOOL success, UIImage *frame) {
        cell.imageView.image = frame;
    }];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self frameSize];
}
@end
