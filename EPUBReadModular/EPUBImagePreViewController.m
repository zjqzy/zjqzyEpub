//
//  CImagePreViewController.m
//  CAJViewer
//
//  Created by zhu on 14-3-28.
//  Copyright (c) 2014年 zhu. All rights reserved.
//

#import "EPUBReadMainViewController.h"
#import "EPUBImagePreViewController.h"

enum {
    //主要功能tag
	//! Default tag
    IMAGEPREVIEW_BACK=221,
    
};



@interface EPUBImagePreViewController ()

@end

@implementation EPUBImagePreViewController

-(void)dealloc
{
    //析构
    
    self.backBlock=nil;
    self.info=nil;
    self.image=nil;
    self.imgView=nil;
    self.scrollView=nil;
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
    
#ifdef DEBUG
    NSLog(@"析构  EPUBImagePreViewController");
#endif
    
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self dataPrepare];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self customViewInit:self.view.bounds];
    
    [self GestureRecognizerTapAddInView:self.view]; //添加手势

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [self initAfter];

        [NSThread sleepForTimeInterval:0.2f];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self refresh];
            
        });
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
////////////////////////////////////////////////////////////////////////////////
///////////////////      旋转       ///////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)shouldAutorotate NS_AVAILABLE_IOS(6_0)
{
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations NS_AVAILABLE_IOS(6_0)
{
    return UIInterfaceOrientationMaskAll;
}

//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation NS_AVAILABLE_IOS(6_0)
//{
//#ifdef DEBUG
//    NSLog(@"偏好 %s",__FUNCTION__);
//#endif
//    return UIInterfaceOrientationPortrait;
//    //return UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight;
//}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
#ifdef DEBUG
    NSLog(@"设备旋转后触发 %s",__FUNCTION__);
#endif
    
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
#ifdef DEBUG
    NSLog(@"设备旋转前触发 %s",__FUNCTION__);
#endif
    
}
////////////////////////////////////////////////////////////////////////
/////////////////// 界面 初始化 相关   ///////////////////////////
////////////////////////////////////////////////////////////////////////
-(void)customViewInit:(CGRect)viewRect
{
    //创建
    
    _headView=[[UIView alloc] init];
    [self.view addSubview:_headView];
    _headView.backgroundColor=[UIColor grayColor];
    
    if (_headView)
    {
        //
        //        self.btnBack=[UIButton buttonWithType:UIButtonTypeCustom];
        //        self.btnBack.tag=MOVIE_BACK;
        //        [self.btnBack addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        //        [_headView addSubview:self.btnBack];
        //        self.btnBack.backgroundColor=gObj.buttonBackgroundColorNormal;
        //        [self.btnBack setTitleColor:gObj.buttonTextColorNormal forState:UIControlStateNormal];
        //        [self.btnBack setTitle:NSLocalizedString(@"Back", @"") forState:UIControlStateNormal];
        //        self.btnBack.contentVerticalAlignment=UIControlContentVerticalAlignmentCenter;
        
    }
    
    _contentView=[[UIView alloc] init];
    [self.view addSubview:_contentView];
    //_contentView.backgroundColor=gObj.contentViewBackgroundColorNormal;
    _contentView.backgroundColor=[UIColor blackColor];
    
    if (_contentView)
    {
        _scrollView=[[UIScrollView alloc] init];
        _scrollView.backgroundColor=[UIColor clearColor];
        _scrollView.showsHorizontalScrollIndicator=YES;
        _scrollView.showsVerticalScrollIndicator=YES;
        _scrollView.bounces=YES;   //滑动反弹
        _scrollView.bouncesZoom=YES;   //缩放反弹
        _scrollView.maximumZoomScale=4.0f;
        _scrollView.minimumZoomScale=1.0f;
        _scrollView.delaysContentTouches=YES; //事件直接传递subviews,否则150ms等待判断
        _scrollView.delegate=self;   //自己处理
        _scrollView.scrollsToTop=NO;
        
        [_contentView addSubview:_scrollView];
        
        if (_scrollView) {
            
            _imgView=[[UIImageView alloc] init];
            _imgView.backgroundColor=[UIColor clearColor];
            _imgView.contentMode=UIViewContentModeScaleAspectFit;
            [_scrollView addSubview:_imgView];
            
        }
    }

}

