//
//  SocketSingleTon.m
//  LongConnect
//
//  Created by gdy on 2016/7/22.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import "SocketSingleTon.h"
#import "PublicTool.h"

@interface SocketSingleTon ()<AsyncSocketDelegate>

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
    NSError* error = nil;
    BOOL isSuccess = NO;
    if (self.socket != nil) {
        if ([self.socket isConnected]) {
            //断开后再连接
            self.socket.userData = SocketOfflineByUser;
            [self cutOffSocket];
           isSuccess = [self.socket connectToHost:self.hostAddr onPort:self.port.intValue error:&error];
        }
        else{
           isSuccess =  [self.socket connectToHost:self.hostAddr onPort:self.port.intValue error:&error];
        }
    }
    else{
        self.socket = [[AsyncSocket alloc]initWithDelegate:self];
        isSuccess = [self.socket connectToHost:self.hostAddr onPort:self.port.intValue error:&error];
    }
    
    if (error != nil) {
        NSLog(@"socket连接失败:%@",error);
    }
    else{
        NSLog(@"socket连接成功");
    }
}

//cut off socket
-(void)cutOffSocket{
    self.socket.userData = SocketOfflineByUser;
    [self.socket disconnect];
}


#pragma mark  - AsyncSocketDelegate

//连接成功回调
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    NSString* logStr = [NSString stringWithFormat:@"连接主机:%@:%d成功\n",host,port];
    [sock readDataWithTimeout:-1 tag:0];
    NSLog(@"%@",logStr);
    if (self.msgLog) {
        self.msgLog(logStr);
    }
    //创建定时器，定时发送beat包
    self.beatTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(longConnectToServer) userInfo:nil repeats:YES];
}

//send beta data
- (void)longConnectToServer{
    [self sendDataToServer:[@"hello" dataUsingEncoding:NSUTF8StringEncoding]];
}

//连接断开回调

- (void)onSocketDidDisconnect:(AsyncSocket *)sock{
    self.socket = nil;
    [self.beatTimer invalidate];
    self.beatTimer = nil;
    if (sock.userData == SocketOfflineByUser) {
        NSLog(@"the socket have been cutted off by user");
        if (self.msgLog) {
            self.msgLog(@"the socket have been cutted off by user");
        }
    }
    else if(sock.userData == SocketOfflineByServer){
        NSLog(@"the socket have been cutted off by server");
        if (self.msgLog) {
            self.msgLog(@"the socket have been cutted off by server");
        }
        //reconnect
        [self connectToServer];
    }
    else{
        [self connectToServer];
    }
}

//收到消息



- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    [sock readDataWithTimeout:-1 tag:0];
    char buf[1024];
    [data getBytes:buf length:1024];
    NSString* receivedData = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
    
    
    if (receivedData.length > 0) {
        NSDictionary* dataDic = [PublicTool dictionaryWithJSON:receivedData];
        NSLog(@"receivedData : %@",dataDic);
        
        
    
        if ([dataDic[@"msgType"] isEqualToString:@"beta"]) {
            NSString* strMsg = [NSString stringWithFormat:@"收到心跳确认的数据： %@\n",receivedData];
            if (self.msgLog) {
                self.msgLog(strMsg);
            }
        }
        else if([dataDic[@"msgType"] isEqualToString:@"normal"]){
            NSString* strMsg = [NSString stringWithFormat:@"收到正常的数据： %@\n",receivedData];
            if (self.msgLog) {
                self.msgLog(strMsg);
            }
        }
        else if([dataDic[@"msgType"] isEqualToString:@"exit"]){
            NSString* strMsg = [NSString stringWithFormat:@"收到关闭的数据： %@\n",receivedData];
            if (self.msgLog) {
                self.msgLog(strMsg);
            }
            [self cutOffSocket];
        }
    }
    
}

//send data
- (void)sendDataToServer:(NSData*)data{
    NSString* dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSMutableDictionary* dicParams = [NSMutableDictionary dictionary];
    
    if ([dataStr isEqualToString:@"hello"]) {
        [dicParams setValue:dataStr forKey:@"msg"];
        [dicParams setValue:@"beta" forKey:@"msgType"];
    }
    else{
        [dicParams setValue:dataStr forKey:@"msg"];
        [dicParams setValue:@"normal" forKey:@"msgType"];
    }
    
    NSData* sendData = [[PublicTool JSONStringWithDic:dicParams] dataUsingEncoding:NSUTF8StringEncoding];
    
    
    NSString* strMsg = [NSString stringWithFormat:@"发送数据: %@\n",[PublicTool JSONStringWithDic:dicParams]];
    if (self.msgLog) {
        self.msgLog(strMsg);
    }
    
    [self.socket writeData:sendData withTimeout:30 tag:0];
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err{
    NSLog(@"error:%@",err);
}



@end
