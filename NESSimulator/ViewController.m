//
//  ViewController.m
//  NESSimulator
//
//  Created by qingzhao on 2019/4/4.
//  Copyright © 2019年 qingzhao. All rights reserved.
//

#import "ViewController.h"
#import "NesGameViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton* btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 80)];
    [btn addTarget:self action:@selector(startGame) forControlEvents:UIControlEventTouchUpInside];
    btn.titleLabel.font = [UIFont systemFontOfSize:15];
    [btn setTitle:@"开始" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor blueColor];
    btn.center = self.view.center;
    [self.view addSubview:btn];
}

- (void)startGame{
    NesGameViewController* gameVc = [[NesGameViewController alloc] init];
    [self presentViewController:gameVc animated:YES completion:^{
        
    }];
}

@end
