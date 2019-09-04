//
//  WWKEditVideoViewController.m
//  VideoEditDemo
//
//  Created by betahuang on 2019/9/2.
//  Copyright © 2019 刘志伟. All rights reserved.
//

#import "WWKEditVideoViewController.h"
#import "WWKCropVideoView.h"

@interface WWKEditVideoViewController () <WWKCropVideoViewDelegate>
@property(nonatomic, strong) WWKCropVideoView *editView;
@end

@implementation WWKEditVideoViewController
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor redColor];
        

    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setIsEdit:(BOOL)isEdit {
    _isEdit = isEdit;
}

- (void)setVideoUrl:(NSURL *)videoUrl {
    _videoUrl = videoUrl;
    
    self.editView = [[WWKCropVideoView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    
    __weak __typeof(self) weakSelf = self;
    self.editView.videoUrl = videoUrl;
    self.editView.delegate = self;
    [self.editView prepareEdit:^(BOOL finished) {
        [weakSelf.view addSubview:self.editView];
    }];
}

- (void)viewWillLayoutSubviews {
    self.editView.frame = self.view.bounds;
}

-(void)cancelCropVideo:(WWKCropVideoView*)editView {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)finishCropVideo:(WWKCropVideoView*)editView videoUrl:(NSURL*)url {
    
}
@end
