//
//  SocketSingleTon.h
//  LongConnect
//
//  Created by gdy on 2016/7/22.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
#import <netdb.h>
#import <arpa/inet.h>

typedef NS_ENUM(NSInteger,SocketOffline) {
    SocketOfflineByServer,
    SocketOfflineByUser
};

@interface SocketSingleTon : NSObject

@property (nonatomic, strong)AsyncSocket *socket;
@property (nonatomic, copy) NSString *hostAddr;
@property (nonatomic, copy) NSString *port;
@property (nonatomic, strong)NSTimer *beatTimer;

@property (nonatomic, copy) void(^msgLog)(NSString*);

+(instancetype)shareInstance;

//connect  to server
-(void)connectToServer;

//cut off socket
-(void)cutOffSocket;

//send data
- (void)sendDataToServer:(NSData*)data;

@end
