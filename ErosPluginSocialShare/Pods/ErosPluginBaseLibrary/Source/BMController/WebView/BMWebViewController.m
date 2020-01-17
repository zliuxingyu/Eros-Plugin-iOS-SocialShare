//
//  BMWebViewController.m
//  BM-JYT
//
//  Created by XHY on 2017/2/28.
//  Copyright © 2017年 XHY. All rights reserved.
//  UIWebViewDelegate替换为WKWebView

#import "BMWebViewController.h"
#import "JYTTitleLabel.h"
#import <Masonry/Masonry.h>
#import "NSTimer+Addition.h"
#import "BMMediatorManager.h"
#import <UINavigationController+FDFullscreenPopGesture.h>
#import <JavaScriptCore/JavaScriptCore.h>
//#import "UIWebView+BMExtend.h"
#import "BMUserInfoModel.h"
//#import "BMNative.h"
#import "UIColor+Util.h"

#import <WebKit/WebKit.h>
#import "BMNotifactionCenter.h"

@interface BMWebViewController () <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, JSExport> // UIWebViewDelegate
{
    // BOOL _showProgress;
}

// @property (nonatomic, strong) JSContext *jsContext;
// @property (nonatomic, strong) UIWebView *webView;
/** 伪进度条 */
//@property (nonatomic, strong) CAShapeLayer *progressLayer;
/** 进度条定时器 */
//@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) WKWebView *webView;

/** 进度条 */
@property (nonatomic, strong) UIProgressView *progressView;

/** 要打开的url */
@property (nonatomic,   copy) NSString *urlStr;

@end

@implementation BMWebViewController

- (void)dealloc
{
    NSLog(@"dealloc >>>>>>>>>>>>> BMWebViewController");
    
//    if (_jsContext) {
//        _jsContext[@"bmnative"] = nil;
//        _jsContext = nil;
//    }
    
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress" context:nil];
}

- (instancetype)initWithRouterModel:(BMWebViewRouterModel *)model
{
    if (self = [super init])
    {
        self.routerInfo = model;
        
        // [self subInit];
        
        [self newSubInit];
    }
    return self;
}

//- (void)subInit
//{
//    CGFloat height = K_SCREEN_HEIGHT - K_STATUSBAR_HEIGHT - K_NAVBAR_HEIGHT;
//    if (!self.routerInfo.navShow) {
//        height = K_SCREEN_HEIGHT;
//    }
//
//    // 减去 Indicator 高度
//    height -= K_TOUCHBAR_HEIGHT;
//
//    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, K_SCREEN_WIDTH, height)];
//    self.webView.backgroundColor = self.routerInfo.backgroundColor? [UIColor colorWithHexString:self.routerInfo.backgroundColor]: K_BACKGROUND_COLOR;
//    self.webView.scrollView.bounces = NO;
//    self.webView.delegate = self;
//
//    self.view.backgroundColor = self.routerInfo.backgroundColor? [UIColor colorWithHexString:self.routerInfo.backgroundColor]: K_BACKGROUND_COLOR;
//
//    self.urlStr = self.routerInfo.url;
//    [self reloadURL];
//
//    /* 获取js的运行环境 */
//    self.jsContext = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
//    [self injectionJsMethod];
//}

- (void)newSubInit
{
    [self.view addSubview:self.webView];
    [self.view addSubview:self.progressView];
    
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    
    //重要：注册本地方法 ；对应【self.jsContext[@"bmnative"]】中的方法
    [self.webView.configuration.userContentController addScriptMessageHandler:self name:@"closePage"];
    [self.webView.configuration.userContentController addScriptMessageHandler:self name:@"fireEvent"];
    
    // js端代码实现实例(此处为js端实现代码示范):
    //window.webkit.messageHandlers.fireEvent.postMessage({body: {"event":"name", "data":id});
    
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    
    self.view.backgroundColor = self.routerInfo.backgroundColor? [UIColor colorWithHexString:self.routerInfo.backgroundColor]: K_BACKGROUND_COLOR;

    self.urlStr = self.routerInfo.url;
    
    [self reloadURL];
    
    // 注入 js 方法
    //[self injectionJsMethod];
}

