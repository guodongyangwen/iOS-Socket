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
    __weak __typeof (&*self)weakSelf = self;
    socketInstance.connectSuccess = ^(NSString* strData){
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.logTV.text = [weakSelf.logTV.text stringByAppendingString:strData];
        });
    };
    [socketInstance connectToServer];
}

- (IBAction)cutOffConnect:(id)sender {
    SocketSingleTon *socketInstance = [SocketSingleTon shareInstance];
    [socketInstance cutOffSocket];
}

- (IBAction)sendDataToServer:(id)sender {//绑定
    SocketSingleTon *socketInstance = [SocketSingleTon shareInstance];
    NSInteger pkgId = (pkg_id + 1);
    pkg_id += 1;
    
    NSMutableDictionary* dicParams = [NSMutableDictionary dictionary];
    [dicParams setObject:appTye forKey:@"apptype"];
    [dicParams setObject:@"04" forKey:@"pkg_type"];
    [dicParams setObject:[NSString stringWithFormat:@"%ld",pkgId] forKey:@"pkg_id"];
    [dicParams setObject:[[PublicTool generateSign:@"04" pkgId:pkgId] lowercaseString] forKey:@"sign"];
    [dicParams setObject:userid forKey:@"userid"];
    [dicParams setObject:deviceToken forKey:@"deviceid"];
    [dicParams setObject:plat forKey:@"platform"];
    [dicParams setObject:platVer forKey:@"platform_ver"];
    [dicParams setObject:sdkStr forKey:@"sdk"];

    NSString* JSONStr = [PublicTool JSONStringWithDic:dicParams];
        NSLog(@"JSONStrParams:%@",JSONStr);

    [socketInstance sendDataToServer:JSONStr];
}


- (IBAction)sendBetaDataToServer:(id)sender {
    SocketSingleTon *socketInstance = [SocketSingleTon shareInstance];
    [socketInstance longConnectToServer];
}

- (IBAction)clearLog:(id)sender {
    self.logTV.text = @"";
}

@end
