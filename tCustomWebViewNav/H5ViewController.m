//
//  ViewController.m
//  tCustomWebViewNav
//
//  Created by hpking　 on 2017/7/5.
//  Copyright © 2017年 hpking　. All rights reserved.
//

#import "H5ViewController.h"

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


#define DZN_IS_IPAD ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define DZN_IS_LANDSCAPE ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)

#ifndef H5LocalizedString
#define H5LocalizedString(key, comment) \
NSLocalizedStringFromTableInBundle(key, @"H5ViewController", [NSBundle bundleWithPath:[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"H5ViewController.bundle"]], comment)
#endif

static char H5WebViewControllerKVOContext = 0;
static NSString *const k404NotFoundURLKey = @"ax_404_not_found";
static NSString *const kNetworkErrorURLKey = @"ax_network_error";

@interface H5ViewController ()<H5NavigationDelegate,  WKUIDelegate, UIScrollViewDelegate> //,WKNavigationDelegate

@property(strong, nonatomic) UILabel *backgroundLabel;
@property(strong, nonatomic) UIView *cusNavLeftView;

@property (nonatomic, strong) UIBarButtonItem *backwardBarItem;
@property (nonatomic, strong) UIBarButtonItem *forwardBarItem;
@property (nonatomic, strong) UIBarButtonItem *stateBarItem;
@property (nonatomic, strong) UIBarButtonItem *actionBarItem;
@property (nonatomic, strong) UIBarButtonItem *commentBarItem;
@property (nonatomic, strong) UIProgressView *progressView;

@property (nonatomic, strong) UILongPressGestureRecognizer *backwardLongPress;
@property (nonatomic, strong) UILongPressGestureRecognizer *forwardLongPress;

@property (nonatomic, weak) UIToolbar *toolbar;
@property (nonatomic, weak) UINavigationBar *navigationBar;
@property (nonatomic, weak) UIView *navigationBarSuperView;

@property (nonatomic) BOOL completedInitialLoad;

@property (nonatomic) BOOL isExpand;

@property (nonatomic) int lastPosition;

@end

@implementation H5ViewController

@synthesize URL = _URL;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL
{
    NSParameterAssert(URL);
    
    self = [self init];
    if (self) {
        _URL = URL;
    }
    return self;
}

- (instancetype)initWithFileURL:(NSURL *)URL
{
    return [self initWithURL:URL];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

- (void)commonInit
{
    self.supportedWebNavigationTools = H5WebNavigationToolAll;
    self.supportedWebActions = H5WebActionAll;
    self.webNavigationPrompt = H5WebNavigationPromptAll;
    self.showType = H5ShowTypeNormal;
    self.autoHide = H5AutoHideClose;
    self.showLoadingProgress = YES;
    self.hideBarsWithGestures = YES;
    self.allowHistory = YES;
    
    self.webView = [[H5WebView alloc] initWithFrame:self.view.bounds configuration:[WKWebViewConfiguration new]];
    self.webView.backgroundColor = [UIColor whiteColor];
    self.webView.allowsBackForwardNavigationGestures = YES; //是否允许左右划手势导航
    self.webView.UIDelegate = self;
//    self.webView.NavigationDelegate = self;
    self.webView.navDelegate = self;
    self.webView.scrollView.delegate = self;
    
    [self.webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:&H5WebViewControllerKVOContext];
    self.completedInitialLoad = NO;
    
    UIView *contentView = _webView.scrollView.subviews.firstObject;
    [contentView addSubview:self.backgroundLabel];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_backgroundLabel(<=width)]" options:0 metrics:@{@"width":@([UIScreen mainScreen].bounds.size.width)} views:NSDictionaryOfVariableBindings(_backgroundLabel)]];
    [contentView addConstraint:[NSLayoutConstraint constraintWithItem:_backgroundLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [contentView addConstraint:[NSLayoutConstraint constraintWithItem:_backgroundLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:-20]];
    
    
    // 隐藏左侧返回按钮
    self.navigationItem.hidesBackButton = YES;
    
    // 自定义视图
    self.cusNavLeftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 66, 22)];
//    UIButton *button = [[UIButton alloc] initWithFrame:contentView.bounds];
//    [button setBackgroundImage:[UIImage imageNamed:@"image.png"] forState:UIControlStateNormal];
//    [button addTarget:self action:@selector(onBarBtn:) forControlEvents:UIControlEventTouchUpInside];
//    [cusView addSubview:button];

    // 绘制一个圆角按钮
    UIImageView* imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"image"]];
    imageView.frame = CGRectMake(0, 0, 30, 30);
    imageView.layer.masksToBounds = YES;
    imageView.layer.cornerRadius = 15.0;
    imageView.backgroundColor = [UIColor grayColor];
    [self.cusNavLeftView addSubview:imageView];
    
    // 绘制文本
    UILabel* lblNick = [[UILabel alloc] initWithFrame:CGRectMake(32, 0, 60, 15)];
    lblNick.textColor = [UIColor lightGrayColor];
    lblNick.font = [UIFont systemFontOfSize:14];
    lblNick.numberOfLines = 1;
    lblNick.textAlignment = NSTextAlignmentLeft;
    lblNick.backgroundColor = [UIColor clearColor];
    lblNick.translatesAutoresizingMaskIntoConstraints = NO;
    lblNick.text = @"hpking";
    [self.cusNavLeftView addSubview:lblNick];
    
    UILabel* lblNum = [[UILabel alloc] initWithFrame:CGRectMake(32, 16, 60, 13)];
    lblNum.textColor = [UIColor lightGrayColor];
    lblNum.font = [UIFont systemFontOfSize:10];
    lblNum.numberOfLines = 1;
    lblNum.textAlignment = NSTextAlignmentLeft;
    lblNum.backgroundColor = [UIColor clearColor];
    lblNum.translatesAutoresizingMaskIntoConstraints = NO;
    lblNum.text = @"30关注";
    [self.cusNavLeftView addSubview:lblNum];
    self.cusNavLeftView.hidden = YES;
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.cusNavLeftView];
    self.navigationItem.leftBarButtonItem = barButtonItem;
}

