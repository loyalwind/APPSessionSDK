//
//  NSString+MD5.h
//  SDK_Normal
//
//  Created by wjpeng on 16/3/17.
//  Copyright © 2016年 wjpeng. All rights reserved.
//

#import <Foundation/Foundation.h>
// MD5加密
@interface NSString (MD5)
/**
 *  MD5加密
 *
 *  @return 加密后的MD5字符串
 */
- (NSString *)md5;

/**
 *  获取随机6位数字字符串
 *
 *  @return 随机数字字符串
 */
+ (NSString *)randomNum;
@end

// 3DES加密
@interface NSString (TripleDES)
#pragma mark - 普通字符串加密、解密
/**
 *  字符串经3DES加密后生成字符串
 *
 *  @param key 密钥
 *
 *  @return 加密后的字符串
 */
- (NSString *)encryptStrWithKey:(NSString *)key;

/**
 *  字符串经3DES解密后返回字符串
 *
 *  @param key 密钥
 *
 *  @return 解密后的原始字符串
 */
- (NSString *)decryptStrWithKey:(NSString *)key;

#pragma mark - 十六进制字符串加密、解密
/**
 *  字符串经3DES加密后生成16进制字符串
 *
 *  @param key 密钥
 *
 *  @return 加密后的16进制字符串
 */
- (NSString *)encryptHexStrWithKey:(NSString *)key;

/**
 *  16进制字符串经3DES解密后返回字符串
 *
 *  @param key 密钥
 *
 *  @return 解密后的原始字符串
 */
- (NSString *)decryptHexStrWithKey:(NSString *)key;
@end