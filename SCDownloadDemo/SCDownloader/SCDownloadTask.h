//
//  SCTaskVM.h
//  testOperation
//
//  Created by cheng on 2017/7/28.
//  Copyright © 2017年 cheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

static NSString * const KSCDownloadDir = @"sc_download";

@interface NSString (SCExtension)

/*** 生成MD5摘要*/
- (NSString *)md5;

/*** 文件大小*/
- (NSInteger)fileSize;

/** 拼接下载文件夹*/
- (NSString *)appendCacheDir;

@end

/**
 下载状态

 - SCDownloadStatus_undefined: 未知
 - SCDownloadStatus_waitting: 等待中
 - SCDownloadStatus_running: 下载中
 - SCDownloadStatus_suspend: 暂停
 - SCDownloadStatus_completed: 已完成
 - SCDownloadStatus_failed: 失败
 */
typedef NS_ENUM(NSInteger, SCDownloadStatus) {
    SCDownloadStatus_undefined = -1,
    SCDownloadStatus_waitting,
    SCDownloadStatus_running,
    SCDownloadStatus_suspend,
    SCDownloadStatus_completed,
    SCDownloadStatus_failed
};

typedef void (^SCDownloadProgressBlock) (NSInteger receivedSize, NSInteger expectedSize, CGFloat progress);
typedef void(^SCDownloadStateBlock)(SCDownloadStatus status);
typedef void(^SCDownloadCompleteBlock)(void);

@interface SCDownloadTask : NSObject

/**下载链接*/
@property (nonatomic, copy) NSString * url;
/**identifier*/
@property (nonatomic, copy) NSString * md5;
/**保存路径*/
@property (nonatomic, copy) NSString * path;
/**文件名*/
@property (nonatomic, copy) NSString * fileName;
/**下载状态*/
@property (nonatomic, assign) SCDownloadStatus state;
/**已经下载的大小*/
@property (nonatomic, assign) NSUInteger downloadedSize;
/**总大小*/
@property (nonatomic, assign) NSUInteger expectedSize;
/**进度*/
@property (nonatomic, assign) double progress;
/**下载状态回调*/
@property (nonatomic, copy) SCDownloadStateBlock stateBlock;
/**进度回调*/
@property (nonatomic, copy) SCDownloadProgressBlock progressBlock;
/**任务完成回调*/
@property (nonatomic, copy) SCDownloadCompleteBlock completeBlock;

/**配置*/
- (void)config;

@end