-(void)onBarBtn:(id)tag{
    
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    self.view = self.webView;
    self.automaticallyAdjustsScrollViewInsets = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.completedInitialLoad) {
        
        [UIView performWithoutAnimation:^{
            [self configureToolBars];
        }];
        self.completedInitialLoad = YES;
    }
    
    if (!self.webView.URL) {
        [self loadURL:self.URL];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    static dispatch_once_t didAppearConfig;
    dispatch_once(&didAppearConfig, ^{
        [self configureBarItemsGestures];
    });
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self clearProgressViewAnimated:animated];
    
    // 删除缓存
    NSSet* types = [NSSet setWithArray:@[WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:types modifiedSince:[NSDate dateWithTimeIntervalSince1970:0] completionHandler:^{}];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.webView stopLoading];
}


#pragma mark - Getter methods

- (UIProgressView *)progressView
{
    if (!_progressView)
    {
        CGFloat lineHeight = 2.0f;
        CGRect frame = CGRectMake(0, CGRectGetHeight(self.navigationBar.bounds) - lineHeight, CGRectGetWidth(self.navigationBar.bounds), lineHeight);
        
        UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:frame];
        progressView.trackTintColor = [UIColor clearColor];
        progressView.alpha = 0.0f;
        
        [self.navigationBar addSubview:progressView];
        
        _progressView = progressView;
    }
    return _progressView;
}

// 背景文本控件
- (UILabel *)backgroundLabel {
    if (_backgroundLabel) return _backgroundLabel;
    
    _backgroundLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _backgroundLabel.textColor = [UIColor colorWithRed:0.322 green:0.322 blue:0.322 alpha:1.00];
    _backgroundLabel.font = [UIFont systemFontOfSize:12];
    _backgroundLabel.numberOfLines = 0;
    _backgroundLabel.textAlignment = NSTextAlignmentCenter;
    _backgroundLabel.backgroundColor = [UIColor clearColor];
    _backgroundLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_backgroundLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    return _backgroundLabel;
}

- (UIBarButtonItem *)backwardBarItem
{
    if (!_backwardBarItem)
    {
        _backwardBarItem = [[UIBarButtonItem alloc] initWithImage:[self backwardButtonImage] landscapeImagePhone:nil style:0 target:self action:@selector(goBackward:)];
        _backwardBarItem.accessibilityLabel = NSLocalizedStringFromTable(@"Backward", @"H5WebViewController", @"Accessibility label button title");
        _backwardBarItem.enabled = NO;
    }
    return _backwardBarItem;
}

- (UIBarButtonItem *)forwardBarItem
{
    if (!_forwardBarItem)
    {
        _forwardBarItem = [[UIBarButtonItem alloc] initWithImage:[self forwardButtonImage] landscapeImagePhone:nil style:0 target:self action:@selector(goForward:)];
        _forwardBarItem.landscapeImagePhone = nil;
        _forwardBarItem.accessibilityLabel = NSLocalizedStringFromTable(@"Forward", @"H5WebViewController", @"Accessibility label button title");
        _forwardBarItem.enabled = NO;
    }
    return _forwardBarItem;
}

