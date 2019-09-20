//
//  WWKEditVideoView.m
//  VideoEditDemo
//
//  Created by betahuang on 2019/9/2.
//

#import "WWKCropVideoView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "WWKVideoSlideView.h"
#import <Photos/Photos.h>

#define EDGE_EXTENSION_FOR_THUMB 20

@interface WWKCropVideoView () <WWKVideoSlideViewDelegate>

@property (nonatomic, strong) AVPlayerItem      *playItem;
@property (nonatomic, strong) AVPlayerLayer     *playerLayer;
@property (nonatomic, strong) AVPlayer          *player;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) WWKVideoSlideView *slider;
@property (nonatomic, assign) CGFloat startTime;
@property (nonatomic, assign) CGFloat endTime;
@property (nonatomic, strong) id playerTimerObserver;
@end

@implementation WWKCropVideoView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        
        _doneButton = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width-60, 50, 60, 30)];
        [_doneButton setTitle:@"完成" forState:UIControlStateNormal];
        [_doneButton setTitleColor:[UIColor colorWithRed:14/255.0 green:178/255.0 blue:10/255.0 alpha:1.0] forState:UIControlStateNormal];
        [_doneButton addTarget:self action:@selector(onCropVideo) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_doneButton];
        [_doneButton sizeToFit];
        _doneButton.frame = CGRectMake(frame.size.width - _doneButton.frame.size.width - 15, frame.size.height - _doneButton.frame.size.height - 20, _doneButton.frame.size.width, _doneButton.frame.size.height);
        
        _cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 50, 60, 30)];
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(onCancel) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_cancelButton];
        [_cancelButton sizeToFit];
        _cancelButton.frame = CGRectMake(15, frame.size.height - _cancelButton.frame.size.height - 20, _cancelButton.frame.size.width, _cancelButton.frame.size.height);
        
        self.slider = [[WWKVideoSlideView alloc] initWithFrame:CGRectMake(0, _doneButton.frame.origin.y - 35 - 50, frame.size.width, 50)];
        self.slider.delegate = self;
        [self addSubview:self.slider];
    }
    return self;
}

- (void)invalidatePlayer{
    if (self.playerTimerObserver) {
        [self.player removeTimeObserver:self.playerTimerObserver];
        self.playerTimerObserver = nil;
    }
    [self.player pause];
    [self.playItem removeObserver:self forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark 视频裁剪
- (void)onCropVideo{
    [self invalidatePlayer];
    
    NSString *tempVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mov", [[NSUUID UUID] UUIDString]]];
    
    AVAsset *asset = [AVAsset assetWithURL:self.videoUrl];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                           initWithAsset:asset presetName:AVAssetExportPresetPassthrough];
    
    NSURL *furl = [NSURL fileURLWithPath:tempVideoPath];
    exportSession.outputURL = furl;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    
    CMTime start = CMTimeMakeWithSeconds(self.startTime, self.player.currentTime.timescale);
    CMTime duration = CMTimeMakeWithSeconds(self.endTime - self.startTime, self.player.currentTime.timescale);;
    CMTimeRange range = CMTimeRangeMake(start, duration);
    exportSession.timeRange = range;
    __weak __typeof(self) weakSelf = self;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch ([exportSession status]) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
                break;
                
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Export canceled");
                break;
                
            case AVAssetExportSessionStatusCompleted:{
                NSLog(@"Export completed");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
                        UISaveVideoAtPathToSavedPhotosAlbum([furl relativePath], weakSelf, @selector(video:didFinishSavingWithError:contextInfo:), nil);
                    }
                    
                    NSLog(@"编辑后的视频路径： %@",tempVideoPath);
                    if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(finishCropVideo:videoUrl:)]) {
                        [weakSelf.delegate finishCropVideo:weakSelf videoUrl:[NSURL fileURLWithPath:tempVideoPath]];
                    }
                });
            }
                break;
                
            default:
                NSLog(@"Export other");
                
                break;
        }
    }];
}

- (void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    if (error) {
        NSLog(@"保存到相册失败");
    }
    else {
        NSLog(@"保存到相册成功");
    }
}

