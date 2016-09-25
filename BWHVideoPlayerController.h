//
//  BWHVideoPlayerController.h
//  BWHVideoPlayer
//
//  Created by 边文辉 on 16/9/4.
//  Copyright © 2016年 bianwenhui. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BWHVideoPlayerController : UIViewController

@property (nonatomic, strong) NSURL *url;


+ (void)presentFromViewController:(UIViewController *)viewController WithURL:(NSString *)urlstr animated:(BOOL)animated;

/**
 *  播放
 */
- (void)play;

@end



