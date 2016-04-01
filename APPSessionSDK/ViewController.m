//
//  ViewController.m
//  APPSessionSDK
//
//  Created by weijianPeng on 16/4/1.
//  Copyright © 2016年 wjpeng. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking/AFNetworking.h"
#import "APPSessionManager.h"
#import "NSString+Secure.h"

#define kIP @"http:192.168.7.203:8888/"

@interface ViewController ()
@property (nonatomic, weak) APPSessionManager *manager;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *entry;
@property (nonatomic, copy) NSString *hexEntry;
@property (nonatomic, strong) NSDictionary *dataDict;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableString *key = [NSMutableString string];
    for (int i = 0; i < 24; i++) {
        [key appendString:@"8"];
    }
    self.key = key;
}

- (APPSessionManager *)manager
{
    if (!_manager) {
        _manager = [APPSessionManager sharedManager];
        [_manager configurationTokenUrl:@"http://192.168.7.203:8888/token.flow" channel:@"IOS" appVersion:@"1.1.0" protocolVersion:@"1.1.0"];
    }
    return _manager;
}
- (IBAction)requestToken:(UIButton *)button
{
    NSLog(@"%s",__func__);
    NSString *urlStr = @"http://192.168.7.203:8888/token.flow";
    NSMutableDictionary *parmas = [NSMutableDictionary dictionary];
    parmas[@"rand"]             = [NSString randomNum];
    parmas[@"channel"]          = @"IOS";
    parmas[@"timestamp"]        = @"20160318123030";
    parmas[@"authstring"]       = @"xxxxxx";
    parmas[@"appversion"]       = @"1.0";
    parmas[@"protocolversion"]  = @"1.0";
    __block typeof(self) weakSelf = self;
    [self.manager postFetchToken:urlStr parameters:parmas success:^(id responseData) {
        NSLog(@"%@",responseData);
        weakSelf.dataDict = responseData[@"data"];
    } failure:^(id responseData) {
        NSLog(@"%@",responseData);
    }];
}
- (IBAction)requestLogin:(UIButton *)button
{
    NSLog(@"%s",__func__);
    if (self.dataDict[@"sessionid"] == nil)return;
    
    NSString *urlStr = @"http://192.168.7.203:8888/login.flow";
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data[@"account"]          = @"testIos";
    data[@"password"]         = @"123456";
    [self.manager post:urlStr data:data success:^(id responseData) {
        NSLog(@"success%@",responseData);
    } failure:^(id responseData) {
        NSLog(@"failure%@",responseData);
    }];
    return;
    NSMutableDictionary *parmas = [NSMutableDictionary dictionary];
    parmas[@"sessionid"]        = self.dataDict[@"sessionid"];
    parmas[@"channel"]          = @"IOS";
    parmas[@"timestamp"]        = @"20160318123030";
    parmas[@"authstring"]       = @"xxxxxx";
    parmas[@"appversion"]       = @"1.1.0";
    parmas[@"protocolversion"]  = @"1.1.0";
    parmas[@"account"]          = @"test123";
    parmas[@"password"]         = @"666666";
    parmas[@"token"]            = self.dataDict[@"token"];
    parmas[@"data"]             = @{
                                    @"sessionid" : @"1B7308E67B67413184AAA4235C7C24E9",
                                    @"token" : @"98350A80284E4FD58E2541B5F9A4415D"
                                    };
    [self.manager postLogin:urlStr parameters:parmas success:^(id responseData) {
        NSLog(@"%@",responseData);
    } failure:^(id responseData) {
        NSLog(@"%@",responseData);
    }];
}
@end
