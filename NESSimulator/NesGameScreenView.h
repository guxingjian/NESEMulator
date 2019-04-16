//
//  NesGameScreenView.h
//  NESSimulator
//
//  Created by qingzhao on 2019/4/11.
//  Copyright © 2019年 qingzhao. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "common.hpp"

@interface NesGameScreenView : UIView

@property(nonatomic, assign)BOOL pause;

- (void)nes_newframe:(u32*)pic;

@end
