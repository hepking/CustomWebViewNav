//
//  H5WebView.h
//  tCustomWebViewNav
//
//  Created by hpking　 on 2017/7/5.
//  Copyright © 2017年 hpking　. All rights reserved.
//

#import <WebKit/WebKit.h>

@protocol H5NavigationDelegate;

@interface H5WebView : WKWebView

@property (nonatomic, weak) id <H5NavigationDelegate> navDelegate;

@end

@protocol H5NavigationDelegate <WKNavigationDelegate>

- (void)webView:(H5WebView *)webView didUpdateProgress:(CGFloat)progress;

@end
