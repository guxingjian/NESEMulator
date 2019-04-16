//
//  SFSinglePixelHorizontalView.m
//  SinaFinance
//
//  Created by qingzhao on 2018/3/23.
//  Copyright © 2018年 sina.com. All rights reserved.
//

#import "Heqingzhao_SinglePixelView.h"
#import "UIColor+extension_qingzhao.h"

@implementation Heqingzhao_SinglePixelView

- (CALayer *)lineLayer
{
    if(!_lineLayer)
    {
        _lineLayer = [CALayer layer];
        [self.layer addSublayer:_lineLayer];
    }
    return _lineLayer;
}

- (CGFloat)onePixelInPoint
{
    return 1.0/[UIScreen mainScreen].scale;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    self.strColor = @"#E5E6F2";
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self setLineColor];
    [self setLineFrame];
    [CATransaction commit];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        [self setup];
    }
    return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:[UIColor clearColor]];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self setLineFrame];
    [CATransaction commit];
}

- (void)setLineColor
{
    
}

- (void)setLineFrame
{
    
}

@end

@interface Heqingzhao_SinglePixelHorizontalView()

@end

@implementation Heqingzhao_SinglePixelHorizontalView

- (void)setFrame:(CGRect)frame
{
    frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 1);
    [super setFrame:frame];
}

- (void)setLineColor
{
    self.lineLayer.backgroundColor = [UIColor colorWithHexString:self.strColor].CGColor;
}

- (void)setLineFrame
{
    if(self.bTop)
    {
        self.lineLayer.frame = CGRectMake(0, 0, self.bounds.size.width, self.onePixelInPoint);
    }
    else
    {
        self.lineLayer.frame = CGRectMake(0, self.bounds.size.height - self.onePixelInPoint, self.bounds.size.width, self.onePixelInPoint);
    }
}

@end

@implementation Heqingzhao_SinglePixelVerticalView

- (void)setFrame:(CGRect)frame
{
    frame = CGRectMake(frame.origin.x, frame.origin.y, 1, frame.size.height);
    [super setFrame:frame];
}

- (void)setLineColor
{
    self.lineLayer.backgroundColor = [UIColor colorWithHexString:self.strColor].CGColor;
}

- (void)setLineFrame
{
    if(self.bLeft)
    {
        self.lineLayer.frame = CGRectMake(0, 0, self.onePixelInPoint, self.bounds.size.height);
    }
    else
    {
        self.lineLayer.frame = CGRectMake(self.bounds.size.width - self.onePixelInPoint, 0, self.onePixelInPoint, self.bounds.size.height);
    }
}

@end

