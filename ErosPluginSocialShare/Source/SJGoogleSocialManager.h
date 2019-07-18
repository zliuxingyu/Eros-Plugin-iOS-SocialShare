//
//  SJGoogleSocialManager.h
//  AFNetworking
//
//  Created by Luke on 7/7/19.
//

#import <Foundation/Foundation.h>
#import <WeexSDK/WeexSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface SJGoogleSocialManager : NSObject

// 单例
+ (SJGoogleSocialManager *)sharedInstance;

// 初始化gGoogle平台
- (void)setGooglePlaformWithClientID:(NSString *)clientID;

// Google登录结果
- (void)loginFromGoogleWithSuccessCallback:(WXModuleCallback)successCallback failedCallback:(WXModuleCallback)failedCallback;

// Google登出结果
- (void)logoutFromGoogleWithSuccessCallback:(WXModuleCallback)successCallback failedCallback:(WXModuleCallback)failedCallback;

// Google刷新登录Token
- (void)refreshTokenFromGoogleWithSuccessCallback:(WXModuleCallback)successCallback failedCallback:(WXModuleCallback)failedCallback;

@end

NS_ASSUME_NONNULL_END