//- (CAShapeLayer *)progressLayer
//{
//    if (!_progressLayer) {
//
//        UIBezierPath *path = [[UIBezierPath alloc] init];
//        [path moveToPoint:CGPointMake(0, self.navigationController.navigationBar.height - 2)];
//        [path addLineToPoint:CGPointMake(K_SCREEN_WIDTH, self.navigationController.navigationBar.height - 2)];
//        _progressLayer = [CAShapeLayer layer];
//        _progressLayer.path = path.CGPath;
//        _progressLayer.strokeColor = [UIColor lightGrayColor].CGColor;
//        _progressLayer.fillColor = K_CLEAR_COLOR.CGColor;
//        _progressLayer.lineWidth = 2;
//
//        _progressLayer.strokeStart = 0.0f;
//        _progressLayer.strokeEnd = 0.0f;
//
//        [self.navigationController.navigationBar.layer addSublayer:_progressLayer];
//    }
//    return _progressLayer;
//}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[BMMediatorManager shareInstance] setCurrentViewController:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
//    if (_timer) {
//        [_timer invalidate];
//        _timer = nil;
//    }
    
//    if (_progressLayer) {
//        [_progressLayer removeFromSuperlayer];
//        _progressLayer = nil;
//    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    /* 解析 router 数据 */
    self.navigationItem.title = self.routerInfo.title;
    
    self.view.backgroundColor = K_BACKGROUND_COLOR;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    /* 判断是否需要隐藏导航栏 并设置weex页面高度
     注：使用FDFullscreenPopGesture方法设置，自定义pop返回动画
     */
    if (!self.routerInfo.navShow) {
        self.fd_prefersNavigationBarHidden = YES;
    } else {
        self.fd_prefersNavigationBarHidden = NO;
    }
    
    /* 返回按钮 */
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"NavBar_BackItemIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(backItemClicked)];
    self.navigationItem.leftBarButtonItem = backItem;

    // [self.view addSubview:self.webView];
    
    // _showProgress = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)backItemClicked
{
    if ([self.webView canGoBack]) {
        
        // _showProgress = NO;
        [self.webView goBack];
        
        if ([self.webView canGoBack] && [self.navigationItem.leftBarButtonItems count] < 2) {
            //  barbuttonitems
            UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"NavBar_BackItemIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(backItemClicked)];
            UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeItemClicked)];
            self.navigationItem.leftBarButtonItems = @[backItem, closeItem];
        }
        
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)closeItemClicked
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}

- (void)reloadURL
{
    if ([self.urlStr isHasChinese]) {
        self.urlStr = [self.urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    NSString *loadURL = [NSString stringWithFormat:@"%@",self.urlStr];
    NSURL *url = [NSURL URLWithString:loadURL];
    url = [url.scheme isEqualToString:BM_LOCAL] ? TK_RewriteBMLocalURL(loadURL) : url;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

#pragma mark - WKScriptMessageHandler
// 实现js注入方法的协议方法
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSLog(@"%@", message.body);
    // 找到对应js端的方法名,获取messge.body
    if ([message.name isEqualToString:@"closePage"]) {
    
         [self closePage];
    }
    else if ([message.name isEqualToString:@"fireEvent"]){
        NSDictionary *msgBody = [[NSDictionary alloc] initWithDictionary:message.body];
        if (!msgBody) {
            return;
        }
        NSString *event = [msgBody objectForKey:@"event"];
        id data = [msgBody objectForKey:@"data"];
        if (event && data) {
            [self fireEvent:event :data];
        }
    }
}

// 具体执行方法
- (void)closePage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[BMMediatorManager shareInstance].currentViewController.navigationController popViewControllerAnimated:YES];
        [[BMMediatorManager shareInstance].currentViewController dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)fireEvent:(NSString *)event :(id)info {
    [[BMNotifactionCenter defaultCenter] emit:event info:info];
}

#pragma mark - <WKUIDelegate, WKNavigationDelegate>
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    //开始加载的时候，让进度条显示
    self.progressView.hidden = NO;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [webView evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable object, NSError * _Nullable error) {
        if (object && [object isKindOfClass:[NSString class]]) {
            self.navigationItem.title = object;
        }
    }];
}


