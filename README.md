# Eros-Plugin-iOS-SocialShare

> 功能简介：
1. 基于友盟ShareSDK实现：微信分享（分享到朋友圈，微信好友），微信授权登录登出，Twitter，Facebook分享和授权登录登出；
2. 基于Google官方的授权登录登出及刷新Token方法;
2. 基于Microsoft官方的授权登录登出。 

> 在使用登录分享之前，还需要一些配置 <br>
1. 首先请到友盟平台注册App获取AppKey; <br>
2. iOS平台请参考友盟的[教程](https://developer.umeng.com/docs/66632/detail/66825)配置SSO白名单、及 URL Scheme等；<br>
3. Google登录集成请参考[教程](https://developers.google.com/identity/sign-in/ios/start-integrating)、[流程](https://www.jianshu.com/p/3251468ba0a1)；<br>
4. Microsoft登录集成请参考[教程](https://docs.microsoft.com/zh-cn/azure/active-directory/develop/quickstart-v2-ios#option-1-register-and-auto-configure-your-app-and-then-download-the-code-sample)；<br>
5. 分享的页面面板可根据产品定制样式自己写。


## 集成方式

1. 打开iOS目录`工程目录/platforms/ios/WeexEros`，编辑Podfile文件，添加`ErosPluginSocialShare`组件的引用，添加代码如下，**注意**版本号改为最新的版本【查看下面Change Log】

```ruby
def common
    ...忽略其他库的引用
    # 在这里添加引用 ErosPluginSocialShare
    pod 'ErosPluginSocialShare'
end

target 'WeexEros' do
    common
end
```

2. 在终端中`cd`到此目录下执行 `pod update`，等待命令执行完毕，重新运行项目，如果没有报错则说明`ErosPluginSocialShare`组件集成成功；

## 使用

**引用Module**

```js
var socialShare = weex.requireModule('SJSocialShare')
```

**API**

* 初始化友盟SDK `initUM('appkey')` 

> 在使用之前，请先调用此方法初始化友盟SDK

```js
socialShare.initUM('友盟平台申请的appkey')
```

* 初始化微信SDK `initWechat(info)`

> 在使用分享到微信平台功能，或者微信登录功能前，需要调用此方法来初始化微信平台；

```js
socialShare.initWechat({
appKey: 'appkey',        // 微信开发平台申请的appkey
appSecret: 'appSecret',  // appKey对应的appSecret，
redirectURL: '回调页面'   // 授权回调页面
})
```

* 初始化Facebook SDK `initFacebook(info)`

> 在使用分享到Facebook平台功能，或者Facebook登录功能前，需要调用此方法来初始化Facebook平台；

```js
socialShare.initFacebook({
appKey: 'appkey',        // Facebook开发平台申请的appkey
appSecret: 'appSecret',  // appKey对应的appSecret，
redirectURL: '回调页面'   // 授权回调页面
})
```

* 初始化Twitter SDK `initTwitter(info)`

> 在使用分享到Twitter平台功能，或者Twitter登录功能前，需要调用此方法来初始化Twitter平台；

```js
socialShare.initTwitter({
appKey: 'appkey',        // Twitter开发平台申请的appkey
appSecret: 'appSecret',  // appKey对应的appSecret，
redirectURL: '回调页面'   // 授权回调页面
})
```

* 初始化Google SDK `initGoogle('clientID')`

> 在使用Google登录功能前，需要调用此方法来初始化Google平台；

```js
socialShare.initGoogle('Google平台申请的clientID')
```


* 初始化Microsoft SDK `initMicrosoft('clientID')`

> 在使用Microsoft登录功能前，需要调用此方法来初始化Microsoft平台；

```js
socialShare.initMicrosoft('Microsoft平台申请的clientID')
```


* 分享：`shareWithInfo(info,successCallback,failedCallback)`

```js
socialShare.shareWithInfo({ /* 注意：请传对应分享类型参数，没有的不传；shareType，platform为必传 */
title:'',                   // 分享的标题
content:'',                 // 分享的文字内容
url: '',                    // 分享对应的URL地址，如h5、音乐链接、视频链接、小程序的链接
thumImage: '',              // 分享类型的缩略图url
image: '',                  // 分享的图片url
path: '',                   // 分享小程序用到的页面路径
shareType: 'Webpage',       // *分享的类型 （BMShareType对应描述）
platform: 'WechatSession'   // *分享平台 朋友圈/好友（BMSharePlatformType对应描述，传字符串：@"WechatSession", @"Facebook", @"Google", @"Twitter"）
},function(resData){     
// 成功回调
},function(resData){
// 失败回调
})

// 平台
platform:[
WechatSession,              // 分享至微信好友及微信登录，支持分享类型：[@"文字", @"图片", @"图文", @"音乐链接", @"视频", @"网页链接", @"微信小程序"]
WechatTimeLine,             // 分享至朋友圈，支持分享类型同上
Facebook,                   // 分享至Facebook及授权登录，支持分享类型：[@"图片", @"图文", @"本地视频", @"网页链接"]
Google,                     // Google授权登录 暂不支持分享
Twitter,                    // 分享至Twitter及授权登录，支持分享类型：[@"文字", @"图片", @"图文", @"音乐链接", @"视频", @"网页链接"]   
Microsoft                   // Microsoft授权登录 暂不支持分享
]

// 分享类型
shareType:[
Text,       // 文字
Image,      // 图片
TextImage,  // 图文
Webpage,    // 网页
Music,      // 音乐
Video,      // 视频
MiniProgram // 小程序
]
```

* 授权登录：`loginWithPlatformType('platformType',successCallback,failedCallback)`

```js
socialShare.loginWithPlatformType(
'平台类型',  // BMSharePlatformType对应描述，传字符串：@"WechatSession", @"Facebook", @"Google", @"Twitter", @"Microsoft"
function(resData){     
// 成功回调
},function(resData){
// 失败回调
})
```

* 取消授权[登出]：`logoutWithPlatformType('platformType',successCallback,failedCallback)`

```js
socialShare.logoutWithPlatformType(
'平台类型',  // BMSharePlatformType对应描述，传字符串：@"WechatSession", @"Facebook", @"Google", @"Twitter", @"Microsoft"
function(resData){     
// 成功回调
},function(resData){
// 失败回调
})
```

* 刷新登录Token：`refreshTokenWithPlatformType('platformType',successCallback,failedCallback)`

```js
socialShare.refreshTokenWithPlatformType(
'平台类型',  // BMSharePlatformType对应描述，传字符串：@"Google"，暂时只支持Google
function(resData){     
// 成功回调
},function(resData){
// 失败回调
})
```
## Change Log
**iOS 1.3.7** <br>
[最新版]
1. 微信sdk替换升级为完整版。

**iOS 1.3.6** <br>
1. podspec文件优化配置。

**iOS 1.3.4** <br>
1. 集成Microsoft第三方登录登出。


**iOS 1.3.3** <br>
1. 集成基于友盟的Twitter第三方登录及分享。


**iOS 1.3.2** <br>
1. 更新友盟UMCShare至6.9.6；
2. 更新Eros基础库ErosPluginBaseLibrary至1.3.6。


**iOS 1.3.1** <br>
1. 优化：集成Google刷新登录Token方法。


**iOS 1.3.0** <br>
1. 优化：单独集成Google登入登出管理。


**iOS 1.2.9** <br>
1. 优化：Google登录成功后返回数据调整。







