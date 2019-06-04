//
//  SJUmengModule.m
//  WeexEros
//
//  Created by Luke on 5/21/19.
//  Copyright © 2019 benmu. All rights reserved.
//

#import "SJUmengModule.h"
#import <WeexPluginLoader/WeexPluginLoader.h>
#import <UMCommon/UMCommon.h>
#import <UMShare/UMShare.h>
#import <GoogleSignIn/GoogleSignIn.h>                                                   // google 登录
#import "YYModel.h"
#import "SJShareModel.h"

//#import "NSDictionary+Util.h"
//#import "BMMediatorManager.h"

WX_PlUGIN_EXPORT_MODULE(SJSocialShare, SJUmengModule)

@interface SJUmengModule ()<GIDSignInDelegate, GIDSignInUIDelegate>

@property (copy, nonatomic) WXModuleCallback successCallback;                           // Google登录/登出成功信息回调
@property (copy, nonatomic) WXModuleCallback failedCallback;                            // Google登录/登出失败信息回调

@end

@implementation SJUmengModule

@synthesize weexInstance;

WX_EXPORT_METHOD_SYNC(@selector(initUM:))                                               // 初始化友盟方法
WX_EXPORT_METHOD_SYNC(@selector(initWechat:))                                           // 初始化Wechat平台方法
WX_EXPORT_METHOD_SYNC(@selector(initFacebook:))                                         // 初始化Facebook平台方法
WX_EXPORT_METHOD_SYNC(@selector(initGoogle:))                                           // 初始化Google平台方法
WX_EXPORT_METHOD(@selector(loginWithPlatformType:successCallback:failedCallback:))      // 第三方授权【登录】方法
WX_EXPORT_METHOD(@selector(logoutWithPlatformType:successCallback:failedCallback:))     // 取消授权【登出】方法
WX_EXPORT_METHOD(@selector(shareWithInfo:successCallback:failedCallback:))              // 分享方法


#pragma mark init
/**
 *  初始化友盟方法
 *  @param appkey 友盟平台申请的appkey
 */
- (void)initUM:(NSString *)appkey
{
    /* 初始化友盟组件 */
    [UMConfigure initWithAppkey:appkey channel:nil];
}


/**
 *  初始化第三方平台: 微信 Wechat【友盟】
 *  @param info  注册信息字典[键值]
             {
                appKey:      'appkey',        // 微信开发平台申请的appkey
                appSecret:   'appSecret',     // appKey对应的appSecret
                redirectURL: '回调页面'         // 授权回调页面
             }
 */
- (void)initWechat:(NSDictionary *)info
{
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_WechatSession
                                          appKey:info[@"appKey"]
                                       appSecret:info[@"appSecret"]
                                     redirectURL:info[@"redirectURL"]];
    
    NSString *appKey      = info[@"appKey"] ? info[@"appKey"]: @"";
    NSString *appSecret   = info[@"appSecret"] ? info[@"appSecret"]: @"";
    NSString *redirectURL = info[@"redirectURL"] ? info[@"redirectURL"]: @"";
    [self initPlatformWithPlaform:UMSocialPlatformType_WechatSession appKey:appKey appSecret:appSecret redirectURL:redirectURL];
}


/**
 *  初始化第三方平台: Facebook 【友盟】
 *  @param info  注册信息字典[键值]
             {
                appKey:      'appkey',        // Facebook开发平台申请的appkey
                appSecret:   'appSecret',     // appKey对应的appSecret
                redirectURL: '回调页面'        // 授权回调页面
             }
 */
- (void)initFacebook:(NSDictionary *)info
{
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_Facebook
                                          appKey:info[@"appKey"]
                                       appSecret:info[@"appSecret"]
                                     redirectURL:info[@"redirectURL"]];
    
    NSString *appKey      = info[@"appKey"] ? info[@"appKey"]: @"";
    NSString *appSecret   = info[@"appSecret"] ? info[@"appSecret"]: @"";
    NSString *redirectURL = info[@"redirectURL"] ? info[@"redirectURL"]: @"";
    [self initPlatformWithPlaform:UMSocialPlatformType_WechatSession appKey:appKey appSecret:appSecret redirectURL:redirectURL];
}


/**
 *  login 初始化第三方平台: Google 【单独集成】
 *  @param clientID  服务器ID
 */
- (void)initGoogle:(NSString *)clientID
{
    [GIDSignIn sharedInstance].clientID   = clientID ? clientID:@"";
    [GIDSignIn sharedInstance].delegate   = self;
    [GIDSignIn sharedInstance].uiDelegate = self;
}


#pragma mark login/logout

