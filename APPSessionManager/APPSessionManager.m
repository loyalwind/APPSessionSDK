//
//  APPSessionManager.m
//  SDK_Normal
//
//  Created by wj peng on 16/3/17.
//  Copyright © 2016年 wjpeng. All rights reserved.
//
/**
 * login接口 :
 返回成功结果格式:
 {"code":0,"msg":"成功","data":""}
 返回失败结果格式:
 {"code":3,"msg":"账号未注册，请先注册后再试","data":""}
 */
#import "APPSessionManager.h"
#import "NSString+Secure.h"
#import "NSDate+TimeStamp.h"
#import "AFNetworking.h"

#define kIP @"http:192.168.7.203:8888/"
#ifdef DEBUG // 调试阶段
#define SCLog(format, ...) NSLog((@"【函数名:%s】【行号:%d】" format), __FUNCTION__, __LINE__, ##__VA_ARGS__);
#else  // 发布阶段
#define SCLog(format, ...);
#endif


@interface APPSessionManager()<NSMutableCopying,NSCopying>
/** 解密的key*/
@property (nonatomic, copy) NSString *key;
/** 存储配置的配置*/
@property (nonatomic, copy) NSMutableDictionary *config;
/** tokenUrl*/
@property (nonatomic, copy) NSString *tokenUrlString;
/** AFN网络管理者*/
@property (nonatomic, strong) AFHTTPSessionManager *manager;

@end

