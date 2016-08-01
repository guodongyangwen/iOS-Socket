//
//  SocketSingleTon.m
//  LongConnect
//
//  Created by gdy on 2016/7/22.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import "SocketSingleTon.h"
#import "PublicTool.h"

static NSInteger SocketOfflineCode = 0;//200用户，1000服务器

@interface SocketSingleTon ()<SRWebSocketDelegate>

@end

@implementation SocketSingleTon


+(instancetype)shareInstance{
    static SocketSingleTon* shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc]init];
    });
    return shareInstance;
}

//connect to server
-(void)connectToServer{
    self.socket.delegate = nil;
    [self.socket close];
    
//    NSURL* url = [NSURL URLWithString:self.hostAddr];
    NSURL* url = [NSURL URLWithString:@"ws://push.qfpay.com"];
    NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    self.socket = [[SRWebSocket alloc]initWithURLRequest:urlRequest];
    self.socket.delegate = self;
    [self.socket open];
}

//cut off socket
-(void)cutOffSocket{
    SocketOfflineCode = 200;//用户
    [self.beatTimer invalidate];
    [self.socket close];
}


#pragma mark  - SRWebSocketDelegate

//socket连接成功
- (void)webSocketDidOpen:(SRWebSocket *)webSocket{
    SocketOfflineCode = 0;
    NSString* strSuc = [NSString stringWithFormat:@"连接主机:%@ 成功\n",self.hostAddr];
    NSLog(@"%@",strSuc);
    if (self.connectSuccess) {
        self.connectSuccess(strSuc);
    }
}

//send beta data
- (void)longConnectToServer{
    NSLog(@"long connecting...");
    NSMutableDictionary* dicParams = [NSMutableDictionary dictionary];
    NSInteger pkgId = (pkg_id + 1);
    pkg_id += 1;
    [dicParams setValue:@"00" forKey:@"pkg_type"];
    [dicParams setValue:[NSString stringWithFormat:@"%ld",pkgId] forKey:@"pkg_id"];
    [dicParams setValue:appTye forKey:@"apptype"];
    [dicParams setValue:[[PublicTool generateBetaSign:@"00" pkgId:pkgId] lowercaseString] forKey:@"sign"];
//    [dicParams setValue:[[PublicTool generateSign:@"00" pkgId:pkgId] lowercaseString] forKey:@"sign"];
    NSString* strParams = [PublicTool JSONStringWithDic:dicParams];
    NSError* error = nil;
    [self.socket sendString:strParams error:&error];
    if (error != nil) {
        NSLog(@"发送心跳包失败:%@",error);
    }
    
    
    NSString* strBeta = [NSString stringWithFormat:@"客户端心跳数据:%@\n",strParams];
    
    if (self.connectSuccess) {
        self.connectSuccess(strBeta);
    }
    
}

//socket失败
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    NSLog(@"socket错误：%@",error);
}

//关闭socket
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(nullable NSString *)reason wasClean:(BOOL)wasClean{
    
    NSLog(@"code : %ld    readyStatus: %ld",code,webSocket.readyState);
    
    if (SocketOfflineCode == 200) {
        NSLog(@"the socket have been cutted off by user");
    }
    else{
        NSLog(@"the socket have been cutted off by other reason");
        //reconnect
        [self connectToServer];
    }
}

//send data
- (void)sendDataToServer:(NSString*)data{
    NSError* error = nil;
    [self.socket sendString:data error:&error];
    if (error != nil) {
        NSLog(@"发送数据失败:%@",error);
    }
    NSString* strSend = [NSString stringWithFormat:@"客户端绑定数据:%@\n",data];
    
    if (self.connectSuccess) {
        self.connectSuccess(strSend);
    }
    
    //发送绑定数据成功后，发送beat包
    //创建定时器，定时发送beat包
    self.beatTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(longConnectToServer) userInfo:nil repeats:YES];
}

//接收到服务器发送的数据
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessageWithString:(NSString *)string{
//    NSLog(@"received message : %@",string);
    
    NSDictionary* receivedDic = [PublicTool dictionaryWithJSON:string];
    if ([receivedDic[@"pkg_type"] isEqualToString:@"01"]) {//心跳包返回信息
        NSString* strBackBeta = [NSString stringWithFormat:@"服务器返回心跳包: %@\n",receivedDic];
        NSLog(@"%@",strBackBeta);
        if (self.connectSuccess) {
            self.connectSuccess(strBackBeta);
        }
    }
    else if ([receivedDic[@"pkg_type"] isEqualToString:@"05"]) {//绑定返回信息
        NSString* strBackBind = [NSString stringWithFormat:@"服务器返回绑定包:%@\n",receivedDic];
        NSLog(@"%@",strBackBind);
        if (self.connectSuccess) {
            self.connectSuccess(strBackBind);
        }
    }
    else if ([receivedDic[@"pkg_type"] isEqualToString:@"06"]) {//服务器主动发送的推送数据
        NSString* strBack = [NSString stringWithFormat:@"服务器主动发送的数据:%@\n",receivedDic];
        NSLog(@"%@",strBack);
        if (self.connectSuccess) {
            self.connectSuccess(strBack);
        }
    }
}


@end
