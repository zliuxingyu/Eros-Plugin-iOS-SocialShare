//
//  SJGoogleSocialManager.m
//  AFNetworking
//
//  Created by Luke on 7/7/19.
//

#import "SJGoogleSocialManager.h"
#import <GoogleSignIn/GoogleSignIn.h>                                                   // google 登录
#import "SJShareModel.h"
#import "YYModel.h"

@interface SJGoogleSocialManager ()<GIDSignInDelegate, GIDSignInUIDelegate>

@property (copy,   nonatomic) WXModuleCallback loginSuccessCallback;                    // Google登录成功信息回调
@property (copy,   nonatomic) WXModuleCallback loginFailedCallback;                     // Google登录失败信息回调
@property (copy,   nonatomic) WXModuleCallback logoutSuccessCallback;                   // Google登出成功信息回调
@property (copy,   nonatomic) WXModuleCallback logoutFailedCallback;                    // Google登出失败信息回调

@end

@implementation SJGoogleSocialManager

#pragma mark 获取对象单例
+ (SJGoogleSocialManager *)sharedInstance
{
    static SJGoogleSocialManager *share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (share == nil) {
            share = [[SJGoogleSocialManager alloc] init];
        }
    });
    return share;
}


#pragma mark Public

// 初始化gGoogle平台
- (void)setGooglePlaformWithClientID:(NSString *)clientID
{
    [GIDSignIn sharedInstance].clientID   = clientID ? clientID:@"";
    [GIDSignIn sharedInstance].delegate   = self;
    [GIDSignIn sharedInstance].uiDelegate = self;
}

// Google登录结果
- (void)loginFromGoogleWithSuccessCallback:(WXModuleCallback)successCallback failedCallback:(WXModuleCallback)failedCallback
{
    [[GIDSignIn sharedInstance] signIn];
    
    self.loginSuccessCallback = successCallback;
    
    self.loginFailedCallback  = failedCallback;
}

// Google登出结果
- (void)logoutFromGoogleWithSuccessCallback:(WXModuleCallback)successCallback failedCallback:(WXModuleCallback)failedCallback
{
    [[GIDSignIn sharedInstance] disconnect];
    
    [[GIDSignIn sharedInstance] signOut];

    self.logoutSuccessCallback = successCallback;
    
    self.logoutFailedCallback  = failedCallback;
}

#pragma mark Google登录代理 - GIDSignInDelegate

// 处理登录过程
- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error
{
    // Perform any operations on signed in user here.
    // NSLog(@"signIn - didSignInForUser %@, \n error:%@", user,error);
    //    NSString *userId = user.userID;                  // For client-side use only!
    //    NSString *idToken = user.authentication.idToken; // Safe to send to the server
    //    NSString *fullName = user.profile.name;
    //    NSString *givenName = user.profile.givenName;
    //    NSString *familyName = user.profile.familyName;
    //    NSString *email = user.profile.email;
    // ...
    
    if (error) {
        WXLogError(@"%@",error);
        NSString   *errorMsg = [self getMesageWithError:error type:@"Google login"];
        NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeError msg:errorMsg data:nil];
        if (self.loginFailedCallback) {
            self.loginFailedCallback(resDic);
        }
    } else {
        if (self.loginSuccessCallback) {
            NSString *show = [NSString stringWithFormat:@"Google login success"];
            NSMutableDictionary *userInfo = [self getSignInInfoWithModel:user];
            NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeSuccess msg:show data:userInfo];
            self.loginSuccessCallback(resDic);
        }
    }
}

// 处理登出后结果
- (void)signIn:(GIDSignIn *)signIn didDisconnectWithUser:(GIDGoogleUser *)user withError:(NSError *)error
{
    // Perform any operations when the user disconnects from app here.
    // NSLog(@"signIn - didDisconnectWithUser: %@, \n error:%@", user,error);
    
    if (error) {
        WXLogError(@"%@",error);
        NSString   *errorMsg = [self getMesageWithError:error type:@"Google logout"];
        NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeError msg:errorMsg data:nil];
        if (self.logoutFailedCallback) {
            self.logoutFailedCallback(resDic);
        }
    } else {
        if (self.logoutSuccessCallback) {
            NSString *show = [NSString stringWithFormat:@"Google logout success"];
            NSMutableDictionary *userInfo = [user yy_modelToJSONObject];
            NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeSuccess msg:show data:userInfo];
            self.logoutSuccessCallback(resDic);
        }
    }
}