static id _instance = nil;
NSString * const kMD5Key= @"#&*^!";
@implementation APPSessionManager
// 单例
+ (APPSessionManager *)sharedManager
{
    return [[APPSessionManager alloc] init];
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:zone] init];
    });
    return _instance;
}
- (id)mutableCopyWithZone:(NSZone *)zone
{
    return self;
}
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}
#pragma mark - 懒加载
- (NSMutableDictionary *)config
{
    if (!_config) {
        _config = [NSMutableDictionary dictionary];
    }
    return _config;
}
- (AFHTTPSessionManager *)manager
{
    @synchronized (self) {
        if (!_manager) {
            _manager = [AFHTTPSessionManager manager];
            // 测试用这个
            NSMutableString *key = [NSMutableString string];
            for (int i = 0; i < 24; i++) {
                [key appendString:@"8"];
            }
            _key = key;
        }
    }
    return _manager;
}
/** 配置manager*/
- (void)configurationTokenUrl:(NSString *)tokenUrlString channel:(NSString *)channel appVersion:(NSString *)appVersion protocolVersion:(NSString *)protocolVersion
{
    if (tokenUrlString.length && channel.length && appVersion.length && protocolVersion.length){
        self.config[@"channel"]         = channel;
        self.config[@"appversion"]      = appVersion;
        self.tokenUrlString             = tokenUrlString;
        self.config[@"protocolversion"] = protocolVersion;
    }
}
/** 获取token接口的部分参数*/
- (NSDictionary *)tokenParameters
{
    // 随机数
    NSString *rand       = [NSString randomNum];
    self.key             = [rand copy];
    NSString *timestamp  = [[NSDate date] timeStamp];
    NSString *authstring = [[timestamp stringByAppendingString:kMD5Key] md5];
    return @{@"rand" : rand, @"timestamp" : timestamp, @"authstring" : authstring};
}
#pragma mark - 'POST'请求 -------------------------------------begin
/** 通用POST请求接口，自动包含token接口*/
- (void)post:(NSString *)URLString data:(NSDictionary *)data success:(void(^)(id responseData))success failure:(void (^)(id responseData))failure
{
    // 设置token请求的参数在config中
    [self.config addEntriesFromDictionary:[self tokenParameters]];
    // 发送第一次请求（默认给它先保存一层请求，token接口请求）
    [self.manager POST:self.tokenUrlString parameters:self.config success:^(NSURLSessionDataTask *task, id responseToken) {
        SCLog(@"token接口POST请求成功");
        if (![responseToken[@"data"] length]) {// data这个key没有值就调用success这个block再退出回调
            SCLog(@"token接口返回的data值为空或者是空串");
            !success?:success(responseToken);
            return ;
        }
        if([responseToken[@"code"] integerValue] == 1){// 获取请求数据失败，是服务器那边出错的
            !failure?:failure(responseToken);
        }else if ([responseToken[@"code"] integerValue] == 0){// 获取请求数据成功
            NSError *error = nil;
            // 把token接口返回的数据进行解密，拿到解了密的一个响应字典
            NSDictionary *responseDecryptedDict = [self handleDataKeyForResponseDict:responseToken entryKey:self.key error:&error];
            if (error) {
                !failure?:failure(error);
                return ;
            }
            // 拿到响应数据data这个key对应的明文数据
            NSDictionary *decryptKey = responseDecryptedDict[@"data"];
            // 进行新的请求参数的拼接处理
            NSDictionary *otherRequestParma = [self hanleRequestParameters:data decryptKey:decryptKey error:&error];
            // 发送第二次请求（就是外界希望发送的接口请求）
            [self.manager POST:URLString parameters:otherRequestParma success:^(NSURLSessionDataTask *task, id responseOther) {
                SCLog(@"该POST请求成功回来了");
                if (![responseOther[@"data"] length]){
                    !success?:success(responseOther);
                    return ;
                }
                if([responseOther[@"code"] integerValue] == 1){// 获取请求数据失败，是服务器那边出错的
                    !failure?:failure(responseOther);
                }else if ([responseOther[@"code"] integerValue] == 0){// 获取请求数据成功
                    NSError *error = nil;
                    // 把外部调用的接口返回的数据用token进行解密，拿到解了密的一个响应字典
                    NSDictionary *tokenDecryptedDict = [self handleDataKeyForResponseDict:responseToken entryKey:decryptKey[@"token"] error:&error];
                    if (error) {
                        !failure?:failure(error);
                        return;
                    }
                    !success? :success(tokenDecryptedDict);
                }
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                SCLog(@"其他POST请求失败了");
                !failure?:failure(error);
            }];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (error) {
            SCLog(@"token接口POST请求错误");
            !failure?:failure(error);
        }
    }];
}
/**
 *  用于拼接请求参数
 *
 *  @param needEncryptParams 需要加密的参数字典
 *  @param decryptKey        加密的秘钥在'token'这个key中，另外一个sessionid这个key拿出来做请求参数的一部分
 *  @param error             错误信息，如果中间某个环节出错了，就有值
 *
 *  @return 拼接好了的参数字典
 */
- (NSDictionary *)hanleRequestParameters:(NSDictionary *)needEncryptParams decryptKey:(NSDictionary *)decryptKey error:(NSError *__autoreleasing *)error
{
    if (![NSJSONSerialization isValidJSONObject:needEncryptParams]) return nil;
    // 把需要加密的字典转成需要加密的二进制数据
    NSData *needEntryData = [NSJSONSerialization dataWithJSONObject:needEncryptParams options:NSJSONWritingPrettyPrinted error:error];
    if (*error) { // 如果有错误，就返回
        SCLog(@"有错误：%@",*error);
        return nil;
    }
    // 把二进制数据转成需要加密的字符串
    NSString *needEntryString = [[NSString alloc] initWithData:needEntryData encoding:NSUTF8StringEncoding];
    if (!needEntryString) { // 如果转化失败就返回
        SCLog(@"data—>string失败");
        *error = [NSError errorWithDomain:@"data -> string is fairlue" code:0 userInfo:@{@"error":@"data -> string is fairlue"}];
        return nil;
    }
    // 把需要加密的字符串进行3DES加密
    NSString *secureString = [needEntryString encryptHexStrWithKey:decryptKey[@"token"]];
    if (!secureString) {// 加密失败就返回
        SCLog(@"字符串加密失败");
        NSString *errorInfo = [NSString stringWithFormat:@"entry this string %@ is fairlue or nil",needEntryString];
        *error = [NSError errorWithDomain:errorInfo code:0 userInfo:@{@"error":errorInfo}];
        return nil;
    }
    // 其他请求的参数封装
    NSMutableDictionary *otherRequestParma = [NSMutableDictionary dictionary];
    NSString *timestamp                    = [[NSDate date] timeStamp];
    NSString *authstring                   = [[NSString stringWithFormat:@"%@%@%@",secureString,timestamp,kMD5Key] md5];
    otherRequestParma[@"sessionid"]        = decryptKey[@"sessionid"];
    otherRequestParma[@"data"]             = secureString;
    otherRequestParma[@"timestamp"]        = timestamp;
    otherRequestParma[@"authstring"]       = authstring;
    otherRequestParma[@"channel"]          = self.config[@"channel"];
    otherRequestParma[@"appversion"]       = self.config[@"appversion"];
    otherRequestParma[@"protocolversion"]  = self.config[@"protocolversion"];
    return otherRequestParma;
}
#pragma mark - token接口的POST请求
- (void)postFetchToken:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void(^)(id responseData))success failure:(void (^)(id responseData))failure
{
    [self.manager POST:URLString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        SCLog(@"AFN请求正确：%@",responseObject);
        if([responseObject[@"code"] integerValue] == 1){// 获取请求数据失败
            !failure?:failure(responseObject);
        }else if ([responseObject[@"code"] integerValue] == 0){// 获取请求数据成功
            NSError *error = nil;
            NSDictionary *dictData = [self handleDataKeyForResponseDict:responseObject entryKey:self.key error:&error];
            if (error) {
                !failure?:failure(error);
                return ;
            }
            !success?:success(dictData);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (error) {
            SCLog(@"AFN请求错误：%@",error);
            !failure?:failure(error);
        }
    }];
}

