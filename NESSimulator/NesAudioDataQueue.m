//
//  HeVideoState.m
//  he_player
//
//  Created by qingzhao on 2018/7/13.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#import "NesAudioDataQueue.h"

@interface NesAudioDataQueue()

@property(nonatomic, readwrite)NSCondition* condition;

@end

@implementation NesAudioDataQueue
{
    audio_buffer* _head_buf;
    audio_buffer* _tail_buf;
    int _bufCount;
}

- (void)dealloc{
    NSLog(@"audio queue dealloc");
    [self clear];
//    [self clearBuffer];
}

- (NSCondition *)condition{
    if(!_condition){
        _condition = [[NSCondition alloc] init];
    }
    return _condition;
}

- (void)clearBuffer{
    audio_buffer* buf = 0;
    while(_head_buf){
        buf = _head_buf;
        _head_buf = _head_buf->next;
        [self freeBuffer:buf];
    }
    
    _head_buf = nil;
    _tail_buf = nil;
}

- (void)clear{
    [self clearBuffer];
}

- (audio_buffer *)idleAudioBuffer{
    audio_buffer* buffer = malloc(sizeof(audio_buffer));
    buffer->buffer = malloc(self.nSize);
    memset(buffer->buffer, 0, self.nSize);
    buffer->size = self.nSize;
    buffer->next = 0;
    buffer->nIndex = 0;
    return buffer;
}

- (void)putBuffer:(audio_buffer *)buffer{
    [_condition lock];
    if(!buffer){
        buffer = malloc(sizeof(audio_buffer));
    }
    
    if(!_head_buf){
        _head_buf = buffer;
    }else{
        _tail_buf->next = buffer;
    }
    _tail_buf = buffer;
    [_condition unlock];
}

- (audio_buffer *)getHeaderBuffer{
    if(0 == _head_buf)
        return 0;
    return _head_buf;
}

- (void)removeHeaderBuffer{
    [_condition lock];
    audio_buffer* head = _head_buf;
    _head_buf = head->next;
    if(0 == head){
        _tail_buf = 0;
    }
    [_condition unlock];
    [self freeBuffer:head];
}

- (void)freeBuffer:(audio_buffer *)buffer{
    if(!buffer)
        return ;
    free(buffer->buffer);
    free(buffer);
}

@end
