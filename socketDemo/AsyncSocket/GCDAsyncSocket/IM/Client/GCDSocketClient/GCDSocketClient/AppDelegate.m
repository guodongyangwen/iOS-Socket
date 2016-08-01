//
//  AppDelegate.m
//  LongConnectServer
//
//  Created by gdy on 2016/7/25.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (nonatomic, strong)NSTimer *timer;
@property (nonatomic, assign)UIBackgroundTaskIdentifier bgTask;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(logAgain:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    UIApplication* app = [UIApplication sharedApplication];
    self.bgTask = UIBackgroundTaskInvalid;
    __weak __typeof (&*self)weakSelf = self;
    self.bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.bgTask != UIBackgroundTaskInvalid) {
                weakSelf.bgTask = UIBackgroundTaskInvalid;
            }
        });
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (weakSelf.bgTask != UIBackgroundTaskInvalid) {
                weakSelf.bgTask = UIBackgroundTaskInvalid;
            }
        });
    }];
}

- (void)logAgain:(NSTimer*)timer{
    //无限后台
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    if (self.timer != nil) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
