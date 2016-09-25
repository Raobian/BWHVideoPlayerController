//
//  BWHVideoPlayerController.m
//  BWHVideoPlayer
//
//  Created by 边文辉 on 16/9/4.
//  Copyright © 2016年 bianwenhui. All rights reserved.
//

#import "BWHVideoPlayerController.h"
#import "BWHVideoControl.h"

#import <IJKMediaFramework/IJKMediaFramework.h>

@interface BWHVideoPlayerController () <IJKMediaUrlOpenDelegate>

@property (nonatomic, strong) id<IJKMediaPlayback> player;
@property (nonatomic, weak) UIButton *btn;

@end

@implementation BWHVideoPlayerController

+ (void)presentFromViewController:(UIViewController *)viewController WithURL:(NSString *)urlstr animated:(BOOL)animated
{
    NSURL *url;
    if ([urlstr hasPrefix:@"http"]) {
        url = [NSURL URLWithString:urlstr];
    } else {
        url = [NSURL fileURLWithPath:urlstr];
    }
    
    BWHVideoPlayerController *bpc = [[BWHVideoPlayerController alloc] initWithURL:url];
    [viewController presentViewController:bpc animated:animated completion:nil];
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [self initWithNibName:@"BWHVideoPlayerController" bundle:nil];
    if (self) {
        self.url = url;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupIJK];
    
    [self setupControl];
}


- (void)setupIJK
{
//#ifdef DEBUG
//    [IJKFFMoviePlayerController setLogReport:NO];
//    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_ERROR];
//#else
    [IJKFFMoviePlayerController setLogReport:NO];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_ERROR];
//#endif
    
    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
    // [IJKFFMoviePlayerController checkIfPlayerVersionMatch:YES major:1 minor:0 micro:0];
    
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    [options setFormatOptionValue:@"ijktcphook" forKey:@"http-tcp-hook"];
    
    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:self.url withOptions:options];
    self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.player.view.frame = self.view.bounds;
    self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
    self.player.shouldAutoplay = YES;
    [self.view addSubview:self.player.view];
    self.view.autoresizesSubviews = YES;
}

- (void)setupControl
{
    // 视频控制界面
    __weak typeof(self) ws = self;
    BWHVideoControl *control = [BWHVideoControl videoControlWithGobackBlock:^{
        [ws dismissViewControllerAnimated:YES completion:nil];
    }];
    control.frame = self.view.bounds;
    control.delegatePlayer = self.player;
    [self.view addSubview:control];
}

- (void)willOpenUrl:(IJKMediaUrlOpenData *)urlOpenData
{
    NSLog(@"---------- urlOpenData url %@", urlOpenData.url);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.player prepareToPlay];
    [self installMovieNotificationObservers];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self removeMovieNotificationObservers];
    [self.player stop];
    [self.player shutdown];
    
}

- (void)play
{
    [self.player play];
}




#pragma mark - observer
/**
 *  缓冲状态
 */
- (void)loadStateDidChange:(NSNotification*)notification
{
    //    MPMovieLoadStateUnknown        = 0,
    //    MPMovieLoadStatePlayable       = 1 << 0,
    //    MPMovieLoadStatePlaythroughOK  = 1 << 1, // Playback will be automatically started in this state when shouldAutoplay is YES
    //    MPMovieLoadStateStalled        = 1 << 2, // Playback will be automatically paused in this state, if started
    
    IJKMPMovieLoadState loadState = _player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"-- bian -- loadStateDidChange: IJKMPMovieLoadStatePlaythroughOK: %d\n", (int)loadState);
    } else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"-- bian -- loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
    } else {
        NSLog(@"-- bian -- loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

/**
 *  完成，处理退出
 */
- (void)moviePlayBackDidFinish:(NSNotification*)notification
{
    //    MPMovieFinishReasonPlaybackEnded,
    //    MPMovieFinishReasonPlaybackError,
    //    MPMovieFinishReasonUserExited
    int reason = [[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    
    switch (reason)
    {
        case IJKMPMovieFinishReasonPlaybackEnded:   // 正常退出
            NSLog(@"-- bian -- playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonUserExited:      // 用户退出
            NSLog(@"-- bian -- playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:   // 错误退出
            NSLog(@"-- bian -- playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            break;
            
        default:
            NSLog(@"-- bian -- playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

/**
 * 准备完毕，开始播放
 */
- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification
{
    NSLog(@"-- bian -- mediaIsPreparedToPlayDidChange\n");
}

/**
 *  播放状态
 */
- (void)moviePlayBackStateDidChange:(NSNotification*)notification
{
    //    MPMoviePlaybackStateStopped,
    //    MPMoviePlaybackStatePlaying,
    //    MPMoviePlaybackStatePaused,
    //    MPMoviePlaybackStateInterrupted,
    //    MPMoviePlaybackStateSeekingForward,
    //    MPMoviePlaybackStateSeekingBackward
    
    switch (_player.playbackState)
    {
        case IJKMPMoviePlaybackStateStopped: {
            NSLog(@"-- bian -- IJKMPMoviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStatePlaying: {
            NSLog(@"-- bian -- IJKMPMoviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStatePaused: {
            NSLog(@"-- bian -- IJKMPMoviePlayBackStateDidChange %d: paused", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateInterrupted: {
            NSLog(@"-- bian -- IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"-- bian -- IJKMPMoviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
        default: {
            NSLog(@"-- bian -- IJKMPMoviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}

#pragma mark Install Movie Notifications

/* Register observers for the various movie object notifications. */
-(void)installMovieNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
}

#pragma mark Remove Movie Notification Handlers

/* Remove the movie notification observers from the movie object. */
-(void)removeMovieNotificationObservers
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerLoadStateDidChangeNotification object:_player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackDidFinishNotification object:_player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification object:_player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:_player];
}



#pragma mark - 状态栏
- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)dealloc
{
    NSLog(@"dealloc");
}

@end