#pragma mark - login接口的POST请求
- (void)postLogin:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void(^)(id responseData))success failure:(void (^)(id responseData))failure
{
    NSError *error = nil;
    // 把处理传进来的参数
    NSDictionary *requestDict = [self handleDataKeyForRequsetDict:parameters error:&error];
    if (error) {
        !failure?:failure(error);
        return;
    }
    // 发送POST请求
    [self.manager POST:URLString parameters:requestDict success:^(NSURLSessionDataTask *task, id responseObject) {
        if ([responseObject[@"code"] integerValue]== 0) { // 返回了成功结果
            !success?:success(responseObject);
        }else if([responseObject[@"code"] integerValue]== 3) {// 返回失败的结果
            !failure?:failure(responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        !failure?:failure(error);
    }];
}
#pragma mark - checkVersion接口的POST请求
- (void)postCheckVersion:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(id))success failure:(void (^)(id))failure
{
    
}
#pragma mark - 'POST'请求 -------------------------------------end
#pragma mark - 'GET'请求 --------------------------------------begin
/** 通用GET请求接口，自动包含token接口*/
- (void)get:(NSString *)URLString data:(NSDictionary *)data success:(void(^)(id responseData))success failure:(void (^)(id responseData))failure
{
    // 设置token请求的参数在config中
    [self.config addEntriesFromDictionary:[self tokenParameters]];
    // 发送第一次请求（默认给它先保存一层请求，token接口请求）
    [self.manager GET:self.tokenUrlString parameters:self.config success:^(NSURLSessionDataTask *task, id responseToken) {
        SCLog(@"token接口GET请求成功");
        if (!responseToken[@"data"]) {// data这个key没有值就调用success这个block再退出回调
            SCLog(@"token接口返回的data值为空或者是空串");
            !success?:success(responseToken);
            return ;
        }
        if([responseToken[@"code"] integerValue] == 1){// 获取请求数据失败，是服务器那边出错的
            !success?:success(responseToken);
        }else if ([responseToken[@"code"] integerValue] == 0){// 获取请求数据成功
            NSError *error = nil;
            // 把token接口返回的数据进行解密，拿到解了密的一个响应字典
            NSDictionary *responseDecryptedDict = [self handleDataKeyForResponseDict:responseToken entryKey:self.key error:&error];
            if (error) {
                !failure?:failure(error);
                return ;
            }
            // 拿到响应数据data这个key对应的明文数据
            NSDictionary *decryptKey = responseDecryptedDict[@"data"];
            // 进行新的请求参数的拼接处理
            NSDictionary *otherRequestParma = [self hanleRequestParameters:data decryptKey:decryptKey error:&error];
            // 发送第二次请求（就是外界希望发送的接口请求）
            [self.manager POST:URLString parameters:otherRequestParma success:^(NSURLSessionDataTask *task, id responseOther) {
                SCLog(@"该GET请求成功回来了");
                if (![responseOther[@"data"] length]){
                    !success?:success(responseOther);
                    return ;
                }
                if([responseOther[@"code"] integerValue] == 1){// 获取请求数据失败，是服务器那边出错的
                    !failure?:failure(responseOther);
                }else if ([responseOther[@"code"] integerValue] == 0){// 获取请求数据成功
                    NSError *error = nil;
                    // 把外部调用的接口返回的数据用token进行解密，拿到解了密的一个响应字典
                    NSDictionary *tokenDecryptedDict = [self handleDataKeyForResponseDict:responseToken entryKey:decryptKey[@"token"] error:&error];
                    if (error) {
                        !failure?:failure(error);
                        return;
                    }
                    !success? :success(tokenDecryptedDict);
                }
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                SCLog(@"其他GET请求失败了");
                !failure?:failure(error);
            }];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (error) {
            SCLog(@"token接口GET请求错误");
            !failure?:failure(error);
        }
    }];
}
#pragma mark - 'GET'请求 ---------------------------------------end

#pragma mark - 内部控制方法---------------------------------------
// 处理请求参数数据字典,主要是加密data这个key对应的值
- (NSDictionary *)handleDataKeyForRequsetDict:(NSDictionary *)dict error:(NSError *__autoreleasing *)error
{
    // 如果无账户、密码就返回
    if (!dict[@"account"] || !dict[@"password"]){
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"account or password is nil" code:0 userInfo:@{@"error":@"account or password is nil"}];
        }
        return nil;
    }
    // 把需要加密的数据存到一个专门的字典中
    NSDictionary *needEntryDict = @{@"account" : dict[@"account"], @"password" : dict[@"password"]};
    
    // 把需要加密的字典转成需要加密的二进制数据
    NSData *needEntryData = [NSJSONSerialization dataWithJSONObject:needEntryDict options:kNilOptions error:error];
    if (*error) { // 如果有错误，就返回
        SCLog(@"有错误：%@",*error);
        return nil;
    }
    // 把二进制数据转成需要加密的字符串
    NSString *needEntryString = [[NSString alloc] initWithData:needEntryData encoding:NSUTF8StringEncoding];
    if (!needEntryString) { // 如果转化失败就返回
        SCLog(@"data—>string失败");
        *error = [NSError errorWithDomain:@"data -> string is fairlue" code:0 userInfo:@{@"error":@"data -> string is fairlue"}];
        return nil;
    }
    // 把需要加密的字符串进行3DES加密
    NSString *secureString = [needEntryString encryptHexStrWithKey:dict[@"token"]];
    if (!secureString) {// 加密失败就返回
        SCLog(@"字符串加密失败");
        NSString *errorInfo = [NSString stringWithFormat:@"entry this string %@ is fairlue or nil",needEntryString];
        *error = [NSError errorWithDomain:errorInfo code:0 userInfo:@{@"error":errorInfo}];
        return nil;
    }
    // 利用传进来的字典生成一个新的字典
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:dict];
    params[@"data"] = secureString;
    return params;
}
// 处理服务器返回的数据字典,主要是解密data这个key对应的值
- (NSDictionary *)handleDataKeyForResponseDict:(NSDictionary *)enryptedResponseDict entryKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    // 获取到加密的data数据
    NSString *secureString = enryptedResponseDict[@"data"];
    if (!secureString) {
        NSString *errorInfo = [NSString stringWithFormat:@"the value for key 'data' in %@ instance %p is nil",enryptedResponseDict.class,enryptedResponseDict];
        if (error != NULL) {
            *error = [NSError errorWithDomain:errorInfo code:0 userInfo:@{@"error":errorInfo}];
        }
        return nil;
    }
