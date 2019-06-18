//
//  SJShareModel.h
//  ErosPluginSocialShare
//
//  Created by Luke on 5/31/19.
//  Copyright © 2019 LUKE. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 请求code
typedef NS_OPTIONS(NSInteger, SJResCode) {
    SJResCodeError   = 0,
    SJResCodeSuccess = 1,
    SJResCodeOther   = 3
};

/** 平台 */
typedef NS_ENUM(NSInteger,BMSharePlatformType) {
    BMSharePlatformType_WechatSession,                         // 微信聊天
    BMSharePlatformType_WechatTimeLine,                        // 微信朋友圈
    BMSharePlatformType_FaceBook,                              // Facebook
    BMSharePlatformType_Google,                                // Google
};

#define K_SharePlatformWechatSession        @"WechatSession"
#define K_SharePlatformWechatTimeLine       @"WechatTimeLine"
#define K_SharePlatformFacebook             @"Facebook"
#define K_SharePlatformGoogle               @"Google"

/** 分享类型 */
typedef NS_ENUM(NSInteger,BMShareType) {
    BMShareTypeText,
    BMShareTypeImage,
    BMShareTypeTextImage,
    BMShareTypeWebpage,
    BMShareTypeMusic,
    BMShareTypeVideo,
    BMShareTypeMiniProgram
};

#define K_ShareTypeText                     @"Text"             // 纯文本
#define K_ShareTypeImage                    @"Image"            // 图片
#define K_ShareTypeTextImage                @"TextImage"        // 图文
#define K_ShareTypeMusic                    @"Music"            // 音乐链接
#define K_ShareTypeVideo                    @"Video"            // 视频
#define K_ShareTypeWebpage                  @"Webpage"          // 网页链接
#define K_ShareTypeMiniProgram              @"MiniProgram"      // 微信小程序


@interface SJShareModel : NSObject

@property (nonatomic,   copy) NSString *image;                  /**< 分享的图片url */
@property (nonatomic,   copy) NSString *thumImage;              /**< 分享类型的缩略图url */
@property (nonatomic,   copy) NSString *title;                  /**< 分享的标题 */
@property (nonatomic,   copy) NSString *content;                /**< 分享的文字内容 */
@property (nonatomic,   copy) NSString *url;                    /**< 分享对应的URL地址，如h5、音乐链接、视频链接、小程序的链接 */
@property (nonatomic,   copy) NSString *path;                   /**< 分享小程序用到的页面路径 */
@property (nonatomic,   copy) NSString *userName;               /**< 小程序名 */
@property (nonatomic, assign) BMSharePlatformType platform;     /**< 分享的平台 */
@property (nonatomic, assign) BMShareType shareType;            /**< 分享的类型 */

@end

NS_ASSUME_NONNULL_END
