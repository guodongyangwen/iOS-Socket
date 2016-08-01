//
//  PublicTool.m
//  LongConnect
//
//  Created by gdy on 2016/7/22.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import "PublicTool.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation PublicTool

//字典转成成JSON字符串
+ (NSString *)JSONStringWithDic:(NSDictionary*)dic {
    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic
                                                       options:0
                                                         error:&error];
    
    if (jsonData == nil) {
        NSLog(@"fail to get JSON from dictionary: %@, error: %@", self, error);
        return nil;
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}


//JSON字符串转换成字典
+ (NSDictionary *)dictionaryWithJSON:(NSString *)json {
    NSError *error = nil;
    
    NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers | NSJSONReadingAllowFragments error:&error];
    
    if (jsonDict == nil) {
        NSLog(@"fail to get dictioanry from JSON: %@, error: %@", json, error);
        
        return nil;
    }
    
    return jsonDict;
}


+ (NSString *)MD5String:(NSString *)string {
    const char *cStr = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X", result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7], result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]];
}

@end