#pragma mark - ***************KVO监听********************
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        
        self.progressView.progress = self.webView.estimatedProgress;
        // 加载完成
        if (self.webView.estimatedProgress >= 1.0f ) {
            
            [UIView animateWithDuration:0.25f animations:^{
                self.progressView.alpha = 0.0f;
                self.progressView.progress = 0.0f;
            }];
            
        }else{
            self.progressView.alpha = 1.0f;
        }
    }
}

#pragma mark - **************懒加载部分******************
- (WKWebView *)webView {
    if (!_webView) {
         WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
         config.preferences = [[WKPreferences alloc] init];
         config.preferences.minimumFontSize = 10;
         config.preferences.javaScriptEnabled = YES;
         config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
         config.userContentController = [[WKUserContentController alloc] init];
         //config.processPool = [[WKProcessPool alloc] init];
         
         CGFloat height = K_SCREEN_HEIGHT - K_STATUSBAR_HEIGHT - K_NAVBAR_HEIGHT - K_TOUCHBAR_HEIGHT;
         CGRect frame = CGRectMake(0, 0, K_SCREEN_WIDTH, height);
        
         _webView = [[WKWebView alloc] initWithFrame:frame configuration:config];
         _webView.backgroundColor = self.routerInfo.backgroundColor? [UIColor colorWithHexString:self.routerInfo.backgroundColor]: K_BACKGROUND_COLOR;
         _webView.scrollView.showsVerticalScrollIndicator = NO;
         _webView.scrollView.showsHorizontalScrollIndicator = NO;
            
    }
    return _webView;
}

- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] init];
        _progressView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 2);
    }
    return _progressView;
}


//#pragma mark - UIWebViewDelegate
//
//- (void)webViewDidStartLoad:(UIWebView *)webView
//{
//    if (!self.timer) {
//        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(progressAnimation:) userInfo:nil repeats:YES];
//    }
//
//    if (_showProgress) {
//
//        [self.timer resumeTimer];
//
//    }
//
//    _showProgress = YES;
//}
//
//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
//{
//    /* 如果是goBack的操作 从新加载url避免有些页面加载不完全的问题 */
//    if (navigationType == UIWebViewNavigationTypeBackForward) {
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            NSURL *url = [NSURL URLWithString:request.URL.absoluteString];
//            NSURLRequest *request = [NSURLRequest requestWithURL:url];
//            [self.webView loadRequest:request];
//        });
//        return YES;
//    }
//
//    WXLogInfo(@"%@",request.URL.absoluteString);
//
//    return YES;
//}
//
//- (void)webViewDidFinishLoad:(UIWebView *)webView
//{
//    /** 检查一下字体大小 */
//    [self.webView checkCurrentFontSize];
//
//    NSString * docTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
//    if (docTitle && docTitle.length) {
//        self.navigationItem.title = docTitle;
//    }
//
//    if (_timer != nil) {
//        [_timer pauseTimer];
//    }
//
//    if (_progressLayer) {
//        _progressLayer.strokeEnd = 1.0f;
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [_progressLayer removeFromSuperlayer];
//            _progressLayer = nil;
//        });
//    }
//}
//
//- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
//{
//    WXLogInfo(@"\n******************** - WebView didFailLoad - ********************\n %@",error);
//
//    if (_timer != nil) {
//        [_timer pauseTimer];
//    }
//
//    if (_progressLayer) {
//        [_progressLayer removeFromSuperlayer];
//        _progressLayer = nil;
//    }
//
//    WXLogInfo(@"\n******************** - WebView didFailLoad - ********************\n %@",webView.request.URL.absoluteString);
//}
//
//- (void)progressAnimation:(NSTimer *)timer
//{
//    self.progressLayer.strokeEnd += 0.005f;
//
//    NSLog(@"%f",self.progressLayer.strokeEnd);
//
//    if (self.progressLayer.strokeEnd >= 0.9f) {
//        [_timer pauseTimer];
//    }
//}

/**
 注入 js 方法
 */
//- (void)injectionJsMethod
//{
//    /* 注入一个关闭当前页面的方法 */
//    BMNative *bmnative = [[BMNative alloc] init];
//    self.jsContext[@"bmnative"] = bmnative;
//}

@end
