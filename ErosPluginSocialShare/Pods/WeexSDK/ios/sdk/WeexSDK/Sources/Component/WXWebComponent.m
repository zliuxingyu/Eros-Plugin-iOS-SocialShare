/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

#import "WXWebComponent.h"
#import "WXComponent_internal.h"
#import "WXUtility.h"
#import "WXHandlerFactory.h"
#import "WXURLRewriteProtocol.h"
#import "WXSDKEngine.h"

#import <JavaScriptCore/JavaScriptCore.h>

#import "BMMediatorManager.h"
#import "BMNotifactionCenter.h"

#define k_SCREEN_HEIGHT    [[UIScreen mainScreen]bounds].size.height
#define k_SCREEN_WIDTH     [[UIScreen mainScreen]bounds].size.width
#define kIsIphoneX         ([UIScreen mainScreen].bounds.size.height == 812.0 || [UIScreen mainScreen].bounds.size.height == 896.0)
#define k_STATUSBAR_HEIGHT (kIsIphoneX ? 44 : 20)
#define k_NAVBAR_HEIGHT    44
#define k_TOPBAR_HEIGHT    (k_NAVBAR_HEIGHT + k_STATUSBAR_HEIGHT)
#define k_TABBAR_HEIGHT    (kIsIphoneX ? 83 : 49)
#define k_TOUCHBAR_HEIGHT  (kIsIphoneX ? 34 : 0)

#define kScripActionName_notifyWeex  @"$notifyWeex"
#define kScripActionName_postMessage @"postMessage"
#define kScripActionName_closePage   @"closePage"
#define kScripActionName_fireEvent   @"fireEvent"

// 替换WKWebView-集成类
@interface WXWebView : WKWebView

@end

@implementation WXWebView

- (void)dealloc
{
    if (self) {
//        self.delegate = nil;
    }
}

@end

@interface WXWebComponent ()

//@property (nonatomic, strong) JSContext *jsContext;

@property (nonatomic, strong) WXWebView *webview;

@property (nonatomic, strong) NSString *url;

@property (nonatomic, strong) NSString *source;

// save source during this initialization
@property (nonatomic, strong) NSString *inInitsource;

@property (nonatomic, assign) BOOL startLoadEvent;

@property (nonatomic, assign) BOOL finishLoadEvent;

@property (nonatomic, assign) BOOL failLoadEvent;

@property (nonatomic, assign) BOOL notifyEvent;

@end

@implementation WXWebComponent

WX_EXPORT_METHOD(@selector(postMessage:))
WX_EXPORT_METHOD(@selector(goBack))
WX_EXPORT_METHOD(@selector(reload))
WX_EXPORT_METHOD(@selector(goForward))

- (instancetype)initWithRef:(NSString *)ref type:(NSString *)type styles:(NSDictionary *)styles attributes:(NSDictionary *)attributes events:(NSArray *)events weexInstance:(WXSDKInstance *)weexInstance
{
    if (self = [super initWithRef:ref type:type styles:styles attributes:attributes events:events weexInstance:weexInstance]) {
        self.url = attributes[@"src"];
        
        if(attributes[@"source"]){
            self.inInitsource = attributes[@"source"];
        }
        
    }
    return self;
}

- (UIView *)loadView
{
     // 适配全屏
    NSString *jScript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);";
    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    [wkUController addUserScript:wkUScript];

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.preferences = [[WKPreferences alloc] init];
    //config.preferences.minimumFontSize = 10;
    config.preferences.javaScriptEnabled = YES;
    //config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    config.allowsInlineMediaPlayback = YES;
    config.userContentController = wkUController;
    //config.processPool = [[WKProcessPool alloc] init];
   
    CGFloat height = k_SCREEN_HEIGHT - k_STATUSBAR_HEIGHT - k_NAVBAR_HEIGHT - k_TOUCHBAR_HEIGHT;
    CGRect frame = CGRectMake(0, 0, k_SCREEN_WIDTH, height);
  
    return [[WKWebView alloc] initWithFrame:frame configuration:config];
}

