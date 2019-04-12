//
//  NesGameViewController.m
//  NESSimulator
//
//  Created by qingzhao on 2019/4/9.
//  Copyright © 2019年 qingzhao. All rights reserved.
//

#import "NesGameViewController.h"
#import "NesGameScreenView.h"
#import "NesGameSoundPlayer.h"

#include "common.hpp"
#include "apu.hpp"
#include "cartridge.hpp"
#include "cpu.hpp"
#include "ppu.hpp"
#include "joypad.hpp"

enum NES_BTN{
    NES_BTN_A,
    NES_BTN_B,
    NES_BTN_SELECT,
    NES_BTN_START,
    NES_BTN_UP,
    NES_BTN_DOWN,
    NES_BTN_LEFT,
    NES_BTN_RIGHT,
    NES_BTN_TOGETHER
};

static void nesNewFrameCallBack(void* obj, u32* pixel);
static u8 nesJoypadCallBack(void* obj, int n);
static void nesApuCallback(void* obj, const blip_sample_t* samples, long int count);

@interface NesGameViewController ()

@property(nonatomic, strong)NesGameScreenView* gameView;
@property(nonatomic, strong)NesGameSoundPlayer* gameSound;
@property(nonatomic, assign)BOOL pause;
@property(nonatomic, assign)CGFloat frameStart;
@property(nonatomic, assign)CGFloat frameTime;

@property(nonatomic, strong)UIView* directionView;
@property(nonatomic, assign)CGRect rtUp;
@property(nonatomic, assign)CGRect rtDown;
@property(nonatomic, assign)CGRect rtLeft;
@property(nonatomic, assign)CGRect rtRight;
@property(nonatomic, assign)CGRect rtTopLeft;
@property(nonatomic, assign)CGRect rtTopRight;
@property(nonatomic, assign)CGRect rtBottomLeft;
@property(nonatomic, assign)CGRect rtBottomRight;

@property(nonatomic, assign)BOOL AFlag;
@property(nonatomic, assign)BOOL BFlag;


- (u8)get_joypad_state;

@end

@implementation NesGameViewController
{
    u8 btnStatus[8];
}

- (u8)get_joypad_state{
//    const int DEAD_ZONE = 8000;
    u8 j = 0;
    
    j |= btnStatus[NES_BTN_A] << 0;
    j |= btnStatus[NES_BTN_B] << 1;
    j |= btnStatus[NES_BTN_SELECT] << 2;
    j |= btnStatus[NES_BTN_START] << 3;
    
    j |= btnStatus[NES_BTN_UP] << 4;
//    j |= ([self JoystickGetAxis:1] < -DEAD_ZONE) << 4;
    
    j |= btnStatus[NES_BTN_DOWN] << 5;
//    j |= ([self JoystickGetAxis:1] > DEAD_ZONE) << 5;
    
    j |= btnStatus[NES_BTN_LEFT] << 6;
//    j |= ([self JoystickGetAxis:0] < -DEAD_ZONE) << 6;
    
    j |= btnStatus[NES_BTN_RIGHT] << 7;
//    j |= ([self JoystickGetAxis:0] > DEAD_ZONE) << 7;
    
    return j;
}

//- (signed short)JoystickGetAxis:(int)axis{
//    if(!self.dirFlag)
//        return 0;
//    CGPoint pt = self.dirPt;
//    CGFloat flen = (pt.x - self.directionView.center.x)*(pt.x - self.directionView.center.x) + (pt.y - self.directionView.center.y)*(pt.y - self.directionView.center.y);
//    flen = sqrt(flen);
//
//    signed short ret = 0;
//    signed short total = 32767;
//    if(0 == axis){
//        ret = total*(pt.x - self.directionView.center.x)/flen;
//    }else if(1 == axis){
//        ret = total*(pt.y - self.directionView.center.y)/flen;
//    }
//    return ret;
//}

