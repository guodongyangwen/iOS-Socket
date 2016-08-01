//
//  ViewController.m
//  GCDSocketClient
//
//  Created by gdy on 2016/7/26.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#import "PublicTool.h"

@interface ViewController ()<GCDAsyncSocketDelegate>
@property (weak, nonatomic) IBOutlet UITextField *addrTF;
@property (weak, nonatomic) IBOutlet UITextField *portTF;
@property (weak, nonatomic) IBOutlet UITextField *msgTF;
@property (weak, nonatomic) IBOutlet UITextView *logTV;

@property (nonatomic, strong)GCDAsyncSocket *socket;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapToResign:)];
    [self.view addGestureRecognizer:tap];
    [self setupClientSocket];
}

- (void)tapToResign:(UITapGestureRecognizer*)tap{
    [_msgTF resignFirstResponder];
}

- (void)setupClientSocket{
    //在主队列中处理,  所有的回执都在主队列中执行。
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
}


- (void)showLogMsg:(NSString*)log{
    _logTV.text = [_logTV.text stringByAppendingFormat:@"%@\n",log];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Event Handle

- (IBAction)connectBtnClick:(id)sender {
    NSError* error = nil;
    if (self.socket == nil) {
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [self.socket connectToHost:_addrTF.text onPort:_portTF.text.intValue error:&error];
    }
    else{
        if (![self.socket isConnected]) {
            [self.socket connectToHost:_addrTF.text onPort:_portTF.text.intValue error:&error];
        }
    }
    
    if (error != nil) {
        [self showLogMsg:@"连接失败..."];
    }
}

- (IBAction)sendBtnClick:(id)sender {
    
    NSMutableDictionary* dicUserData = [NSMutableDictionary dictionary];
    [dicUserData setValue:@"msg" forKey:@"msgType"];
    [dicUserData setValue:self.socket.localHost forKey:@"host"];
    [dicUserData setValue:@"rose" forKey:@"fromUser"];
    [dicUserData setValue:@"jack" forKey:@"toUser"];
    [dicUserData setValue:_msgTF.text forKey:@"msg"];
    NSString* strMsg = [PublicTool JSONStringWithDic:dicUserData];
    [self.socket writeData:[strMsg dataUsingEncoding:NSUTF8StringEncoding] withTimeout:30 tag:0];
    [self showLogMsg:[NSString stringWithFormat:@"%@:%@",@"rose",_msgTF.text]];
    _msgTF.text = @"";
    
}

#pragma mark - GCDAsyncSocket

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    [self showLogMsg:[NSString stringWithFormat:@"连接服务器地址： %@,端口：%d成功",host,port]];
    [self.socket readDataWithTimeout:-1 tag:0];
    //把自己的信息发送给服务器
    NSMutableDictionary* dicUserData = [NSMutableDictionary dictionary];
    [dicUserData setValue:@"login" forKey:@"msgType"];
    [dicUserData setValue:sock.localHost forKey:@"host"];
    [dicUserData setValue:@"rose" forKey:@"name"];
    NSString* strMsg = [PublicTool JSONStringWithDic:dicUserData];
    [self.socket writeData:[strMsg dataUsingEncoding:NSUTF8StringEncoding] withTimeout:30 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    [self showLogMsg:@"socket断开连接..."];
}

//注意：要想长连接,必须还要在DidReceiveData的delegate中再写一次[_udpSocket receiveOnce:&error]
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    [self.socket readDataWithTimeout:-1 tag:0];
    NSString* strMsg = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary* dicMsg = [PublicTool dictionaryWithJSON:strMsg];
    
    if ([dicMsg[@"msgType"] isEqualToString:@"loginAck"]) {
        [self showLogMsg:@"登录成功...."];
    }
    if ([dicMsg[@"msgType"] isEqualToString:@"msg"]) {
        [self showLogMsg:[NSString stringWithFormat:@"%@:%@",dicMsg[@"fromUser"],dicMsg[@"msg"]]];
    }
}

@end
