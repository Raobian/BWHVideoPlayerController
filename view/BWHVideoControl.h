//
//  BWHVideoControl.h
//  BWHVideoPlayer
//
//  Created by 边文辉 on 16/9/10.
//  Copyright © 2016年 bianwenhui. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^BWHVideoControlGobackBlock)();

@protocol IJKMediaPlayback;

@interface BWHVideoControl : UIView

+ (instancetype)videoControlWithGobackBlock:(BWHVideoControlGobackBlock)block;

@property (nonatomic, weak) id<IJKMediaPlayback> delegatePlayer;



@end
