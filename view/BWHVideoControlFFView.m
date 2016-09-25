//
//  BWHVideoControlSpeedView.m
//  BWHVideoPlayer
//
//  Created by 边文辉 on 16/9/20.
//  Copyright © 2016年 bianwenhui. All rights reserved.
//

#import "BWHVideoControlFFView.h"

@interface BWHVideoControlFFView ()
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *curTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;

@end

@implementation BWHVideoControlFFView

- (void)setFForward:(BOOL)fForward
{
    _fForward = fForward;
    _iconView.highlighted = fForward;
}

- (void)setCurTime:(NSString *)curTime
{
    _curTime = [curTime copy];
    _curTimeLabel.text = curTime;
}

- (void)setDuration:(NSString *)duration
{
    _duration = [duration copy];
    _durationLabel.text = duration;
}





/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {


}
 */

@end








