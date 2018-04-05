//
//  SCDownloaderTests.m
//  SCDownloadDemoTests
//
//  Created by cheng on 2018/4/5.
//  Copyright © 2018年 cheng. All rights reserved.
//


#import <XCTest/XCTest.h>
#import "SCDownloader.h"

const int64_t kAsyncTestTimeout = 5;
const int64_t kMinDelayNanosecond = NSEC_PER_MSEC * 100; // 0.1s

@interface SCDownloaderTests : XCTestCase

@end

@implementation SCDownloaderTests

- (void)test01ThatSharedDownloaderIsNotEqualToInitDownloader
{
    SCDownloader * downloader = [[SCDownloader alloc] init];
    XCTAssertEqual(downloader, [SCDownloader shared], @"SCDownloader is not equal");
}

- (void)test02Cancle
{
    XCTestExpectation * expectation = [self expectationWithDescription:@"Cancle"];
    SCDownloadTask * task = [SCDownloadTask new];
    task.url = @"http://v.stu.126.net/mooc-video/nos/mp4/2017/08/29/1006889357_2015a3c8f1ae4934b66c1fcdfd3d7c61_shd.mp4?ak=3c1b27f96e79b6f2630f2d7bc8c997e2feb0cc7862207077abfe9a6a7b1ccff6558e4badf8088fbe71f49610e689ea431ee2fb6240fc719e1b3940ed872a11f18b99430082f8bb7f5497b3ad9dfc23e31e46d140b7b30f910299bee40b26a5c2d9e1e3c44585e5de5b539ccdbe8423a821b91261e44e538d2765af73aa008299a7f5cc498d43fe59a782bc973c30c066b767da1f870bc890754ea6567cb70ca9830b67d08aac63e1ac0c534090a89323f6fd9d4e9030d5d8cb0cb4b5fcb8e77c";
    task.fileName = @"1.1欢迎来到深度学习.mp4";
    [task config];
    [[SCDownloader shared] startDownloadWithWithSCTask:task];
    [[SCDownloader shared] cancleAllDownload];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kMinDelayNanosecond), dispatch_get_main_queue(), ^{
        NSLog(@"opertaion count - %zd", [SCDownloader shared].opertionCount);
        XCTAssertEqual([SCDownloader shared].opertionCount, 0, @"is running");
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:nil];
}

@end
