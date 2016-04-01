//
//  NSDate+TimeStamp.m
//  SDK_Normal
//
//  Created by weijianPeng on 16/3/31.
//  Copyright © 2016年 wjpeng. All rights reserved.
//

#import "NSDate+TimeStamp.h"

@implementation NSDate (TimeStamp)
- (NSString *)timeStamp
{
    NSDateFormatter *fmt= [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyyMMddHHmmss";
    return [fmt stringFromDate:self];
}
+ (NSString *)timeStampFromDate:(NSDate *)date
{
    return [date timeStamp];
}
@end
