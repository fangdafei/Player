//
//  PlayerView.m
//  CLPlayerDemo
//
//  Created by JmoVxia on 2016/11/1.
//  Copyright © 2016年 JmoVxia. All rights reserved.
//

#import "PlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIView+SetRect.h"
#import "UIImage+TintColor.h"
#import "UIImage+ScaleToSize.h"
#import "BackView.h"
#define Padding   15

@interface PlayerView ()

/**原始Farme*/
@property (nonatomic,assign) CGRect customFarme;


/**播放器*/
@property(nonatomic,strong)AVPlayer *player;
/**playerLayer*/
@property (nonatomic,strong) AVPlayerLayer *playerLayer;
/**播放器item*/
@property(nonatomic,strong)AVPlayerItem *playerItem;
/**播放进度条*/
@property(nonatomic,strong)UISlider *slider;
/**播放时间*/
@property(nonatomic,strong)UILabel *currentTimeLabel;
/**表面View*/
@property(nonatomic,strong)BackView *backView;
/**转子*/
@property(nonatomic,strong)UIActivityIndicatorView *activity;
/**缓冲进度条*/
@property(nonatomic,strong)UIProgressView *progress;
/**顶部控件*/
@property(nonatomic,strong) UIView *topView;
/**底部控件 */
@property (nonatomic,strong) UIView *bottomView;
/**播放按钮*/
@property (nonatomic,strong) UIButton *startButton;
/**轻拍定时器*/
@property (nonatomic,strong) NSTimer *timer;

/**返回按钮回调*/
@property (nonatomic,copy) void(^BackBlock)(UIButton *backButton);


@end

@implementation PlayerView
#pragma mark - 初始化
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _customFarme = frame;
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}
#pragma mark - 传入播放地址
-(void)setUrl:(NSURL *)url
{
    _url = url;
    self.playerItem = [AVPlayerItem playerItemWithURL:url];
    self.player = [AVPlayer playerWithPlayerItem:_playerItem];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    [self creatUI];

}
//创建UI
- (void)creatUI
{
    if (ScreenWidth < ScreenHeight)
    {
        self.frame = _customFarme;
        _playerLayer.frame = CGRectMake(0, 0, _customFarme.size.width, _customFarme.size.height);
    }
    else
    {
        self.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
        _playerLayer.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    }
    
    _playerLayer.videoGravity = AVLayerVideoGravityResize;
    [self.layer addSublayer:_playerLayer];

    
    //播放
    [self continuePlay];
    //AVPlayer播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
    //面上的View
    self.backView = [[BackView alloc]initWithFrame:CGRectMake(0, _playerLayer.frame.origin.y, _playerLayer.frame.size.width, _playerLayer.frame.size.height)];
    [self addSubview:_backView];
    _backView.backgroundColor = [UIColor clearColor];
    //顶部View条
    self.topView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, 60)];
    _topView.backgroundColor = [UIColor blackColor];
    _topView.alpha = 0.5;
    [_backView addSubview:_topView];
    //底部View条
    self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, _backView.height - 60, self.frame.size.width, 60)];
    _bottomView.backgroundColor = [UIColor blackColor];
    _bottomView.alpha = 0.5;
    [_backView addSubview:_bottomView];
    // 监听loadedTimeRanges属性
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    [self createButton];
    [self createProgress];
    [self createSlider];
    [self createCurrentTimeLabel];
    [self createBackButton];
    [self createMaxButton];
    [self createGesture];
    
    //菊花
    self.activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _activity.center = _backView.center;
    [self addSubview:_activity];
    [_activity startAnimating];
    
    //计时器
    [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(Stack) userInfo:nil repeats:YES];
    //工具条定时消失
    _timer = [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(disappear) userInfo:nil repeats:NO];
}
#pragma mark - 状态栏
- (BOOL)prefersStatusBarHidden
{
    return YES; // 返回NO表示要显示，返回YES将hiden
}
#pragma mark - 创建UISlider
- (void)createSlider
{
    self.slider = [[UISlider alloc]initWithFrame:CGRectMake(_progress.left - Padding/2.0, _progress.top, _progress.width + Padding, Padding)];
    _slider.centerY = _progress.centerY;
    [_bottomView addSubview:_slider];
    //自定义滑块大小
    
    UIImage *image = [UIImage imageNamed:@"iconfont-yuan"];
    //改变滑块大小
    UIImage *tempImage = [image OriginImage:image scaleToSize:CGSizeMake(Padding, Padding)];
    //改变滑块颜色
    UIImage *newImage = [tempImage imageWithTintColor:[UIColor orangeColor]];
    [_slider setThumbImage:newImage forState:UIControlStateNormal];

    [_slider addTarget:self action:@selector(progressSlider:) forControlEvents:UIControlEventValueChanged];
    //左边颜色
    _slider.minimumTrackTintColor = [UIColor redColor];
    //右边颜色
    _slider.maximumTrackTintColor = [UIColor clearColor];
    
}