-(void)resizeViews:(CGRect)viewRect
{
    //布局
    if (viewRect.size.width < 1 || viewRect.size.height <1) {
        return;
    }
    
    CGRect rectHead=viewRect;
    rectHead.size.height=0.0f;
    _headView.frame=rectHead;
    if (_headView)
    {
        //        int leftPadding=10;
        //        //int offx=10;
        //        CGSize btnSize=CGSizeMake(80, 40);
        //        float fontSize=14.0f;
        //        if (gDevice.isPhone)
        //        {
        //
        //            //offx=2;
        //            btnSize=CGSizeMake(60, 40);
        //            fontSize=12.0f;
        //        }
        //
        //        CGRect rect1=CGRectMake(leftPadding,20, btnSize.width,btnSize.height);
        //        self.btnBack.frame=rect1;
        //        self.btnBack.titleLabel.font=[UIFont boldSystemFontOfSize:fontSize];
    }
    
    CGRect rectContent=viewRect;
    rectContent.origin.y=rectHead.origin.y+rectHead.size.height;
    rectContent.size.height=viewRect.size.height-rectContent.origin.y;
    _contentView.frame=rectContent;
    if (_contentView)
    {
        CGRect rectContentBound=_contentView.bounds;
        _scrollView.frame=rectContentBound;
        _imgView.frame=_scrollView.bounds;
    }

}
-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self resizeViews:self.view.bounds];
}
-(void)dataPrepare
{
    //数据
    _image=nil;
}
-(void)initAfter
{
    //后续初始化
    NSString *imgFileFullPath=[self.info objectForKey:@"imgFileFullPath"];
    if (imgFileFullPath && [self.epubVC isFileExist:imgFileFullPath]) {
        UIImage *img1=[[UIImage alloc] initWithContentsOfFile:imgFileFullPath];
        if (img1)
        {
            self.image=img1;
        }
    }
}
-(void)refresh
{
    //刷新
    if (self.image && self.imgView)
    {
        self.imgView.contentMode=UIViewContentModeScaleAspectFit;
        
        {
            CGSize imgSize=[self.image size];
            CGSize viewSize=self.imgView.frame.size;
            if (imgSize.height < viewSize.height && imgSize.width < viewSize.width) {
                self.imgView.contentMode=UIViewContentModeCenter;
            }
        }
        
        self.imgView.image=self.image;
        
    }
}
////////////////////////////////////////////////////////////////////////
/////////////////// UIScrollView delegate ///////////////////////////
///////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIScrollView delegate methods
#pragma mark -
-(void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    
}
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return self.imgView;
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    // any zoom scale changes
    
}
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{    
    [self.imgView setNeedsDisplay];
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{    
    //开始滚动时
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //滚动进行时    
}
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //结束翻页标签
    
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self scrollViewDidEndDecelerating:scrollView];
    }
}
////////////////////////////////////////////////////////////////////////////////
///////////////////      其他          //////////////////////
////////////////////////////////////////////////////////////////////////////////
-(void)GestureRecognizerTapAddInView:(UIView*)inView
{
    //手势添加或移出   手势种类见博客
    
    UITapGestureRecognizer *gestureDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doTap:)];
    gestureDoubleTap.numberOfTouchesRequired = 1;
    gestureDoubleTap.numberOfTapsRequired = 2;

    UITapGestureRecognizer *gestureSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doTap:)];
    gestureSingleTap.numberOfTouchesRequired = 1;
    gestureSingleTap.numberOfTapsRequired = 1;
    [gestureSingleTap requireGestureRecognizerToFail:gestureDoubleTap];
    
    [inView addGestureRecognizer:gestureSingleTap];   //其后的子View里的btn不响应了
    [inView addGestureRecognizer:gestureDoubleTap];
    

    UIRotationGestureRecognizer *gestureRotate = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(doRotate:)];    
    [inView addGestureRecognizer:gestureRotate];
    
    
#if !__has_feature(objc_arc)
    [gestureSingleTap release];
    [gestureDoubleTap release];
    [gestureRotate release];
#endif

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
        //CGPoint ptLocation=[recognizer locationInView:self.view];
        
        self.scrollView.transform=CGAffineTransformIdentity;
        self.scrollView.zoomScale=1.0f;
    }
}
- (void) doubleTaped:(UITapGestureRecognizer *)recognizer
{
    //双击
    //手指坐标
    if (recognizer.state == UIGestureRecognizerStateRecognized)
	{
        //CGPoint pt = [recognizer locationInView:self.pageView.pageWebView];
        if (self.backBlock) {
            self.backBlock(nil);
        }
    }
}
-(void)doRotate:(UIRotationGestureRecognizer*)recognizer
{
    self.scrollView.transform=CGAffineTransformRotate(self.scrollView.transform, recognizer.rotation);
    recognizer.rotation=0;
}

@end
