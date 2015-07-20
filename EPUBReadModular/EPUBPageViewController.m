//
//  EPUBReadPageViewController.m
//  CommonReader
//
//  Created by fanzhenhua on 15/6/30.
//  Copyright (c) 2015年 zjqzy. All rights reserved.
//

#import "UIWebView+SearchWebView.h"
#import "EPUBParser.h"
#import "EPUBReadMainViewController.h"
#import "EPUBPageViewController.h"
#import "EPUBPageWebView.h"

@interface EPUBPageViewController ()<UIWebViewDelegate,UIGestureRecognizerDelegate>
{
    UITapGestureRecognizer          *m_gestureSingleTap;    //轻击 单击
    UITapGestureRecognizer          *m_gestureDoubleTap;    //轻击 双击
}
@end

@implementation EPUBPageViewController
-(void)dealloc
{
    //析构

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
    
#ifdef DEBUG
    NSLog(@"析构 EPUBPageViewController 页码=%@",@(_pageRefIndex));
#endif
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        //准备数据
        [self dataPrepare];
        
    }
    return self;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //__weak typeof(self) _weakself = self;
    
    {
        NSString *themeBodyColor=[self.epubVC.arrTheme[self.epubVC.themeIndex] objectForKey:@"bodycolor"];
        UIColor *bgColor1=[self.epubVC UIColorFromRGBString:themeBodyColor];
        self.view.backgroundColor=bgColor1;
        //_pageViewController.view.backgroundColor=bgColor1;
    }
    
    //界面
    [self customViewInit:self.view.bounds];
    _pageWebView.hidden=YES;
    
    //
    [self resizeViews:self.view.bounds];
    
    //
    if (_pageRefIndex>-1)
    {
        if ([self.epubVC.jsContent length] <1) {
            
            self.epubVC.jsContent= [self.epubVC jsContentWithViewRect:self.pageWebView.frame];
        }
        
        NSString *pageURL=[self.epubVC pageURLWithPageRefIndex:_pageRefIndex];
        NSString *htmlContent=[self.epubVC.epubParser HTMLContentFromFile:pageURL AddJsContent:self.epubVC.jsContent];
        NSURL* baseURL = [NSURL fileURLWithPath:pageURL];
        [_pageWebView loadHTMLString:htmlContent baseURL:baseURL];
    }
    
    //手势
    [self GestureRecognizerTapAddOrRemove:YES InView:self.pageWebView];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self resizeViews:self.view.bounds];
}
////////////////////////////////////////////////////////////////////////////////
//////////////     life circle   界面 相关  ////////// ///////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - life circle
-(void)customViewInit:(CGRect)viewRect
{
    //创建
    
    CGRect rectContent=viewRect;
    _contentView=[[UIView alloc] initWithFrame:rectContent];
    [self.view addSubview:_contentView];
    //_contentView.backgroundColor=gObj.contentViewBackgroundColorNormal;
    _contentView.backgroundColor=[UIColor clearColor];
    if (_contentView)
    {
        //
        _titleView=[UIView new];
        _titleView.backgroundColor=[UIColor clearColor];
        [_contentView addSubview:_titleView];
        if (_titleView) {
            _titleLabel=[[UILabel alloc] init];
            _titleLabel.backgroundColor=[UIColor clearColor];
            _titleLabel.textColor=[UIColor grayColor];
            _titleLabel.textAlignment=NSTextAlignmentLeft;
            _titleLabel.font=[UIFont systemFontOfSize:12.0f];
            [_titleView addSubview:_titleLabel];
        }
        
        //
        _statusView=[UIView new];
        _statusView.backgroundColor=[UIColor clearColor];
        [_contentView addSubview:_statusView];
        if (_statusView) {
            
            //
            _pageStatusLabel=[[UILabel alloc] init];
            _pageStatusLabel.backgroundColor=[UIColor clearColor];
            _pageStatusLabel.textColor=[UIColor grayColor];
            _pageStatusLabel.textAlignment=NSTextAlignmentRight;
            _pageStatusLabel.font=[UIFont systemFontOfSize:12.0f];
            [_statusView addSubview:_pageStatusLabel];
            
            //
            _timeStatusLabel=[[UILabel alloc] init];
            _timeStatusLabel.backgroundColor=[UIColor clearColor];
            _timeStatusLabel.textColor=[UIColor grayColor];
            _timeStatusLabel.textAlignment=NSTextAlignmentLeft;
            _timeStatusLabel.font=[UIFont systemFontOfSize:12.0f];
            [_statusView addSubview:_timeStatusLabel];
        }
        
        //
        _pageWebView=[EPUBPageWebView new];
        _pageWebView.parentVC=self;
        _pageWebView.delegate=self;
        _pageWebView.backgroundColor=[UIColor clearColor];
        _pageWebView.opaque = NO;
        //[webView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"webbg.png"]]];
        //_pageWebView.dataDetectorTypes=UIDataDetectorTypePhoneNumber;//不起作用
        [_contentView addSubview:_pageWebView];
        
        for (UIView* v in  _pageWebView.subviews)
        {
            
            if([v isKindOfClass:[UIScrollView class]]){
                UIScrollView *sv = (UIScrollView*)v;
                sv.scrollEnabled = NO;
                sv.bounces = NO;
            }
        }
        

    }

}

