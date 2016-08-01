//
//  ViewController.m
//  LongConnect
//
//  Created by gdy on 2016/7/22.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import "ViewController.h"
#import "SocketSingleTon.h"
#import "PublicTool.h"


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *addressTF;
@property (weak, nonatomic) IBOutlet UITextField *portTF;
@property (weak, nonatomic) IBOutlet UITextField *msgTF;
@property (weak, nonatomic) IBOutlet UITextView *logTV;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (NSString *)queryIpWithDomain:(NSString *)domain
{
    struct hostent *hs;
    struct sockaddr_in server;
    if ((hs = gethostbyname([domain UTF8String])) != NULL)
    {
        server.sin_addr = *((struct in_addr*)hs->h_addr_list[0]);
        return [NSString stringWithUTF8String:inet_ntoa(server.sin_addr)];
    }
    return nil;
}

#pragma mark - Event Handle

- (IBAction)connectToServer:(id)sender {
    SocketSingleTon *socketInstance = [SocketSingleTon shareInstance];
    socketInstance.hostAddr = _addressTF.text;
    socketInstance.port = _portTF.text;
    __weak __typeof (&*self)weakSelf = self;
    socketInstance.msgLog = ^(NSString* log){
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.logTV.text = [weakSelf.logTV.text stringByAppendingString:log];
        });
    };
    [socketInstance connectToServer];
}

- (IBAction)cutOffConnect:(id)sender {
    SocketSingleTon *socketInstance = [SocketSingleTon shareInstance];
    [socketInstance cutOffSocket];
}

- (IBAction)sendDataToServer:(id)sender {
    SocketSingleTon *socketInstance = [SocketSingleTon shareInstance];
    [socketInstance sendDataToServer:[_msgTF.text dataUsingEncoding:NSUTF8StringEncoding]];
}


- (IBAction)sendBetaDataToServer:(id)sender {
    SocketSingleTon *socketInstance = [SocketSingleTon shareInstance];
    NSMutableDictionary* dicParams = [NSMutableDictionary dictionary];
    [dicParams setValue:@"beta" forKey:@"msgType"];
    [dicParams setValue:@"hello" forKey:@"msg"];
    NSString* strMsg = [PublicTool JSONStringWithDic:dicParams];
    [socketInstance sendDataToServer:[strMsg dataUsingEncoding:NSUTF8StringEncoding]];
}


- (IBAction)clearLog:(id)sender {
    _logTV.text = nil;
}


- (IBAction)tapToResign:(id)sender {
    [_msgTF resignFirstResponder];
}



@end