- (void)setupDirectionArea{
    CGFloat fLen = 40;
    CGPoint ptCenter = self.directionView.center;
    CGRect frame = self.view.frame;
    self.rtUp = CGRectMake(ptCenter.x - fLen/2, 0, fLen, ptCenter.y - fLen/2);
    self.rtDown = CGRectMake(ptCenter.x - fLen/2, ptCenter.y + fLen/2, fLen, frame.size.height - ptCenter.y - fLen/2);
    self.rtLeft = CGRectMake(0, ptCenter.y - fLen/2, ptCenter.x - fLen/2, fLen);
    self.rtRight = CGRectMake(ptCenter.x + fLen/2, ptCenter.y - fLen/2, frame.size.width - ptCenter.x - fLen/2, fLen);
    self.rtTopLeft = CGRectMake(0, 0, self.rtUp.origin.x, self.rtLeft.origin.y);
    self.rtTopRight = CGRectMake(self.rtUp.origin.x + self.rtUp.size.width, 0, frame.size.width - (self.rtUp.origin.x + self.rtUp.size.width), self.rtRight.origin.y);
    self.rtBottomLeft = CGRectMake(0, self.rtLeft.origin.y + self.rtLeft.size.height, ptCenter.x - fLen/2, frame.size.height - (self.rtLeft.origin.y + self.rtLeft.size.height));
    self.rtBottomRight = CGRectMake(ptCenter.x + fLen/2, self.rtRight.origin.y + self.rtRight.size.height, frame.size.width - (ptCenter.x + fLen/2), frame.size.height - (self.rtRight.origin.y + self.rtRight.size.height));
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.pause = YES;
    
    CGFloat fW = self.view.bounds.size.height;
    CGFloat fH = self.view.bounds.size.width;
    NesGameScreenView* gameView = [[NesGameScreenView alloc] initWithFrame:CGRectMake(0, 0, fW, fH)];
    [self.view addSubview:gameView];
    self.gameView = gameView;
    
    NesGameSoundPlayer* soundPlayer = [[NesGameSoundPlayer alloc] init];
    self.gameSound = soundPlayer;
    
    CGFloat fLen = 120;
    UIView* directionView = [[UIView alloc] initWithFrame:CGRectMake(10, fH - 20 - fLen, fLen, fLen)];
    directionView.backgroundColor = [UIColor grayColor];
    directionView.layer.cornerRadius = fLen/2;
    directionView.layer.masksToBounds = YES;
    [self.view addSubview:directionView];
    self.directionView = directionView;
    [self setupDirectionArea];
    
    UIButton* btnSelect = [[UIButton alloc] initWithFrame:CGRectMake(fW - 20 - 100, 30, 80, 30)];
    btnSelect.backgroundColor = [UIColor grayColor];
    [btnSelect setTitle:@"选择" forState:UIControlStateNormal];
    [btnSelect setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnSelect addTarget:self action:@selector(selectDownBtn:) forControlEvents:UIControlEventTouchDown];
    [btnSelect addTarget:self action:@selector(selectUpBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnSelect];
    
    UIButton* btnStart = [[UIButton alloc] initWithFrame:CGRectMake(fW - 20 - 100, 90, 80, 30)];
    btnStart.backgroundColor = [UIColor grayColor];
    [btnStart setTitle:@"开始" forState:UIControlStateNormal];
    [btnStart setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnStart addTarget:self action:@selector(startDownBtn:) forControlEvents:UIControlEventTouchDown];
    [btnStart addTarget:self action:@selector(startUpBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnStart];
    
    CGFloat fBtnLen = 60;
    UIButton* btnA = [[UIButton alloc] initWithFrame:CGRectMake(fW - 70, fH - 140, fBtnLen, fBtnLen)];
    btnA.backgroundColor = [UIColor redColor];
    btnA.layer.cornerRadius = fBtnLen/2;
    btnA.layer.masksToBounds = YES;
    [btnA setTitle:@"A" forState:UIControlStateNormal];
    [btnA setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnA addTarget:self action:@selector(aDownBtn:) forControlEvents:UIControlEventTouchDown];
    [btnA addTarget:self action:@selector(aUpBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnA];
    
    UIButton* btnB = [[UIButton alloc] initWithFrame:CGRectMake(fW - 140, fH - 140, fBtnLen, fBtnLen)];
    btnB.backgroundColor = [UIColor blueColor];
    btnB.layer.cornerRadius = fBtnLen/2;
    btnB.layer.masksToBounds = YES;
    [btnB setTitle:@"B" forState:UIControlStateNormal];
    [btnB setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnB addTarget:self action:@selector(bDownBtn:) forControlEvents:UIControlEventTouchDown];
    [btnB addTarget:self action:@selector(bUpBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnB];
    
    UIButton* btnTogether = [[UIButton alloc] initWithFrame:CGRectMake(fW - 100, fH - 70, fBtnLen, fBtnLen)];
    btnTogether.backgroundColor = [UIColor yellowColor];
    btnTogether.layer.cornerRadius = fBtnLen/2;
    btnTogether.layer.masksToBounds = YES;
    [btnTogether addTarget:self action:@selector(togetherDownBtn:) forControlEvents:UIControlEventTouchDown];
    [btnTogether addTarget:self action:@selector(togetherUpBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnTogether];
    
    [self setupEmulator];
}

- (void)makeTogetherSerial{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(!self.AFlag || !self.BFlag)
            return ;
        self->btnStatus[NES_BTN_A] = !self->btnStatus[NES_BTN_A];
        self->btnStatus[NES_BTN_B] = !self->btnStatus[NES_BTN_B];
        [self makeTogetherSerial];
    });
}

- (void)togetherDownBtn:(UIButton*)btn{
    btnStatus[NES_BTN_A] = 1;
    btnStatus[NES_BTN_B] = 1;
    self.AFlag = YES;
    self.BFlag = YES;
    [self makeTogetherSerial];
}

- (void)togetherUpBtn:(UIButton*)btn{
    self.AFlag = NO;
    self.BFlag = NO;
    btnStatus[NES_BTN_A] = 0;
    btnStatus[NES_BTN_B] = 0;
}

- (void)makeBBtnSerial{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(!self.BFlag)
            return ;
        self->btnStatus[NES_BTN_B] = !self->btnStatus[NES_BTN_B];
        [self makeBBtnSerial];
    });
}

- (void)bDownBtn:(UIButton*)btn{
    btnStatus[NES_BTN_B] = 1;
    self.BFlag = YES;
    [self makeBBtnSerial];
}

- (void)bUpBtn:(UIButton*)btn{
    self.BFlag = NO;
    btnStatus[NES_BTN_B] = 0;
}

- (void)makeABtnSerial{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(!self.AFlag)
            return ;
        self->btnStatus[NES_BTN_A] = !self->btnStatus[NES_BTN_A];
        [self makeABtnSerial];
    });
}

