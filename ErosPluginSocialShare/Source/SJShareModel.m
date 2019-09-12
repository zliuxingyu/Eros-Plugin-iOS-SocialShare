//
//  SJShareModel.m
//  ErosPluginSocialShare
//
//  Created by Luke on 5/31/19.
//  Copyright © 2019 LUKE. All rights reserved.
//

#import "SJShareModel.h"
#import "YYModel.h"

@implementation SJShareModel

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    
    NSString *platform = dic[@"platform"];
    if ([platform isEqualToString:K_SharePlatformWechatSession]) {
        _platform = BMSharePlatformType_WechatSession;
    }
    else if ([platform isEqualToString:K_SharePlatformWechatTimeLine])
    {
        _platform = BMSharePlatformType_WechatTimeLine;
    }
    else if ([platform isEqualToString:K_SharePlatformFacebook])
    {
        _platform = BMSharePlatformType_FaceBook;
    }
    else if ([platform isEqualToString:K_SharePlatformGoogle])
    {
        _platform = BMSharePlatformType_Google;
    }
    else if ([platform isEqualToString:K_SharePlatformTwitter])
    {
        _platform = BMSharePlatformType_Twitter;
    }
    
    NSString *type = dic[@"shareType"];
    if ([type isEqualToString:K_ShareTypeText]) {
        _shareType = BMShareTypeText;
    }
    else if ([type isEqualToString:K_ShareTypeImage])
    {
        _shareType = BMShareTypeImage;
    }
    else if ([type isEqualToString:K_ShareTypeTextImage])
    {
        _shareType = BMShareTypeTextImage;
    }
    else if ([type isEqualToString:K_ShareTypeWebpage])
    {
        _shareType = BMShareTypeWebpage;
    }
    else if ([type isEqualToString:K_ShareTypeMusic])
    {
        _shareType = BMShareTypeMusic;
    }
    else if ([type isEqualToString:K_ShareTypeVideo])
    {
        _shareType = BMShareTypeVideo;
    }
    else if ([type isEqualToString:K_ShareTypeMiniProgram])
    {
        _shareType = BMShareTypeMiniProgram;
    }
    else {
        _shareType = BMShareTypeWebpage;
    }
    
    return YES;
}

@end