/**
 *  login 第三方授权【登录】
 *  @param platformType    平台类型 （传字符串：@"WechatSession", @"Facebook", @"Google"）
 *  @param successCallback 成功回调
 *  @param failedCallback  失败回调
 */
- (void)loginWithPlatformType:(NSString *)platformType successCallback:(WXModuleCallback)successCallback failedCallback:(WXModuleCallback)failedCallback
{
    // 是否安装当前平台
//    BOOL isInstall = [[UMSocialManager defaultManager] isInstall:platform];
//    if (!isInstall) {
//        [self alertWithShow:@"平台未安装"];
//    }
    
    UMSocialPlatformType platform = [self getPlatformTypeWithKey:platformType];

    NSString *platformName = [self getPlatformShowName:platform];
    
    // Google登录
    if (platform == UMSocialPlatformType_GooglePlus) {
        
        [[GIDSignIn sharedInstance] signIn];
        
        self.successCallback = successCallback;
        
        self.failedCallback  = failedCallback;
        
    }
    else{
        // Facebook，Wechat登录
        [[UMSocialManager defaultManager] getUserInfoWithPlatform:platform currentViewController:weexInstance.viewController completion:^(id result, NSError *error) {
            if (error) {
                WXLogError(@"%@",error);
                NSString   *errorMsg = [self getMesageWithError:error type:@"login"];
                NSString       *show = [NSString stringWithFormat:@"%@ %@", platformName, errorMsg];
                NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeError msg:show data:nil];
                if (failedCallback) {
                    failedCallback(resDic);
                }
            } else {
                UMSocialUserInfoResponse *resp = result;
                
                if (successCallback) {
                    NSString *show = [NSString stringWithFormat:@"%@ login success", platformName];
                    NSMutableDictionary *userInfo = [resp yy_modelToJSONObject];
                    NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeSuccess msg:show data:userInfo];
                    successCallback(resDic);
                }
            }
        }];
    }
}

/**
 *  logout 取消授权【登出】
 *  @param platformType    平台类型 （传字符串：@"WechatSession", @"Facebook", @"Google"）
 *  @param successCallback 成功回调
 *  @param failedCallback  失败回调
 */
- (void)logoutWithPlatformType:(NSString *)platformType successCallback:(WXModuleCallback)successCallback failedCallback:(WXModuleCallback)failedCallback
{
    UMSocialPlatformType platform = [self getPlatformTypeWithKey:platformType];
    
    NSString *platformName = [self getPlatformShowName:platform];

    // Google登出
    if (platform == UMSocialPlatformType_GooglePlus) {
        
        [[GIDSignIn sharedInstance] signOut];
        
        self.successCallback = successCallback;
        
        self.failedCallback  = failedCallback;
        
    }
    else{
        // Facebook，Wechat登出
        [[UMSocialManager defaultManager] cancelAuthWithPlatform:platform completion:^(id result, NSError *error) {
            if (error) {
                WXLogError(@"%@",error);
                NSString   *errorMsg = [self getMesageWithError:error type:@"logout"];
                NSString       *show = [NSString stringWithFormat:@"%@ %@", platformName, errorMsg];
                NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeError msg:show data:nil];
                if (failedCallback) {
                    failedCallback(resDic);
                }
                
            } else {
                UMSocialUserInfoResponse *resp = result;
                
                if (successCallback) {
                    NSString *show = [NSString stringWithFormat:@"%@ logout success", platformName];
                    NSMutableDictionary *userInfo = [resp yy_modelToJSONObject];
                    NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeSuccess msg:show data:userInfo];
                    successCallback(resDic);
                }
            }
        }];
    }
    
}


#pragma mark Share 分享

/**
 *  各平台分享：【不支持Google分享】
 *  @param info  分享信息字典[键值]
             {
                title:'',                 // 分享的标题
                content:'',               // 分享的文字内容 字符串
                url: '',                  // 分享对应的URL地址，如h5、音乐链接、视频链接、小程序的链接
                thumImage: '',            // 分享类型的缩略图url
                image: '',                // 分享的图片url
                path: '',                 // 分享小程序用到的页面路径
                userName: ''              // 小程序名称
                shareType: 'Webpage',     // 分享的类型：网页链接  （BMShareType 对应描述）
                platform: 'WechatSession' // 分享平台：朋友圈/好友 （BMSharePlatformType对应描述，传字符串：@"WechatSession", @"Facebook", @"Google"）
             }
 *  @param successCallback 成功回调
 *  @param failedCallback  失败回调
 *  支持类型：
    Wechat  ：[@"纯文本", @"图片", @"图文", @"音乐链接", @"视频", @"网页链接", @"微信小程序"]
    FaceBook：[@"图片", @"图文", @"本地视频", @"网页链接"]
 */
