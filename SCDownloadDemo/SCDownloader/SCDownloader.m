//
//  SCDownloader.m
//  testOperation
//
//  Created by cheng on 2017/7/28.
//  Copyright © 2017年 cheng. All rights reserved.
//

#import "SCDownloader.h"
#import "SCOperation.h"

@interface SCDownloader ()

// 所有url 对应的任务
@property (nonatomic, strong) NSMutableDictionary * taskDict;

/**所有文件大小缓存路径*/
@property (nonatomic, copy) NSString * totalFileSizeCachePath;
/**所有文件大小存储dict*/
@property (nonatomic, strong) NSMutableDictionary * totalFileSizeDict;
// 任务数组
@property (nonatomic, strong, readwrite) NSMutableArray * tasks;
//所有url 对应的op
@property (nonatomic, strong) NSMutableDictionary * operations;
/**operation queue*/
@property (nonatomic, strong) NSOperationQueue * operationQueue;

@end

@implementation SCDownloader

static SCDownloader * _downloader = nil;
+ (instancetype)shared{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloader = [[self alloc] init];
    });
    return _downloader;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloader = [super allocWithZone:zone];
    });
    return _downloader;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self config];
    }
    return self;
}

- (void)config
{
    _taskDict = @{}.mutableCopy;
    _operations = @{}.mutableCopy;
    _tasks = @[].mutableCopy;
    _totalFileSizeCachePath = [@"SCDownloadFileSizes" appendCacheDir];
    NSLog(@"\n*********************************\n\n\ndownload path - %@\n\n\n\n*********************************\n", [@"" appendCacheDir]);
    _totalFileSizeDict = [NSMutableDictionary dictionaryWithContentsOfFile:_totalFileSizeCachePath];
    if (_totalFileSizeDict == nil) {
        _totalFileSizeDict = @{}.mutableCopy;
    }
    
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.maxConcurrentOperationCount = 1;
    
}

+ (void)setMaxConcurrentDownloadCount:(NSInteger)count{
    
    SCDownloader * downloader = [self shared];
    downloader.operationQueue.maxConcurrentOperationCount = count;
}

#pragma mark - get task

- (SCDownloadTask *)getDownloaderTaskWithMD5:(NSString *)md5
{
    SCDownloadTask * task = [self.taskDict valueForKey:md5];
    return task;
}

- (NSUInteger)getFileTotalSizeByUrl:(NSString *)url{
    return [[_totalFileSizeDict valueForKey:url.md5] integerValue];
}

- (void)saveUrl:(NSString *)url totalLength:(NSUInteger)length{
    
    [_totalFileSizeDict setValue:@(length) forKey:url.md5];
    [_totalFileSizeDict writeToFile:_totalFileSizeCachePath atomically:YES];
}


#pragma mark - start

/**
 开始/继续所有的下载
 */
- (void)startAllDownload
{
    [self.tasks enumerateObjectsUsingBlock:^(SCDownloadTask *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self startDownloadWithWithSCTask:obj];
    }];
}

/**
 通过一个task 开始一个下载
 */
- (void)startDownloadWithWithSCTask:(SCDownloadTask *)task
{
    __weak typeof(self) weakSelf = self;
    
    //1. 先检查是否下载过（task 已经改变了状态）
    
    //2. 检查是否正在下载
    SCDownloadTask * downloadingTask = [self getDownloaderTaskWithMD5:task.md5];
    
    //3. 没有就加入到 map
    if (!downloadingTask) {
        downloadingTask = task;
        NSString * md5 = downloadingTask.md5;
        [downloadingTask setCompleteBlock:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.operations removeObjectForKey:md5];
        }];
        [self.taskDict setObject:task forKey:task.md5];
        [self.tasks addObject:task];
    }
    
    //4. 检查是否有task所对应的Operation
    SCOperation * op = [self.operations valueForKey:downloadingTask.md5];
    if (!op && downloadingTask.state != SCDownloadStatus_completed) {
        [self createSCOperationWithSCTask:downloadingTask priority:0];
    }
}

/**
 通过一个task 创建一个operation
 */
- (void)createSCOperationWithSCTask:(SCDownloadTask *)task priority:(NSOperationQueuePriority)priority
{
    SCOperation * op = [[SCOperation alloc] init];
    op.queuePriority = priority;
    op.task = task;
    [self.operationQueue addOperation:op];
    [self.operations setObject:op forKey:task.md5];
}


#pragma mark - suspend

/**
 暂停所有的下载
 */
- (void)suspendAllDownload
{
    [self.operationQueue cancelAllOperations];
    [self.taskDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, SCDownloadTask *  _Nonnull obj, BOOL * _Nonnull stop) {
        [self suspendDownloadWithSCTask:obj];
    }];
}

/**
 通过一个task 暂停下载
 */
- (void)suspendDownloadWithSCTask:(SCDownloadTask *)task
{
    SCOperation * op = [self.operations objectForKey:task.md5];
    if (task.state == SCDownloadStatus_running) {
        
        task.state = SCDownloadStatus_suspend;
        [op sc_suspend];
    }
    [self.operations removeObjectForKey:task.md5];
}


#pragma mark - resume
/**
 * 继续下载一个task,
 * 说明肯定存在这个task
 * 需要重新创建一个op
 * 需要判断此场景- 当前队列正在下载， 需要继续，肯定是之前手动点了某一个的暂停，重新继续下载采取的策略是重新创建一个新的op， 但是又不想让它排到operation queue 的最后面， 所以此时要增加这个op 的优先级
 */

- (void)resumeDownloadWithSCTask:(SCDownloadTask *)task
{
    if (task) {
        NSOperationQueuePriority priority = (self.operationQueue.operationCount && !self.operationQueue.isSuspended) ? NSOperationQueuePriorityHigh : NSOperationQueuePriorityNormal;
        task.state = SCDownloadStatus_waitting;
        [self createSCOperationWithSCTask:task priority:priority];
    }
}


#pragma mark - cancle

/**
 删除掉所有的下载
 */
- (void)cancleAllDownload
{
    [self suspendAllDownload];
    [self.taskDict removeAllObjects];
    [self.tasks removeAllObjects];
    [[NSNotificationCenter defaultCenter] postNotificationName:KSCDownloadNeedRefreshNoti object:nil];
}


/**
 删除一个下载
 */
- (void)cancleDownloadWithSCTask:(SCDownloadTask *)task
{
    if (!task) {
        return;
    }
    NSString * md5 = task.md5;
    [self suspendDownloadWithSCTask:task];
    [self.tasks removeObject:task];
    [self.taskDict removeObjectForKey:md5];
    [[NSNotificationCenter defaultCenter] postNotificationName:KSCDownloadNeedRefreshNoti object:nil];
}

@end