#pragma mark Google登录代理 - GIDSignInUIDelegate

// Implement these methods only if the GIDSignInUIDelegate is not a subclass of
// UIViewController.

// Stop the UIActivityIndicatorView animation that was started when the user
// pressed the Sign In button
- (void)signInWillDispatch:(GIDSignIn *)signIn error:(NSError *)error
{
    
}

// Present a view that prompts the user to sign in with Google
- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController
{
    //[weexInstance.viewController  presentViewController:viewController animated:YES completion:nil];
    
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    [topController presentViewController:viewController animated:YES completion:nil];
}

// Dismiss the "Sign in with Google" view
- (void)signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController
{
    //[weexInstance.viewController dismissViewControllerAnimated:YES completion:nil];
    
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    [topController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

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

/** 处理Google登录成功后返回的信息 */
- (NSMutableDictionary *)getSignInInfoWithModel:(GIDGoogleUser *)user{
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    if (!user) {
        return userInfo;
    }
    
    NSString *userId         = user.userID ? user.userID : @"";                                  // For client-side use only!
    NSString *hostedDomain   = user.hostedDomain ? user.hostedDomain : @"";
    NSString *serverAuthCode = user.serverAuthCode ? user.serverAuthCode : @"";
    NSString *fullName       = user.profile.name ? user.profile.name : @"";
    NSString *givenName      = user.profile.givenName ? user.profile.givenName : @"";
    NSString *familyName     = user.profile.familyName ? user.profile.familyName : @"";
    NSString *email          = user.profile.email ? user.profile.email : @"";
    NSString *idToken        = user.authentication.idToken ? user.authentication.idToken : @"";  // Safe to send to the server
    NSString *accessToken    = user.authentication.accessToken ? user.authentication.accessToken : @"";
    NSString *refreshToken   = user.authentication.refreshToken ? user.authentication.refreshToken : @"";
    NSString *clientID       = user.authentication.clientID ? user.authentication.clientID : @"";
    
    NSString *accessTokenExpirationDate = @"";
    if (user.authentication.accessTokenExpirationDate) {
        accessTokenExpirationDate = [self getTimeByDate:user.authentication.accessTokenExpirationDate];
    }
    
    NSString *idTokenExpirationDate = @"";
    if (user.authentication.idTokenExpirationDate) {
        idTokenExpirationDate = [self getTimeByDate:user.authentication.idTokenExpirationDate];
    }
    
    NSString *headUrl = @"";
    if (user.profile.hasImage) {
        NSURL *url = [user.profile imageURLWithDimension:100];
        if (url) {
            headUrl = url.absoluteString;
        }
    }
    
    [userInfo setObject:userId forKey:@"userId"];
    [userInfo setObject:hostedDomain forKey:@"hostedDomain"];
    [userInfo setObject:serverAuthCode forKey:@"serverAuthCode"];
    [userInfo setObject:fullName forKey:@"fullName"];
    [userInfo setObject:givenName forKey:@"givenName"];
    [userInfo setObject:familyName forKey:@"familyName"];
    [userInfo setObject:email forKey:@"email"];
    [userInfo setObject:idToken forKey:@"idToken"];
    [userInfo setObject:accessToken forKey:@"accessToken"];
    [userInfo setObject:refreshToken forKey:@"refreshToken"];
    [userInfo setObject:clientID forKey:@"clientID"];
    [userInfo setObject:accessTokenExpirationDate forKey:@"accessTokenExpirationDate"];
    [userInfo setObject:idTokenExpirationDate forKey:@"idTokenExpirationDate"];
    [userInfo setObject:headUrl forKey:@"headUrl"];
    
    return userInfo;
}

#pragma mark Tool

- (NSDictionary *)configCallbackDataWithResCode:(NSInteger)resCode msg:(NSString *)msg data:(id)data
{
    NSMutableDictionary *resultDic = [[NSMutableDictionary alloc] init];
    
    msg = msg ?: @"";
    data = data ?: @"";
    
    [resultDic setValue:[NSNumber numberWithInteger:resCode] forKey:@"status"];
    [resultDic setValue:msg forKey:@"errorMsg"];
    [resultDic setValue:data forKey:@"data"];
    
    return resultDic;
}

- (NSString *)getTimeByDate:(NSDate *)date
{
    NSString *time = @"";
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterFullStyle];
    time = [formatter stringFromDate:date];
    return time;
}

@end