#warning 注意修改下面两行代码
//    NSString *rand       = [NSString randomNum];
//    self.key             = [rand copy];
    // 对加密data的值进行16进制解密
    NSString *decryptHexString = [secureString decryptHexStrWithKey:key];
    if (!decryptHexString.length) {
        //        SCLog(@"%@",secureString);
        NSString *errorInfo = [NSString stringWithFormat:@"decrypt this string '%@' is failure ",secureString];
        if (error != NULL) {
            *error = [NSError errorWithDomain:errorInfo code:0 userInfo:@{@"error":errorInfo}];
        }
        return nil;
    }
    // 把解了密的字符串进行转成NSData数据
    NSData *decryptData = [decryptHexString dataUsingEncoding:NSUTF8StringEncoding];
    
    // 对NSData数据进行JSON序列化
    NSDictionary *decryptDataDict = [NSJSONSerialization JSONObjectWithData:decryptData options:NSJSONReadingMutableContainers error:error];
    if (*error) {
        SCLog(@"json序列化失败：%@",*error);
        return nil;
    }
    // 生成一个新的字典，用于返回，避免dict是不可变的情况
    NSMutableDictionary *decryptedResponseDict = [NSMutableDictionary dictionaryWithDictionary:enryptedResponseDict];
    decryptedResponseDict[@"data"] = decryptDataDict;
    return decryptedResponseDict;
}
@end
