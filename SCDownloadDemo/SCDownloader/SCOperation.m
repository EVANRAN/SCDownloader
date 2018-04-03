//
//  SCOperation.m
//  testOperation
//
//  Created by cheng on 2017/7/28.
//  Copyright © 2017年 cheng. All rights reserved.
//

#import "SCOperation.h"

@interface  SCOperation () <NSURLSessionDelegate>

@property (nonatomic, assign, getter=isExecuting) BOOL executing;
@property (nonatomic, assign, getter=isFinished) BOOL finished;
/**输出流*/
@property (nonatomic, strong) NSOutputStream * outputStream;
/**sessionTask*/
@property (nonatomic, strong) NSURLSessionDataTask * sessionTask;
/**session*/
@property (nonatomic, strong) NSURLSession * session;

@end


@implementation SCOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

#pragma mark - setter
- (instancetype)init
{
    self = [super init];
    if (self) {
        _executing = NO;
        _finished = NO;
    }
    return self;
}

- (void)setTask:(SCDownloadTask *)task{
    _task = task;
}

- (void)setExecuting:(BOOL)executing{
    
    [self willChangeValueForKey:@"executing"];
    _executing = executing;
    [self didChangeValueForKey:@"executing"];
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"finished"];
    _finished = finished;
    [self didChangeValueForKey:@"finished"];
}

/**下载完成*/
- (void)done
{
    self.executing = NO;
    self.finished = YES;
}

- (void)sc_suspend
{
    [_sessionTask cancel];
}

#pragma mark - main
- (void)start{
    
    @synchronized(self){
        if (self.cancelled) {
            self.finished = YES;
            return;
        }
    }

    self.executing = YES;
    self.task.state = SCDownloadStatus_running;
    
//     此处为了方便演示，每个operation 都创建了一个session，实际开发中最好在downloader中只创建一次，让dataTask关联上SCDownloadTask来处理回调。
//     原因： 为了处理后台下载， 详情 @" https://developer.apple.com/documentation/foundation/url_loading_system/downloading_files_in_the_background?language=objc "
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:nil];
    
    NSOutputStream *stream = [NSOutputStream outputStreamToFileAtPath:self.task.path append:YES];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                    [NSURL URLWithString:self.task.url]];
    
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", self.task.downloadedSize];
    [request setValue:range forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
   
    _session = session;
    _sessionTask = task;
    _outputStream = stream;
    [task resume];
    
}

#pragma mark - delegate

- (void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSHTTPURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler
{
    
    if (response.statusCode < 200 || response.statusCode >= 400) {
   
        _task.state = SCDownloadStatus_failed;
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    
    [_outputStream open];
    long long  totalLength = [response.allHeaderFields[@"Content-Length"] longLongValue];
    
    if (!_task.expectedSize) {
        if (!_task.downloadedSize) {
            _task.expectedSize = totalLength;
        } else {
            _task.expectedSize = totalLength + _task.downloadedSize;
        }
        
    }

    completionHandler(NSURLSessionResponseAllow);
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveData:(nonnull NSData *)data
{
    [_outputStream write:data.bytes maxLength:data.length];
    _task.downloadedSize += data.length;

}

- (void)URLSession:(NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    [_outputStream close];
    [_session finishTasksAndInvalidate];
    
    if (!(_task.state == SCDownloadStatus_completed || _task.state == SCDownloadStatus_failed)) {

        if (error) {
            
            if (error.code == -999) {
                _task.state = SCDownloadStatus_suspend;
            } else {
                _task.state = SCDownloadStatus_failed;
            }
        } else {
            _task.state = SCDownloadStatus_completed;
        }
    }
    
    [self done];
}

@end