#pragma mark - slider滑动事件
- (void)progressSlider:(UISlider *)slider
{
    //拖动改变视频播放进度
    if (_player.status == AVPlayerStatusReadyToPlay) {
        
        //    //计算出拖动的当前秒数
        CGFloat total = (CGFloat)_playerItem.duration.value / _playerItem.duration.timescale;
        
        NSInteger dragedSeconds = floorf(total * slider.value);
        //转换成CMTime才能给player来控制播放进度
    
        CMTime dragedCMTime = CMTimeMake(dragedSeconds, 1);
        //暂停
        [self pausePlay];
        
        [_player seekToTime:dragedCMTime completionHandler:^(BOOL finish){
            //继续播放
            [self continuePlay];
        }];
        
    }
}
#pragma mark - 创建UIProgressView
- (void)createProgress
{
    self.progress = [[UIProgressView alloc]initWithFrame:CGRectMake(_startButton.right + Padding, 0, self.frame.size.width - 80 - Padding - _startButton.right - Padding - Padding, Padding)];
    self.progress.centerY = _startButton.centerY;
    
    //进度条颜色
    self.progress.trackTintColor = [UIColor redColor];;
    
    NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
    CMTime duration = self.playerItem.duration;
    CGFloat totalDuration = CMTimeGetSeconds(duration);
    [self.progress setProgress:timeInterval / totalDuration animated:NO];
    
    CGFloat time = round(timeInterval);
    CGFloat total = round(totalDuration);
   
    //确保都是number
    if (isnan(time) == 0 && isnan(total) == 0)
    {
        if (time == total)
        {
            //缓冲进度颜色
            self.progress.progressTintColor = [UIColor yellowColor];
        }
        else
        {
            //缓冲进度颜色
            self.progress.progressTintColor = [UIColor clearColor];
        }
    }
    else
    {
        //缓冲进度颜色
        self.progress.progressTintColor = [UIColor clearColor];
    }
    [_bottomView addSubview:_progress];
}
#pragma mark - 缓存条监听
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        // 计算缓冲进度
        NSTimeInterval timeInterval = [self availableDuration];
        CMTime duration = self.playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        [self.progress setProgress:timeInterval / totalDuration animated:NO];
        //设置缓存进度颜色
        self.progress.progressTintColor = [UIColor yellowColor];
    }
}
//计算缓冲进度
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}