- (UIBarButtonItem *)stateBarItem
{
    if (!_stateBarItem)
    {
        _stateBarItem = [[UIBarButtonItem alloc] initWithImage:nil landscapeImagePhone:nil style:0 target:nil action:nil];
        [self updateStateBarItem];
    }
    return _stateBarItem;
}

- (UIBarButtonItem *)actionBarItem
{
    if (!_actionBarItem)
    {
        _actionBarItem = [[UIBarButtonItem alloc] initWithImage:[self actionButtonImage] landscapeImagePhone:nil style:0 target:self action:@selector(presentActivityController:)];
        _actionBarItem.accessibilityLabel = NSLocalizedStringFromTable(@"Share", @"H5WebViewController", @"Accessibility label button title");
        _actionBarItem.enabled = NO;
    }
    return _actionBarItem;
}

- (UIBarButtonItem *)commentBarItem
{
    if (!_commentBarItem)
    {
        UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 120, 33)];
        view.layer.masksToBounds = YES;
        view.layer.cornerRadius = 18.0;
        view.backgroundColor = [UIColor lightGrayColor];//[UIColor colorWithRed:192 green:192 blue:192 alpha:1];
        
        // 绘制文本
        UILabel* lblpl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 80, 33)];
        lblpl.textColor = [UIColor darkGrayColor];
        lblpl.font = [UIFont systemFontOfSize:14];
        lblpl.numberOfLines = 1;
        lblpl.textAlignment = NSTextAlignmentCenter;
//        lblpl.backgroundColor = [UIColor clearColor];
        lblpl.translatesAutoresizingMaskIntoConstraints = NO;
        lblpl.text = @"我来说两句";
        [view addSubview:lblpl];
        
        _commentBarItem = [[UIBarButtonItem alloc] initWithCustomView:view];
        
//        _commentBarItem = [[UIBarButtonItem alloc] initWithImage:[self actionButtonImage] landscapeImagePhone:nil style:0 target:self action:@selector(presentActivityController:)];
//        _commentBarItem.accessibilityLabel = NSLocalizedStringFromTable(@"Share", @"H5WebViewController", @"Accessibility label button title");
//        _commentBarItem.enabled = NO;
    }
    return _commentBarItem;
}

// 获取工具条所有工具按钮
- (NSArray *)navigationToolItems
{
    NSMutableArray *items = [NSMutableArray new];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    
    if ((self.supportedWebNavigationTools & H5WebNavigationToolBackward) > 0 || self.supportsAllNavigationTools) {
        [items addObject:self.backwardBarItem];
    }
    
    if ((self.supportedWebNavigationTools & H5WebNavigationToolForward) > 0 || self.supportsAllNavigationTools) {
        if (!DZN_IS_IPAD) [items addObject:flexibleSpace];
        [items addObject:self.forwardBarItem];
    }
    
    [items addObject:self.commentBarItem];
    
    if ((self.supportedWebNavigationTools & H5WebNavigationToolstopReload) > 0 || self.supportsAllNavigationTools) {
        if (!DZN_IS_IPAD) [items addObject:flexibleSpace];
        [items addObject:self.stateBarItem];
    }
    
    if (self.supportedWebActions > 0) {
        if (!DZN_IS_IPAD) [items addObject:flexibleSpace];
        [items addObject:self.actionBarItem];
    }
    
    return items;
}

- (BOOL)supportsAllNavigationTools
{
    return (_supportedWebNavigationTools == H5WebNavigationToolAll) ? YES : NO;
}

