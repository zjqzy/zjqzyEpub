//
//  EPUBPageWebView.m
//  CommonReader
//
//  Created by fanzhenhua on 15/7/1.
//  Copyright (c) 2015年 zjqzy. All rights reserved.
//
#import "EPUBPageViewController.h"
#import "EPUBPageWebView.h"

@implementation EPUBPageWebView

-(void)dealloc
{
    [self cleanForDealloc];
#ifdef DEBUG
    //NSLog(@"释放 EPUBPageWebView");
#endif
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
    
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        //[self menuInit];
//        NSLog(@"%@", NSStringFromClass([self class]));//输出 EPUBPageWebView
//        NSLog(@"%@", NSStringFromClass([super class]));//输出 EPUBPageWebView
        
        [self menuInit2];
    }
    return self;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    //只显示系统自带
    //return [super canPerformAction:action withSender:sender];
    
    //只显示自定义
    //    if(action == @selector(ciYi:) || action == @selector(listeningSound:) ||action == @selector(addWord:))
    //    {
    //        return YES;
    //    }
    //    return NO;
    
    //系统和自定义都显示
    if(action == @selector(addNote:))
    {
        return YES;
    }
    return [super canPerformAction:action withSender:sender];//
}

-(void)menuInit
{
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    UIMenuItem *menuItemCiYi = [[UIMenuItem alloc] initWithTitle:@"看词义" action:@selector(ciYi:)];
    UIMenuItem *menuItemSound = [[UIMenuItem alloc] initWithTitle:@"听发音" action:@selector(listeningSound:)];
    UIMenuItem *menuItemShengCi = [[UIMenuItem alloc] initWithTitle:@"加入生词本" action:@selector(addWord:)];
    NSArray *mArray = [NSArray arrayWithObjects:menuItemCiYi,menuItemSound,menuItemShengCi, nil];

    [menuController setMenuItems:mArray];
    
#if !__has_feature(objc_arc)
    [menuItemCiYi release];
    [menuItemSound release];
    [menuItemShengCi release];
#endif
    
}
-(IBAction)ciYi:(id)sender;
{
    NSLog(@"ciYi");
}

-(IBAction)listeningSound:(id)sender
{
    NSLog(@"listeningSound");
}

