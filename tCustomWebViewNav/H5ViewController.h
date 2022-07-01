//
//  ViewController.h
//  tCustomWebViewNav
//
//  Created by hpking　 on 2017/7/5.
//  Copyright © 2017年 hpking　. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
//#import "H5WebView.h"

/**
 Types of supported navigation tools.
 */
typedef NS_OPTIONS(NSUInteger, H5WebNavigationTools) {
    H5WebNavigationToolAll = -1,
    H5WebNavigationToolNone = 0,
    H5WebNavigationToolBackward = (1 << 0),
    H5WebNavigationToolForward = (1 << 1),
    H5WebNavigationToolstopReload = (1 << 2),
};

/**
 Types of supported actions (i.e. Share & Copy link, Add to Reading List, Open in Safari/Chrome/Opera/Dolphin).
 */
typedef NS_OPTIONS(NSUInteger, H5supportedWebActions) {
    H5WebActionAll = -1,
    H5WebActionNone = 0,
    H5supportedWebActionshareLink = (1 << 0),
    H5WebActionCopyLink = (1 << 1),
    H5WebActionReadLater = (1 << 2),
    H5WebActionOpenSafari = (1 << 3),
    H5WebActionOpenChrome = (1 << 4),
    H5WebActionOpenOperaMini = (1 << 5),
    H5WebActionOpenDolphin = (1 << 6),
};

/**
 Types of information to be shown on navigation bar. Default is DZNWebNavigationPromptAll.
 */
typedef NS_OPTIONS(NSUInteger, H5WebNavigationPrompt) {
    H5WebNavigationPromptNone = 0,
    H5WebNavigationPromptTitle = (1 << 0),
    H5WebNavigationPromptURL = (1 << 1),
    H5WebNavigationPromptAll = H5WebNavigationPromptTitle | H5WebNavigationPromptURL,
};

// 页面控件显示情况
typedef NS_OPTIONS(NSUInteger, H5ShowType) {
    H5ShowTypeNormal = -1, //默认
    H5ShowTypeFullScreen = 0,//全屏，无状态栏、导航栏、工具栏
    H5ShowTypeNoNavBar = (1 << 0), // 无导航栏
    H5ShowTypeNoToolBar = (1 << 1), // 无工具栏
    
    // 预先定义的几个特殊样式
    H5ShowTypeUrl = (1 << 2), // 导航栏 显示网址
    H5ShowTypeAd = (1 << 3), // 广告页 无工具条，导航左侧关闭按钮，右侧分享
    H5ShowTypeTopic = (1 << 4), // 显示帖子详情
    H5ShowTypeLive = (1 << 5), // 显示直播
};

// 自动隐藏
typedef NS_OPTIONS(NSUInteger, H5AutoHide) {
    
    H5AutoHideClose = -1,//默认
    H5AutoHideAll = 0,//自动隐藏 状态栏、导航栏、工具栏
    H5AutoHideNavToolBar = (1 << 0), // 自动隐藏 导航栏、工具栏
    H5AutoHideToolBar = (1 << 1), // 自动隐藏 工具栏
};

@protocol H5NavigationDelegate;

@interface H5WebView : WKWebView

@property (nonatomic, weak) id <H5NavigationDelegate> navDelegate;

@end

@protocol H5NavigationDelegate <WKNavigationDelegate>

- (void)webView:(H5WebView *)webView didUpdateProgress:(CGFloat)progress;

@end

//
@interface H5ViewController : UIViewController

@property (nonatomic, strong) H5WebView *webView;

@property (nonatomic, readwrite) NSURL *URL;

@property (nonatomic, readwrite) UIView *quanView; //圈子logo
@property (nonatomic, readwrite) UIToolbar *cutomToolbar; // 自定义工具条

@property (nonatomic, readwrite) H5ShowType showType; //显示预定义样式
@property (nonatomic, readwrite) H5AutoHide autoHide; // 自动隐藏类型

/** The supported navigation tool bar items. Default is All. */
@property (nonatomic, readwrite) H5WebNavigationTools supportedWebNavigationTools;
/** The supported actions like sharing and copy link, add to reading list, open in Safari, etc. Default is All. */
@property (nonatomic, readwrite) H5supportedWebActions supportedWebActions;
/** The information to be shown on navigation bar. Default is DZNWebNavigationPromptAll. */
@property (nonatomic, readwrite) H5WebNavigationPrompt webNavigationPrompt;

@property (nonatomic) BOOL showLoadingProgress;// 是否显示加载条

/** YES if long pressing the backward and forward buttons the navigation history is displayed. Default is YES. */
@property (nonatomic) BOOL allowHistory;

// 是否用手势隐藏导航
@property (nonatomic) BOOL hideBarsWithGestures;

// 是否显示页面的标题和url [Deprecated] YES if should set the title automatically based on the page title and URL. Default is YES. */
@property (nonatomic) BOOL showPageTitleAndURL __deprecated_msg("Use 'webNavigationPrompt' instead.");

///------------------------------------------------
/// @name 初始化
///------------------------------------------------

/**
 Initializes and returns a newly created webview controller with an initial HTTP URL to be requested as soon as the view appears.
 
 @param URL The HTTP URL to be requested.
 @returns The initialized webview controller.
 */
- (instancetype)initWithURL:(NSURL *)URL;

/**
 Initializes and returns a newly created webview controller for local HTML navigation.
 
 @param URL The file URL of the main html.
 @returns The initialized webview controller.
 */
- (instancetype)initWithFileURL:(NSURL *)URL;

/**
 Starts loading a new request. Useful to programatically update the web content.
 
 @param URL The HTTP or file URL to be requested.
 */
- (void)loadURL:(NSURL *)URL NS_REQUIRES_SUPER;

/**
 Starts loading a new request. Useful to programatically update the web content.
 
 @param URL The HTTP or file URL to be requested.
 @param baseURL A URL that is used to resolve relative URLs within the document.
 */
- (void)loadURL:(NSURL *)URL baseURL:(NSURL *)baseURL;

///------------------------------------------------
/// 工具条的按钮
///------------------------------------------------

// The back button displayed on the tool bar (requieres DZNWebNavigationToolBackward)
@property (nonatomic, strong) UIImage *backwardButtonImage;
// The forward button displayed on the tool bar (requieres DZNWebNavigationToolForward)
@property (nonatomic, strong) UIImage *forwardButtonImage;
// The stop button displayed on the tool bar (requieres H5WebNavigationToolstopReload)
@property (nonatomic, strong) UIImage *stopButtonImage;
// The reload button displayed on the tool bar (requieres H5WebNavigationToolstopReload)
@property (nonatomic, strong) UIImage *reloadButtonImage;
// The action button displayed on the navigation bar (requieres at least 1 DZNsupportedWebActions value)
@property (nonatomic, strong) UIImage *actionButtonImage;


///------------------------------------------------
/// @name Delegate Methods Requiring Super
///------------------------------------------------

// H5NavigationDelegate
- (void)webView:(H5WebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation NS_REQUIRES_SUPER;
- (void)webView:(H5WebView *)webView didCommitNavigation:(WKNavigation *)navigation NS_REQUIRES_SUPER;
- (void)webView:(H5WebView *)webView didUpdateProgress:(CGFloat)progress NS_REQUIRES_SUPER;
- (void)webView:(H5WebView *)webView didFinishNavigation:(WKNavigation *)navigation NS_REQUIRES_SUPER;
- (void)webView:(H5WebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error NS_REQUIRES_SUPER;

// WKUIDelegate
- (H5WebView *)webView:(H5WebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures NS_REQUIRES_SUPER;


@end

