//
//  ViewController.m
//  GCDSocketServer
//
//  Created by gdy on 2016/7/26.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#import "PublicTool.h"


@interface ViewController ()<GCDAsyncSocketDelegate>
@property (weak, nonatomic) IBOutlet UITextField *portTF;
@property (weak, nonatomic) IBOutlet UITextField *msgTF;
@property (weak, nonatomic) IBOutlet UITextView *logTV;




@property (nonatomic, strong)GCDAsyncSocket *serverSocket;
@property (nonatomic, strong)GCDAsyncSocket *clientSocket;


@property (nonatomic, strong)NSMutableArray *clientArr;//连接池
@property (nonatomic, strong)NSMutableArray *clientInfoArr;//客户端信息


@end

@implementation ViewController


- (NSMutableArray*)clientArr{
    if (_clientArr == nil) {
        _clientArr = [NSMutableArray array];
    }
    return _clientArr;
}

- (NSMutableArray*)clientInfoArr{
    if (_clientInfoArr == nil) {
        _clientInfoArr = [NSMutableArray array];
    }
    return _clientInfoArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapToResign:)];
    [self.view addGestureRecognizer:tap];
    [self setupServerSocket];
}

- (void)tapToResign:(UITapGestureRecognizer*)tap{
    [_msgTF resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setupServerSocket{
    //在主线程里面回调
    self.serverSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)showLogMsg:(NSString*)log{
    _logTV.text = [_logTV.text stringByAppendingFormat:@"%@\n",log];
}


#pragma mark - Event Handle
- (IBAction)btnListenClick:(id)sender {//监听
    NSError* error = nil;
    [self.serverSocket acceptOnPort:_portTF.text.intValue error:&error];
    if (error != nil) {
        NSLog(@"监听出错：%@",error);
    }
    else{
        [self showLogMsg:@"正在监听..."];
    }
}

- (IBAction)btnSendClick:(id)sender {
    [self showLogMsg:[NSString stringWithFormat:@"me: %@",_msgTF.text]];
    NSData* data = [_msgTF.text dataUsingEncoding:NSUTF8StringEncoding];
    //给对应的客户端发送数据
    [self.clientSocket writeData:data withTimeout:-1 tag:0];
    _msgTF.text = @"";
}


#pragma mark - GCDAsyncSocketDelegate

//接收到请求
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    [self showLogMsg:@"收到客户端连接...."];
    [self showLogMsg:[NSString stringWithFormat:@"客户端地址：%@,客户端端口：%d",newSocket.connectedHost,newSocket.connectedPort]];
    
    
    //收到连接，保存连接到连接池
    NSMutableDictionary* dicClient = [NSMutableDictionary dictionary];
    [dicClient setValue:newSocket forKey:@"socket"];
    [dicClient setValue:newSocket.connectedHost forKey:@"host"];
    
    //排重
    int tempI = -1;
    for (int i=0; i<self.clientArr.count; i++) {
        NSDictionary* client = [self.clientArr objectAtIndex:i];
        if ([client[@"host"] isEqualToString:newSocket.connectedHost]) {
            tempI = i;
        }
    }
    if (tempI >= 0) {
        [self.clientArr removeObjectAtIndex:tempI];
    }
    
    
    [self.clientArr addObject:dicClient];
    
    [newSocket readDataWithTimeout:-1 tag:0];
}

//读取信息
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString* strMsg = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    [self showLogMsg:[NSString stringWithFormat:@"client:%@",strMsg]];
    [sock readDataWithTimeout:-1 tag:0];
    NSDictionary* dicMsg = [PublicTool dictionaryWithJSON:strMsg];
    if ([dicMsg[@"msgType"] isEqualToString:@"login"]) {//登录
        
        NSMutableDictionary* dicUser = [NSMutableDictionary dictionary];
        [dicUser setValue:dicMsg[@"name"] forKey:@"name"];
        [dicUser setValue:dicMsg[@"host"] forKey:@"host"];
        
        //去重
        int tempI = -1;
        for (int i=0; i<self.clientInfoArr.count; i++) {
            NSDictionary* clientInfo = [self.clientInfoArr objectAtIndex:i];
            if ([clientInfo[@"host"] isEqualToString:dicMsg[@"host"]]) {
                tempI = i;
            }
        }
        if (tempI >= 0) {
            [self.clientInfoArr removeObjectAtIndex:tempI];
        }
        
        [self.clientInfoArr addObject:dicUser];
        
        
        
        GCDAsyncSocket* clientSocket = nil;
        //获取对应host地址的socket
        for(int i=0;i<self.clientArr.count;i++){
            NSDictionary* clientInfo = [self.clientArr objectAtIndex:i];
            if ([dicUser[@"host"] isEqualToString:clientInfo[@"host"]]) {
                clientSocket = (GCDAsyncSocket*)clientInfo[@"socket"];
                break;
            }
        }
        
        //发送确认信息
        NSMutableDictionary* dicSend = [NSMutableDictionary dictionary];
        [dicSend setValue:@"loginAck" forKey:@"msgType"];
        NSString* strSend = [PublicTool JSONStringWithDic:dicSend];
        [clientSocket writeData:[strSend dataUsingEncoding:NSUTF8StringEncoding] withTimeout:30 tag:0];
        
    }
    else if([dicMsg[@"msgType"] isEqualToString:@"msg"]){//正常的发送消息
        //发送者的host
        NSString* fromHost = dicMsg[@"host"];
        NSString* fromUser = dicMsg[@"fromUser"];
        NSString* toUser = dicMsg[@"toUser"];
        NSString* msgStr = dicMsg[@"msg"];
        
        //获取要接受消息的clientsocket
        GCDAsyncSocket* recvSocket = nil;
        for(int i=0;i<self.clientInfoArr.count;i++){
            NSDictionary* clientInfo = [self.clientInfoArr objectAtIndex:i];
            if ([toUser isEqualToString:clientInfo[@"name"]]) {//匹配接受者的名字
               NSString* recvHost = clientInfo[@"host"];
                for (int i=0; i<self.clientArr.count; i++) {
                    NSDictionary* clientInfo = [self.clientArr objectAtIndex:i];
                    if ([recvHost isEqualToString:clientInfo[@"host"]]) {
                        recvSocket = (GCDAsyncSocket*)clientInfo[@"socket"];
                        break;
                    }
                }
            }
        }
        
        //转发消息
        NSMutableDictionary* dicRecv = [NSMutableDictionary dictionary];
        [dicRecv setValue:@"msg" forKey:@"msgType"];
        [dicRecv setValue:msgStr forKey:@"msg"];
        [dicRecv setValue:fromUser forKey:@"fromUser"];
        NSString* strMsg = [PublicTool JSONStringWithDic:dicRecv];
        [recvSocket writeData:[strMsg dataUsingEncoding:NSUTF8StringEncoding] withTimeout:30 tag:0];
    }
}

@end