- (void)shareWithInfo:(NSDictionary *)info successCallback:(WXModuleCallback)successCallback failedCallback:(WXModuleCallback)failedCallback
{
    SJShareModel *model = [SJShareModel yy_modelWithJSON:info];
 
    NSString *shareTitle = model.title?:@"";
    NSString *shareText  = model.content?:@"";
    NSString *shareUrl   = model.url;
    id shareImage        = model.image;
    id thumbImage        = model.thumImage;

    UMSocialPlatformType    platformType = UMSocialPlatformType_UnKnown;
    UMSocialMessageObject *messageObject = [UMSocialMessageObject messageObject];
    
    /** 分享平台 */
    //微信聊天
    if (model.platform == BMSharePlatformType_WechatSession)
    {
        platformType = UMSocialPlatformType_WechatSession;
    }
    //微信朋友圈
    else if (model.platform == BMSharePlatformType_WechatTimeLine)
    {
        platformType = UMSocialPlatformType_WechatTimeLine;
    }
    //Facebook
    else if (model.platform == BMSharePlatformType_FaceBook)
    {
        platformType = UMSocialPlatformType_Facebook;
    }
    
    // 判断当前平是否支持分享
//    BOOL isSupport = [[UMSocialManager defaultManager] isSupport:platformType];
//    if (!isSupport) {
//        //NSLog(@"当前平台不支持分享");
//        return;
//    }
    
    /** 分享类型 */
    //文本
    if (model.shareType == BMShareTypeText) {
        messageObject.text = shareText;
    }
    //图片
    else if (model.shareType == BMShareTypeImage)
    {
        UMShareImageObject *shareObject = [[UMShareImageObject alloc] init];
        shareObject.shareImage    = shareImage;
        messageObject.shareObject = shareObject;
    }
    //图文
    else if (model.shareType == BMShareTypeTextImage)
    {
        UMShareImageObject *shareObject = [UMShareImageObject shareObjectWithTitle:shareTitle descr:shareText thumImage:nil];
        shareObject.shareImage    = shareImage;
        messageObject.text        = shareText;
        messageObject.shareObject = shareObject;
    }
    //音乐链接
    else if (model.shareType == BMShareTypeMusic)
    {
        UMShareMusicObject *shareObject = [UMShareMusicObject shareObjectWithTitle:shareTitle descr:shareText thumImage:thumbImage];
        shareObject.musicUrl      = shareUrl;
        messageObject.shareObject = shareObject;
    }
    //视频链接
    else if (model.shareType == BMShareTypeVideo)
    {
        UMShareVideoObject *shareObject = [UMShareVideoObject shareObjectWithTitle:shareTitle descr:shareText thumImage:thumbImage];
        shareObject.videoUrl      = shareUrl;
        messageObject.shareObject = shareObject;
    }
    //小程序
    else if (model.shareType == BMShareTypeMiniProgram)
    {
        UMShareMiniProgramObject *shareObject = [UMShareMiniProgramObject shareObjectWithTitle:shareTitle descr:shareText thumImage:thumbImage];
        shareObject.webpageUrl    = shareUrl;
        shareObject.path          = model.path;
        shareObject.userName      = model.userName;
        messageObject.shareObject = shareObject;
    }
    //网页链接
    else
    {
        UMShareWebpageObject *shareObject = [UMShareWebpageObject shareObjectWithTitle:shareTitle descr:shareText thumImage:thumbImage];
        shareObject.webpageUrl    = shareUrl;
        messageObject.text        = shareText;
        messageObject.shareObject = shareObject;
    }
    
    // 设置分享内容
    [[UMSocialManager defaultManager] shareToPlatform:platformType
                                        messageObject:messageObject
                                currentViewController:weexInstance.viewController //[BMMediatorManager shareInstance].currentViewController
                                           completion:^(id result, NSError *error) {
                                               
                                               if (error) {
                                                   WXLogError(@"%@",error);
                                                   // UMSocialLogInfo(@"************Share fail with error %@*********",error);
                                                   NSString *errorMsg = [self getMesageWithError:error type:@"Share"];
                                                   
                                                   /* 失败回调 */
                                                   if (failedCallback) {
                                                       NSDictionary *data = [self configCallbackDataWithResCode:SJResCodeError msg:errorMsg data:nil];
                                                       failedCallback(data);
                                                   }
                                                   
                                               } else {
                                                   
                                                   /* 成功回调 */
                                                   if (successCallback) {
                                                       NSDictionary *data = [self configCallbackDataWithResCode:SJResCodeSuccess msg:@"Share success" data:nil];
                                                       successCallback(data);
                                                   }
                                                   
//                                                   if (error) {
//                                                       UMSocialLogInfo(@"************Share fail with error %@*********",error);
//                                                       NSLog(@"error = %@",error);
                                                   
//                                                   if ([result isKindOfClass:[UMSocialShareResponse class]]) {
//                                                       UMSocialShareResponse *resp = result;
//                                                       //分享结果消息
//                                                       UMSocialLogInfo(@"response message is %@",resp.message);
//                                                       //第三方原始返回的数据
//                                                       UMSocialLogInfo(@"response originalResponse data is %@",resp.originalResponse);
//
//                                                   }else{
//                                                       UMSocialLogInfo(@"response data is %@",result);
//                                                   }
                                               }
                                           }];
}


