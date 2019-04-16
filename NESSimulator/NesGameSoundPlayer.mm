//
//  NesGameSoundPlayer.m
//  NESSimulator
//
//  Created by qingzhao on 2019/4/12.
//  Copyright © 2019年 qingzhao. All rights reserved.
//

#import "NesGameSoundPlayer.h"
#import "NesAudioDataQueue.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#define BUFFER_COUNT 3
#define BUFFER_SIZE 4096

@implementation NesGameSoundPlayer
{
    AudioQueueRef queueRef;
    AudioQueueBufferRef buffers[BUFFER_COUNT];
    dispatch_queue_t _audioDispatchQueue;
    
    UInt32 nUnit;
    
    NesAudioDataQueue* audioDataQueue;
    dispatch_queue_t _audioStoreQueue;
}

- (void)dealloc{
}

- (instancetype)init{
    if(self = [super init]){
        [self setupAudioQueue];
        
        AVAudioSession* session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        [session setActive:YES error:nil];
    }
    return self;
}

- (void)setupAudioQueue{
    _audioDispatchQueue = dispatch_queue_create("audioqueue", DISPATCH_QUEUE_SERIAL);
    nUnit = sizeof(blip_sample_t);
    _audioStoreQueue = dispatch_queue_create("audioStoreQueue", DISPATCH_QUEUE_SERIAL);
    audioDataQueue = [[NesAudioDataQueue alloc] init];
    audioDataQueue.nSize = BUFFER_SIZE*nUnit;
    
    AudioStreamBasicDescription des;
    des.mSampleRate = 96000;
    des.mFormatID=kAudioFormatLinearPCM;
    des.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    des.mBitsPerChannel=16;//采样的位数
    des.mChannelsPerFrame=1;//通道数
    des.mBytesPerFrame= (1*des.mBitsPerChannel)/8;
    des.mFramesPerPacket=1;
    des.mBytesPerPacket = des.mFramesPerPacket*des.mBytesPerFrame;
    des.mReserved = 0;
    
    __weak typeof(self) weakSelf = self;
    AudioQueueNewOutputWithDispatchQueue(&queueRef, &des, 0, _audioDispatchQueue, ^(AudioQueueRef  _Nonnull inAQ, AudioQueueBufferRef  _Nonnull inBuffer) {
        [weakSelf pickAudioPacketWithQueue:inAQ Buffer:inBuffer];
    });
    
    for(int i = 0 ; i < BUFFER_COUNT ; i ++){
        AudioQueueAllocateBuffer(queueRef, BUFFER_SIZE*nUnit, &buffers[i]);
    }
    
    Float32 gain = 5.0;
    AudioQueueSetParameter(queueRef, kAudioQueueParam_Volume, gain);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for(int i = 0 ; i < BUFFER_COUNT ; i ++){
            [self pickAudioPacketWithQueue:self->queueRef Buffer:self->buffers[i]];
        }
        AudioQueueStart(self->queueRef, NULL);
    });
}

- (void)nes_newsoundSample:(const blip_sample_t*)samples count:(long int)count{
    if(self.pause)
        return ;
    
    uint8_t* tempBuff = (uint8_t*)malloc(count*nUnit);
    memcpy(tempBuff, samples, count*nUnit);
    dispatch_async(_audioStoreQueue, ^{
        audio_buffer* audioPacket = (audio_buffer*)malloc(sizeof(audio_buffer));
        audioPacket->buffer = tempBuff;
        audioPacket->size = (UInt32)count*self->nUnit;
        audioPacket->next = 0;
        audioPacket->nIndex = 0;
        [self->audioDataQueue putBuffer:audioPacket];
    });
}

- (void)pickAudioPacketWithQueue:(AudioQueueRef)queue Buffer:(AudioQueueBufferRef)bufferRef{
    if(!self){
        dispatch_async(dispatch_get_main_queue(), ^{
            AudioQueueDispose(queue, YES);
        });
        return ;
    }
    
    audio_buffer* audioBuffer = [audioDataQueue getHeaderBuffer];
    if(!audioBuffer){
        audioBuffer = [audioDataQueue idleAudioBuffer];
        memcpy(bufferRef->mAudioData, audioBuffer->buffer, audioBuffer->size);
    }else{
        UInt32 needLen = BUFFER_SIZE*nUnit;
        UInt32 bufferLen = audioBuffer->size - audioBuffer->nIndex;
        UInt32 nAudioOffset = 0;
        UInt32 nCopyLen = bufferLen;
        if(needLen < bufferLen){
            nCopyLen = needLen;
        }
        
        while(needLen > 0){
            memcpy((uint8_t*)bufferRef->mAudioData + nAudioOffset, audioBuffer->buffer + audioBuffer->nIndex, nCopyLen);
            audioBuffer->nIndex += nCopyLen;
            if(audioBuffer->nIndex == audioBuffer->size){
                [audioDataQueue removeHeaderBuffer];
                audioBuffer = [audioDataQueue getHeaderBuffer];
            }
            
            needLen -= nCopyLen;
            if(0 == needLen)
                break ;
            
            nAudioOffset += nCopyLen;
            bufferLen = audioBuffer->size - audioBuffer->nIndex;
            if(bufferLen < needLen){
                nCopyLen = bufferLen;
            }else{
                nCopyLen = needLen;
            }
        }
    }
    
    bufferRef->mAudioDataByteSize = BUFFER_SIZE*nUnit;
    AudioQueueEnqueueBuffer(queueRef, bufferRef, 0, nil);
}

@end