-(void)resizeViews:(CGRect)viewRect
{
    //整体界面调整
    
    if (viewRect.size.width<1 || viewRect.size.height<1) {
        return;
    }
    
    _contentView.frame=CGRectInset(viewRect, 20, 0);
    if (_contentView) {
        
        CGRect rectContentBound=_contentView.bounds;
        
        CGRect rectTitle=rectContentBound;
        rectTitle.size.height=40;
        _titleView.frame=rectTitle;
        
        if (_titleView)
        {
            CGRect rectTitleBound=_titleView.bounds;
            CGRect rectLb1=rectTitleBound;
            //rectLb1.origin.y=20;
            rectLb1.origin.y=10;
            rectLb1.size.height=rectTitleBound.size.height-rectLb1.origin.y;
            _titleLabel.frame=rectLb1;
        }
        
        CGRect rectStatus=rectTitle;
        rectStatus.size.height=20;
        rectStatus.origin.y=viewRect.size.height-rectStatus.size.height;
        _statusView.frame=rectStatus;
        if (_statusView) {
            CGRect rectStatusBound=_statusView.bounds;
            CGRect rectLb1=rectStatusBound;
            rectLb1.origin.x =rectStatusBound.size.width * 0.5f;
            rectLb1.size.width=rectStatusBound.size.width-rectLb1.origin.x;
            _pageStatusLabel.frame=rectLb1;
            
            
            CGRect rectLb2=rectLb1;
            rectLb2.origin.x=0;
            _timeStatusLabel.frame=rectLb2;

        }
        
        
        CGRect rectWeb=rectContentBound;
        rectWeb.origin.y=rectTitle.origin.y+rectTitle.size.height;
        rectWeb.size.height=rectStatus.origin.y-rectWeb.origin.y;
        _pageWebView.frame=rectWeb;
        
        
    }
    
}
-(void)dataPrepare
{
    //用户设置属性
    _pageRefIndex=-1;
    _offYIndexInPage=-1;
}
-(void)initAfter
{
    //后续初始化

}


-(void)refresh
{
    //刷新
    NSMutableDictionary *catalog=[self.epubVC catalogWithPageRef:self.pageRefIndex];
    if (catalog)
    {
        NSString *text1=catalog[@"text"];
        _titleLabel.text=text1?text1:@"";
    }
    
    {
        NSInteger currentOffCountInPage=[[self.epubVC.dictPageWithOffYCount objectForKey:[NSString stringWithFormat:@"%@",@(self.pageRefIndex)]] integerValue];
        
        NSString *pageStatus=[NSString stringWithFormat:@"%@ / %@",@(self.offYIndexInPage+1) ,@(currentOffCountInPage)];
        _pageStatusLabel.text=pageStatus;
    }
    {
        _timeStatusLabel.text=[self.epubVC getTimeStringWithFormat:@"HH:mm"];;
    }
}

