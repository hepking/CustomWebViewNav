//
//  H5WebView.m
//  tCustomWebViewNav
//
//  Created by hpking　 on 2017/7/5.
//  Copyright © 2017年 hpking　. All rights reserved.
//

#import "H5WebView.h"

@implementation H5WebView

#pragma mark - Setters

- (void)setNavDelegate:(id<H5NavigationDelegate>)delegate
{
    if (!delegate || (self.navDelegate && ![self.navDelegate isEqual:delegate])) {
        [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    }
    
    if (delegate) {
        [self addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
    }
    
    _navDelegate = delegate;
    
    [super setNavigationDelegate:delegate];
}


#pragma mark - Key Value Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self] && [keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))])
    {
        if (self.navDelegate && [self.navDelegate respondsToSelector:@selector(webView:didUpdateProgress:)]) {
            [self.navDelegate webView:self didUpdateProgress:self.estimatedProgress];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
