//
//  PublicTool.h
//  LongConnect
//
//  Created by gdy on 2016/7/22.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PublicTool : NSObject

//字典转换成JSON字符串
+ (NSString *)JSONStringWithDic:(NSDictionary*)dic;

//JSON字符串转换成字典
+ (NSDictionary *)dictionaryWithJSON:(NSString *)json ;

//字符串MD5加密
+ (NSString *)MD5String:(NSString *)string;

@end
