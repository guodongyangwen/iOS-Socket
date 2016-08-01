//
//  ViewController.m
//  CFNetworkDemo
//
//  Created by gdy on 2016/7/27.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import "ViewController.h"
#import <CFNetwork/CFNetwork.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageV;
@property (nonatomic, strong)NSMutableData *imageData;
@property (nonatomic, strong)UIActivityIndicatorView *indicatorV;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.indicatorV = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(110, 85, 100, 100)];
    self.indicatorV.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [self.view addSubview:self.indicatorV];
    [self.view bringSubviewToFront:self.indicatorV];
    self.indicatorV.hidden = YES;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)requestImageComplete{
    UIImage* image = [UIImage imageWithData:self.imageData];
    self.imageV.image = image;
}

- (IBAction)requestImage:(id)sender {
    self.indicatorV.hidden = NO;
    [self.indicatorV startAnimating];
    [NSThread detachNewThreadSelector:@selector(request) toTarget:self withObject:nil];
}

- (void)request{
    //url
    CFStringRef urlStr = CFSTR("http://pics.sc.chinaz.com/files/pic/pic9/201605/apic20649.jpg");
    //GET请求
    CFStringRef method = CFSTR("GET");
    //构造url
    CFURLRef url = CFURLCreateWithString(kCFAllocatorDefault, urlStr, NULL);
    //http请求
    CFHTTPMessageRef request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, method, url, kCFHTTPVersion1_1);
    //创建一个读取流，读取网络数据
    CFReadStreamRef readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, request);
    //设置流的context，这里将self传入，用于回调
    CFStreamClientContext ctx = {0,(__bridge void*)(self),NULL,NULL,NULL};
    //设置回调事件，用于监听网络事件
    //  kCFStreamEventNone,（没有事件发生）
    //  kCFStreamEventOpenCompleted,（流被成功打开）
    //  kCFStreamEventHasBytesAvailable,（有数据可以读取）
    //  kCFStreamEventCanAcceptBytes,（流可以接受写入数据（用于写入流））
    //  kCFStreamEventErrorOccurred,（在流上有错误发生）
    //  kCFStreamEventEndEncountered ,（到达了流的结束位置）
    
    CFOptionFlags event = kCFStreamEventHasBytesAvailable | kCFStreamEventEndEncountered;
    
    CFReadStreamSetClient(readStream, event, myCallBack, &ctx);
    //打开输入流
    CFReadStreamOpen(readStream);
    //将流加入到runloop中
    CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    //开启runloop
    CFRunLoopRun();
}

//回调函数
void myCallBack(CFReadStreamRef stream,CFStreamEventType type ,void* clientCallBackInfo){
    ViewController* self = (__bridge ViewController*)clientCallBackInfo;
    
    if (type == kCFStreamEventHasBytesAvailable) {
        UInt8 buff[255];
        int length = CFReadStreamRead(stream, buff, 255);
        if (!self.imageData) {
            self.imageData = [NSMutableData data];
        }
        [self.imageData appendBytes:buff length:length];
        
    }
    
    if (type == kCFStreamEventEndEncountered) {
        [self.indicatorV stopAnimating];
        self.indicatorV.hidden = YES;
        [self requestImageComplete];
        //关闭流
        CFReadStreamClose(stream);
        //将流从runloop中移除
        CFReadStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    }
}

@end