- (UIImage *)backwardButtonImage
{
    if (!_backwardButtonImage) {
        _backwardButtonImage = [UIImage imageNamed:@"toolbar_backward" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    return _backwardButtonImage;
}

- (UIImage *)forwardButtonImage
{
    if (!_forwardButtonImage) {
        _forwardButtonImage = [UIImage imageNamed:@"toolbar_forward" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    return _forwardButtonImage;
}

- (UIImage *)reloadButtonImage
{
    if (!_reloadButtonImage) {
        _reloadButtonImage = [UIImage imageNamed:@"toolbar_reload" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    return _reloadButtonImage;
}

- (UIImage *)stopButtonImage
{
    if (!_stopButtonImage) {
        _stopButtonImage = [UIImage imageNamed:@"toolbar_stop" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    return _stopButtonImage;
}

- (UIImage *)actionButtonImage
{
    if (!_actionButtonImage) {
        _actionButtonImage = [UIImage imageNamed:@"toolbar_action" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    return _actionButtonImage;
}

/*
- (NSArray *)applicationActivitiesForItem:(id)item
{
    NSMutableArray *activities = [NSMutableArray new];
    
    if ([item isKindOfClass:[UIImage class]]) {
        return activities;
    }
    
    if ((_supportedWebActions & DZNWebActionCopyLink) > 0 || self.supportsAllActions) {
        [activities addObject:[DZNPolyActivity activityWithType:DZNPolyActivityTypeLink]];
    }
    if ((_supportedWebActions & DZNWebActionOpenSafari) > 0 || self.supportsAllActions) {
        [activities addObject:[DZNPolyActivity activityWithType:DZNPolyActivityTypeSafari]];
    }
    if ((_supportedWebActions & DZNWebActionOpenChrome) > 0 || self.supportsAllActions) {
        [activities addObject:[DZNPolyActivity activityWithType:DZNPolyActivityTypeChrome]];
    }
    if ((_supportedWebActions & DZNWebActionOpenOperaMini) > 0 || self.supportsAllActions) {
        [activities addObject:[DZNPolyActivity activityWithType:DZNPolyActivityTypeOpera]];
    }
    if ((_supportedWebActions & DZNWebActionOpenDolphin) > 0 || self.supportsAllActions) {
        [activities addObject:[DZNPolyActivity activityWithType:DZNPolyActivityTypeDolphin]];
    }
    
    return activities;
}

- (NSArray *)excludedActivityTypesForItem:(id)item
{
    NSMutableArray *types = [NSMutableArray new];
    
    if (![item isKindOfClass:[UIImage class]]) {
        [types addObjectsFromArray:@[UIActivityTypeCopyToPasteboard,
                                     UIActivityTypeSaveToCameraRoll,
                                     UIActivityTypePostToFlickr,
                                     UIActivityTypePrint,
                                     UIActivityTypeAssignToContact]];
    }
    
    if (self.supportsAllActions) {
        return types;
    }
    
    if ((_supportedWebActions & DZNsupportedWebActionshareLink) == 0) {
        [types addObjectsFromArray:@[UIActivityTypeMail, UIActivityTypeMessage,
                                     UIActivityTypePostToFacebook, UIActivityTypePostToTwitter,
                                     UIActivityTypePostToWeibo, UIActivityTypePostToTencentWeibo,
                                     UIActivityTypeAirDrop]];
    }
    if ((_supportedWebActions & DZNWebActionReadLater) == 0 && [item isKindOfClass:[UIImage class]]) {
        [types addObject:UIActivityTypeAddToReadingList];
    }
    
    return types;
}*/

- (BOOL)supportsAllActions
{
    return (_supportedWebActions == H5WebActionAll) ? YES : NO;
}


#pragma mark - Setter methods

- (void)setURL:(NSURL *)URL
{
    if ([self.URL isEqual:URL]) {
        return;
    }
    
    if (self.isViewLoaded) {
        [self loadURL:URL];
    }
    
    _URL = URL;
}

// 设置标题
- (void)setTitle:(NSString *)title
{
    if (self.webNavigationPrompt == H5WebNavigationPromptNone) {
        [super setTitle:title];
        return;
    }
    
    NSString *url = self.webView.URL.absoluteString;
    
    UILabel *label = (UILabel *)self.navigationItem.titleView;
    
    if (!label || ![label isKindOfClass:[UILabel class]]) {
        label = [UILabel new];
        label.numberOfLines = 2;
        label.textAlignment = NSTextAlignmentCenter;
        label.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.navigationItem.titleView = label;
    }
    
    UIFont *titleFont = self.navigationBar.titleTextAttributes[NSFontAttributeName] ? : [UIFont boldSystemFontOfSize:14.0];
    UIFont *urlFont = [UIFont fontWithName:titleFont.fontName size:titleFont.pointSize-2.0];
    UIColor *textColor = self.navigationBar.titleTextAttributes[NSForegroundColorAttributeName] ? : [UIColor blackColor];
    
    NSMutableString *text = [NSMutableString new];
    
    if (title.length > 0 && self.showNavigationPromptTitle) {
        [text appendFormat:@"%@", title];
        
        if (url.length > 0 && self.showNavigationPromptURL) {
            [text appendFormat:@"\n"];
        }
    }
    
    if (url.length > 0 && self.showNavigationPromptURL) {
        [text appendFormat:@"%@", url];
    }
    
    NSDictionary *attributes = @{NSFontAttributeName: titleFont, NSForegroundColorAttributeName: textColor};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    NSRange urlRange = [text rangeOfString:url];
    
    if (urlRange.location != NSNotFound && self.showNavigationPromptTitle) {
        [attributedString addAttribute:NSFontAttributeName value:urlFont range:urlRange];
    }
    
    label.attributedText = attributedString;
    [label sizeToFit];
    
    CGRect frame = label.frame;
    frame.size.height = CGRectGetHeight(self.navigationController.navigationBar.frame);
    label.frame = frame;
}

// 载入出错
- (void)setLoadingError:(NSError *)error
{
    switch (error.code) {
        case NSURLErrorUnknown:
        case NSURLErrorCancelled:   return;
    }
    
    _backgroundLabel.text = [NSString stringWithFormat:@"%@%@", H5LocalizedString(@"load failed:", nil) , error.localizedDescription];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
//    [alert show];
}

- (BOOL)showNavigationPromptTitle
{
    if ((self.webNavigationPrompt & H5WebNavigationPromptTitle) > 0 || self.webNavigationPrompt == H5WebNavigationPromptAll) {
        return YES;
    }
    return NO;
}

- (BOOL)showNavigationPromptURL
{
    if ((self.webNavigationPrompt & H5WebNavigationPromptURL) > 0 || self.webNavigationPrompt == H5WebNavigationPromptAll) {
        return YES;
    }
    return NO;
}


#pragma mark - H5WebViewController methods

- (void)loadURL:(NSURL *)URL
{
    NSURL *baseURL = [[NSURL alloc] initFileURLWithPath:URL.path.stringByDeletingLastPathComponent isDirectory:YES];
    [self loadURL:URL baseURL:baseURL];
}

- (void)loadURL:(NSURL *)URL baseURL:(NSURL *)baseURL
{
    if ([URL isFileURL]) {
        NSData *data = [[NSData alloc] initWithContentsOfURL:URL];
        NSString *HTMLString = [[NSString alloc] initWithData:data encoding:NSStringEncodingConversionAllowLossy];
        
        [self.webView loadHTMLString:HTMLString baseURL:baseURL];
    }
    else {
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
        [self.webView loadRequest:request];
    }
}

- (void)goBackward:(id)sender
{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }
}

- (void)goForward:(id)sender
{
    if ([self.webView canGoForward]) {
        [self.webView goForward];
    }
}

- (void)dismissHistoryController
{
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:^{
            
            // The bar button item's gestures are invalidated after using them, so we must re-assign them.
            [self configureBarItemsGestures];
        }];
    }
}

- (void)showBackwardHistory:(UIGestureRecognizer *)sender
{
    if (!self.allowHistory || self.webView.backForwardList.backList.count == 0 || sender.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    //[self presentHistoryControllerForTool:H5WebNavigationToolBackward fromView:sender.view];
}

- (void)showForwardHistory:(UIGestureRecognizer *)sender
{
    if (!self.allowHistory || self.webView.backForwardList.forwardList.count == 0 || sender.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    //[self presentHistoryControllerForTool:H5WebNavigationToolForward fromView:sender.view];
}

/*
- (void)presentHistoryControllerForTool:(H5WebNavigationTools)tool fromView:(UIView *)view
{
    UITableViewController *controller = [UITableViewController new];
    controller.title = NSLocalizedStringFromTable(@"History", @"H5WebViewController", nil);
    controller.tableView.delegate = self;
    controller.tableView.dataSource = self;
    controller.tableView.tag = tool;
    controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissHistoryController)];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    UIView *bar = DZN_IS_IPAD ? self.navigationBar : self.toolbar;
    
    if (DZN_IS_IPAD) {
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
        [popover presentPopoverFromRect:view.frame inView:bar permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else {
        [self presentViewController:navigationController animated:YES completion:NULL];
    }
}
 */

// 配置工具条
- (void)configureToolBars
{
    if (DZN_IS_IPAD) {
        self.navigationItem.rightBarButtonItems = [[[self navigationToolItems] reverseObjectEnumerator] allObjects];
    }
    else {
        [self setToolbarItems:[self navigationToolItems]];
    }
    
    self.toolbar = self.navigationController.toolbar; // 工具条
    self.navigationBar = self.navigationController.navigationBar;
    self.navigationBarSuperView = self.navigationBar.superview;
    
    // 是否隐藏导航条
//    self.navigationController.hidesBarsOnSwipe = self.hideBarsWithGestures; //滑动时隐藏navigationbar
//    self.navigationController.hidesBarsWhenKeyboardAppears = self.hideBarsWithGestures; //输入键盘出现时将导航栏隐藏
//    self.navigationController.hidesBarsWhenVerticallyCompact = self.hideBarsWithGestures;//敲击屏幕可以隐藏与显示导航栏
    
    // 自动隐藏条
    if (self.hideBarsWithGestures) {
        [self.navigationBar addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:&H5WebViewControllerKVOContext];
        [self.navigationBar addObserver:self forKeyPath:@"center" options:NSKeyValueObservingOptionNew context:&H5WebViewControllerKVOContext];
        [self.navigationBar addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:&H5WebViewControllerKVOContext];
    }
    
    if (!DZN_IS_IPAD && self.navigationController.toolbarHidden && self.toolbarItems.count > 0) {
        [self.navigationController setToolbarHidden:NO];
    }
}

// Light hack for adding custom gesture recognizers to UIBarButtonItems
- (void)configureBarItemsGestures
{
    UIView *backwardButton= [self.backwardBarItem valueForKey:@"view"];
    if (backwardButton.gestureRecognizers.count == 0) {
        if (!_backwardLongPress) {
            _backwardLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showBackwardHistory:)];
        }
        [backwardButton addGestureRecognizer:self.backwardLongPress];
    }
    
    UIView *forwardBarButton= [self.forwardBarItem valueForKey:@"view"];
    if (forwardBarButton.gestureRecognizers.count == 0) {
        if (!_forwardLongPress) {
            _forwardLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showForwardHistory:)];
        }
        [forwardBarButton addGestureRecognizer:self.forwardLongPress];
    }
}

- (void)updateToolbarItems
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:[self.webView isLoading]];
    
    self.backwardBarItem.enabled = [self.webView canGoBack];
    self.forwardBarItem.enabled = [self.webView canGoForward];
    self.actionBarItem.enabled = !self.webView.isLoading;
    
    [self updateStateBarItem];
}

- (void)updateStateBarItem
{
    self.stateBarItem.target = self.webView;
    self.stateBarItem.action = self.webView.isLoading ? @selector(stopLoading) : @selector(reload);
    self.stateBarItem.image = self.webView.isLoading ? self.stopButtonImage : self.reloadButtonImage;
    self.stateBarItem.landscapeImagePhone = nil;
    self.stateBarItem.accessibilityLabel = NSLocalizedStringFromTable(self.webView.isLoading ? @"Stop" : @"Reload", @"H5WebViewController", @"Accessibility label button title");
    self.stateBarItem.enabled = YES;
}


- (void)presentActivityController:(id)sender
{
    if (!self.webView.URL.absoluteString) {
        return;
    }
    
    //[self presentActivityControllerWithItem:self.webView.URL.absoluteString andTitle:self.webView.title sender:sender];
}

/*
- (void)presentActivityControllerWithItem:(id)item andTitle:(NSString *)title sender:(id)sender
{
    if (!item) {
        return;
    }
    
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[title, item] applicationActivities:[self applicationActivitiesForItem:item]];
    controller.excludedActivityTypes = [self excludedActivityTypesForItem:item];
    
    if (title) {
        [controller setValue:title forKey:@"subject"];
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        controller.popoverPresentationController.barButtonItem = sender;
    }
    
    [self presentViewController:controller animated:YES completion:NULL];
}*/

- (void)clearProgressViewAnimated:(BOOL)animated
{
    if (!_progressView) {
        return;
    }
    
    [UIView animateWithDuration:animated ? 0.25 : 0.0
                     animations:^{
                         self.progressView.alpha = 0;
                     } completion:^(BOOL finished) {
                         [self destroyProgressViewIfNeeded];
                     }];
}

- (void)destroyProgressViewIfNeeded
{
    if (_progressView) {
        [_progressView removeFromSuperview];
        _progressView = nil;
    }
}


#pragma mark - H5NavigationDelegate methods

- (void)webView:(H5WebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    [self updateStateBarItem];
    
    _backgroundLabel.text = H5LocalizedString(@"loading", @"Loading");
    self.navigationItem.title = H5LocalizedString(@"loading", @"Loading");
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    /*if (_navigationType == AXWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
     }
     if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
     }
     
     if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerDidStartLoad:)]) {
     [_delegate webViewControllerDidStartLoad:self];
     }*/
    
    //    _loading = YES;
}

- (void)webView:(H5WebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:[self.webView isLoading]];
}

// 更新进度
- (void)webView:(H5WebView *)webView didUpdateProgress:(CGFloat)progress
{
    if (!self.showLoadingProgress) {
        [self destroyProgressViewIfNeeded];
        return;
    }
    
    if (self.progressView.alpha == 0 && progress > 0) {
        
        self.progressView.progress = 0;
        
        [UIView animateWithDuration:0.2 animations:^{
            self.progressView.alpha = 1.0;
        }];
    }
    else if (self.progressView.alpha == 1.0 && progress == 1.0)
    {
        [UIView animateWithDuration:0.2 animations:^{
            self.progressView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.progressView.progress = 0;
        }];
    }
    
    [self.progressView setProgress:progress animated:YES];
}

// 页面加载完成后调用
- (void)webView:(H5WebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if (self.webNavigationPrompt > H5WebNavigationPromptNone) {
        self.title = self.webView.title;
    }
    
    /*@try {
     [self hookWebContentCommitPreviewHandler];
     } @catch (NSException *exception) {
     } @finally {
     }*/
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    /*if (_navigationType == AXWebViewControllerNavigationBarItem) {
     [self updateNavigationItems];
     }
     if (_navigationType == AXWebViewControllerNavigationToolItem) {
     [self updateToolbarItems];
     }*/
    
    NSString *title;
    title = [_webView title];
    if (title.length > 10) {
        title = [[title substringToIndex:9] stringByAppendingString:@"…"];
    }
    
    self.navigationItem.title = title?:H5LocalizedString(@"browsing the web", @"browsing the web");
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *bundle = ([infoDictionary objectForKey:@"CFBundleDisplayName"]?:[infoDictionary objectForKey:@"CFBundleName"])?:[infoDictionary objectForKey:@"CFBundleIdentifier"];
    
    NSString *host;
    host = _webView.URL.host;
    
    // 网页由xx提供
    _backgroundLabel.text = [NSString stringWithFormat:@"%@\"%@\"%@.", H5LocalizedString(@"web page",@""), host?:bundle, H5LocalizedString(@"provided",@"")];
    
    /*if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerDidFinishLoad:)]) {
     [_delegate webViewControllerDidFinishLoad:self];
     }*/
    
    //    _loading = NO;
}

// navigation发生错误时调用
- (void)webView:(H5WebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [self setLoadingError:error];
    
    // if this is a cancelled error, then don't affect the title
    switch (error.code) {
        case NSURLErrorCancelled:   return;
    }
    
    self.title = nil;
}

// 在发送请求之前，决定是否继续处理。根据webView、navigationAction相关信息决定这次跳转
// 是否可以继续进行,这些信息包含HTTP发送请求，如头部包含User-Agent,Accept。
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    // 忽略空白页 Disable all the '_blank' target in page's target.
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView evaluateJavaScript:@"var a = document.getElementsByTagName('a');for(var i=0;i<a.length;i++){a[i].setAttribute('target','');}" completionHandler:nil];
    }
    
    // Resolve URL. Fixs the issue: https://github.com/devedbox/AXWebViewController/issues/7
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:webView.URL.absoluteString];
    
    // For appstore.
    if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'https://itunes.apple.com/cn/app/'"] evaluateWithObject:webView.URL.absoluteString]) {
        if ([[UIApplication sharedApplication] canOpenURL:webView.URL]) {
            [[UIApplication sharedApplication] openURL:webView.URL];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    else if (![[NSPredicate predicateWithFormat:@"SELF MATCHES[cd] 'https' OR SELF MATCHES[cd] 'http'"] evaluateWithObject:components.scheme]) {
        // For any other schema.
        if ([[UIApplication sharedApplication] canOpenURL:webView.URL]) {
            [[UIApplication sharedApplication] openURL:webView.URL];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    // URL actions
    if ([navigationAction.request.URL.absoluteString isEqualToString:k404NotFoundURLKey] ||
        [navigationAction.request.URL.absoluteString isEqualToString:kNetworkErrorURLKey]) {
        
        [self loadURL:_URL];
    }
    
    // Update the items.
    /*if (_navigationType == AXWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }*/
    
    // Call the decision handler to allow to load web page.
    decisionHandler(WKNavigationActionPolicyAllow);
}

//在收到响应后，决定是否继续处理。根据response相关信息，可以决定这次跳转是否可以继续进行。
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
}

// 接收到服务器跳转请求之后调用(重定向)
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
}