////////////////////////////////////////////////////////////////////////////////
/////////////////     手势     ///////////////////////////
////////////////////////////////////////////////////////////////////////////////
-(void)GestureRecognizerTapAddOrRemove:(BOOL)isAdd InView:(UIView*)inView
{
    //手势添加或移出   手势种类见博客

    if (m_gestureDoubleTap == nil) {
        m_gestureDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doTap:)];
        m_gestureDoubleTap.numberOfTouchesRequired = 1;
        m_gestureDoubleTap.numberOfTapsRequired = 2;

    }
    
    if (m_gestureSingleTap == nil) {
        m_gestureSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doTap:)];
        m_gestureSingleTap.numberOfTouchesRequired = 1;
        m_gestureSingleTap.numberOfTapsRequired = 1;

        [m_gestureSingleTap requireGestureRecognizerToFail:m_gestureDoubleTap];
        //m_gestureSingleTap.cancelsTouchesInView=NO;//// YES的话，其后的子View里的btn不响应了
        //测试后， 也不灵， 不会只指self吧
        
    }
    
    {
        //uiwebview特殊化了
        //http://stackoverflow.com/questions/5504955/custom-control-overlay-on-uiwebview-on-single-tap-touch-in-iphone
        m_gestureSingleTap.delegate=self;
        m_gestureDoubleTap.delegate=self;
    }
    
    if (isAdd)
    {
//        [inView addGestureRecognizer:m_gestureSwipeLeft];
//        [inView addGestureRecognizer:m_gestureSwipeRight];
        //[inView addGestureRecognizer:m_gesturePan];
        //[inView addGestureRecognizer:m_gesturelongPress];
        [inView addGestureRecognizer:m_gestureSingleTap];   //其后的子View里的btn不响应了
        [inView addGestureRecognizer:m_gestureDoubleTap];
    }
    else
    {
//        [inView removeGestureRecognizer:m_gestureSwipeLeft];
//        [inView removeGestureRecognizer:m_gestureSwipeRight];
        //[inView removeGestureRecognizer:m_gesturePan];
        //[inView removeGestureRecognizer:m_gesturelongPress];
        [inView removeGestureRecognizer:m_gestureSingleTap];
        [inView removeGestureRecognizer:m_gestureDoubleTap];
    }
}
-(void)doTap:(UITapGestureRecognizer*)recognizer
{
    //轻击
    if (recognizer.numberOfTouchesRequired == 1 && recognizer.numberOfTapsRequired == 1)
    {
        [self singleTaped:recognizer];
    }
    else if(recognizer.numberOfTouchesRequired == 1 && recognizer.numberOfTapsRequired == 2)
    {
        [self doubleTaped:recognizer];
    }
}
- (void)singleTaped:(UITapGestureRecognizer *)recognizer
{
    //单击
    
    //手指坐标
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        CGPoint ptLocation=[recognizer locationInView:self.view];
        CGRect viewRect=self.view.bounds;
        float fBoundary=60.0f;
        CGRect tapRect = CGRectInset(viewRect,fBoundary, 0.0f); // Area
        if (CGRectContainsPoint(tapRect, ptLocation))
        {
            [self.epubVC showOrHideHeadAndFoot];
        }

        
    }
}
- (void) doubleTaped:(UITapGestureRecognizer *)recognizer
{
    //双击
    //手指坐标
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
#ifdef DEBUG
        NSLog(@"epubVC 双击");
#endif
//        //清空查找
//        if (self.currentSearchResult) {
//            self.currentSearchResult=nil;
//        }
//        
        CGPoint pt = [recognizer locationInView:self.pageWebView];
        NSString *imgFileFullPath=[self getContentFromPoint:pt];
        
        if (imgFileFullPath)
        {
            NSMutableDictionary *para=[NSMutableDictionary dictionary];
            [para setObject:imgFileFullPath forKey:@"imgFileFullPath"];
            [self.epubVC showImagePreView:para];
        }
    }
}
////////////////////////////////////////////////////////////////////////////////
/////////////////     UIGestureRecognizerDelegate   ////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}
////////////////////////////////////////////////////////////////////////////////
/////////////////     UIWebViewDelegate     ///////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked )
    {
        //禁止内容里面的超链接
        return NO;
    }
    return YES;
}
-(void)webViewDidStartLoad:(UIWebView *)webView
{
    //[self.indicatorView startAnimating];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    //[self.indicatorView stopAnimating];
}
- (void)webViewDidFinishLoad:(UIWebView *)theWebView
{
    //[self.indicatorView stopAnimating];
    _pageWebView.hidden=NO;
    
    NSString *insertRule1 = [NSString stringWithFormat:@"addCSSRule('html', 'padding: 0px; height: %fpx; -webkit-column-gap: 0px; -webkit-column-width: %fpx;')", theWebView.frame.size.height, theWebView.frame.size.width];
    
    NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', ' font-size:%@px;')", @(self.epubVC.currentTextSize)];
    NSString *setTextSizeRule2 = [NSString stringWithFormat:@"addCSSRule('p', ' font-size:%@px;')", @(self.epubVC.currentTextSize)];
    
    [theWebView stringByEvaluatingJavaScriptFromString:insertRule1];
    [theWebView stringByEvaluatingJavaScriptFromString:setTextSizeRule];
    [theWebView stringByEvaluatingJavaScriptFromString:setTextSizeRule2];
    
    
    if (self.calcPageOffy && self.pageRefIndex>-1)
    {
        //需要计算  页面的信息

        NSInteger totalWidth = [[theWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollWidth"] integerValue];
        
        NSInteger theWebSizeWidth=theWebView.bounds.size.width;
        int offCountInPage = (int)((float)totalWidth/theWebSizeWidth);
//        if (offCountInPage < 0 || offCountInPage >100)
//        {
//            NSLog(@"11");
//        }

        [self.epubVC.dictPageWithOffYCount setObject:[NSString stringWithFormat:@"%@",@(offCountInPage)] forKey:[NSString stringWithFormat:@"%@",@(self.pageRefIndex)]];
        
        //
        self.calcPageOffy=0;    //计算完成
        
    }
    
    NSInteger currentOffCountInPage=[[self.epubVC.dictPageWithOffYCount objectForKey:[NSString stringWithFormat:@"%@",@(self.pageRefIndex)]] integerValue];

    //滚动索引
    if (self.isPrePage) {
        self.offYIndexInPage=currentOffCountInPage-1;
    }
    if (self.offYIndexInPage >= currentOffCountInPage) {
        self.offYIndexInPage=currentOffCountInPage-1;
    }
    if (self.offYIndexInPage <0) {
        self.offYIndexInPage=0;
    }
    
    
    //
    if (self.offYIndexInPage > -1 && self.offYIndexInPage < currentOffCountInPage && currentOffCountInPage>0)
    {
        
        
        //查找
        if (self.epubVC.pageIsShowSearchResultText && [self.epubVC.currentSearchText length]>0) {

            [(EPUBPageWebView*)theWebView highlightAllOccurencesOfString:self.epubVC.currentSearchText];
        }
        
        //笔记
        for (NSMutableDictionary *item1 in self.epubVC.arrNotes) {
            NSInteger notePageRefIndex= [[item1 objectForKey:@"PageRefIndex"] integerValue];
            if (self.pageRefIndex == notePageRefIndex) {
                
                NSString *noteContent=[item1 objectForKey:@"NoteContent"];
                [(EPUBPageWebView*)theWebView highlightAllOccurencesOfString:noteContent];    //ok
//                [theWebView underlineAllOccurencesOfString:noteContent];  // 需要 js 调试
            }
            
        }
 
        //页码内跳转
        [self gotoOffYInPageWithOffYIndex:self.offYIndexInPage WithOffCountInPage:currentOffCountInPage];
        
        self.epubVC.currentOffYIndexInPage=self.offYIndexInPage;
    }
    
    
}

-(int)gotoOffYInPageWithOffYIndex:(NSInteger)offyIndex WithOffCountInPage:(NSInteger)offCountInPage
{
    //页码内跳转
    if(offyIndex >= offCountInPage)
    {
        offyIndex = offCountInPage - 1;
    }
    
    
    float pageOffset = offyIndex*self.pageWebView.bounds.size.width;
    
    //NSString* goToOffsetFunc = [NSString stringWithFormat:@" function pageScroll(yOffset){ window.scroll(yOffset,0); } "];
    NSString* goToOffsetFunc = [NSString stringWithFormat:@" function pageScroll(xOffset){ window.scroll(xOffset,0); } "];
    NSString* goTo =[NSString stringWithFormat:@"pageScroll(%f)", pageOffset];
    
    [self.pageWebView stringByEvaluatingJavaScriptFromString:goToOffsetFunc];
    [self.pageWebView stringByEvaluatingJavaScriptFromString:goTo];
    
    
    //背景主题
    //NSString *bodycolor= [NSString stringWithFormat:@"addCSSRule('body', 'background-color: #f6e5c3;')"];
    NSString *themeBodyColor=[self.epubVC.arrTheme[self.epubVC.themeIndex] objectForKey:@"bodycolor"];
    NSString *bodycolor= [NSString stringWithFormat:@"addCSSRule('body', 'background-color: %@;')",themeBodyColor];
    [self.pageWebView stringByEvaluatingJavaScriptFromString:bodycolor];
    
    //NSString *textcolor1=[NSString stringWithFormat:@"addCSSRule('h1', 'color: #ffffff;')"];
    NSString *themeTextColor=[self.epubVC.arrTheme[self.epubVC.themeIndex] objectForKey:@"textcolor"];
    NSString *textcolor1=[NSString stringWithFormat:@"addCSSRule('h1', 'color: %@;')",themeTextColor];
    [self.pageWebView stringByEvaluatingJavaScriptFromString:textcolor1];
    
    //NSString *textcolor2=[NSString stringWithFormat:@"addCSSRule('p', 'color: #ffffff;')"];
    NSString *textcolor2=[NSString stringWithFormat:@"addCSSRule('p', 'color: %@;')",themeTextColor];
    [self.pageWebView stringByEvaluatingJavaScriptFromString:textcolor2];

    //刷新显示文本
    [self refresh];
//
//    //刷新 epubVC Head,Foot
//    [self.epubVC refreshChapterLabel];
    
    return 1;
}

-(id)getContentFromPoint:(CGPoint)pt1
{
    //得到 webview点击位置的内容
    id ret=nil;
    
    //int scrollPositionY = [[self.pageWebView stringByEvaluatingJavaScriptFromString:@"window.pageYOffset"] intValue];
    //int scrollPositionX = [[self.pageWebView stringByEvaluatingJavaScriptFromString:@"window.pageXOffset"] intValue];
    
    //int displayWidth = [[self.pageWebView stringByEvaluatingJavaScriptFromString:@"window.outerWidth"] intValue];
    //CGFloat scale = self.pageWebView.frame.size.width / displayWidth;
    
    //CGPoint pt = [sender locationInView:self.theWebView];
    CGPoint pt =pt1;
    //pt.x += scrollPositionX;
    //pt.y += scrollPositionY;
    
    NSString *js = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).tagName", pt.x, pt.y];
    
    NSString * tagName = [self.pageWebView stringByEvaluatingJavaScriptFromString:js];
    //NSLog(@"tagName=%@, pt=%@",tagName,NSStringFromCGPoint(pt));
    
    if ([[tagName uppercaseString] isEqualToString:@"IMG"])
    {
        NSString *imgURL = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src", pt.x, pt.y];
        NSString *fileURLString = [self.pageWebView stringByEvaluatingJavaScriptFromString:imgURL];
        NSString *fileFullPath=[fileURLString  stringByReplacingOccurrencesOfString:@"file://" withString:@"" ];
        
        //含有 “％” 会再次转码
        //NSString *fileFullPath2=[fileFullPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        //把含有 "%编码" 转成中文
        NSString *fileFullPath2=[fileFullPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];  //ok 解决中文路径
        //        NSString *fileFullPath2 =[fileFullPath URLDecodedString];   //ok 解决中文路径
        //        NSString *fileFullPath3=[fileFullPath2 stringByReplacingOccurrencesOfString:@"%20" withString:@" " ];
        
        if ([self.epubVC isFileExist:fileFullPath2]) {
            ret=fileFullPath2;
        }
    }
    
    return ret;
}
-(void)addNote:(NSString*)noteContent
{
    //加入笔记
    NSMutableDictionary *item1=[NSMutableDictionary dictionary];
    
    [item1 setObject:[NSString stringWithFormat:@"%@",@(self.pageRefIndex)] forKey:@"PageRefIndex"];
    [item1 setObject:[NSString stringWithFormat:@"%@",@(self.offYIndexInPage)] forKey:@"OffYIndexInPage"];
    [item1 setObject:noteContent forKey:@"NoteContent"];
    
    [self.epubVC.arrNotes addObject:item1];
    
    //需要刷新页面
    [self.epubVC refreshPageViewController];
}

@end
