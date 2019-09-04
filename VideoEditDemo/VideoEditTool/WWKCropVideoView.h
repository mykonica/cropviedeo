//
//  WWKEditVideoView.h
//  VideoEditDemo
//
//  Created by betahuang on 2019/9/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class WWKCropVideoView;
@protocol WWKCropVideoViewDelegate <NSObject>
@optional
-(void)cancelCropVideo:(WWKCropVideoView*)editView;
-(void)finishCropVideo:(WWKCropVideoView*)editView videoUrl:(NSURL*)url;
@end

@interface WWKCropVideoView : UIView
@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic, weak) id<WWKCropVideoViewDelegate> delegate;
-(void)showOnView:(UIView*)parentView animated:(BOOL)isAnimated;
-(void)prepareEdit:(void (^ __nullable)(BOOL finished))completion;
@end

NS_ASSUME_NONNULL_END
