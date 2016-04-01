//
//  NSString+MD5.m
//  SDK_Normal
//
//  Created by wjpeng on 16/3/17.
//  Copyright © 2016年 wjpeng. All rights reserved.
//

#import "NSString+Secure.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <Security/Security.h>
#import "GTMBase64.h"

@implementation NSString (MD5)

- (NSString *)md5
{
    const char *str = [self UTF8String];
    uint32_t    len = (uint32_t)strlen(str);
    
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(str, len, result);
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH];
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02X",result[i]];
    }
    return ret;
}
+ (NSString *)randomNum
{
    // 测试用这个
    NSMutableString *key = [NSMutableString string];
    for (int i = 0; i < 24; i++) {
        [key appendString:@"8"];
    }
    return key;
    // 部署用这个
    NSMutableString *random = [NSMutableString string];
    for (NSInteger i = 0; i < 6; i++) {
        random = (NSMutableString *)[random stringByAppendingString:[NSString stringWithFormat:@"%zd",arc4random_uniform(10)]];
    }
    return random;
}
@end

//偏移量
#define gIv @"jukai"
#ifdef NEEDOFFSET
#define vinitVec (const void *)[gIv UTF8String]
#else
#define  vinitVec nil
#endif

@implementation NSString (TripleDES)
#pragma mark - 普通字符串加密、解密
//字符串
- (NSString *)encryptStrWithKey:(NSString *)key{
    
    //把string 转NSData
    NSData* data               = [self dataUsingEncoding:NSUTF8StringEncoding];

    //length
    size_t plainTextBufferSize = [data length];
    const void *vplainText     = (const void *)[data bytes];
    
//    CCCryptorStatus ccStatus;
    uint8_t *bufferPtr = NULL;
    size_t bufferPtrSize = 0;
    size_t movedBytes = 0;
    
    bufferPtrSize = (plainTextBufferSize + kCCBlockSize3DES) & ~(kCCBlockSize3DES - 1);
    bufferPtr = malloc( bufferPtrSize * sizeof(uint8_t));
    memset((void *)bufferPtr, 0x0, bufferPtrSize);
    
    const void *vkey = (const void *) [key UTF8String];
    //偏移量
//    const void *vinitVec = (const void *) [gIv UTF8String];
    
    //配置CCCrypt
    CCCrypt(kCCEncrypt,
            kCCAlgorithm3DES, //3DES
            kCCOptionECBMode|kCCOptionPKCS7Padding, //设置模式
            vkey,    //key
            kCCKeySize3DES,
            vinitVec,     //偏移量，这里不用，设置为nil;不用的话，必须为nil,不可以为@""
            vplainText,
            plainTextBufferSize,
            (void *)bufferPtr,
            bufferPtrSize,
            &movedBytes);
    
    NSData *myData = [NSData dataWithBytes:(const void *)bufferPtr length:(NSUInteger)movedBytes];
    NSString *result = [GTMBase64 stringByEncodingData:myData];
    return result;
}

- (NSString *)decryptStrWithKey:(NSString *)key
{
    NSData *encryptData = [GTMBase64 decodeData:[self dataUsingEncoding:NSUTF8StringEncoding]];
    size_t plainTextBufferSize = [encryptData length];
    const void *vplainText = [encryptData bytes];
    
//    CCCryptorStatus ccStatus;
    uint8_t *bufferPtr = NULL;
    size_t bufferPtrSize = 0;
    size_t movedBytes = 0;
    
    bufferPtrSize = (plainTextBufferSize + kCCBlockSize3DES) & ~(kCCBlockSize3DES - 1);
    bufferPtr = malloc( bufferPtrSize * sizeof(uint8_t));
    memset((void *)bufferPtr, 0x0, bufferPtrSize);
    
    const void *vkey = (const void *) [key UTF8String];
//    const void *vinitVec = (const void *) [gIv UTF8String];
    
    CCCrypt(kCCDecrypt,
           kCCAlgorithm3DES,
           kCCOptionPKCS7Padding|kCCOptionECBMode,
           vkey,
           kCCKeySize3DES,
           vinitVec,
           vplainText,
           plainTextBufferSize,
           (void *)bufferPtr,
           bufferPtrSize,
           &movedBytes);
    
    NSString *result = [[NSString alloc] initWithData:[NSData dataWithBytes:(const void *)bufferPtr length:(NSUInteger)movedBytes] encoding:NSUTF8StringEncoding];
    
    return result;
}

