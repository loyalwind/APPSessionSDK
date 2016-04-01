//
//  APPSessionManager.h
//  SDK_Normal
//
//  Created by  wj peng on 16/3/17.
//  Copyright © 2016年 wjpeng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APPSessionManager : NSObject
//使用步骤：
//1、调用 APPSessionManager *mgr = [APPSessionManager sharedManager];
//2、配置一次mgr ,主要是配置token请求时url,channel,appVersion,protocolVersion
//3、调用[mgr post: data: success: failure:]发送请求;


/**
 *  网络请求单例
 */
+ (APPSessionManager *)sharedManager;
/**
 *  配置manager（改方法必须配置一次mgr，方可使用post）
 *
 *  @param tokenUrlString  token接口的url,用于内部获取token 和sessionid
 *  @param channel         渠道
 *  @param appVersion      app版本号
 *  @param protocolVersion 通信协议版本号
 */
- (void)configurationTokenUrl:(NSString *)tokenUrlString channel:(NSString *)channel appVersion:(NSString *)appVersion protocolVersion:(NSString *)protocolVersion;
/**
 *  发送'POST'请求，获取token
 *
 *  @param URLString  http请求地址
 *  @param parameters 请求参数
 *  @param success    成功的回调
 *  @param failure    失败的回调
 */
- (void)postFetchToken:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void(^)(id responseData))success failure:(void (^)(id responseData))failure;
/**
 *  发送'POST'请求，获取login
 *
 *  @param URLString  http请求地址
 *  @param parameters 请求参数
 *  @param success    成功的回调
 *  @param failure    失败的回调
 */
- (void)postLogin:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void(^)(id responseData))success failure:(void (^)(id responseData))failure;
/**
 *  发送'POST'请求，获取检查版本
 *
 *  @param URLString  http请求地址
 *  @param parameters 请求参数
 *  @param success    成功的回调
 *  @param failure    失败的回调
 */
- (void)postCheckVersion:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void(^)(id responseData))success failure:(void (^)(id responseData))failure;

/**
 *  发送'POST'请求，通用接口
 *
 *  @param URLString  http请求地址
 *  @param parameters 请求参数
 *  @param success    成功的回调
 *  @param failure    失败的回调
 */
- (void)post:(NSString *)URLString data:(NSDictionary *)data success:(void(^)(id responseData))success failure:(void (^)(id responseData))failure;
/**
 *  发送'GET'请求，通用接口
 *
 *  @param URLString  http请求地址
 *  @param parameters 请求参数
 *  @param success    成功的回调
 *  @param failure    失败的回调
 */
- (void)get:(NSString *)URLString data:(NSDictionary *)data success:(void(^)(id responseData))success failure:(void (^)(id responseData))failure;
@end
