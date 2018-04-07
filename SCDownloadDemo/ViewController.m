//
//  ViewController.m
//  testOperation
//
//  Created by cheng on 2017/7/28.
//  Copyright © 2017年 cheng. All rights reserved.
//

#import "ViewController.h"
#import "SCCell.h"
#import "SCDownloader.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray * urls;
@property (weak, nonatomic) IBOutlet UITableView *tableview;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _urls = @[].mutableCopy;
    _tableview.estimatedRowHeight = 80;
    _tableview.allowsSelection = NO;
    _tableview.rowHeight = UITableViewAutomaticDimension;
    
    [_tableview registerNib:[UINib nibWithNibName:@"SCCell" bundle:nil] forCellReuseIdentifier:@"SCCell"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:KSCDownloadNeedRefreshNoti object:nil];
    [SCDownloader setMaxConcurrentDownloadCount:3];
    
    [self start:nil];
}


- (IBAction)start:(id)sender {
    
    NSString * path = [[NSBundle mainBundle] pathForResource:@"神经网络和深度学习-吴恩达.txt" ofType:nil];
    NSData * data = [NSData dataWithContentsOfFile:path];
    NSArray * content = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    for (NSDictionary * item in content) {
        NSString * filename = [[[item valueForKey:@"title"] stringByReplacingOccurrencesOfString:@" / " withString:@"-"] stringByAppendingString:@".mp4"];
        NSString * urlString = [item valueForKey:@"shdUrl"];
        SCDownloadTask * task = [[SCDownloadTask alloc] initWithFilename:filename urlString:urlString];
        [[SCDownloader shared] startDownloadWithWithSCTask:task];
    }
    [self refresh];
}

- (IBAction)pause:(id)sender {
    
    [[SCDownloader shared] suspendAllDownload];
}

- (IBAction)cancle:(id)sender {
    
    [self.urls removeAllObjects];
    [self.tableview reloadData];
    [[SCDownloader shared] cancleAllDownload];
}

- (void)refresh
{
    _urls = [SCDownloader shared].tasks.mutableCopy;
    [self.tableview reloadData];
}

#pragma mark - delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _urls.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCDownloadTask * task = _urls[indexPath.row];
    SCCell * cell = [tableView dequeueReusableCellWithIdentifier:@"SCCell"];
    cell.task = task;
    return cell;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end