-(void)updateProgress:(CMTime)time {
    self.slider.now = CMTimeGetSeconds(self.player.currentTime);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        switch (self.playItem.status) {
            case AVPlayerItemStatusUnknown:
                NSLog(@"KVO：未知状态，此时不能播放");
                break;
            case AVPlayerItemStatusReadyToPlay:
                if (!_player.timeControlStatus || _player.timeControlStatus != AVPlayerTimeControlStatusPaused) {
                    [_player play];
                }
                NSLog(@"KVO：准备完毕，可以播放");
                break;
            case AVPlayerItemStatusFailed:
                NSLog(@"KVO：加载失败，网络或者服务器出现问题");
                break;
            default:
                break;
        }
    }
}

- (void)replay{
    [self seekToTimeAccurate:self.slider.startTime];
    //设置播放结束时间。修改forwardPlaybackEndTime后会重新触发AVPlayerItemStatusReadyToPlay。
    self.player.currentItem.forwardPlaybackEndTime = CMTimeMakeWithSeconds(self.slider.endTime, self.player.currentTime.timescale);
    NSLog(@"seek to %f, %f", self.slider.startTime, self.slider.endTime);
}

- (void)pause{
    [self.player pause];
}

-(void)seekToTimeAccurate:(CGFloat)seconds {
    [self.player seekToTime:CMTimeMakeWithSeconds(seconds, self.player.currentItem.asset.duration.timescale)
            toleranceBefore:kCMTimeZero
             toleranceAfter:kCMTimeZero];
}

- (void)initPlayerWithVideoUrl:(NSURL *)videlUrl{
    self.playItem = [[AVPlayerItem alloc] initWithURL:videlUrl];
    [self.playItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    self.player = [AVPlayer playerWithPlayerItem:self.playItem];
    self.player.currentItem.forwardPlaybackEndTime = CMTimeMake(self.slider.endTime, 1);
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    __weak __typeof(self) weakSelf = self;
    self.playerTimerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1,100)
                                                                         queue:dispatch_get_main_queue()
                                                                    usingBlock:^(CMTime time) {
                                                                        /// 更新播放进度
                                                                        [weakSelf updateProgress:time];
                                                                    }];
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.contentsScale = [UIScreen mainScreen].scale;
    self.playerLayer.frame = CGRectMake(25, 0, self.bounds.size.width - 2 * 25, self.slider.frame.origin.y - 15);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(playerItemDidPlayToEndTimeNotification:)
                                                name:AVPlayerItemDidPlayToEndTimeNotification
                                              object:nil];
    
    [self.layer addSublayer:self.playerLayer];
}

- (void)playerItemDidPlayToEndTimeNotification:(NSNotification *)sender {
    [self seekToTimeAccurate:self.slider.startTime];
}

-(void)prepareEdit:(void (^ __nullable)(BOOL finished))completion {
    self.slider.videoUrl = self.videoUrl;
    self.slider.maxDuration = 15;
    [self initPlayerWithVideoUrl:self.videoUrl];
    if(completion) {
        completion(YES);
    }
//    [self analysisVideoFrames:completion];
}

- (void)onCancel{
    [self invalidatePlayer];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cancelCropVideo:)]) {
        [self.delegate cancelCropVideo:self];
    }
}

-(void)showOnView:(UIView*)parentView animated:(BOOL)isAnimated
{
    if(!parentView){
        return;
    }
    
    self.frame = parentView.bounds;
    [parentView addSubview:self];
}

#pragma mark - WWKVideoSlideViewDelegate
-(void)slide:(WWKVideoSlideView*)slideView toStartTime:(CGFloat)startTime andEndTime:(CGFloat)endTime {
    BOOL b1 = NO;
    BOOL b2 = NO;
    NSLog(@"startTime = %f, endTime = %f", startTime, endTime);
    
    if (self.startTime != startTime) {
        b1 = YES;
        self.startTime = startTime;
    }
    
    if (self.endTime != endTime) {
        b2 = YES;
        self.endTime = endTime;
    }
    
    if (b1) {
        [self seekToTimeAccurate:self.startTime];
    } else if (b2) {
        [self seekToTimeAccurate:self.endTime];
    }
}

-(void)slideStart:(WWKVideoSlideView*)slideView {
    [self pause];
}

-(void)slideStop:(WWKVideoSlideView*)slideView {
    [self replay];
}

-(void)slideAnchorStart:(WWKVideoSlideView*)slideView {
    [self pause];
}

-(void)slideAnchorStop:(WWKVideoSlideView*)slideView {
    [self replay];
}

@end
