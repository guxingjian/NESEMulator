//
//  ViewController.m
//  NESSimulator
//
//  Created by qingzhao on 2019/4/4.
//  Copyright © 2019年 qingzhao. All rights reserved.
//

#import "ViewController.h"
#import "NesGameViewController.h"
#import "Heqingzhao_SinglePixelView.h"
#import "UIColor+extension_qingzhao.h"

#import <AVFoundation/AVFoundation.h>

@interface NesGameModel : NSObject

@property(nonatomic, strong)NSString* nesName;
@property(nonatomic, strong)NSString* nesPath;

@end

@implementation NesGameModel

@end

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, assign)BOOL bAudioFlag;
@property(nonatomic, strong)UITableView* tableView;
@property(nonatomic, strong)NSMutableArray* arrayGames;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        self.bAudioFlag = granted;
    }];
    
    UITableView* tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:tableView];
    tableView.delegate = self;
    tableView.dataSource = self;
    self.tableView = tableView;
    
    self.title = @"我的游戏";
    
    UIButton* btnRefresh = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 50)];
    [btnRefresh addTarget:self action:@selector(readGameFiles) forControlEvents:UIControlEventTouchUpInside];
    [btnRefresh setTitle:@"刷新" forState:UIControlStateNormal];
    [btnRefresh setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btnRefresh.titleLabel.font = [UIFont systemFontOfSize:15];
    
    UIBarButtonItem* btnItem = [[UIBarButtonItem alloc] initWithCustomView:btnRefresh];
    self.navigationItem.rightBarButtonItem = btnItem;
    
    [self readGameFiles];
}

- (NSMutableArray *)arrayGames{
    if(!_arrayGames){
        _arrayGames = [NSMutableArray array];
    }
    return _arrayGames;
}

- (void)readGameFiles{
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSDirectoryEnumerator<NSURL *>* fileEnum = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:documentPath] includingPropertiesForKeys:@[NSURLIsRegularFileKey] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
        NSLog(@"error: %@", error);
        return NO;
    }];
    [self.arrayGames removeAllObjects];
    NSURL* fileUrl = [fileEnum nextObject];
    while (fileUrl) {
        NSString* fileName = [[fileUrl.absoluteString stringByRemovingPercentEncoding] lastPathComponent];
        if([fileName hasSuffix:@".nes"]){
            NesGameModel* model = [[NesGameModel alloc] init];
            model.nesName = [fileName componentsSeparatedByString:@"."].firstObject;
            model.nesPath = fileUrl.path;
            [self.arrayGames addObject:model];
        }
        fileUrl = [fileEnum nextObject];
    }
    
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(0 == self.arrayGames.count){
        return 1;
    }
    return self.arrayGames.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(0 == self.arrayGames.count){
        return self.tableView.bounds.size.height;
    }
    return 80;
}

- (void)runDefaultNes{
    NesGameViewController* gameVc = [[NesGameViewController alloc] init];
    gameVc.nesPath = [[NSBundle mainBundle] pathForResource:@"test.nes" ofType:nil];
    gameVc.bAudioStatus = self.bAudioFlag;
    [self.navigationController presentViewController:gameVc animated:YES completion:^{
        
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString* strId = @"cell";
    if(0 == self.arrayGames.count){
        strId = @"EmptyCell";
    }
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:strId];
    if(!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if(0 == self.arrayGames.count){
        UIButton* btnTip = [cell.contentView viewWithTag:2001];
        if(!btnTip){
            btnTip = [[UIButton alloc] initWithFrame:CGRectMake(30, tableView.bounds.size.height/2 - 100/2 - 80, tableView.frame.size.width - 30*2, 100)];
            btnTip.tag = 2001;
            btnTip.titleLabel.font = [UIFont systemFontOfSize:15];
            btnTip.titleLabel.numberOfLines = 0;
            btnTip.titleLabel.textAlignment = NSTextAlignmentCenter;
            [btnTip setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [btnTip setTitle:@"本地没有找到可用的.nes文件，您可以使用iTunes向app添加您喜欢的.nes文件. 点击使用默认的nes游戏" forState:UIControlStateNormal];
            [btnTip addTarget:self action:@selector(runDefaultNes) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:btnTip];
        }
    }else{
        UILabel* labelName = [cell.contentView viewWithTag:1001];
        if(!labelName){
            labelName = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 80)];
            labelName.tag = 1001;
            labelName.font = [UIFont systemFontOfSize:15];
            labelName.textAlignment = NSTextAlignmentCenter;
            labelName.textColor = [UIColor blackColor];
            [cell.contentView addSubview:labelName];
        }
        if(![cell.contentView viewWithTag:1002]){
            Heqingzhao_SinglePixelHorizontalView* lineView = [[Heqingzhao_SinglePixelHorizontalView alloc] initWithFrame:CGRectMake(0, 79, tableView.frame.size.width, 1)];
            lineView.tag = 1002;
            lineView.backgroundColor = [UIColor colorWithHexString:@"#6d676d"];
            [cell.contentView addSubview:lineView];
        }
        
        if(indexPath.row < self.arrayGames.count){
            NesGameModel* model = [self.arrayGames objectAtIndex:indexPath.row];
            labelName.text = model.nesName;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(0 == self.arrayGames.count)
        return ;
    
    NesGameModel* model = [self.arrayGames objectAtIndex:indexPath.row];
    NesGameViewController* gameVc = [[NesGameViewController alloc] init];
    gameVc.nesPath = model.nesPath;
    gameVc.bAudioStatus = self.bAudioFlag;
    [self.navigationController presentViewController:gameVc animated:YES completion:^{
        
    }];
}

@end