- (void)viewDidLoad
{
    _webview = (WXWebView *)self.view;
    
//    _webview.delegate = self;
//    _webview.allowsInlineMediaPlayback = YES;
//    _webview.scalesPageToFit = YES;
    
    _webview.UIDelegate = self;
    _webview.navigationDelegate = self;
    
    //重要：注册本地方法 ；对应【self.jsContext[@"bmnative"]】中的方法
    [_webview.configuration.userContentController addScriptMessageHandler:self name:kScripActionName_notifyWeex];
    [_webview.configuration.userContentController addScriptMessageHandler:self name:kScripActionName_postMessage];
    [_webview.configuration.userContentController addScriptMessageHandler:self name:kScripActionName_closePage];
    [_webview.configuration.userContentController addScriptMessageHandler:self name:kScripActionName_fireEvent];
    
    // JS调用格式
    // window.webkit.messageHandlers.方法名.postMessage({"params":"参数"});
    // window.webkit.messageHandlers.fireEvent.postMessage({"event":"back","data":"参数"});

    [_webview setBackgroundColor:[UIColor clearColor]];
    _webview.opaque = NO;
    
//    _jsContext = [_webview valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
//    __weak typeof(self) weakSelf = self;

    // This method will be abandoned slowly.
//    _jsContext[@"$notifyWeex"] = ^(JSValue *data) {
//        if (weakSelf.notifyEvent) {
//            [weakSelf fireEvent:@"notify" params:[data toDictionary]];
//        }
//    };

    //Weex catch postMessage event from web
//    _jsContext[@"postMessage"] = ^() {
//
//        NSArray *args = [JSContext currentArguments];
//
//        if (args && args.count < 2) {
//            return;
//        }
//
//        NSDictionary *data = [args[0] toDictionary];
//        NSString *origin = [args[1] toString];
//
//        if (data == nil) {
//            return;
//        }
//
//        NSDictionary *initDic = @{ @"type" : @"message",
//                                   @"data" : data,
//                                   @"origin" : origin
//        };
//
//        [weakSelf fireEvent:@"message" params:initDic];
//    };

    self.source = _inInitsource;
    if (_url) {
        [self loadURL:_url];
    }
}

- (void)dealloc
{
    if (_webview) {
        [_webview.configuration.userContentController removeAllUserScripts];
    }
}

- (void)updateAttributes:(NSDictionary *)attributes
{
    if (attributes[@"src"]) {
        self.url = attributes[@"src"];
    }

    if (attributes[@"source"]) {
        self.inInitsource = attributes[@"source"];
        self.source = self.inInitsource;
    }
}

- (void)addEvent:(NSString *)eventName
{
    if ([eventName isEqualToString:@"pagestart"]) {
        _startLoadEvent = YES;
    }
    else if ([eventName isEqualToString:@"pagefinish"]) {
        _finishLoadEvent = YES;
    }
    else if ([eventName isEqualToString:@"error"]) {
        _failLoadEvent = YES;
    }
}

- (void)setUrl:(NSString *)url
{
    NSString* newURL = [url copy];
    WX_REWRITE_URL(url, WXResourceTypeLink, self.weexInstance)
    if (!newURL) {
        return;
    }
    
    if (![newURL isEqualToString:_url]) {
        _url = newURL;
        if (_url) {
            [self loadURL:_url];
        }
    }
}

- (void)setSource:(NSString *)source
{
    NSString *newSource=[source copy];
    if(!newSource || _url){
        return;
    }
    if(![newSource isEqualToString:_source]){
        _source=newSource;
        if(_source){
            [_webview loadHTMLString:_source baseURL:nil];
        }
    }
}

