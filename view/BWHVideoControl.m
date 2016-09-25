//
//  BWHVideoControl.m
//  BWHVideoPlayer
//
//  Created by 边文辉 on 16/9/10.
//  Copyright © 2016年 bianwenhui. All rights reserved.
//

#import "BWHVideoControl.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "BWHVideoControlFFView.h"

typedef NS_ENUM(NSUInteger, PanType) {
    PanTypeNull,
    PanTypeVolume,
    PanTypeBrightness,
    PanTypeSpeed,
};

@interface BWHVideoControl()

@property (nonatomic, copy) BWHVideoControlGobackBlock gobackBlock;

@property (weak, nonatomic) IBOutlet UIView *overlayView;
@property (nonatomic, assign, getter=isShowOverlay) BOOL showOverlay;

/**
 *  头部
 */
@property (weak, nonatomic) IBOutlet UIView *backBtn;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
- (IBAction)goback:(id)sender;

/**
 *  底部
 */
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UISlider *slider;

- (IBAction)playORPause:(UIButton *)sender;

/**
 *  其他
 */

/* 音量条 */
@property (nonatomic, strong) UISlider *volumeViewSlider;

/* 快进快退 */
@property (nonatomic, weak)  BWHVideoControlFFView *ffView;
@property (nonatomic, assign) NSInteger startTime;
@property (nonatomic, assign) NSInteger duration;

/** 滑动手势类型 */
@property (nonatomic, assign) PanType panType;

/** 计时器 更新progress*/
@property (nonatomic, strong) NSTimer *timer;

@end



@implementation BWHVideoControl

+ (instancetype)videoControlWithGobackBlock:(BWHVideoControlGobackBlock)block
{
    BWHVideoControl *control = [BWHVideoControl viewFromNib];
    control.gobackBlock = block;
    return control;
}

+ (instancetype)viewFromNib
{
    return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil] lastObject];
}


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // 覆盖
    [self initOverlay];
    
    // 滑杆
    [self.slider setThumbImage:[UIImage imageNamed:@"icmpv_thumb_light"] forState:UIControlStateNormal];
    
    // 音量
    [self configureVolume];
    
    // 快进快退
    [self addFFView];
    
    // 手势
    [self initGesture];
    
    // 通知
    [self initNotification];
    
    // timer 用于更新滑杆 和progress
    [self createTimer];
    
}

- (void)dealloc
{
}

- (void)removeFromSuperview
{
    [super removeFromSuperview];
    [self removeTimer];                 /* 必须，否则不能销毁 */
    [self removeNotification];
}

- (void)layoutSubviews
{
    self.ffView.center = self.center;
}

#pragma mark - 显示覆盖
- (void)initOverlay
{
    self.overlayView.alpha = 1;
    self.showOverlay = YES;
    
    [self autoHideOverlay];
}

/**
 *  自动隐藏
 */
- (void)autoHideOverlay
{
    if (!self.isShowOverlay) return;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideOverlay) object:nil];
    [self performSelector:@selector(hideOverlay) withObject:nil afterDelay:20.f];
}

- (void)hideOverlay
{
    if (!self.isShowOverlay) return;
    [UIView animateWithDuration:.35f animations:^{
        _overlayView.alpha = 0;
    } completion:^(BOOL finished) {
        self.showOverlay = NO;
    }];
}

- (void)showOverlay
{
    if (self.isShowOverlay) return;
    [UIView animateWithDuration:.35f animations:^{
        _overlayView.alpha = 1;
    } completion:^(BOOL finished) {
        self.showOverlay = YES;
        [self autoHideOverlay];
        
    }];
}

#pragma mark - 系统音量
- (void)configureVolume
{
    // 音量滑杆
    MPVolumeView *volumeView = [MPVolumeView new];
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]) {
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]) {
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    
    /* 这个category 应用不会随手机静音而静音，可在静音模式下播放声音 */
    NSError *err = nil;
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&err];
    if (!success) {}
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    
}

/**
 *  耳机处理
 */
- (void)routeChange:(NSNotification *)noti
{
    NSDictionary *interuptionDict = noti.userInfo;
    NSInteger routeChangeRease = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeRease) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            // 耳机 插入
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            // 耳机 拔出
            if (![self.delegatePlayer isPlaying]) {
                [self.delegatePlayer play];
            }
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            break;
        default:
            break;
    }
}

- (void)removeRouteChangeObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - 快进快退
- (void)addFFView
{
    BWHVideoControlFFView *ffView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([BWHVideoControlFFView class]) owner:nil options:nil] lastObject];
    
    ffView.hidden = YES;
    [self addSubview:ffView];
    self.ffView = ffView;
}

#pragma mark - 改变播放状态
- (void)changePlayStatus
{
    if ([self.delegatePlayer isPlaying]) {
        [self.delegatePlayer pause];
    } else {
        [self.delegatePlayer play];
    }
    
    self.playBtn.selected = [self.delegatePlayer isPlaying];
}

- (void)seekToTime:(NSUInteger)time
{
    [self pasueTimer];
    [self.delegatePlayer setCurrentPlaybackTime:time];
    [self updateProgress];
    
    [self resumeTimer];
}


#pragma mark - 手势
- (void)initGesture
{
    // 单击
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self addGestureRecognizer:tap];
    
    // 双击
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
    [doubleTap setNumberOfTapsRequired:2];
    [self addGestureRecognizer:doubleTap];
    
    // 双击失败才能用单击
    [tap requireGestureRecognizerToFail:doubleTap];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];
    
    
}

