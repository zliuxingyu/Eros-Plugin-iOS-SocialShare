//
//  SJMicrosoftSocialManager.m
//  ErosPluginSocialShare
//
//  Created by Luke on 2020/1/15.
//  Copyright © 2020 LUKE. All rights reserved.
//

#import "SJMicrosoftSocialManager.h"
#import "SJShareModel.h"
#import <MSAL/MSAL.h>

// Additional variables for Auth and Graph API
#define kGraphURI    @"https://graph.microsoft.com/v1.0/me/"
#define kScopes      @[@"https://graph.microsoft.com/user.read"]
#define kAuthority   @"https://login.microsoftonline.com/common"

@interface SJMicrosoftSocialManager ()

@property (copy,   nonatomic) NSString                    *accessToken;
@property (strong, nonatomic) MSALPublicClientApplication *applicationContext;
@property (strong, nonatomic) MSALWebviewParameters       *webViewParamaters;

@property (copy,   nonatomic) WXModuleCallback loginSuccessCallback;                    // Microsoft登录成功信息回调
@property (copy,   nonatomic) WXModuleCallback loginFailedCallback;                     // Microsoft登录失败信息回调
@property (copy,   nonatomic) WXModuleCallback logoutSuccessCallback;                   // Microsoft登出成功信息回调
@property (copy,   nonatomic) WXModuleCallback logoutFailedCallback;                    // Microsoft登出失败信息回调

@end

@implementation SJMicrosoftSocialManager

#pragma mark 获取对象单例
+ (SJMicrosoftSocialManager *)sharedInstance
{
    static SJMicrosoftSocialManager *share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (share == nil) {
            share = [[SJMicrosoftSocialManager alloc] init];
        }
    });
    return share;
}

// MARK: Public

// 初始化Microsoft平台
- (void)setMicrosoftPlaformWithClientID:(NSString *)clientID{
    
//    guard let authorityURL = URL(string: kAuthority) else {
//        self.updateLogging(text: "Unable to create authority URL")
//        return
//    }
//    let authority = try MSALAADAuthority(url: authorityURL)
//    let msalConfiguration = MSALPublicClientApplicationConfig(clientId: kClientID, redirectUri: nil, authority: authority)
//    self.applicationContext = try MSALPublicClientApplication(configuration: msalConfiguration)
//    self.webViewParamaters = MSALWebviewParameters(parentViewController: self)
    
    NSError *msalError = nil;
        
    MSALPublicClientApplicationConfig *config = [[MSALPublicClientApplicationConfig alloc] initWithClientId:clientID];
        
    self.applicationContext = [[MSALPublicClientApplication alloc] initWithConfiguration:config error:&msalError];
        
    #if TARGET_OS_IPHONE
        UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topController.presentedViewController) {
            topController = topController.presentedViewController;
        }
        self.webViewParamaters = [[MSALWebviewParameters alloc] initWithParentViewController:topController];
    #else
        self.webViewParamaters = [MSALWebviewParameters new];
    #endif
   
}


// Microsoft登录结果
- (void)loginFromMicrosoftWithSuccessCallback:(WXModuleCallback)successCallback failedCallback:(WXModuleCallback)failedCallback
{
    // 默认以交互方式获取令牌登录
    [self acquireTokenInteractively];
    
    self.loginSuccessCallback = successCallback;
    
    self.loginFailedCallback  = failedCallback;
    
}

// Microsoft登出结果
- (void)logoutFromMicrosoftWithSuccessCallback:(WXModuleCallback)successCallback failedCallback:(WXModuleCallback)failedCallback
{
    // 主动登出
    [self signOut];
    
    self.logoutSuccessCallback = successCallback;
    
    self.logoutFailedCallback  = failedCallback;
    
}


// MARK:  Private 登录用户与请求令牌
// MSAL 有两种用来获取令牌的方法：acquireToken 和 acquireTokenSilent

- (void)callGraphAPI{
    MSALAccount *account = [self currentAccount];
    if (!account) {
        
        // 以交互方式登录
        [self acquireTokenInteractively];
        return;
    }
    
    // 静默刷新token
    [self acquireTokenSilently:account];
}


