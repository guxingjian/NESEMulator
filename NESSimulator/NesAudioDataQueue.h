//
//  HeVideoState.h
//  he_player
//
//  Created by qingzhao on 2018/7/13.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct audio_buffer{
    uint8_t* buffer;
    UInt32 size;
    UInt32 nIndex;
    struct audio_buffer* next;
}audio_buffer;

@interface NesAudioDataQueue : NSObject

@property(nonatomic, assign)UInt32 nSize;
- (audio_buffer*)idleAudioBuffer;
- (void)putBuffer:(audio_buffer*)buffer;
- (audio_buffer*)getHeaderBuffer;
- (void)removeHeaderBuffer;

- (void)clear;

@end
