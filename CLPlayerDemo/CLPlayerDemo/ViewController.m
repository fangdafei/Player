//
//  ViewController.m
//  CLPlayerDemo
//
//  Created by JmoVxia on 2016/11/1.
//  Copyright © 2016年 JmoVxia. All rights reserved.
//

#import "ViewController.h"
#import "PlayerView.h"
#import "UIView+SetRect.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    UIView *view1 = [[UIView alloc] initWithFrame:CGRectMake(99, 99, 300, 300)];
//    [self.view addSubview:view1];
    
    UIView *view2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
    [self.view addSubview:view2];
    
    
    PlayerView *playerView = [[PlayerView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
    playerView.url = [NSURL URLWithString:@"http://wvideo.spriteapp.cn/video/2016/1026/58101f312c4e6_wpd.mp4"];
    [playerView backButton:^(UIButton *button) {
        
    }];
    [view2 addSubview:playerView];
    
    

}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