#pragma mark - 创建播放时间
- (void)createCurrentTimeLabel
{
    self.currentTimeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 80, Padding)];
    self.currentTimeLabel.centerY = _progress.centerY;
    self.currentTimeLabel.right = self.backView.right - Padding;
    [_bottomView addSubview:_currentTimeLabel];
    _currentTimeLabel.textColor = [UIColor whiteColor];
    _currentTimeLabel.font = [UIFont systemFontOfSize:12];
    _currentTimeLabel.text = @"00:00/00:00";
}
#pragma mark - 计时器事件
- (void)Stack
{
    if (_playerItem.duration.timescale != 0)
    {
        _slider.maximumValue = 1;//总共时长
        _slider.value = CMTimeGetSeconds([_playerItem currentTime]) / (_playerItem.duration.value / _playerItem.duration.timescale);//当前进度
        //当前时长进度progress
        NSInteger proMin = (NSInteger)CMTimeGetSeconds([_player currentTime]) / 60;//当前秒
        NSInteger proSec = (NSInteger)CMTimeGetSeconds([_player currentTime]) % 60;//当前分钟
        //duration 总时长
        NSInteger durMin = (NSInteger)_playerItem.duration.value / _playerItem.duration.timescale / 60;//总秒
        NSInteger durSec = (NSInteger)_playerItem.duration.value / _playerItem.duration.timescale % 60;//总分钟
        self.currentTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld / %02ld:%02ld", proMin, proSec, durMin, durSec];
    }
    //开始播放停止转子
    if (_player.status == AVPlayerStatusReadyToPlay)
    {
        [_activity stopAnimating];
    } else {
        [_activity startAnimating];
    }
    
}
#pragma mark - 播放按钮
- (void)createButton
{
    _startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _startButton.frame = CGRectMake(Padding, 0, 30, 30);
    _startButton.centerY = _bottomView.height/2.0;
    [_bottomView addSubview:_startButton];
    
    if (_player.rate == 1.0)
    {
        [_startButton setBackgroundImage:[UIImage imageNamed:@"pauseBtn"] forState:UIControlStateNormal];
    }
    else
    {
        [_startButton setBackgroundImage:[UIImage imageNamed:@"playBtn"] forState:UIControlStateNormal];
    }
    [_startButton addTarget:self action:@selector(startAction:) forControlEvents:UIControlEventTouchUpInside];
    
}
#pragma mark - 播放暂停按钮方法
- (void)startAction:(UIButton *)button
{
    if (button.selected)
    {
        [self continuePlay];
    }
    else
    {
        [self pausePlay];
    }
    button.selected =!button.selected;
    
}
#pragma mark - 返回按钮方法
- (void)createBackButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(Padding, 0, 30, 30);
    button.centerY = _topView.centerY;
    [button setBackgroundImage:[UIImage imageNamed:@"iconfont-back"] forState:UIControlStateNormal];
    [_topView addSubview:button];
    [button addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
}
#pragma mark - 全屏按钮
- (void)createMaxButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 30, 30);
    button.right = _topView.right - Padding;
    button.centerY = _topView.centerY;
    button.tintColor = [UIColor whiteColor];
    if (ScreenWidth < ScreenHeight)
    {
        [button setBackgroundImage:[UIImage imageNamed:@"max"] forState:UIControlStateNormal];
    }
    else
    {
        [button setBackgroundImage:[UIImage imageNamed:@"min"] forState:UIControlStateNormal];
    }
    
    [button addTarget:self action:@selector(maxAction:) forControlEvents:UIControlEventTouchUpInside];
    [_topView addSubview:button];
}
#pragma mark - 横屏代码
- (void)maxAction:(UIButton *)button
{
    //横屏采取删除UI重新构建
    if (ScreenWidth < ScreenHeight)
    {
        
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeRight] forKey:@"orientation"];
        [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
        [self creatUI];
    } else {
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];
        [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
        [self creatUI];
    }
}

#pragma mark - 创建手势
- (void)createGesture
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
    [self addGestureRecognizer:tap];
}
#pragma mark - 轻拍方法
- (void)tapAction:(UITapGestureRecognizer *)tap
{
    if (_backView.alpha == 1)
    {
        [UIView animateWithDuration:0.5 animations:^{
            _backView.alpha = 0;
        }];
        //取消定时消失
        [_timer invalidate];
        
    } else if (_backView.alpha == 0)
    {
        [UIView animateWithDuration:0.5 animations:^{
            
            _backView.alpha = 1;
        }];
        //添加定时消失
        _timer = [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(disappear) userInfo:nil repeats:NO];
    }
}
#pragma mark - 定时消失
- (void)disappear
{
    [UIView animateWithDuration:0.5 animations:^{
        _backView.alpha = 0;
    }];
}
#pragma mark - 播放完成
- (void)moviePlayDidEnd:(id)sender
{
    [self pausePlay];
}
#pragma mark - 返回按钮
- (void)backButtonAction:(UIButton *)button
{
//    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];
//    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        [obj removeFromSuperview];
//    }];
//    [self creatUI];

    self.BackBlock(button);
}
- (void)backButton:(BackButtonBlock) backButton;
{
    self.BackBlock = backButton;
}

#pragma mark - 暂停播放
- (void)pausePlay
{
    [_player pause];
    [_startButton setBackgroundImage:[UIImage imageNamed:@"playBtn"] forState:UIControlStateNormal];

}
#pragma mark - 继续播放
- (void)continuePlay
{
    [_player play];
    [_startButton setBackgroundImage:[UIImage imageNamed:@"pauseBtn"] forState:UIControlStateNormal];
}

#pragma mark - dealloc
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
}

//- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
//    UIView *view = [super hitTest:point withEvent:event];
//    if (view == nil) {
//        for (UIView *subView in self.subviews) {
//            CGPoint tp = [subView convertPoint:point fromView:self];
//            if (CGRectContainsPoint(subView.bounds, tp)) {
//                view = subView;
//            }
//        }
//    }
//    return view;
//}

@end