//十六进制
- (NSString *)encryptHexStrWithKey:(NSString *)key
{
    //把string 转NSData
    NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
    
    //length
    size_t plainTextBufferSize = [data length];
    
    const void *vplainText = (const void *)[data bytes];
    
//    CCCryptorStatus ccStatus;
    uint8_t *bufferPtr   = NULL;
    size_t bufferPtrSize = 0;
    size_t movedBytes    = 0;
    
    bufferPtrSize = (plainTextBufferSize + kCCBlockSize3DES) & ~(kCCBlockSize3DES - 1);
    bufferPtr     = malloc( bufferPtrSize * sizeof(uint8_t));
    memset((void *)bufferPtr, 0x0, bufferPtrSize);
    
    const void *vkey     = (const void *) [key UTF8String];
    //偏移量
//    const void *vinitVec = (const void *) [gIv UTF8String];
    
    //配置CCCrypt
    CCCrypt(kCCEncrypt,
            kCCAlgorithm3DES, //3DES
            kCCOptionECBMode|kCCOptionPKCS7Padding, //设置模式
            vkey,    //key
            kCCKeySize3DES,
            vinitVec,     //偏移量，这里不用，设置为nil;不用的话，必须为nil,不可以为@“”
            vplainText,
            plainTextBufferSize,
            (void *)bufferPtr,
            bufferPtrSize,
            &movedBytes);
    
    NSData *myData                = [NSData dataWithBytes:(const char *)bufferPtr length:(NSUInteger)movedBytes];

    NSUInteger          len       = [myData length];
    char *              chars     = (char *)[myData bytes];
    NSMutableString *   hexString = [[NSMutableString alloc] init];

    for(NSUInteger i = 0; i < len; i++ )
        [hexString appendString:[NSString stringWithFormat:@"%0.2hhx", chars[i]]];
    
    return hexString;
}

- (NSString *)decryptHexStrWithKey:(NSString *)key{

    //十六进制转NSData
    long len                  = [self length] / 2;
    unsigned char *buf        = malloc(len);
    unsigned char *whole_byte = buf;
    char byte_chars[3]        = {'\0','\0','\0'};
    
    int i;
    for (i=0; i < [self length] / 2; i++) {
        byte_chars[0] = [self characterAtIndex:i*2];
        byte_chars[1] = [self characterAtIndex:i*2+1];
        *whole_byte   = strtol(byte_chars, NULL, 16);
        whole_byte++;
    }
    
    NSData *encryptData        = [NSData dataWithBytes:buf length:len];
    size_t plainTextBufferSize = [encryptData length];
    const void *vplainText     = [encryptData bytes];
    
//    CCCryptorStatus ccStatus;
    uint8_t *bufferPtr   = NULL;
    size_t bufferPtrSize = 0;
    size_t movedBytes    = 0;
    
    bufferPtrSize = (plainTextBufferSize + kCCBlockSize3DES) & ~(kCCBlockSize3DES - 1);
    bufferPtr     = malloc( bufferPtrSize * sizeof(uint8_t));
    memset((void *)bufferPtr, 0x0, bufferPtrSize);
    
    const void *vkey     = (const void *) [key UTF8String];
//    const void *vinitVec = (const void *) [gIv UTF8String];

    CCCrypt(kCCDecrypt,
            kCCAlgorithm3DES,
            kCCOptionPKCS7Padding|kCCOptionECBMode,
            vkey,
            kCCKeySize3DES,
            vinitVec,
            vplainText,
            plainTextBufferSize,
            (void *)bufferPtr,
            bufferPtrSize,
            &movedBytes);
    
    NSString *result = [[NSString alloc] initWithData:[NSData dataWithBytes:(const void *)bufferPtr length:(NSUInteger)movedBytes] encoding:NSUTF8StringEncoding];
    // 释放内存
//    free(whole_byte);
    free(buf);
    return result;
}

@end