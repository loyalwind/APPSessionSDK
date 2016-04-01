//
//  NSDate+TimeStamp.h
//  SDK_Normal
//
//  Created by weijianPeng on 16/3/31.
//  Copyright © 2016年 wjpeng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (TimeStamp)
/**
 *  时间戳
 *
 *  @return 年月日时分秒（比如此刻时间是：2016年3月31日10点36分30秒，则返回20160331103630）
 */
- (NSString *)timeStamp;
/**
 *  时间戳
 *
 *  @param date 给的一个日期对象
 *
 *  @return 格式：年月日时分秒（比如date时间是：2016年3月31日10点50分30秒，则返回20160331105030）
 */
+ (NSString *)timeStampFromDate:(NSDate *)date;
@end