// 以交互方式获取令牌
- (void)acquireTokenInteractively
{
    if (!self.applicationContext) { return; }
    if (!self.webViewParamaters) { return; }

    MSALInteractiveTokenParameters *interactiveParams = [[MSALInteractiveTokenParameters alloc] initWithScopes:kScopes webviewParameters:self.webViewParamaters];
    interactiveParams.promptType = MSALPromptTypeSelectAccount;
    
    [self.applicationContext acquireTokenWithParameters:interactiveParams completionBlock:^(MSALResult *result, NSError *error) {
        if (!error)
        {
            if (!result) {
                NSString *show = @"Could not acquire token: No result returned";
                NSLog(@"%@", show);
                WXLogError(show);
                NSString   *errorMsg = [NSString stringWithFormat:@"Microsoft login fail : %@", show];
                NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeError msg:errorMsg data:nil];
                if (self.loginFailedCallback) {
                    self.loginFailedCallback(resDic);
                }
                return;
            }
            
            // You'll want to get the account identifier to retrieve and reuse the account
            // for later acquireToken calls
            
            // NSString *accountIdentifier = result.account.identifier;
            NSString *accessToken = result.accessToken;
            self.accessToken = accessToken;
            
            NSLog(@"Access token is %@", self.accessToken);
            
            // 通过accessTokentok获取用户信息
            [self getContentWithToken];
        }
        else {
            
            NSLog(@"Could not acquire token: %@", error);
            WXLogError(@"%@",error);
            NSString   *errorMsg = [self getMesageWithError:error type:@"Microsoft login"];
            NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeError msg:errorMsg data:nil];
            if (self.loginFailedCallback) {
                self.loginFailedCallback(resDic);
            }
        }
        
    }];
}


// Silently Acquiring an Updated Token  - 以无提示方式获取访问令牌
- (void)acquireTokenSilently:(MSALAccount *)account
{
    if (!self.applicationContext) { return; }
    /**
     Acquire a token for an existing account silently
     - forScopes:           Permissions you want included in the access token received
     in the result in the completionBlock. Not all scopes are
     guaranteed to be included in the access token returned.
     - account:             An account object that we retrieved from the application object before that the
     authentication flow will be locked down to.
     - completionBlock:     The completion block that will be called when the authentication
     flow completes, or encounters an error.
     */
    
//    NSError *error = nil;
//    MSALAccount *account = [self.applicationContext accountForIdentifier:accountIdentifier error:&error];
//    if (!account)
//    {
//        // handle error
//        return;
//    }
        
    MSALSilentTokenParameters *silentParams = [[MSALSilentTokenParameters alloc] initWithScopes:kScopes account:account];
    [self.applicationContext acquireTokenSilentWithParameters:silentParams completionBlock:^(MSALResult *result, NSError *error) {
        if (!error)
        {
            if (result) {
                NSString *accessToken = result.accessToken;
                self.accessToken = accessToken;
                
                NSLog(@"Refreshed Access token is %@", accessToken);
                
                // 通过token获取用户信息
                [self getContentWithToken];
                
            }else{
                
                NSLog(@"Could not acquire token: No result returned");
            }
        }
        else
        {
            NSLog(@"Could not acquire token silently:%@", error);
            
            /* Check the error
             interactionRequired means we need to ask the user to sign-in. This usually happens
             when the user's Refresh Token is expired or if the user has changed their password
             among other possible reasons.
             */
            if ([error.domain isEqual:MSALErrorDomain] && error.code == MSALErrorInteractionRequired)
            {
                // Interactive auth will be required 以交互方式获取令牌
                [self acquireTokenInteractively];
            }
        
            // Other errors may require trying again later, or reporting authentication problems to the user
        }
    }];
}


/**
    This will invoke the call to the Microsoft Graph API. It uses the
    built in URLSession to create a connection.
*/
- (void)getContentWithToken
{
    // ---- get请求 ----
    // 1.创建NSURLSession对象（可以获取单例对象）
    NSURLSession *session = [NSURLSession sharedSession];

    // 2.根据NSURLSession对象创建一个Task
    NSURL *url = [[NSURL alloc] initWithString:kGraphURI];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    // Set the Authorization header for the request. We use Bearer tokens, so we specify Bearer + the token we got from the result
    NSString *value = [NSString stringWithFormat:@"Bearer %@", self.accessToken];
    [request setValue:value forHTTPHeaderField:@"Authorization"];
    
    // post请求示例，把参数放在请求体中传递
    // request.HTTPMethod = @"POST";
    // request.HTTPBody = [@"deviceType=IOS" dataUsingEncoding:NSUTF8StringEncoding];
    
    /*
     注意：该block是在子线程中调用的，如果拿到数据之后要做一些UI刷新操作，那么需要回到主线程刷新
     第一个参数：需要发送的请求对象
     block:当请求结束拿到服务器响应的数据时调用block
     block-NSData:该请求的响应体
     block-NSURLResponse:存放本次请求的响应信息，响应头，真实类型为NSHTTPURLResponse
     block-NSErroe:请求错误信息
     */
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
       
        // 拿到响应头信息
        // NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
        
        // 4.解析拿到的响应数据
        // NSLog(@"%@\n%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding], res.allHeaderFields);
      
        NSString *show = @"";
        NSString *errorMsg = @"";
        
        if (!error) {
            if (data) {
                NSObject *jsonObject = [NSJSONSerialization
                                        JSONObjectWithData:data
                                        options:NSJSONReadingMutableLeaves
                                        error:nil];
                
                if (jsonObject && [jsonObject isKindOfClass:[NSDictionary class]]) {
                    
                    NSMutableDictionary *mutiDic = jsonObject.mutableCopy;
                   
                    // 增加accessToken字段
                    [mutiDic setObject:self.accessToken forKey:@"accessToken"];
                    
                    NSLog(@"Result from Graph: %@", mutiDic);
                    
                    if (self.loginSuccessCallback) {
                        NSString *show = [NSString stringWithFormat:@"Microsoft login success"];
                        NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeSuccess msg:show data:mutiDic];
                        self.loginSuccessCallback(resDic);
                    }
                    
                    return;

                }else{
                    
                    show = @"Couldn't deserialize result JSON";
                }
            }else{
                show = @"Couldn't get graph result data";
            }
            
            errorMsg = [NSString stringWithFormat:@"Microsoft login fail : %@", show];

        }else{
            
            show = [NSString stringWithFormat: @"Couldn't get graph result: %@", error];
            errorMsg = [self getMesageWithError:error type:@"Microsoft login"];
        }
        
        NSLog(@"%@", show);
        WXLogError(show);
        NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeError msg:errorMsg data:nil];
        if (self.loginFailedCallback) {
            self.loginFailedCallback(resDic);
        }
        
    }];
    
    // 3.执行Task: 刚创建出来的task默认是挂起状态的，需要调用该方法来启动任务（执行任务）
    [dataTask resume];
}


