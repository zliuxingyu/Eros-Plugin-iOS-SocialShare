//
//  SJMicrosoftSocialManager.h
//  ErosPluginSocialShare
//
//  Created by Luke on 2020/1/15.
//  Copyright © 2020 LUKE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WeexSDK/WeexSDK.h>

#define UMSocialPlatformType_UserDefine_Microsoft 1888 // 自定义Microsoft平台号

NS_ASSUME_NONNULL_BEGIN

@interface SJMicrosoftSocialManager : NSObject

// 单例
+ (SJMicrosoftSocialManager *)sharedInstance;

// 初始化Microsoft平台
- (void)setMicrosoftPlaformWithClientID:(NSString *)clientID;

// Microsoft登录结果
- (void)loginFromMicrosoftWithSuccessCallback:(WXModuleCallback)successCallback failedCallback:(WXModuleCallback)failedCallback;

// Microsoft登出结果
- (void)logoutFromMicrosoftWithSuccessCallback:(WXModuleCallback)successCallback failedCallback:(WXModuleCallback)failedCallback;

@end

NS_ASSUME_NONNULL_END