- (void)loadURL:(NSString *)url
{
    if (self.webview) {
        NSURLRequest *request =[NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        [self.webview loadRequest:request];
    }
}

- (void)reload
{
    [self.webview reload];
}

- (void)goBack
{
    if ([self.webview canGoBack]) {
        [self.webview goBack];
    }
}

- (void)goForward
{
    if ([self.webview canGoForward]) {
        [self.webview goForward];
    }
}

// This method will be abandoned slowly, use postMessage
- (void)notifyWebview:(NSDictionary *) data
{
    NSString *json = [WXUtility JSONString:data];
    NSString *code = [NSString stringWithFormat:@"(function(){var evt=null;var data=%@;if(typeof CustomEvent==='function'){evt=new CustomEvent('notify',{detail:data})}else{evt=document.createEvent('CustomEvent');evt.initCustomEvent('notify',true,true,data)}document.dispatchEvent(evt)}())", json];
    
    // [_jsContext evaluateScript:code];
    
    [self webViewRunScript:code];
}

// Weex postMessage to web
- (void)postMessage:(NSDictionary *)data {
    WXSDKInstance *instance = [WXSDKEngine topInstance];

    NSString *bundleUrlOrigin = @"";

    if (instance.pageName) {
        NSString *bundleUrl = [instance.scriptURL absoluteString];
        NSURL *url = [NSURL URLWithString:bundleUrl];
        bundleUrlOrigin = [NSString stringWithFormat:@"%@://%@%@", url.scheme, url.host, url.port ? [NSString stringWithFormat:@":%@", url.port] : @""];
    }

    NSDictionary *initDic = @{
        @"type" : @"message",
        @"data" : data,
        @"origin" : bundleUrlOrigin
    };

    NSString *json = [WXUtility JSONString:initDic];

    NSString *code = [NSString stringWithFormat:@"(function (){window.dispatchEvent(new MessageEvent('message', %@));}())", json];
   
    // [_jsContext evaluateScript:code];
    
    [self webViewRunScript:code];
}

#pragma mark - 封装方法
- (void)webViewRunScript:(NSString *)script
{
    [self.webview evaluateJavaScript:script completionHandler:^(id _Nullable dict, NSError * _Nullable error) {
        if (error) {
            WXLogError(@"Run script:%@ Error:%@",script,error);
        }
    }];
}

- (void)bm_closePage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[BMMediatorManager shareInstance].currentViewController.navigationController popViewControllerAnimated:YES];
        [[BMMediatorManager shareInstance].currentViewController dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)bm_fireEvent:(NSString *)event info:(id)info {
    [[BMNotifactionCenter defaultCenter] emit:event info:info];
}

- (NSMutableDictionary<NSString *, id> *)baseInfo
{
    NSMutableDictionary<NSString *, id> *info = [NSMutableDictionary new];
    //[info setObject:self.webview.request.URL.absoluteString ?: @"" forKey:@"url"];
    [info setObject:self.webview.URL.absoluteString ?: @"" forKey:@"url"];
    //[info setObject:[self.webview stringByEvaluatingJavaScriptFromString:@"document.title"] ?: @"" forKey:@"title"];
    [info setObject:@(self.webview.canGoBack) forKey:@"canGoBack"];
    [info setObject:@(self.webview.canGoForward) forKey:@"canGoForward"];
    return info;
}