#pragma mark Google登录代理 - GIDSignInDelegate

// 处理登录过程
- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
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
        if (self.failedCallback) {
            self.failedCallback(resDic);
        }
    } else {
        if (self.successCallback) {
            NSString *show = [NSString stringWithFormat:@"Google login success"];
            NSMutableDictionary *userInfo = [user yy_modelToJSONObject];
            NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeSuccess msg:show data:userInfo];
            self.successCallback(resDic);
        }
    }
}

- (void)signIn:(GIDSignIn *)signIn didDisconnectWithUser:(GIDGoogleUser *)user withError:(NSError *)error {
    // Perform any operations when the user disconnects from app here.
    // NSLog(@"signIn - didDisconnectWithUser: %@, \n error:%@", user,error);
    
    if (error) {
        WXLogError(@"%@",error);
        NSString   *errorMsg = [self getMesageWithError:error type:@"Google logout"];
        NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeError msg:errorMsg data:nil];
        if (self.failedCallback) {
            self.failedCallback(resDic);
        }
    } else {
        if (self.successCallback) {
            NSString *show = [NSString stringWithFormat:@"Google logout success"];
            NSMutableDictionary *userInfo = [user yy_modelToJSONObject];
            NSDictionary *resDic = [self configCallbackDataWithResCode:SJResCodeSuccess msg:show data:userInfo];
            self.successCallback(resDic);
        }
    }
}

#pragma mark Google登录代理 - GIDSignInUIDelegate

// Implement these methods only if the GIDSignInUIDelegate is not a subclass of
// UIViewController.

// Stop the UIActivityIndicatorView animation that was started when the user
// pressed the Sign In button
- (void)signInWillDispatch:(GIDSignIn *)signIn error:(NSError *)error {
    //[myActivityIndicator stopAnimating];
}

// Present a view that prompts the user to sign in with Google
- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController {
    [weexInstance.viewController  presentViewController:viewController animated:YES completion:nil];
}

// Dismiss the "Sign in with Google" view
- (void)signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController {
    [weexInstance.viewController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark private

/** 初始化平台方法：[支持WechatSession,Facebook]  */
- (void)initPlatformWithPlaform:(UMSocialPlatformType)plaform appKey:(NSString *)appKey appSecret:(NSString *)appSecret redirectURL:(NSString *)redirectURL{
    
    if ([redirectURL isEqualToString:@""]) {
        redirectURL = nil;
    }
    if ([appSecret isEqualToString:@""]) {
        appSecret = nil;
    }
    
    [[UMSocialManager defaultManager] setPlaform:plaform appKey:appKey appSecret:appSecret redirectURL:redirectURL];
    
    [UMSocialGlobal shareInstance].isUsingHttpsWhenShareContent = NO;
}


/** 通过平台类型及操作类型获取显示的平台名称 */
- (NSString *)getPlatformShowName:(UMSocialPlatformType)platform
{
    NSString *name = @"";
    switch (platform) {
        case UMSocialPlatformType_WechatSession:{  // 微信聊天
            name = @"Wechat";
            break;
        }
        case UMSocialPlatformType_Facebook:       // Facebook
            name = K_SharePlatformFacebook;
            break;
        case UMSocialPlatformType_GooglePlus:     // Google
            name = K_SharePlatformGoogle;
            break;
        default:
            break;
    }
    return name;
}


/**  获取平台类型 */
- (UMSocialPlatformType)getPlatformTypeWithKey:(NSString *)key
{
    UMSocialPlatformType platform = UMSocialPlatformType_UnKnown;
    
    if ([key isEqualToString:K_SharePlatformWechatSession]) {
        platform = UMSocialPlatformType_WechatSession;
    }
    else if ([key isEqualToString:K_SharePlatformWechatTimeLine])
    {
        platform = UMSocialPlatformType_WechatSession;
    }
    else if ([key isEqualToString:K_SharePlatformFacebook])
    {
        platform = UMSocialPlatformType_Facebook;
    }
    else if ([key isEqualToString:K_SharePlatformGoogle])
    {
        platform = UMSocialPlatformType_GooglePlus;
    }
    return platform;
}


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

@end