//页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
}

// web视图需要响应身份验证时调用
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler {
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
// web视图需要响应身份验证时调用。
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    
    // Get the host name.
    NSString *host = webView.URL.host;
    
    // Initialize alert view controller.
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:host?:H5LocalizedString(@"messages", nil) message:H5LocalizedString(@"terminate", nil) preferredStyle:UIAlertControllerStyleAlert];
    // Initialize cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:H5LocalizedString(@"cancel", @"cancel") style:UIAlertActionStyleCancel handler:NULL];
    // Initialize ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:H5LocalizedString(@"confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
    }];
    
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
}
#endif


#pragma mark - WKUIDelegate methods

- (H5WebView *)webView:(H5WebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    
    return nil;
}


#pragma mark - Key Value Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != &H5WebViewControllerKVOContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([object isEqual:self.navigationBar]) {
        
        // Skips for landscape orientation, since there is no status bar visible on iPhone landscape
        if (DZN_IS_LANDSCAPE) {
            return;
        }
        
        id new = change[NSKeyValueChangeNewKey];
        
        if ([keyPath isEqualToString:@"hidden"] && [new boolValue] && self.navigationBar.center.y >= -2.0) {
            
            self.navigationBar.hidden = NO;
            
            if (!self.navigationBar.superview) {
                [self.navigationBarSuperView addSubview:self.navigationBar];
            }
        }
        
        if ([keyPath isEqualToString:@"center"]) {
            
            CGPoint center = [new CGPointValue];
            
            if (center.y < -2.0) {
                center.y = -2.0;
                self.navigationBar.center = center;
                
                [UIView beginAnimations:@"DZNNavigationBarAnimation" context:nil];
                
                for (UIView *subview in self.navigationBar.subviews) {
                    if (subview != self.navigationBar.subviews[0]) {
                        subview.alpha = 0.0;
                    }
                }
                
                [UIView commitAnimations];
            }
        }
    }
    
    if ([object isEqual:self.webView] && [keyPath isEqualToString:@"loading"]) {
        [self updateToolbarItems];
    }
}