#pragma mark - WKScriptMessageHandler
// 实现js注入方法的协议方法
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSLog(@"- userContentController - name:%@ , body:%@", message.name, message.body);
    
    // 找到对应js端的方法名,获取messge.body
    if ([message.name isEqualToString:kScripActionName_closePage]) {
    
         [self bm_closePage];
    }
    else if ([message.name isEqualToString:kScripActionName_fireEvent]){
        
        NSDictionary *msgBody = [[NSDictionary alloc] initWithDictionary:message.body];
        if (!msgBody) {
            return;
        }
        NSString *event = [msgBody objectForKey:@"event"];
        id data = [msgBody objectForKey:@"data"];
        if (event && data) {
            [self bm_fireEvent:event info:data];
        }
        
    }
    else if ([message.name isEqualToString:kScripActionName_notifyWeex]){
        
        NSDictionary *msgBody = [[NSDictionary alloc] initWithDictionary:message.body];
        if (self.notifyEvent && msgBody) {
            [self fireEvent:@"notify" params:msgBody];
        }
        
    }
    else if ([message.name isEqualToString:kScripActionName_postMessage]){
        
         NSArray *args = message.body;

         if (!args) {
             return;
         }
        
         if (![args isKindOfClass:[NSArray class]]) {
            return;
         }
        
         if (args.count < 2) {
             return;
         }

         NSDictionary *data = [args[0] toDictionary];
         NSString *origin = [args[1] toString];

         if (data == nil) {
             return;
         }

         NSDictionary *initDic = @{ @"type" : @"message",
                                    @"data" : data,
                                    @"origin" : origin
         };

         [self fireEvent:@"message" params:initDic];
        
    }else{
        
        [[BMNotifactionCenter defaultCenter] emit:message.name info:message.body];
    }
}



#pragma mark - <WKUIDelegate, WKNavigationDelegate>
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    if (_startLoadEvent) {
         NSMutableDictionary<NSString *, id> *data = [NSMutableDictionary dictionary];
         [data setObject:self.webview.URL.absoluteString ?:@"" forKey:@"url"];
         [self fireEvent:@"pagestart" params:data];
     }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [webView evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable object, NSError * _Nullable error) {
        NSString *title = @"";
        if (object && [object isKindOfClass:[NSString class]]) {
            title = object;
        }
        
        if (self.finishLoadEvent) {
            NSMutableDictionary *info = [self baseInfo];
            [info setObject:title forKey:@"title"];
            NSDictionary *data = info;
            [self fireEvent:@"pagefinish" params:data domChanges:@{@"attrs": @{@"src":self.webview.URL.absoluteString}}];
        }
    }];
    
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if (_failLoadEvent) {
        NSMutableDictionary *data = [self baseInfo];
        [data setObject:[error localizedDescription] forKey:@"errorMsg"];
        [data setObject:[NSString stringWithFormat:@"%ld", (long)error.code] forKey:@"errorCode"];
        
        NSString * urlString = error.userInfo[NSURLErrorFailingURLStringErrorKey];
        if (urlString) {
            // webview.request may not be the real error URL, must get from error.userInfo
            [data setObject:urlString forKey:@"url"];
            if (![urlString hasPrefix:@"http"]) {
                return;
            }
        }
        [self fireEvent:@"error" params:data];
    }
    
}


//#pragma mark Webview Delegate
//
//- (void)webViewDidStartLoad:(UIWebView *)webView
//{
//}
//
//- (void)webViewDidFinishLoad:(UIWebView *)webView
//{
//    if (_finishLoadEvent) {
//        NSDictionary *data = [self baseInfo];
//        [self fireEvent:@"pagefinish" params:data domChanges:@{@"attrs": @{@"src":self.webview.request.URL.absoluteString}}];
//    }
//}
//
//- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
//{
//    if (_failLoadEvent) {
//        NSMutableDictionary *data = [self baseInfo];
//        [data setObject:[error localizedDescription] forKey:@"errorMsg"];
//        [data setObject:[NSString stringWithFormat:@"%ld", (long)error.code] forKey:@"errorCode"];
//
//        NSString * urlString = error.userInfo[NSURLErrorFailingURLStringErrorKey];
//        if (urlString) {
//            // webview.request may not be the real error URL, must get from error.userInfo
//            [data setObject:urlString forKey:@"url"];
//            if (![urlString hasPrefix:@"http"]) {
//                return;
//            }
//        }
//        [self fireEvent:@"error" params:data];
//    }
//}
//
//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
//{
//    if (_startLoadEvent) {
//        NSMutableDictionary<NSString *, id> *data = [NSMutableDictionary new];
//        [data setObject:request.URL.absoluteString ?:@"" forKey:@"url"];
//        [self fireEvent:@"pagestart" params:data];
//    }
//    return YES;
//}

@end
