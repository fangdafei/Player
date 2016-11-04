//
//  PlayerView.h
//  CLPlayerDemo
//
//  Created by JmoVxia on 2016/11/1.
//  Copyright © 2016年 JmoVxia. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^BackButtonBlock)(UIButton *button);
typedef void(^EndBolck)();

@interface PlayerView : UIView

/**视频url*/
@property (nonatomic,strong) NSURL *url;


/**返回按钮回调方法*/
- (void)backButton:(BackButtonBlock) backButton;

/**播放完成回调*/
- (void)endPlay:(EndBolck) end;


/**播放*/
- (void)playVideo;

/**暂停*/
- (void)pausePlay;

@end