#pragma mark - 滚动触发显示隐藏

- (void)setIsExpand:(BOOL)isExpand{
    [UIView animateWithDuration:0.25 delay:0.0 usingSpringWithDamping:0.4 initialSpringVelocity:10.0 options:UIViewAnimationOptionTransitionCurlUp animations:^{
        
//        self.toolbar.constant = isExpand?44.0f:0.0f;
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        _isExpand = isExpand;
    }];
    [self.navigationController setNavigationBarHidden:!isExpand animated:YES];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
//    [[UIApplication sharedApplication] setStatusBarHidden:!isExpand withAnimation:NO];
#pragma clang diagnostic pop
}

// 滚动代理方法
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSLog(@"开始滚动");
    int currentPostion = scrollView.contentOffset.y;
    
    // 控制左上角的自定义视图
    self.cusNavLeftView.hidden = currentPostion < 80;
    
    if (currentPostion - _lastPosition > 20  && currentPostion >0) {
        
        _lastPosition = currentPostion;
        
        NSLog(@"向上滚动");
        
//        self.tabBarController.tabBar.hidden = YES;// tabbar
//        [self.navigationController setNavigationBarHidden:YES animated:YES];//导航栏
        [self.navigationController setToolbarHidden:YES animated:YES];//工具条
        
    }
    else if ((_lastPosition - currentPostion >20) && (currentPostion  <= scrollView.contentSize.height-scrollView.bounds.size.height-20) )
    {
        _lastPosition = currentPostion;
        
        NSLog(@"向下滚动");
        
//        self.tabBarController.tabBar.hidden = NO;//隐藏时，没有动画效果
//        [self.navigationController setNavigationBarHidden:NO animated:YES];//导航栏
        [self.navigationController setToolbarHidden:NO animated:YES];//工具条
        
    }
}


#pragma mark - View Auto-Rotation

#ifdef __IPHONE_9_0
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#else
- (NSUInteger)supportedInterfaceOrientations
#endif
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return NO;
}


#pragma mark - View lifeterm

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)dealloc
{
    if (self.hideBarsWithGestures) {
        [self.navigationBar removeObserver:self forKeyPath:@"hidden" context:&H5WebViewControllerKVOContext];
        [self.navigationBar removeObserver:self forKeyPath:@"center" context:&H5WebViewControllerKVOContext];
        [self.navigationBar removeObserver:self forKeyPath:@"alpha" context:&H5WebViewControllerKVOContext];
    }
    [self.webView removeObserver:self forKeyPath:@"loading" context:&H5WebViewControllerKVOContext];
    
    _backwardBarItem = nil;
    _forwardBarItem = nil;
    _stateBarItem = nil;
    _actionBarItem = nil;
    _progressView = nil;
    
    _backwardLongPress = nil;
    _forwardLongPress = nil;
    
    _webView.scrollView.delegate = nil;
    _webView.navDelegate = nil;
    _webView.UIDelegate = nil;
    _webView.scrollView.delegate = nil;
    _webView = nil;
    _URL = nil;
}


@end
