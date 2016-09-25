//
//  BWHVideoControlSpeedView.h
//  BWHVideoPlayer
//
//  Created by 边文辉 on 16/9/20.
//  Copyright © 2016年 bianwenhui. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BWHVideoControlFFView : UIView

@property (nonatomic, assign, getter=isfForward) BOOL fForward;
@property (nonatomic, copy) NSString *curTime;
@property (nonatomic, copy) NSString *duration;

@end
