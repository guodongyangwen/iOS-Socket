//
//  ViewController.m
//  CFSocketServer
//
//  Created by gdy on 2016/7/26.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import "ViewController.h"
#import <sys/socket.h>
#import <arpa/inet.h>
#import <Foundation/Foundation.h>

CFSocketNativeHandle nativeHandle = -1;
CFWriteStreamRef  outputStream = NULL;

@interface ViewController (){
    CFSocketNativeHandle _nativeHandle;
}
@property (nonatomic, assign)CFSocketRef socket;
@property (nonatomic, assign)CFWriteStreamRef oStream;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)startListen:(id)sender {
    [NSThread detachNewThreadSelector:@selector(startConnect) toTarget:self withObject:nil];
}


- (void)startConnect{
    //创建socke，并制定连接回调函数
    //1 内存分配类型   2 协议簇IPV4   3   流式套接字   4 套接字协议  5 回调事件触发类型（连接成功回调）  6 回调函数
    self.socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, TCPServerAcceptCallBack, NULL);
    if (self.socket == NULL) {
        NSLog(@"创建socket失败!\n");
        return;
    }
    
    int optVal = 1;
    //初始化   1 返回系统原生套接字   2套接字级别        3允许本地地址重用
    setsockopt(CFSocketGetNative(self.socket), SOL_SOCKET, SO_REUSEADDR, (void*)&optVal,sizeof(optVal));
    
    
    //设置地址和接口
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    addr.sin_port = htons(8888);
    
    CFDataRef address = CFDataCreate(kCFAllocatorDefault, (UInt8*)&addr, sizeof(addr));
    
    //绑定socke到指定ip
    if (CFSocketSetAddress(self.socket, address) != kCFSocketSuccess) {
        NSLog(@"绑定socket失败\n");
        if (self.socket) {
            CFRelease(self.socket);
            exit(1);
        }
        self.socket = NULL;
    }
    
    NSLog(@"---启动循环监听客户端连接---\n");
    
    //把socket作为事件源添加到当前线程的runloop中
    CFRunLoopRef cfRunloop = CFRunLoopGetCurrent();
    //把socket包装成CFRunLoopSource
    CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, self.socket, 0);
    //为CFRunloop对象添加source
    CFRunLoopAddSource(cfRunloop, source, kCFRunLoopCommonModes);
    CFRelease(source);
    //运行当前线程的runloop
    CFRunLoopRun();
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - CFSocket
//读取数据的回调函数
void readStream(CFReadStreamRef iStream,CFStreamEventType eventType,void *clientCallBackInfo){
    uint8_t buff[2048];
    CFIndex hasRead = CFReadStreamRead(iStream, buff, 2048);
    if (hasRead > 0) {
        buff[hasRead] = '\0';
        printf("接收到数据:%s\n",buff);
    }
}

//写入数据回到函数
void writeStream(CFWriteStreamRef stream,CFStreamEventType type,void* clientCallBackInfo){
    outputStream = stream;//拿到输出流，用于主动输出
}

//客户端连接成功的回调函数

void TCPServerAcceptCallBack(CFSocketRef socket ,CFSocketCallBackType type,CFDataRef address,const void *data,void *info){
    //客户端连接
    if (kCFSocketAcceptCallBack == type) {
        //data  the handle of socket
        CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle*)data;
        //拿到socket句柄，用于手动写入数据
        nativeHandle = nativeSocketHandle;
        uint8_t name[SOCK_MAXADDRLEN];
        socklen_t nameLen = sizeof(name);
        //获取对方socket信息，还有getsocketname()函数用于获取本程序所在socket信息
        if (getpeername(nativeSocketHandle, (struct sockaddr *)name,&nameLen) != 0) {
            NSLog(@"error");
            exit(1);
        }
        
        //获取连接的客户端信息
        struct sockaddr_in* addr_in = (struct sockaddr_in*)name;
        NSLog(@"%s:%d 连接进来了",inet_ntoa(addr_in->sin_addr),addr_in->sin_port);
        
        //创建一对输入输出流用于duxie shujuu
        CFReadStreamRef iStream;
        CFWriteStreamRef oStream;
        //创建一组可读/写的 CFStreame
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &iStream, &oStream);
        if (iStream && oStream) {
            //打开输入流和输出流
            CFReadStreamOpen(iStream);
            CFWriteStreamOpen(oStream);
            CFStreamClientContext streamContext = {0,NULL,NULL,NULL};
            //if have data to read   call the readStream function
            if (!CFReadStreamSetClient(iStream, kCFStreamEventHasBytesAvailable, readStream, &streamContext)) {
                exit(1);
            }
            
            //if the ostream can accept bytes can writestream function
            if (!CFWriteStreamSetClient(oStream, kCFStreamEventCanAcceptBytes, writeStream, &streamContext)) {
                exit(1);
            }
            
            CFReadStreamScheduleWithRunLoop(iStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
            //向客户端输出数据
            char* str = "hello，我是服务器!\n";
            CFWriteStreamWrite(oStream, (UInt8*)str, strlen(str)+1);
        }
        
    }
}


- (IBAction)sendBtnClick:(id)sender {
//    [NSThread detachNewThreadSelector:@selector(sendToClient) toTarget:self withObject:nil];
    [self sendToClient];
}

- (void)sendToClient{
        //向客户端输出数据
        char* str = "hello，我是服务器!\n";
        CFWriteStreamWrite(outputStream, (UInt8*)str, strlen(str)+1);
}

@end
