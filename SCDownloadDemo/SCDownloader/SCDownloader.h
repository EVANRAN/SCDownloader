//
//  SCDownloader.h
//  testOperation
//
//  Created by cheng on 2017/7/28.
//  Copyright © 2017年 cheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCDownloadTask.h"

static NSString * const KSCDownloadNeedRefreshNoti = @"KSCDownloadNeedRefreshNoti";

@interface SCDownloader : NSObject

+ (instancetype)shared;

/**任务List*/
@property (nonatomic, strong, readonly) NSMutableArray * tasks;

/**设置同时下载的最大值*/
+ (void)setMaxConcurrentDownloadCount:(NSInteger)count;

/**通过一个task开始一个下载*/
- (void)startDownloadWithWithSCTask:(SCDownloadTask *)task;

/**通过一个task暂停一个下载*/
- (void)suspendDownloadWithSCTask:(SCDownloadTask *)task;

/**通过一个task继续一个下载*/
- (void)resumeDownloadWithSCTask:(SCDownloadTask *)task;

/**通过一个task取消一个下载*/
- (void)cancleDownloadWithSCTask:(SCDownloadTask *)task;

/**开始所有下载*/
- (void)startAllDownload;

/**暂停所有下载*/
- (void)suspendAllDownload;

/**取消所有下载*/
- (void)cancleAllDownload;

//通过url获得cache的总大小
- (NSUInteger)getFileTotalSizeByUrl:(NSString *)url;

/**保存文件的总大小 url */
- (void)saveUrl:(NSString *)url totalLength:(NSUInteger)length;

@end
