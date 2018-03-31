//
//  SCOperation.h
//  testOperation
//
//  Created by cheng on 2017/7/28.
//  Copyright © 2017年 cheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCDownloadTask.h"

@interface SCOperation : NSOperation

@property (nonatomic, weak) SCDownloadTask * task;

/**
 暂停这个下载任务
 */
- (void)sc_suspend;

@end
