# Eros-Plugin-iOS-SocialShare

> 功能简介：
1. 基于友盟ShareSDK实现：微信分享（分享到朋友圈，微信好友），微信授权登录登出，以及Facebook分享和授权登录登出；
2. 基于Google官方的授权登录登出。 

> 在使用登录分享之前，还需要一些配置 <br>
1. 首先请到友盟平台注册App获取AppKey; <br>
2. iOS平台请参考友盟的[教程](https://developer.umeng.com/docs/66632/detail/66825)配置SSO白名单、及 URL Scheme等；<br>
3. Google登录集成请参考[教程](https://developers.google.com/identity/sign-in/ios/start-integrating)、[流程](https://www.jianshu.com/p/3251468ba0a1)；<br>
4. 分享的页面面板可根据产品定制样式自己写。


## 集成方式

1. 打开iOS目录`工程目录/platforms/ios/WeexEros`，编辑Podfile文件，添加`ErosPluginSocialShare`组件的引用，添加代码如下，**注意**版本号改为最新的版本【查看下面Change Log】

```ruby
def common
...忽略其他库的引用
# 在这里添加引用 ErosPluginSocialShare
pod 'ErosPluginSocialShare', :git => 'https://github.com/zliuxingyu/Eros-Plugin-iOS-SocialShare.git', :tag => '版本'
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

* 初始化Google SDK `initGoogle('clientID')`

> 在使用Google登录功能前，需要调用此方法来初始化Google平台；

```js
socialShare.initGoogle('Google平台申请的clientID')
```


* 分享：`shareWithInfo(info,successCallback,failedCallback)`

```js
socialShare.shareWithInfo({
title:'',                   // 分享的标题
content:'',                 // 分享的文字内容
url: '',                    // 分享对应的URL地址，如h5、音乐链接、视频链接、小程序的链接
thumImage: '',              // 分享类型的缩略图url
image: '',                  // 分享的图片url
path: '',                   // 分享小程序用到的页面路径
shareType: 'Webpage',       // 分享的类型 （BMShareType对应描述）
platform: 'WechatSession'   // 分享平台 朋友圈/好友（BMSharePlatformType对应描述，传字符串：@"WechatSession", @"Facebook", @"Google"）
},function(resData){     
// 成功回调
},function(resData){
// 失败回调
})

// 平台
platform:[
WechatSession,              // 分享至微信好友及微信登录
WechatTimeLine,             // 分享至朋友圈
Facebook,                   // 分享至Facebook及授权登录
Google                      // Google授权登录
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
'平台类型',  // BMSharePlatformType对应描述，传字符串：@"WechatSession", @"Facebook", @"Google"
function(resData){     
// 成功回调
},function(resData){
// 失败回调
})
```

* 取消授权[登出]：`logoutWithPlatformType('platformType',successCallback,failedCallback)`

```js
socialShare.logoutWithPlatformType(
'平台类型',  // BMSharePlatformType对应描述，传字符串：@"WechatSession", @"Facebook", @"Google"
function(resData){     
// 成功回调
},function(resData){
// 失败回调
})
```

## Change Log
**iOS 1.0.7** <br>
[最新版]
1. 依赖库调整.

**iOS 1.0.6** <br>
1. 调整头文件引用.

**iOS 1.0.5** <br>
1. 调整项目文件路径.