- (void)aDownBtn:(UIButton*)btn{
    btnStatus[NES_BTN_A] = 1;
    self.AFlag = YES;
    [self makeABtnSerial];
}

- (void)aUpBtn:(UIButton*)btn{
    self.AFlag = NO;
    btnStatus[NES_BTN_A] = 0;
}

- (void)selectDownBtn:(UIButton*)btn{
    btnStatus[NES_BTN_SELECT] = 1;
}

- (void)selectUpBtn:(UIButton*)btn{
    btnStatus[NES_BTN_SELECT] = 0;
}

- (void)startDownBtn:(UIButton*)btn{
    btnStatus[NES_BTN_START] = 1;
}

- (void)startUpBtn:(UIButton*)btn{
    btnStatus[NES_BTN_START] = 0;
}

- (void)clearDirectionStatus{
    for(NSInteger i = NES_BTN_UP; i <= NES_BTN_RIGHT; ++ i){
        btnStatus[i] = 0;
    }
}

- (void)positionChanged:(CGPoint)pt{
    [self clearDirectionStatus];
    if(CGRectContainsPoint(self.rtUp, pt)){
        btnStatus[NES_BTN_UP] = 1;
    }else if(CGRectContainsPoint(self.rtDown, pt)){
        btnStatus[NES_BTN_DOWN] = 1;
    }else if(CGRectContainsPoint(self.rtLeft, pt)){
        btnStatus[NES_BTN_LEFT] = 1;
    }else if(CGRectContainsPoint(self.rtRight, pt)){
        btnStatus[NES_BTN_RIGHT] = 1;
    }else if(CGRectContainsPoint(self.rtTopLeft, pt)){
        btnStatus[NES_BTN_UP] = 1;
        btnStatus[NES_BTN_LEFT] = 1;
    }else if(CGRectContainsPoint(self.rtTopRight, pt)){
        btnStatus[NES_BTN_UP] = 1;
        btnStatus[NES_BTN_RIGHT] = 1;
    }else if(CGRectContainsPoint(self.rtBottomLeft, pt)){
        btnStatus[NES_BTN_DOWN] = 1;
        btnStatus[NES_BTN_LEFT] = 1;
    }else if(CGRectContainsPoint(self.rtBottomRight, pt)){
        btnStatus[NES_BTN_DOWN] = 1;
        btnStatus[NES_BTN_RIGHT] = 1;
    }
}

- (void)setupEmulator{
    APU::init();
    NSString* nesPath = [[NSBundle mainBundle] pathForResource:@"test2.nes" ofType:nil];
    Cartridge::load([nesPath UTF8String]);
    if(Cartridge::loaded()){
        self.pause = NO;
    }
    PPU::registeNewFrame((__bridge void*)self.gameView, nesNewFrameCallBack);
    Joypad::registeJoypadCallback((__bridge void*)self, nesJoypadCallBack);
    APU::registeSoundCallback((__bridge void*)self.gameSound, nesApuCallback);
    [self run];
}

- (void)run{
    const int FPS   = 60;
    const CGFloat DELAY = 1000.0f / FPS;
    
    self.frameStart = [NSDate timeIntervalSinceReferenceDate]*1000;
    if (!self.pause){
        CPU::run_frame();
    }
    
    self.frameTime = [NSDate timeIntervalSinceReferenceDate]*1000 - self.frameStart;
    if (self.frameTime < DELAY){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((DELAY - self.frameTime) * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [self run];
        });
    }else{
        [self run];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscapeLeft;
}

- (BOOL)shouldAutorotate{
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    UITouch* touch = [touches anyObject];
    CGPoint pt = [touch locationInView:self.view];
    [self positionChanged:pt];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesMoved:touches withEvent:event];
    UITouch* touch = [touches anyObject];
    CGPoint pt = [touch locationInView:self.view];
    [self positionChanged:pt];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    [self clearDirectionStatus];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesCancelled:touches withEvent:event];
    [self clearDirectionStatus];
}

@end

static void nesNewFrameCallBack(void* obj, u32* pixel){
    NesGameScreenView* gameView = (__bridge NesGameScreenView*)obj;
    [gameView nes_newframe:pixel];
}

static u8 nesJoypadCallBack(void* obj, int n){
    NesGameViewController* vc = (__bridge NesGameViewController*)obj;
    return [vc get_joypad_state];
}

static void nesApuCallback(void* obj, const blip_sample_t* samples, long int count){
    
}
