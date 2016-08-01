//
//  ViewController.m
//  LongConnectServer
//
//  Created by gdy on 2016/7/25.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import "ViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <string.h>

#import "PublicTool.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *addrTF;
@property (weak, nonatomic) IBOutlet UITextField *portTF;
@property (weak, nonatomic) IBOutlet UITextView *logTV;
@property (weak, nonatomic) IBOutlet UITextField *msgTF;

@property (nonatomic, assign)int fd;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)startTCPServer:(id)sender {
    [NSThread detachNewThreadSelector:@selector(startTCPServer) toTarget:self withObject:nil];
}

- (void)startTCPServer{
    //创建并初始化socket，返回socket的文件描述符（-1表示失败）
    /*
     AF_INET  地址描述，目前只支持这一种
     SOCK_STREAM  socket类型
     */
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    NSString* logStr = nil;
    if (fd == -1) {
        printf("创建socket失败...\n");
        logStr = @"创建socket失败...\n";
        dispatch_async(dispatch_get_main_queue(), ^{
            _logTV.text = [_logTV.text stringByAppendingString:logStr];
        });
        return;
    }
    else{
        printf("socket 创建成功... fd = %d\n",fd);
        logStr = @"创建socket成功...\n";
        dispatch_async(dispatch_get_main_queue(), ^{
            _logTV.text = [_logTV.text stringByAppendingString:logStr];
        });
    }
    
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(_portTF.text.intValue);
    addr.sin_addr.s_addr = inet_addr([_addrTF.text UTF8String]);//0.0.0.0,本机任意地址（可能有多个网卡）
    
    //将socket与特定主机和端口绑定
    int err = bind(fd, (const struct sockaddr *)&addr, sizeof(addr));
    if (err != 0) {
        printf("socket绑定失败...\n");
        logStr = @"socket绑定失败...\n";
        dispatch_async(dispatch_get_main_queue(), ^{
            _logTV.text = [_logTV.text stringByAppendingString:logStr];
        });
        return;
    }
    else{
        printf("socket绑定成功...\n");
        logStr = @"socket绑定成功...\n";
        dispatch_async(dispatch_get_main_queue(), ^{
            _logTV.text = [_logTV.text stringByAppendingString:logStr];
        });
    }
    
    //监听客户端的请求
    err = listen(fd, 5);//5：最大连接个数
    
    if (err != 0) {
        printf("监听失败...\n");
        logStr = @"监听失败...\n";
        dispatch_async(dispatch_get_main_queue(), ^{
            _logTV.text = [_logTV.text stringByAppendingString:logStr];
        });
        return;
    }
    else{
        printf("socket监听成功...\n");
        logStr = @"socket监听成功...\n";
        dispatch_async(dispatch_get_main_queue(), ^{
            _logTV.text = [_logTV.text stringByAppendingString:logStr];
        });
    }
    
    while(true){//循环监听
        struct sockaddr_in peeraddr;
        int peerfd;
        socklen_t addrLen;
        addrLen=sizeof(peeraddr);
        //接受客户单的请求，并建立连接
        peerfd=accept(fd, (struct sockaddr *)&peeraddr, &addrLen);//peeraddr是客户端的连接地址
        self.fd = peerfd;
        if(peerfd != -1){
            char buf[1024];
            ssize_t count;
            size_t len = sizeof(buf);
            do{
                
                count=recv(peerfd, buf, len, 0);//返回读取的字节数
                NSString* receivedStr = [NSString stringWithUTF8String:buf];
                
                memset(&buf, 0, sizeof(buf));
                
                NSDictionary* dicData = [PublicTool dictionaryWithJSON:receivedStr];
                if ([dicData[@"msgType"] isEqualToString:@"beta"]) {
                    
                    NSString* strReceiveMsg = [NSString stringWithFormat:@"client:===%@\n",receivedStr];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _logTV.text = [_logTV.text stringByAppendingString: strReceiveMsg];
                    });
                    
                    //发送确认数据
                    NSMutableDictionary* dicParams = [NSMutableDictionary dictionary];
                    [dicParams setValue:@"beta" forKey:@"msgType"];
                    [dicParams setValue:@"world" forKey:@"msg"];
                    NSString* strMsg = [PublicTool JSONStringWithDic:dicParams];
                    //给对应的连接发送数据
                    send(self.fd,[strMsg UTF8String],1024,0);
                    
                    NSString* strLog = [NSString stringWithFormat:@"%@======:server\n",strMsg];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _logTV.text = [_logTV.text stringByAppendingString: strLog];
                    });
                }
                else if ([dicData[@"msgType"] isEqualToString:@"normal"]) {
                    if ([dicData[@"msg"] isEqualToString:@"exit"]) {
                       int closefd = close(self.fd);
                        if (closefd == 0) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                _logTV.text = [_logTV.text stringByAppendingString: @"关闭socke成功\n"];
                            });
                        }
                        else{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                _logTV.text = [_logTV.text stringByAppendingString: @"关闭socke失败\n"];
                            });
                        }
                    }
                    else{
                        NSString* strReceiveMsg = [NSString stringWithFormat:@"client:===%@\n",receivedStr];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            _logTV.text = [_logTV.text stringByAppendingString: strReceiveMsg];
                        });
                    }
                }
            }while(1);
        }
        
    }

}


- (IBAction)sendBtnClick:(id)sender {
    NSMutableDictionary* dicParams = [NSMutableDictionary dictionary];
    [dicParams setValue:_msgTF.text forKey:@"msg"];
    [dicParams setValue:@"normal" forKey:@"msgType"];
    NSString* sendStr = [PublicTool JSONStringWithDic:dicParams];
    
    send(self.fd, [sendStr UTF8String], 1024, 0);//返回发送的字节数
    NSString* strMsg = [NSString stringWithFormat:@"      %@:~~~server\n",_msgTF.text];
    _logTV.text = [_logTV.text stringByAppendingString:strMsg];
}

- (IBAction)tapToResign:(id)sender {
    [_msgTF resignFirstResponder];
}
@end
