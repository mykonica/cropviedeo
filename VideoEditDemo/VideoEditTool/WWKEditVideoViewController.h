//
//  WWKEditVideoViewController.h
//  VideoEditDemo
//
//  Created by betahuang on 2019/9/2.
//  Copyright © 2019 刘志伟. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WWKEditVideoViewController : UIViewController
@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic, assign) BOOL isEdit;
@end

NS_ASSUME_NONNULL_END
