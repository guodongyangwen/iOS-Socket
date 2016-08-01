//
//  ViewController.m
//  CFSocketClient
//
//  Created by gdy on 2016/7/26.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import "ViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>


@interface ViewController ()

@property (nonatomic, assign)CFSocketRef socket;
@property (nonatomic, assign)BOOL isOnline;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)connectToServer:(id)sender {
    [NSThread detachNewThreadSelector:@selector(connectServer) toTarget:self withObject:nil];
}

- (void)connectServer{
    //创建套接字
    self.socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketConnectCallBack, ServerConnectCallBack, NULL);
//    self.socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketNoCallBack, nil, NULL);
    if (_socket != nil) {
        //配置地址和端口
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_len = sizeof(addr);
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = inet_addr("172.100.108.52");
        addr.sin_port = htons(8888);
        
        CFDataRef address = CFDataCreate(kCFAllocatorDefault, (UInt8*)&addr, sizeof((addr)));
        //连接服务器
        CFSocketError result = CFSocketConnectToAddress(_socket, address, 5);
        
        //启用新线程来读取服务器响应的数据
        if (result == kCFSocketSuccess) {
            _isOnline = YES;
            [NSThread detachNewThreadSelector:@selector(readStream) toTarget:self withObject:nil];
        }
        
        CFRunLoopRef cfrl = CFRunLoopGetCurrent();
        CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, self.socket, 0);
        CFRunLoopAddSource(cfrl, source, kCFRunLoopCommonModes);
        CFRelease(source);
        CFRunLoopRun();

    }
}

//连接成功的回调函数

void ServerConnectCallBack(CFSocketRef socket,CFSocketCallBackType type,CFDataRef address,const void* data,void *info){
    if (data != NULL) {
        printf("connect\n");//连接事件，该指针存放连接错误码
    }
    else{
        printf("connect success\n");
    }
}

//读取数据

- (void)readStream{
    char buff[2048];
    int hasRead;
    ssize_t buffLen = sizeof(buff);
    while((hasRead = recv(CFSocketGetNative(_socket), buff, buffLen, 0))){
        NSLog(@"%@",[[NSString alloc] initWithBytes:buff length:hasRead encoding:NSUTF8StringEncoding]);
    }
}

//发送数据

- (IBAction)sendBtnClick:(id)sender {
    if (_isOnline) {
        NSString* strMsg = @"hello，我是客户端";
        const char *data = [strMsg UTF8String];
        send(CFSocketGetNative(_socket), data, strlen(data) + 1, 1);
    }
    else{
        
    }
}

@end