-(IBAction)addWord:(id)sender
{
    NSLog(@"addWord");
}
-(void)menuInit2
{
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    UIMenuItem *menuItemNote = [[UIMenuItem alloc] initWithTitle:@"加入笔记" action:@selector(addNote:)];
    NSArray *mArray = [NSArray arrayWithObjects:menuItemNote, nil];
    
    [menuController setMenuItems:mArray];
    
    
}
-(void)addNote:(id)sender
{
    NSString* selectionString = [self stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"];
    
    [self.parentVC addNote:selectionString];

}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
////////////////////////////////////////////////////////////////////////////////
///////////////////      公共方法     /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - 公共方法
- (NSString *)documentTitle
{
   	return [self stringByEvaluatingJavaScriptFromString:@"document.title"];
}

/*
 
 Using this Category is easy, simply add this to the top of your file where
 you have a UIWebView:
 
 #import "UIWebView+Clean.h"
 
 Then, any time you want to throw away or deallocate a UIWebView instance, do
 the following before you throw it away:
 
 [self.webView cleanForDealloc];
 self.webView = nil;
 
 If you still have leak issues, read the notes at the bottom of this class,
 they  may help you.
 
 */


- (void) cleanForDealloc
{
    /*
     
     There are several theories and rumors about UIWebView memory leaks, and how
     to properly handle cleaning a UIWebView instance up before deallocation. This
     method implements several of those recommendations.
     
     #1: Various developers believe UIWebView may not properly throw away child
     objects & views without forcing the UIWebView to load empty content before
     dealloc.
     
     Source: http://stackoverflow.com/questions/648396/does-uiwebview-leak-memory
     
     */
    [self loadHTMLString:@"" baseURL:nil];
    
    /*
     
     #2: Others claim that UIWebView's will leak if they are loading content
     during dealloc.
     
     Source: http://stackoverflow.com/questions/6124020/uiwebview-leaking
     
     */
    [self stopLoading];
    
    /*
     
     #3: Apple recommends setting the delegate to nil before deallocation:
     "Important: Before releasing an instance of UIWebView for which you have set
     a delegate, you must first set the UIWebView delegate property to nil before
     disposing of the UIWebView instance. This can be done, for example, in the
     dealloc method where you dispose of the UIWebView."
     
     Source: UIWebViewDelegate class reference
     
     */
    self.delegate = nil;
    
    
    /*
     
     #4: If you're creating multiple child views for any given view, and you're
     trying to deallocate an old child, that child is pointed to by the parent
     view, and won't actually deallocate until that parent view dissapears. This
     call below ensures that you are not creating many child views that will hang
     around until the parent view is deallocated.
     */
    
    [self removeFromSuperview];
    
    /*
     
     Further Help with UIWebView leak problems:
     
     #1: Consider implementing the following in your UIWebViewDelegate:
     
     - (void) webViewDidFinishLoad:(UIWebView *)webView
     {
     //source: http://blog.techno-barje.fr/post/2010/10/04/UIWebView-secrets-part1-memory-leaks-on-xmlhttprequest/
     [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
     }
     
     #2: If you can, avoid returning NO in your UIWebViewDelegate here:
     
     - (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
     {
     //this source says don't do this: http://stackoverflow.com/questions/6421813/lots-of-uiwebview-memory-leaks
     //return NO;
     return YES;
     }
     
     #3: Some leaks appear to be fixed in IOS 4.1
     Source: http://stackoverflow.com/questions/3857519/memory-leak-while-using-uiwebview-load-request-in-ios4-0
     
     #4: When you create your UIWebImageView, disable link detection if possible:
     
     webView.dataDetectorTypes = UIDataDetectorTypeNone;
     
     (This is also the "Detect Links" checkbox on a UIWebView in Interfacte Builder.)
     
     Sources:
     http://www.iphonedevsdk.com/forum/iphone-sdk-development/46260-how-free-memory-after-uiwebview.html
     http://www.iphonedevsdk.com/forum/iphone-sdk-development/29795-uiwebview-how-do-i-stop-detecting-links.html
     http://blog.techno-barje.fr/post/2010/10/04/UIWebView-secrets-part2-leaks-on-release/
     
     #5: Consider cleaning the NSURLCache every so often:
     
     [[NSURLCache sharedURLCache] removeAllCachedResponses];
     [[NSURLCache sharedURLCache] setDiskCapacity:0];
     [[NSURLCache sharedURLCache] setMemoryCapacity:0];
     
     Source: http://blog.techno-barje.fr/post/2010/10/04/UIWebView-secrets-part2-leaks-on-release/
     
     Be careful with this, as it may kill cache objects for currently executing URL
     requests for your application, if you can't cleanly clear the whole cache in
     your app in some place where you expect zero URLRequest to be executing, use
     the following instead after you are done with each request (note that you won't
     be able to do this w/ UIWebView's internal request objects..):
     
     [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
     
     Source: http://stackoverflow.com/questions/6542114/clearing-a-webviews-cache-for-local-files
     
     */
}
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - highlight
- (NSInteger)highlightAllOccurencesOfString:(NSString*)str {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"SearchWebView" ofType:@"js"];
    NSString *jsCode = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [self stringByEvaluatingJavaScriptFromString:jsCode];
    
    NSString *startSearch = [NSString stringWithFormat:@"MyApp_HighlightAllOccurencesOfString('%@');",str];
    [self stringByEvaluatingJavaScriptFromString:startSearch];
    
    //    NSLog(@"%@", [self stringByEvaluatingJavaScriptFromString:@"console"]);
    return [[self stringByEvaluatingJavaScriptFromString:@"MyApp_SearchResultCount;"] intValue];
}

- (void)removeAllHighlights {
    [self stringByEvaluatingJavaScriptFromString:@"MyApp_RemoveAllHighlights()"];
}
/////////////////////////////////////

- (NSInteger)underlineAllOccurencesOfString:(NSString*)str
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"SearchWebView" ofType:@"js"];
    NSString *jsCode = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [self stringByEvaluatingJavaScriptFromString:jsCode];
    NSString *startSearch = [NSString stringWithFormat:@"MyApp_UnderlineAllOccurencesOfString('%@');",str];
    [self stringByEvaluatingJavaScriptFromString:startSearch];
    
    //    NSLog(@"%@", [self stringByEvaluatingJavaScriptFromString:@"console"]);
    return [[self stringByEvaluatingJavaScriptFromString:@"MyApp_SearchResultCount;"] intValue];
}
@end
