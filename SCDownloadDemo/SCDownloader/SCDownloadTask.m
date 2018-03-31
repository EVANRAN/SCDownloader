//
//  SCTaskVM.m
//  testOperation
//
//  Created by cheng on 2017/7/28.
//  Copyright © 2017年 cheng. All rights reserved.
//

#import "SCDownloadTask.h"
#import "SCDownloader.h"

@implementation NSString (SCExtension)

- (NSString *)md5{
    // 得出bytes
    const char *cstring = self.UTF8String;
    unsigned char bytes[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cstring, (CC_LONG)strlen(cstring), bytes);
    
    // 拼接
    NSMutableString *md5String = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5String appendFormat:@"%02x", bytes[i]];
    }
    return md5String;
}

- (NSInteger)fileSize
{
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:self error:nil][NSFileSize] integerValue];
}

/** 拼接下载文件夹*/
- (NSString *)appendCacheDir{
    NSString * path = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    return [NSString stringWithFormat:@"%@/%@/%@", path, KSCDownloadDir, self];
}

@end

@implementation SCDownloadTask

- (NSString *)path
{
    if (!_path) {
        _path = [self.fileName appendCacheDir];
    }
    if (_path && ![[NSFileManager defaultManager] fileExistsAtPath:_path]) {
        NSString *dir = [_path stringByDeletingLastPathComponent];
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return _path;
}

- (NSString *)fileName
{
    if (!_fileName) {
        NSString *pathExtension = self.url.pathExtension;
        if (pathExtension.length) {
            pathExtension = [pathExtension componentsSeparatedByString:@"?"].firstObject;
        }
        if (pathExtension.length) {
            _fileName = [NSString stringWithFormat:@"%@.%@", self.url.md5, pathExtension];
        } else {
            _fileName = self.url.md5;
        }
    }
    return _fileName;
}

- (void)config
{
    _md5 = _url.md5;
    _downloadedSize = [self.path fileSize];
    _state = SCDownloadStatus_waitting;
    _expectedSize = [[SCDownloader shared] getFileTotalSizeByUrl:_url];
    if (_expectedSize) {
        _progress = _downloadedSize * 1.0 / _expectedSize;
    } else {
        _progress = 0;
    }
    
    if (_progress >= 1.0) {
        _state = SCDownloadStatus_completed;
    }
}

- (void)setState:(SCDownloadStatus)state
{
    _state = state;
    
    if (_state == SCDownloadStatus_completed && _completeBlock ) {
        _completeBlock();
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_stateBlock) {
            _stateBlock(_state);
        }
    });
    
}

- (void)setDownloadedSize:(NSUInteger)downloadedSize{
    _downloadedSize = downloadedSize;
    self.progress = _downloadedSize * 1.0 / _expectedSize;
}

- (void)setExpectedSize:(NSUInteger)expectedSize{
    _expectedSize = expectedSize;
    [[SCDownloader shared] saveUrl:_url totalLength:expectedSize];
    self.progress = _downloadedSize * 1.0 / _expectedSize;
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_progressBlock) {
            _progressBlock(_downloadedSize, _expectedSize, progress);
        }
    });
}

@end
