//
//  WXWebComponent+BMExtend.m
//  Pods
//
//  Created by XHY on 2017/5/5.
//
//

#import "WXWebComponent+BMExtend.h"
#import <WeexSDK/WXUtility.h>
#import "BMNative.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>
#import "BMChartComponent.h"
#import <WeexSDK/WXSDKInstance_private.h>
#import <WeexSDK/WXComponent_internal.h>
#import "YYModel.h"

@class WXWebView;

@implementation WXWebComponent (BMExtend)

- (void)bm_webViewDidFinishLoad:(UIWebView *)webView
{
    [self bm_webViewDidFinishLoad:webView];
    
    CGFloat contentHeight = webView.scrollView.contentSize.height;
    
    CGFloat pixelScale = [WXUtility defaultPixelScaleFactor];
    
    contentHeight = contentHeight/(pixelScale*2);
    
    [self fireEvent:@"bmPageFinish" params:@{@"contentHeight": @(contentHeight)}];
    
    [self runSetOptionsScript];
}
- (void)bm_viewDidLoad
{
    [self bm_viewDidLoad];
    UIWebView * webview = (UIWebView *)self.view;
    webview.opaque = NO;
    webview.backgroundColor = [UIColor clearColor];
    
    JSContext *jsContext = [self valueForKey:@"jsContext"];
    BMNative *bmnative = [[BMNative alloc] init];
    jsContext[@"bmnative"] = bmnative;
    
    if (self.attributes[@"scrollEnabled"] && NO == [self.attributes[@"scrollEnabled"] boolValue]) {
        webview.scrollView.scrollEnabled = NO;
    }
    jsContext[@"mapData"] = self.attributes[@"mapData"];
}

/** 修复如果url为 NSNull、或者nil的时候 崩溃的问题 weex没有做判断 */
- (void)bm_setUrl:(NSString *)url;
{
    if (![url isKindOfClass:[NSString class]]) {
        return;
    }
    
    [self bm_setUrl:url];
}

/**
 这里主要判断是否是本地html，如果是本地html，则加载本地html
 */
-(void)bm_loadURL:(NSString *)url
{
    WXPerformBlockOnMainThread(^{
        UIWebView * webview = (UIWebView *)self.view;
        
        if(webview){
            NSURL *urlPath = [NSURL URLWithString:url];
            if([urlPath.scheme isEqualToString:BM_LOCAL]){
                if (BM_InterceptorOn()) {
                    NSURLRequest *request = [NSURLRequest requestWithURL:TK_RewriteBMLocalURL(url)];
                    [webview loadRequest:request];
                }else {
                    NSString *debugUrl = TK_RewriteBMLocalURL(url).absoluteString;
                    [self bm_loadURL:debugUrl];
                }
            } else {
                [self bm_loadURL:url];
            }
        }
    });
}

- (void)runSetOptionsScript
{
    NSString *script = [NSString stringWithFormat:@"setOptions(%@)",self.attributes[@"mapData"]];
    UIWebView * webView = (UIWebView *)self.view;
    [webView stringByEvaluatingJavaScriptFromString:script];
}

- (void)_updateAttributesOnComponentThread:(NSDictionary *)attributes
{
    [super _updateAttributesOnComponentThread:attributes];
    
    [self fillAttributes:attributes];
}

- (void)fillAttributes:(NSDictionary *)attributes
{
    if (attributes[@"mapData"]) {
        WXPerformBlockOnMainThread(^{
            [self runSetOptionsScript];
        });
    }
}

@end