// MARK: Get account and removing cache
- (MSALAccount *)currentAccount
{
    if (!self.applicationContext) {
        return nil;
    }
    
    // We retrieve our current account by getting the first account from cache
    // In multi-account applications, account should be retrieved by home account identifier or username instead
    
    NSError *error = nil;
    NSArray *cachedAccounts = [self.applicationContext allAccounts:&error];
    
    if (!error && cachedAccounts && cachedAccounts.count > 0) {
    
        return cachedAccounts.firstObject;
    }
    else {
        NSLog(@"Didn't find any accounts in cache: %@", error);
    }

    return nil;
}


/**
 This action will invoke the remove account APIs to clear the token cache
 to sign out a user from this application.
 */
- (void)signOut
{
    if (!self.applicationContext) {
        return;
    }
    
    MSALAccount *account = [self currentAccount];
    if (!account) {
        
        NSString *show = @"Didn't find any accounts in cache.";
        NSLog(@"%@", show);
        WXLogError(show);
        NSString   *errorMsg = [NSString stringWithFormat:@"Microsoft logout fail : %@", show];
        NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeError msg:errorMsg data:nil];
        if (self.loginFailedCallback) {
            self.loginFailedCallback(resDic);
        }
        return;
    }
    
    /**
     Removes all tokens from the cache for this application for the provided account
     - account:    The account to remove from the cache
     */
    NSError *error = nil;
    
    [self.applicationContext removeAccount:account error:&error];
    
    if (!error) {
        self.accessToken = @"";
        
        if (self.logoutSuccessCallback) {
            NSString *show = [NSString stringWithFormat:@"Microsoft logout success"];
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeSuccess msg:show data:userInfo];
            self.logoutSuccessCallback(resDic);
        }
    }
    else {
        NSLog(@"Received error signing account out: %@", error);
        WXLogError(@"%@",error);
        NSString   *errorMsg = [self getMesageWithError:error type:@"Microsoft logout"];
        NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeError msg:errorMsg data:nil];
        if (self.loginFailedCallback) {
            self.loginFailedCallback(resDic);
        }
    }
}

#pragma mark Tool
/** 获取返回结果-错误信息 */
- (NSString *)getMesageWithError:(NSError *)error type:(NSString *)type
{
    NSString *result = nil;
    if (!error) {
        result = [NSString stringWithFormat:@"%@ complete",type];
    }
    else{
        NSMutableString *str = [NSMutableString string];
        if (error.userInfo) {
            for (NSString *key in error.userInfo) {
                [str appendFormat:@"%@ = %@\n", key, error.userInfo[key]];
            }
        }
        if (error) {
            result = [NSString stringWithFormat:@"%@ fail with error code: %d, %@", type, (int)error.code, str];
        }
        else{
            result = [NSString stringWithFormat:@"%@ fail",type];
        }
    }
    return result;
}

/** 结果封装 */
- (NSDictionary *)configCallbackDataWithResCode:(NSInteger)resCode msg:(NSString *)msg data:(id)data
{
    NSMutableDictionary *resultDic = [[NSMutableDictionary alloc] init];
    
    msg = msg ?: @"";
    data = data ?: @"";
    
    [resultDic setValue:[NSNumber numberWithInteger:resCode] forKey:@"status"];
    [resultDic setValue:msg forKey:@"message"];
    [resultDic setValue:data forKey:@"data"];
    
    return resultDic;
}

@end
