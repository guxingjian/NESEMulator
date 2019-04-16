//
//  NesGameSoundPlayer.h
//  NESSimulator
//
//  Created by qingzhao on 2019/4/12.
//  Copyright © 2019年 qingzhao. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "Nes_Apu.h"

@interface NesGameSoundPlayer : NSObject

@property(atomic, assign)BOOL pause;

- (void)nes_newsoundSample:(const blip_sample_t*)samples count:(long int)count;

@end