// 单击
- (void)tapAction:(UITapGestureRecognizer *)tap
{
    if (tap.state == UIGestureRecognizerStateRecognized) {
        self.isShowOverlay ? [self hideOverlay] : [self showOverlay];
    }
}

// 双击
- (void)doubleTapAction:(UITapGestureRecognizer *)tap
{
    [self showOverlay];
    
    [self changePlayStatus];
}

- (void)pan:(UIPanGestureRecognizer *)pan
{
    BWHVideoControlFFView *ffView = self.ffView;
    CGSize ssize = self.bounds.size;
    CGPoint locationPoint = [pan locationInView:pan.view];
    CGPoint velocityPoint = [pan velocityInView:pan.view];
//    NSLog(@"locationPoint %@", NSStringFromCGPoint(locationPoint));
//    NSLog(@"velocityPoint %@", NSStringFromCGPoint(velocityPoint));
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: {
            CGFloat x = fabs(velocityPoint.x);
            CGFloat y = fabs(velocityPoint.y);
            if (x > y) { // 水平移动
                _panType = PanTypeSpeed;
                
                // 图片方向
                ffView.fForward = velocityPoint.x > 0;
                // 当前时间
                _startTime = [self.delegatePlayer currentPlaybackTime];
                _duration = [self.delegatePlayer duration];
                ffView.curTime = [self timeFormat:_startTime];
                ffView.duration = [NSString stringWithFormat:@"/%@", [self timeFormat:_duration]];
                // 显示
                ffView.hidden = NO;
                
            } else { // 垂直移动
                _panType = locationPoint.x > ssize.width * 0.5 ? PanTypeVolume : PanTypeBrightness;
            }
            
            break;
        }
        case UIGestureRecognizerStateChanged: {
            switch (_panType) {
                case PanTypeVolume: {
                    /** 音量 只在真机上显示 */
                    _volumeViewSlider.value -= velocityPoint.y / 10000.0;
                    break;
                }
                case PanTypeBrightness: {
                    /** 亮度 只在真机上显示 */
                    CGFloat curBrihtness = [UIScreen mainScreen].brightness;
                    CGFloat change = velocityPoint.y / ssize.height;
                    [[UIScreen mainScreen] setBrightness:curBrihtness - change];
                    break;
                }
                case PanTypeSpeed: {
                    CGFloat increment = velocityPoint.x / 10000.0;
                    increment = MIN(increment, 0.01);
                    _startTime += increment * _duration;
                    _startTime = MIN(_startTime, _duration);
                    _startTime = MAX(_startTime, 0);
                    ffView.curTime = [self timeFormat:_startTime];
                    
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            //== UIGestureRecognizerStateRecognized
            switch (_panType) {
                case PanTypeSpeed: {
                    self.ffView.hidden = YES;
                    [self seekToTime:_startTime];
                    break;
                }
                default:
                    break;
            }
            
            _panType = PanTypeNull;
            
            break;
        }
        default:
            break;
    }
}


#pragma mark - 缓存通知
- (void)initNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buffing:) name:IJKMPMoviePlayerLoadStateDidChangeNotification object:nil];
}

- (void)removeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)buffing:(NSNotification *)noti
{
    IJKFFMoviePlayerController *player = (IJKFFMoviePlayerController *)noti.object;
    if (player.loadState == IJKMPMovieLoadStateStalled) { // 缓冲开始
        NSLog(@"缓冲开始");
    } else if (player.loadState == IJKMPMovieLoadStatePlayable) { // 缓冲结束
        NSLog(@"缓冲结束");
    }
}


#pragma mark - timer
- (void)createTimer
{
    if (_timer) [self removeTimer];
    
    _timer = [NSTimer timerWithTimeInterval:1.f target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)removeTimer
{
    if (!_timer) return;
    [_timer invalidate];
    _timer = nil;
}

- (void)pasueTimer
{
    _timer.fireDate = [NSDate distantFuture];
}

- (void)resumeTimer
{
    _timer.fireDate = [NSDate distantPast];
}

- (void)updateProgress
{
    NSInteger curtime = [self.delegatePlayer currentPlaybackTime];
    NSInteger duration = [self.delegatePlayer duration];
    NSInteger playableDuration = [self.delegatePlayer playableDuration];
    
    if (duration) {
        
        self.slider.value = curtime * 1.f / duration;
        self.progressView.progress = playableDuration * 1.f / duration;
        
        if (curtime == duration) {
            [self goback:nil];
        }
    }
    
    NSString *curText = [self timeFormat:curtime];
    NSString *durText = [self timeFormat:duration];
//    NSLog(@"--- cur %@ --  dur %@", curText, durText);
    self.currentTimeLabel.text = curText;
    self.durationLabel.text = durText;
}

/**
 *  格式化时间为分秒字符串
 */
- (NSString *)timeFormat:(NSInteger)time
{
    return [NSString stringWithFormat:@"%02zd:%02zd", time / 60, time % 60];
}

/**
 *  拖动滑杆
 */
- (IBAction)sliderValuChanged:(UISlider *)sender
{
    _duration = [self.delegatePlayer duration];
    _startTime = sender.value * _duration;
    [self seekToTime:_startTime];
}

# pragma mark - 按钮
- (IBAction)goback:(id)sender
{
    if (self.gobackBlock) {
        self.gobackBlock();
    }
    
}

- (IBAction)playORPause:(UIButton *)sender
{
    [self changePlayStatus];
}

/**
 *  截获事件，防止点击事件向下传递
 */
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {}


@end
