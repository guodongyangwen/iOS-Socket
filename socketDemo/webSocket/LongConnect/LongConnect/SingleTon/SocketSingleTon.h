//
//  SocketSingleTon.h
//  LongConnect
//
//  Created by gdy on 2016/7/22.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRWebSocket.h"
#import <netdb.h>
#import <arpa/inet.h>
#import "socketMacro.h"

@interface SocketSingleTon : NSObject

@property (nonatomic, strong)SRWebSocket *socket;
@property (nonatomic, copy) NSString *hostAddr;
@property (nonatomic, strong)NSTimer *beatTimer;

@property (nonatomic, copy) void (^connectSuccess)(NSString*);

+(instancetype)shareInstance;

//connect  to server
-(void)connectToServer;

//cut off socket
-(void)cutOffSocket;

//beta data
- (void)longConnectToServer;

//send data
- (void)sendDataToServer:(NSString*)data;

@end
