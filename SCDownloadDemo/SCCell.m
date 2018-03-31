//
//  SCCell.m
//  testOperation
//
//  Created by cheng on 2017/7/28.
//  Copyright © 2017年 cheng. All rights reserved.
//

#import "SCCell.h"
#import "SCDownloader.h"
#import <MediaPlayer/MediaPlayer.h>

@interface SCCell()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIButton *leftBtn;
@property (weak, nonatomic) IBOutlet UIButton *rightBtn;

@end

@implementation SCCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setTask:(SCDownloadTask *)task{
    
    if (_task) {
        [_task setStateBlock:nil];
        [_task setProgressBlock:nil];
    }
    _task = task;
    
    self.titleLabel.text = task.path.lastPathComponent;
    [self layoutStatus:task.state];
    [self layoutProgress:task];
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [task setStateBlock:^(SCDownloadStatus status) {
        
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                 [strongSelf layoutStatus:status];
            }
        }];
        
        [task setProgressBlock:^(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress) {
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf layoutProgress:progress receivedSize:receivedSize expectedSize:expectedSize];
            }
        }];
    });
}


- (void)layoutStatus:(SCDownloadStatus)status{
    
    NSString * string = [NSString stringWithFormat:@"%@ ", [self getStatusTextByState:status]];
    _statusLabel.text = string;
    
    switch (status) {
        case SCDownloadStatus_undefined:{
            [self.leftBtn setTitle:@"" forState:UIControlStateNormal];
            break;}
        case SCDownloadStatus_waitting:{
            [self.leftBtn setTitle:@"开始" forState:UIControlStateNormal];
            break;}
        case SCDownloadStatus_running:{
            [self.leftBtn setTitle:@"暂停" forState:UIControlStateNormal];
            break;}
        case SCDownloadStatus_suspend:{
            [self.leftBtn setTitle:@"继续" forState:UIControlStateNormal];
            break;}
        case SCDownloadStatus_completed:{
            [self.leftBtn setTitle:@"播放" forState:UIControlStateNormal];
            break;}
        case SCDownloadStatus_failed:{
            [self.leftBtn setTitle:@"重试" forState:UIControlStateNormal];
            break;}
            
        default:
            break;
    }
}

- (void)layoutProgress:(SCDownloadTask *)task
{
    [self layoutProgress:task.progress receivedSize:task.downloadedSize expectedSize:task.expectedSize];
}

- (void)layoutProgress:(CGFloat)progress receivedSize:(NSInteger)receivedSize expectedSize:(NSInteger)expectedSize
{
    self.progressLabel.text = [NSString stringWithFormat:@"%@ / %@ = %.2f", [self getStrFormateSize:receivedSize], [self getStrFormateSize:expectedSize], progress];
}

- (NSString *)getStrFormateSize:(NSInteger)size{
    
     double byts =  size * 1.0 / 1024 / 1024;
    if (byts > 1024) {
        return [NSString stringWithFormat:@"%.2fG", byts/1024];
    } else {
        return [NSString stringWithFormat:@"%.2fM", byts];
    }
}

- (NSString *)getStatusTextByState:(SCDownloadStatus)state{
    
    NSString * text = @"未知状态";
    switch (state) {
        case SCDownloadStatus_undefined:{
            break;}
        case SCDownloadStatus_waitting:{
            text = @"等待下载";
            break;}
        case SCDownloadStatus_running:{
            text = @"正在下载";
            break;}
        case SCDownloadStatus_suspend:{
            text = @"下载暂停";
            break;}
        case SCDownloadStatus_completed:{
            text = @"下载完成";
            break;}
        case SCDownloadStatus_failed:{
            text = @"下载失败";
            break;}
            
        default:
            break;
    }
    return text;
}

- (IBAction)btnClink:(UIButton *)sender {
    
    NSString * name = sender.currentTitle;
    if ([name isEqualToString:@"继续"]) {
        [[SCDownloader shared] resumeDownloadWithSCTask:_task];
    }
    if ([name isEqualToString:@"开始"]) {
        [[SCDownloader shared] startDownloadWithWithSCTask:_task];
    }
    if ([name isEqualToString:@"暂停"]) {
        [[SCDownloader shared] suspendDownloadWithSCTask:_task];
    }
    if ([name isEqualToString:@"取消"]) {
        [[SCDownloader shared] cancleDownloadWithSCTask:_task];
    }
    if ([name isEqualToString:@"播放"]) {
        UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
        MPMoviePlayerViewController * mpVC = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:_task.path]];
        [vc presentViewController:mpVC animated:YES completion:nil];
    }
    
}



- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
