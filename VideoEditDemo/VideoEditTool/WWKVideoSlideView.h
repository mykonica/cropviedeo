//
//  WWKVideoFrameView.h
//  VideoEditDemo
//
//  Created by betahuang on 2019/9/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WWKVideoSlideView;

@protocol WWKVideoSlideViewDelegate <NSObject>
@optional
-(void)slide:(WWKVideoSlideView*)slideView toStartTime:(CGFloat)startTime andEndTime:(CGFloat)endTime;
-(void)slideAnchorStart:(WWKVideoSlideView*)slideView;
-(void)slideAnchorStop:(WWKVideoSlideView*)slideView;
-(void)slideStart:(WWKVideoSlideView*)slideView;
-(void)slideStop:(WWKVideoSlideView*)slideView;
@end

@interface WWKVideoSlideView : UIView
@property(nonatomic, assign) CGFloat now;
@property(nonatomic, assign) CGFloat duration;
@property(nonatomic, assign, readonly) CGFloat startTime;
@property(nonatomic, assign, readonly) CGFloat endTime;
@property(nonatomic, assign) CGFloat minDuration; //裁剪后的最短时长，默认1秒
@property(nonatomic, assign) CGFloat maxDuration; //裁剪后的最长时长，默认15秒
@property(nonatomic, weak) id<WWKVideoSlideViewDelegate> delegate;
-(void)clearFrames;
-(void)addFrame:(UIImage*)frameImage;
@end

NS_ASSUME_NONNULL_END
