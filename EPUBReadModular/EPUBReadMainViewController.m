//
//  EPUBReadMainViewController.m
//  CommonReader
//
//  Created by fanzhenhua on 15/6/30.
//  Copyright (c) 2015年 zjqzy. All rights reserved.
//
#import <CommonCrypto/CommonDigest.h>   //算法 md5
#import <CoreText/CoreText.h>

#import "MBProgressHUD.h"
#import "GDataXMLNode.h"

#import "EPUBParser.h"

#import "EPUBReadMainViewController.h"
#import "EPUBPageViewController.h"
#import "EPUBPageWebView.h"
#import "EPUBPageProgressView.h"
#import "EPUBPageOptionView.h"
#import "EPUBPageOptionMoreViewController.h"
#import "EPUBPageCatalogViewController.h"
#import "EPUBFileInfoViewController.h"
#import "EPUBFontViewController.h"
#import "EPUBImagePreViewController.h"
#import "EPUBPageSearchTextViewController.h"

typedef NS_ENUM(NSInteger, EPUBREADBUTTONTAG)
{
    READ_BUTTON_BACK=200,
    READ_BUTTON_CATALOG,
    READ_BUTTON_PROGRESS,
    READ_BUTTON_OPTION,
    READ_BUTTON_FILEINFO,
    READ_BUTTON_SEARCH,
    READ_BUTTON_STYLE2,
};

@interface EPUBReadMainViewController ()<MBProgressHUDDelegate,UIPageViewControllerDataSource,UIPageViewControllerDelegate>
{
    int m_imageEdgeInset;   //uibutton 显示图片的缩进
    int m_initALLFinished;  //是否初始化操作完成， 不管成功还是失败
    MBProgressHUD *m_msg;     //消息
    
    NSTimeInterval m_readStartTime; //阅读累计
    
    UIPageViewControllerTransitionStyle m_pageViewTransitionStyle;    //显示样式
    UIPageViewControllerNavigationOrientation m_pageViewNavigationOrientation; //显示样式
    
}
////////////////////////////////////////////////////////////////////////////////
/////////////////   数据   /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic,strong) NSString *manifestFilePath;//epub 核心文件
@property (nonatomic,strong) NSString *opfFilePath;     //epub 核心文件
@property (nonatomic,strong) NSString *ncxFilePath;     //epub 核心文件


@property (nonatomic) NSInteger textSizeMax;                  //支持文字大小
@property (nonatomic) NSInteger textSizeMin;                  //支持文字大小
@property (nonatomic) NSInteger stepTextSize;                 //文字大小步长
@property (nonatomic,strong) NSString *currentTextFontName;    //字体名称

@property (nonatomic,strong) NSTimer *timerTime;  //以时间为准的状态刷新 ，默认 60s 一次

////////////////////////////////////////////////////////////////////////////////
/////////////////   界面    /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@property (nonatomic,strong) UIView *headView;          // in self.view
@property (nonatomic,strong) UIView *footView;          // in self.view
@property (nonatomic,strong) UIView *contentView;       // in self.view

@property (nonatomic,strong) UIPageViewController * pageViewController;

@property (nonatomic,strong) EPUBPageProgressView *progressView;  //进度 in self.view
@property (nonatomic,strong) EPUBPageOptionView *optionView;    //设置 in self.view

//button  上下工具栏
@property (nonatomic,strong) UIButton *btnBack;        //返回
@property (nonatomic,strong) UIButton *btnCatalog;     //目录
@property (nonatomic,strong) UIButton *btnProgress;    //进度
@property (nonatomic,strong) UIButton *btnOption;      //设置
@property (nonatomic,strong) UIButton *btnOptionMore;  //更多设置

@property (nonatomic,strong) UIButton *btnFileInfo;    //文件信息
@property (nonatomic,strong) UIButton *btnSearch;      //全文搜索
@property (nonatomic,strong) UIButton *btnStyle2;      //样式2


-(void)customViewInit:(CGRect)viewRect;     //创建
-(void)resizeViews:(CGRect)viewRect;        //布局
-(void)dataPrepare;                         //数据
-(void)initAfter;                           //线程初始化

-(void)addSomeObserver;     //监听
-(void)removeSomeObserver;  //监听

-(int)checkLicence; //检查SDK是否过期
-(NSString*)checkInputs;  //检查输入 , 返回不合格信息

-(void)showPageViewController;

-(void)backDocument;    //文档返回

-(void)btnClick:(id)sender; //上下工具栏响应

@end

@implementation EPUBReadMainViewController
-(void)dealloc
{
    //析构

    self.epubReadBackBlock=nil;
    self.fileInfo=nil;

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
    
#ifdef DEBUG
    NSLog(@"析构 EPUBReadMainViewController");
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
    

    //背景
    //self.view.backgroundColor=[UIColor blackColor];
    self.view.backgroundColor=[UIColor colorWithRed:0.81 green:0.81 blue:0.81 alpha:1.0];
    
    //监视
    [self addSomeObserver];
    
    [self customFontAdd];
    
    __weak typeof(self) _weakself = self;
    
    //界面
    [self customViewInit:self.view.bounds];
    
    
    //检查输入， 不符合的话，提示并退出
    NSString *checkMsg=[self checkInputs];
    if ([checkMsg length] >1)
    {
        [self showMsgInView:self.view ContentString:checkMsg isActivity:NO HideAfter:2.0];
        m_initALLFinished=1;
        return;
    }
    
    //后续初始化
    self.view.userInteractionEnabled=NO;
    [self showMsgInView:self.view ContentString:NSLocalizedString(@"Loading...", @"Loading...") isActivity:YES HideAfter:0.0];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [_weakself initAfter];
        
        [NSThread sleepForTimeInterval:0.5f];
        //sleep(1);
        //刷新
        dispatch_async(dispatch_get_main_queue(), ^{
            
            m_initALLFinished=1;
            
            [_weakself closeMsg];
            
            [_weakself showPageViewController];
            
            [_weakself refresh];     //刷新显示页码数据等
            

            _weakself.view.userInteractionEnabled=YES;
            
            [_weakself performSelector:@selector(showOrHideHeadAndFoot) withObject:nil afterDelay:1.0f];
            
            [_weakself startTimerTime];
        });
    });

}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //需要设置info.plist里的 View controller-based status bar appearance 设为NO
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //需要设置info.plist里的 View controller-based status bar appearance 设为NO
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
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

////////////////////////////////////////////////////////////////////////////////
//////////////     life circle   界面 相关  ////////// ///////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - life circle
-(void)customFontAdd
{
    NSString *path1=[self fileFindFullPathWithFileName:@"DFPShaoNvW5.ttf" InDirectory:nil];
    self.fontCustom1 = [self customFontWithPath:path1 size:14.0f];
}
-(void)customFontRemove
{
    NSString *path1=[self fileFindFullPathWithFileName:@"DFPShaoNvW5.ttf" InDirectory:nil];
    [self UnRegisterCustomFont:path1];
}
-(void)customViewInit:(CGRect)viewRect
{
    //创建
    
    //
    _maskLightView=[UIView new];
    _maskLightView.backgroundColor=[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:_maskValue];
    _maskLightView.userInteractionEnabled=NO;
    [self.view addSubview:_maskLightView];
    
    //进度
    _progressView=[[EPUBPageProgressView alloc] init];
    _progressView.epubVC=self;
    _progressView.backgroundColor=[UIColor blackColor];

    _progressView.hidden=YES;
    [self.view addSubview:_progressView];
    
    //设置
    _optionView=[[EPUBPageOptionView alloc] init];
    _optionView.epubVC=self;
    _optionView.backgroundColor=[UIColor blackColor];
    _optionView.hidden=YES;
    [_optionView initAfter];
    [self.view addSubview:_optionView];
    
    //上方工具栏
    _headView =[[UIView alloc] init];
    [self.view addSubview:_headView];
    _headView.backgroundColor=[UIColor blackColor];
    if (_headView)
    {
        //返回
        self.btnBack=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnBack.tag=READ_BUTTON_BACK;
        [self.btnBack addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_headView addSubview:self.btnBack];
        {
            NSString *path1=[self fileFindFullPathWithFileName:@"epub_button_back.png" InDirectory:@"epub.bundle"];
            if (path1)
            {
                UIImage *imgButton=[[UIImage alloc] initWithContentsOfFile:path1];
                
                self.btnBack.imageView.contentMode=UIViewContentModeScaleAspectFit;
                //self.btnBack.showsTouchWhenHighlighted=YES; //如果用图片显示，则写此句效果不好
                [self.btnBack setImage:imgButton forState:UIControlStateNormal];
                [self.btnBack setImage:imgButton forState:UIControlStateHighlighted];
                self.btnBack.imageEdgeInsets = UIEdgeInsetsMake(m_imageEdgeInset,0,m_imageEdgeInset,0);
            }
            else
            {
                [self.btnBack setTitle:NSLocalizedString(@"Back", @"") forState:UIControlStateNormal];
            }
        }

        //
        self.btnSearch=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnSearch.tag=READ_BUTTON_SEARCH;
        [self.btnSearch addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_headView addSubview:self.btnSearch];
//        self.btnSearch.titleLabel.font=[UIFont systemFontOfSize:10.0f];
//        [self.btnSearch setTitle:NSLocalizedString(@"全文搜索", @"") forState:UIControlStateNormal];
        {
            NSString *path1=[self fileFindFullPathWithFileName:@"epub_button_search.png" InDirectory:@"epub.bundle"];
            if (path1)
            {
                UIImage *imgButton=[[UIImage alloc] initWithContentsOfFile:path1];
                
                self.btnSearch.imageView.contentMode=UIViewContentModeScaleAspectFit;
                //self.btnBack.showsTouchWhenHighlighted=YES; //如果用图片显示，则写此句效果不好
                [self.btnSearch setImage:imgButton forState:UIControlStateNormal];
                [self.btnSearch setImage:imgButton forState:UIControlStateHighlighted];
                
//                self.btnSearch.imageEdgeInsets = UIEdgeInsetsMake(0,0,20,0);
//                [self.btnSearch setTitleEdgeInsets:UIEdgeInsetsMake(20,-60,0,0)];
                
            }
        }

        //
        self.btnFileInfo=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnFileInfo.tag=READ_BUTTON_FILEINFO;
        [self.btnFileInfo addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_headView addSubview:self.btnFileInfo];
        [self.btnFileInfo setTitle:NSLocalizedString(@"i", @"") forState:UIControlStateNormal];
        
        //
        self.btnStyle2=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnStyle2.tag=READ_BUTTON_STYLE2;
        [self.btnStyle2 addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_headView addSubview:self.btnStyle2];
        [self.btnStyle2 setTitle:NSLocalizedString(@"测试2", @"") forState:UIControlStateNormal];
        [self.btnStyle2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.btnStyle2.titleLabel.font=self.fontCustom1;
        self.btnStyle2.hidden=YES;
     }
    
    //下方工具栏
    _footView=[[UIView alloc] init];
    [self.view addSubview:_footView];
    _footView.backgroundColor=[UIColor blackColor];
    if (_footView)
    {
        //目录
        self.btnCatalog=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnCatalog.tag=READ_BUTTON_CATALOG;
        [self.btnCatalog addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_footView addSubview:self.btnCatalog];
        self.btnCatalog.titleLabel.font=[UIFont systemFontOfSize:10.0f];
        [self.btnCatalog setTitle:NSLocalizedString(@"目录", @"") forState:UIControlStateNormal];
        {
            NSString *path1=[self fileFindFullPathWithFileName:@"epub_button_catalog.png" InDirectory:@"epub.bundle"];
            if (path1)
            {
                UIImage *imgButton=[[UIImage alloc] initWithContentsOfFile:path1];
                
                self.btnCatalog.imageView.contentMode=UIViewContentModeScaleAspectFit;
                //self.btnBack.showsTouchWhenHighlighted=YES; //如果用图片显示，则写此句效果不好
                [self.btnCatalog setImage:imgButton forState:UIControlStateNormal];
                [self.btnCatalog setImage:imgButton forState:UIControlStateHighlighted];

                self.btnCatalog.imageEdgeInsets = UIEdgeInsetsMake(0,0,20,0);
                [self.btnCatalog setTitleEdgeInsets:UIEdgeInsetsMake(20,-40,0,0)];

            }
        }
        
        //进度
        self.btnProgress=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnProgress.tag=READ_BUTTON_PROGRESS;
        [self.btnProgress addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_footView addSubview:self.btnProgress];
        self.btnProgress.titleLabel.font=[UIFont systemFontOfSize:10.0f];
        [self.btnProgress setTitle:NSLocalizedString(@"进度", @"") forState:UIControlStateNormal];
        {
            NSString *path1=[self fileFindFullPathWithFileName:@"epub_button_progress.png" InDirectory:@"epub.bundle"];
            if (path1)
            {
                UIImage *imgButton=[[UIImage alloc] initWithContentsOfFile:path1];
                
                self.btnProgress.imageView.contentMode=UIViewContentModeScaleAspectFit;
                //self.btnBack.showsTouchWhenHighlighted=YES; //如果用图片显示，则写此句效果不好
                [self.btnProgress setImage:imgButton forState:UIControlStateNormal];
                [self.btnProgress setImage:imgButton forState:UIControlStateHighlighted];

                self.btnProgress.imageEdgeInsets = UIEdgeInsetsMake(0,0,20,0);
                [self.btnProgress setTitleEdgeInsets:UIEdgeInsetsMake(20,-40,0,0)];
                
            }
        }
        
        //目录
        self.btnOption=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnOption.tag=READ_BUTTON_OPTION;
        [self.btnOption addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_footView addSubview:self.btnOption];
        self.btnOption.titleLabel.font=[UIFont systemFontOfSize:10.0f];
        [self.btnOption setTitle:NSLocalizedString(@"设置", @"") forState:UIControlStateNormal];
        
        {
            NSString *path1=[self fileFindFullPathWithFileName:@"epub_button_option.png" InDirectory:@"epub.bundle"];
            if (path1)
            {
                UIImage *imgButton=[[UIImage alloc] initWithContentsOfFile:path1];
                
                self.btnOption.imageView.contentMode=UIViewContentModeScaleAspectFit;
                //self.btnOption.showsTouchWhenHighlighted=YES; //效果 还行
                [self.btnOption setImage:imgButton forState:UIControlStateNormal];
                [self.btnOption setImage:imgButton forState:UIControlStateHighlighted];
                

                self.btnOption.imageEdgeInsets = UIEdgeInsetsMake(0,0,20,0);
                [self.btnOption setTitleEdgeInsets:UIEdgeInsetsMake(20,-40,0,0)];
                
            }
        }
    }
    
    //内容
    _contentView=[[UIView alloc] init];
    [self.view addSubview:_contentView];
    _contentView.backgroundColor=[UIColor clearColor];
    [self.view sendSubviewToBack:_contentView];
    if (_contentView)
    {

    }



}

-(void)resizeViews:(CGRect)viewRect
{
    //整体界面调整
    
    if (viewRect.size.width<1 || viewRect.size.height<1) {
        return;
    }
    
    _maskLightView.frame=viewRect;
    
    int statusBarHeight=20; //iphone ,ipad  statusBar都是20
    float viewHeight=64.0f; // 20+ 44.0
    
    CGRect rectHead=viewRect;
    rectHead.size.height=viewHeight;
    _headView.frame=rectHead;
    //
    if (_headView)
    {
        CGSize btnSize=CGSizeMake(60, 40);
        int offx=20;
        int offy=(rectHead.size.height-btnSize.height-statusBarHeight)/2;// 为了排除 statusBar
        
        if (_isPhone) {
            offx=5;
            btnSize=CGSizeMake(60, 40);
        }
        
        CGRect rectLast = CGRectMake(rectHead.size.width-btnSize.width-offx,offy+statusBarHeight,btnSize.width,btnSize.height);//offy加statusBarHeight 是为了排除 statusBar
        self.btnSearch.frame=rectLast;
        
        CGRect rectLast2=rectLast;
        rectLast2.origin.x=rectLast.origin.x-rectLast2.size.width -offx;
        self.btnFileInfo.frame=rectLast2;
        
        CGRect rectLast3=rectLast2;
        rectLast3.origin.x=rectLast2.origin.x-rectLast3.size.width -offx;
        self.btnStyle2.frame=rectLast3;
        
        CGRect rectFirst=rectLast;
        rectFirst.origin.x=offx;
        self.btnBack.frame=rectFirst;
        
    }

    //
    CGRect rectFoot=CGRectMake(0, 0, viewRect.size.width, 54.0f);
    rectFoot.origin.y=self.view.bounds.size.height-rectFoot.size.height;
    _footView.frame=rectFoot;
    if (_footView)
    {
        CGSize btnSize=CGSizeMake(44, 44);
        int offx=40;

        
        CGRect rectLast = CGRectMake(rectFoot.size.width-btnSize.width-offx,5,btnSize.width,btnSize.height);
        self.btnOption.frame=rectLast;

        
        CGRect rectFirst=rectLast;
        rectFirst.origin.x=offx;
        self.btnCatalog.frame=rectFirst;
        
        
        CGRect rectMid=rectLast;
        int mid1=rectLast.origin.x-(rectFirst.origin.x+ rectFirst.size.width);
        
        rectMid.origin.x=rectFirst.origin.x+ rectFirst.size.width + (mid1-rectMid.size.width)*0.5f;
        self.btnProgress.frame=rectMid;

    }
    
    //
    _contentView.frame=viewRect;
    if (_contentView)
    {
        CGRect rectContent=_contentView.bounds;
        _pageViewController.view.frame=rectContent;

 
    }
    
    //
    _progressView.frame=rectFoot;
    
    //
    CGRect rectOptopm=rectFoot;
    rectOptopm.size.height=240.0f;
    rectOptopm.origin.y=viewRect.size.height -rectOptopm.size.height;
    _optionView.frame=rectOptopm;

#ifdef DEBUG
    NSLog(@"epubRead界面重新布局");
#endif
    
}
-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self resizeViews:self.view.bounds];
}
-(void)dataPrepare
{
    //用户设置属性
    m_initALLFinished=0;
    m_imageEdgeInset=_isPhone?8:5;
    
    //开始阅读时间，用于累计阅读时间
    m_readStartTime = [NSDate timeIntervalSinceReferenceDate];
    
    //m_Style=UIPageViewControllerTransitionStyleScroll;
    m_pageViewTransitionStyle=UIPageViewControllerTransitionStylePageCurl;
    m_pageViewNavigationOrientation=UIPageViewControllerNavigationOrientationHorizontal;
    
    //
    _isPhone=[UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 1 : 0 ;

    //
    _textSizeMax=38;
    _textSizeMin=12;
    _stepTextSize=2;
    _currentTextSize = _isPhone?18:22;

    _currentTextFontName=[[NSString alloc] initWithFormat:@"%@",@"Helvetica"];
    
    _currentPageRefIndex=0;         //当前页码索引
    _currentOffYIndexInPage=0;      //当前页码  滚动索引
    
    _dictPageWithOffYCount=[NSMutableDictionary new];
    
    _themeIndex=2;
    _arrTheme= [[NSMutableArray alloc] init];
    [self loadEpubTheme];

    
    _maskValue=0;
    
    //笔记
    _arrNotes=[[NSMutableArray alloc] init];
    
    //全文检索
    _arrSearchResult=[[NSMutableArray alloc] init];
    _currentSearchText=@"";
    
    //
    _fontSelectIndex=0;
    _arrFont=[[NSMutableArray alloc] init];
    {
        NSMutableDictionary *fontItem=[NSMutableDictionary dictionary];
        [fontItem setObject:@"0" forKey:@"type"];   // 0 系统自带 ， 1 为 custom
        [fontItem setObject:NSLocalizedString(@"系统字体", @"") forKey:@"name"];
        [fontItem setObject:@"Helvetica" forKey:@"fontName"];
        
        [_arrFont addObject:fontItem];
    }
    {
        NSMutableDictionary *fontItem=[NSMutableDictionary dictionary];
        [fontItem setObject:@"1" forKey:@"type"];   // 0 系统自带 ， 1 为 custom
        [fontItem setObject:NSLocalizedString(@"华康少女体", @"") forKey:@"name"];
        [fontItem setObject:@"DFPShaoNvW5" forKey:@"fontName"];
        [fontItem setObject:@"DFPShaoNvW5.ttf" forKey:@"fontFile"];
        [_arrFont addObject:fontItem];
    }
    
    //
//    NSString *js1=@"<style>img {  max-width:100% ; }</style>\n";
//    NSArray *arrJs2=@[@"<script>"
//                      ,@"var mySheet = document.styleSheets[0];"
//                      ,@"function addCSSRule(selector, newRule){"
//                      ,@"if (mySheet.addRule){"
//                      ,@"mySheet.addRule(selector, newRule);"
//                      ,@"} else {"
//                      ,@"ruleIndex = mySheet.cssRules.length;"
//                      ,@"mySheet.insertRule(selector + '{' + newRule + ';}', ruleIndex);"
//                      ,@"}"
//                      ,@"}"
//                      ,@"addCSSRule('p', 'text-align: justify;');"
//                      ,@"addCSSRule('highlight', 'background-color: yellow;');"
//                      //,@"addCSSRule('body', '-webkit-text-size-adjust: 100%; font-size:10px;');"
//                      ,@"addCSSRule('body', ' font-size:18px;');"
//                      ,@"addCSSRule('body', ' margin:2.2em 5%% 0 5%%;');"   //上，右，下，左 顺时针
//                      ,@"addCSSRule('html', 'padding: 0px; height: 480px; -webkit-column-gap: 0px; -webkit-column-width: 320px;');"
//                      ,@"</script>"];
//    
//    NSString *js2=[arrJs2 componentsJoinedByString:@"\n"];
//    self.jsContent=[NSString stringWithFormat:@"%@\n%@",js1,js2];


}

-(void)initAfter
{
    //后续初始化
    __weak typeof(self) _weakself = self;
    //文档
    if (self.fileInfo)
    {

        //文档读取
        NSString *fileFullPath=[self.fileInfo objectForKey:@"fileFullPath"];
        NSString *fileName=[[fileFullPath lastPathComponent] stringByDeletingPathExtension];
        if ( !_unzipEpubFolder || [_unzipEpubFolder length] <2)
        {
            NSString *libraryPath = [NSHomeDirectory() stringByAppendingPathComponent:  @"Library"];
            NSString *cachesPath=[libraryPath stringByAppendingPathComponent:@"Caches"];
            NSString *epubCachePath=[cachesPath stringByAppendingPathComponent:@"epubcache"];
            self.unzipEpubFolder=[NSString stringWithFormat:@"%@/%@",epubCachePath,fileName];
            [self createDirectory:_unzipEpubFolder];
        }
        
        self.manifestFilePath =[NSString stringWithFormat:@"%@/META-INF/container.xml", _unzipEpubFolder];
        
        int openSuccess=1;
        if ( ! [self isFileExist:self.manifestFilePath]) {
            openSuccess=[self.epubParser openFilePath:fileFullPath WithUnzipFolder:_unzipEpubFolder];
        }
        if (openSuccess<1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_weakself showMsgInView:self.view ContentString:@"文件open失败" isActivity:NO HideAfter:3.0];
            });
            return;
        }
        
        
        self.opfFilePath=[self.epubParser opfFilePathWithManifestFile:self.manifestFilePath WithUnzipFolder:_unzipEpubFolder];
        
        self.ncxFilePath=[self.epubParser ncxFilePathWithOpfFile:self.opfFilePath WithUnzipFolder:_unzipEpubFolder];

        //NSString *coverFile=[self.epubParser coverFilePathWithOpfFile:self.opfFilePath WithUnzipFolder:_unzipEpubFolder]; //ok
        
        //基本信息
        self.epubInfo=[self.epubParser epubFileInfoWithOpfFile:self.opfFilePath];
        
        //目录信息
        self.epubCatalogs=[self.epubParser epubCatalogWithNcxFile:self.ncxFilePath];

        //页码索引
        self.epubPageRefs=[self.epubParser epubPageRefWithOpfFile:self.opfFilePath];
        
        //页码信息
        self.epubPageItems=[self.epubParser epubPageItemWithOpfFile:self.opfFilePath];

    }
    else
    {
        //没有文档信息, 应该无运行到这里
#ifdef DEBUG
        NSLog(@" epubVC  没有文档信息,传参有问题");
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            [_weakself showMsgInView:self.view ContentString:@"没有文档信息,传参有问题" isActivity:NO HideAfter:3.0];
        });
    }
}
-(void)addSomeObserver
{
    [self addObserver:self forKeyPath:@"currentPageRefIndex" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"displayStyle" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    //[self addObserver:self forKeyPath:@"view.bounds" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"view.frame" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    //[self addObserver:self forKeyPath:@"showViews.frame" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];  //没有监听到, 可能 showViews.frame 不是key
    
}
-(void)removeSomeObserver
{
    [self removeObserver:self forKeyPath:@"currentPageRefIndex"];
    [self removeObserver:self forKeyPath:@"displayStyle"];
    //[self removeObserver:self forKeyPath:@"view.bounds"];
    [self removeObserver:self forKeyPath:@"view.frame"];
    //[self removeObserver:self forKeyPath:@"showViews.frame"];
    
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    if([keyPath isEqualToString:@"view.bounds"])
    {
        
        CGRect old=[[change objectForKey:@"old"] CGRectValue];
        CGRect new=[[change objectForKey:@"new"] CGRectValue];
        if (! CGRectEqualToRect(old, new))
        {
#ifdef DEBUG
            NSLog(@"bounds=%@,frame=%@",NSStringFromCGRect(self.view.bounds),NSStringFromCGRect(self.view.frame));
#endif
            [self resizeViews:self.view.bounds];    //ok
        }
    }
    else if([keyPath isEqualToString:@"view.frame"])
    {
        
        CGRect old=[[change objectForKey:@"old"] CGRectValue];
        CGRect new=[[change objectForKey:@"new"] CGRectValue];
        if (! CGRectEqualToRect(old, new))
        {
#ifdef DEBUG
            NSLog(@"frame=%@,bounds=%@",NSStringFromCGRect(self.view.frame),NSStringFromCGRect(self.view.bounds));
#endif
            [self resizeViews:self.view.bounds];    //ok
        }
    }
    else if ([keyPath isEqualToString:@"currentPageRefIndex"])
    {
        NSInteger old=[[change objectForKey:@"old"] integerValue];
        NSInteger new=[[change objectForKey:@"new"] integerValue];
        if ( old != new)
        {
#ifdef DEBUG
            NSLog(@" PageRefIndex改变 old=%@,new=%@",@(old),@(new));
#endif
            
        }
    }
    else if ([keyPath isEqualToString:@"displayStyle"])
    {
        NSInteger old=[[change objectForKey:@"old"] integerValue];
        NSInteger new=[[change objectForKey:@"new"] integerValue];
        if ( old != new)
        {
#ifdef DEBUG
            NSLog(@"displayStyle改变 old=%@,new=%@",@(old),@(new));
#endif
            
        }
    }
    else if( [keyPath isEqualToString:@"showViews.frame"])
    {
        //        CGRect old=[[change objectForKey:@"old"] CGRectValue];
        //        CGRect new=[[change objectForKey:@"new"] CGRectValue];
        //        if (! CGRectEqualToRect(old, new))
        //        {
        //            NSLog(@"showViews.frame old=%@,new=%@",NSStringFromCGRect(old),NSStringFromCGRect(new));
        //        }
    }
    
}

-(void)refresh
{
    //刷新
    if ( m_initALLFinished < 1) {
        return;
    }

}
////////////////////////////////////////////////////////////////////////////////
///////////////////      旋转       ///////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - 旋转
- (BOOL)shouldAutorotate
{
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations
{
    //return UIInterfaceOrientationMaskAllButUpsideDown;
    if ( _isPhone )
    {
        return UIInterfaceOrientationMaskPortrait;
    }
    
    //return UIInterfaceOrientationMaskLandscape;
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
    //    m_InterfaceOrientation=interfaceOrientation;
    //
    //    if (gDevice.isPhone) {
    //        return ((interfaceOrientation == UIInterfaceOrientationPortrait));
    //    }
    
    //return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
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
////////////////////////////////////////////////////////////////////////////////
//////////////     MBProgressHUDDelegate    ////////// ///////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - MBProgressHUDDelegate
- (void)hudWasHidden:(MBProgressHUD *)hud
{
    // Remove HUD from screen when the HUD was hidded
    [self closeMsg];
}
////////////////////////////////////////////////////////////////////////////////
//////////////     UIPageViewControllerDataSource    ////////// ///////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    //UIPageViewControllerDataSource协议 翻页触发 获得上一页资源
    
    EPUBPageViewController *pageCurVC=(EPUBPageViewController*)viewController;
    NSInteger pageRefIndex = pageCurVC.pageRefIndex;
    NSInteger offYIndexInPage=pageCurVC.offYIndexInPage;
    
    NSInteger currentOffCountInPage=[[self.dictPageWithOffYCount objectForKey:[NSString stringWithFormat:@"%@",@(pageRefIndex)]] integerValue];
    if (currentOffCountInPage<1)
    {
        return nil;
    }
    
    if (pageRefIndex == 0 )
    {
        //第一页 或 没有找到
        return nil;
    }
    
    if (offYIndexInPage >0)
    {
        //同一页内 上滚动翻页
        EPUBPageViewController *pageVC=[EPUBPageViewController new];
        pageVC.epubVC=self;
        pageVC.pageRefIndex=pageRefIndex;
        pageVC.offYIndexInPage=offYIndexInPage-1;
        
        self.currentOffYIndexInPage=offYIndexInPage-1;
        
        return pageVC;
        
    }
    else
    {
        //上一页
        EPUBPageViewController *pageVC=[EPUBPageViewController new];
        pageVC.epubVC=self;
        pageVC.pageRefIndex=pageRefIndex-1;
        pageVC.isPrePage=1;
        pageVC.calcPageOffy=1;
        
        self.currentPageRefIndex=pageRefIndex-1;
        
        return pageVC;
    }

    return nil;
    
    
}
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{

    //UIPageViewControllerDataSource协议 翻页触发 获得下一页资源
    
    //对页显示要注意单数补空白
    EPUBPageViewController *pageCurVC=(EPUBPageViewController*)viewController;
    NSInteger pageRefIndex = pageCurVC.pageRefIndex;
    NSInteger offYIndexInPage=pageCurVC.offYIndexInPage;
    
    NSInteger currentOffCountInPage=[[self.dictPageWithOffYCount objectForKey:[NSString stringWithFormat:@"%@",@(pageRefIndex)]] integerValue];
    if (currentOffCountInPage<1)
    {
        return nil;
    }
    
    if (pageRefIndex <0) {
        //说明是 补充页
        return nil;
    }

    if (offYIndexInPage +1 < currentOffCountInPage)
    {
        //同一页内 下滚动翻页
        
        EPUBPageViewController *pageVC=[EPUBPageViewController new];
        pageVC.epubVC=self;
        pageVC.pageRefIndex=pageRefIndex;
        pageVC.offYIndexInPage=offYIndexInPage+1;
        
        self.currentOffYIndexInPage=offYIndexInPage+1;
        
        return pageVC;
    }
    else
    {
        //下一页
        NSInteger pageCount=[self.self.epubPageRefs count];
        
        if (pageRefIndex < pageCount-1)
        {
            EPUBPageViewController *pageVC=[EPUBPageViewController new];
            pageVC.epubVC=self;
            pageVC.pageRefIndex=pageRefIndex+1;
            pageVC.calcPageOffy=1;
            
            self.currentPageRefIndex=pageRefIndex+1;
            
            return pageVC;
        }
    }

//    int isHeng=0;
//    UIDeviceOrientation curOrientation = [UIDevice currentDevice].orientation;
//    if (curOrientation == UIDeviceOrientationLandscapeLeft || curOrientation==UIDeviceOrientationLandscapeRight)
//    {
//        isHeng=1;
//    }
//    if(isHeng && pageRefIndex == pageCount-1 && pageCount%2==1 )
//    {
//        //结尾增加一个空白
//        EPUBPageViewController *pageVC=[EPUBPageViewController new];
//        pageVC.epubVC=self;
//        pageVC.pageRefIndex=-1000;
//        pageVC.view.tag=-1000;
//        pageVC.view.backgroundColor=[UIColor yellowColor];//会在此句 触发viewdidload
//        
//        return pageVC;
//        
//    }

    return nil;
    
}
- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    //
    if ( !self.progressView.hidden) {
        self.progressView.hidden=YES;
    }
    if ( !self.optionView.hidden) {
        self.optionView.hidden=YES;
    }
}
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    //操作完成
    if (finished && completed)
    {
//        NSUInteger viewCount=[self.pageViewController.viewControllers count];
//        if (viewCount>0)
        {
//            EPUBPageViewController *pagePreVC=(EPUBPageViewController*)previousViewControllers[0];
//            NSInteger pagePreIndex = pagePreVC.pageRefIndex;
//#ifdef DEBUG
//            NSLog(@"transitionCompleted ， preIndex=%@",@(pagePreIndex));
//#endif
            
        }
    }
    
}
- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    //UIPageViewControllerDelegate协议 设备纵横发生变化 触发
    //横 双页 ； 纵 单页
    
//    if (_isPhone != 1 && UIInterfaceOrientationIsLandscape(orientation) ) {
//        // （ 横屏 && pad ），则显示双页
//        NSArray *viewControllers = nil;
//        EPUBPageViewController *currentViewController = (EPUBPageViewController*)[pageViewController.viewControllers objectAtIndex:0];
//        NSInteger currentIndex = currentViewController.pageRefIndex;
//        
//        if(currentIndex == 0 || currentIndex %2 == 0)
//        {
//            UIViewController *nextViewController = [self pageViewController:pageViewController viewControllerAfterViewController:currentViewController];
//            viewControllers = [NSArray arrayWithObjects:currentViewController, nextViewController, nil];
//        }
//        else
//        {
//            UIViewController *previousViewController = [self pageViewController:pageViewController viewControllerBeforeViewController:currentViewController];
//            viewControllers = [NSArray arrayWithObjects:previousViewController, currentViewController, nil];
//        }
//        //Now, set the viewControllers property of UIPageViewController
//        [pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
//        
//        pageViewController.doubleSided = YES;
//        
//        return UIPageViewControllerSpineLocationMid;
//    }
    
    // 纵 单页
    UIViewController *currentViewController = [pageViewController.viewControllers objectAtIndex:0];
    NSArray *viewControllers = [NSArray arrayWithObject:currentViewController];
    [pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
    
    //Important- Set the doubleSided property to NO.
    pageViewController.doubleSided = NO;
    //Return the spine location
    return UIPageViewControllerSpineLocationMin;

}
////////////////////////////////////////////////////////////////////////////////
///////////////////      公共方法     /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - 公共方法
-(NSString*)getTimeStringWithFormat:(NSString*)formatString
{
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    if ([formatString length]>2) {
        [dateFormatter setDateFormat:formatString];
    }
    else
    {
        [dateFormatter setDateFormat:@"HH:mm:ss"];
    }
    
    
    NSString *strNow=[dateFormatter stringFromDate:[NSDate date]];
    return strNow;
}
-(NSString*)getNowTimeIntervalString
{
    //返回当前时间 毫秒数
    NSDate *now=[NSDate date];
    NSTimeInterval val=[now timeIntervalSince1970];
    NSString *ret=[NSString stringWithFormat:@"%.00f",val*1000.0f]; //时间戳签名。为从1970-1-1 0:0:0 GMT至今的毫秒数。目前和授权服务器允许有10分钟的误差
    return ret;
    
}
-(NSString*)getDateStringFromTimeInterval:(NSString*)strTimeInterval
{
    //根据毫秒数  得到当前时间
    long long  d1=[strTimeInterval longLongValue];  //毫秒
    //NSTimeInterval ti=(d1/1000.0f); // 得到错误的结果
    NSTimeInterval ti=d1/1000; // 正确
    if (ti <= 0)
        return @"N/A";
    NSDate *date1= [NSDate dateWithTimeIntervalSince1970:ti];
    //NSLog(@"getDateStringFromTimeInterval = %@ from %f and %lld",date1,ti,d1);
    return [self NSDateToNSString:date1];
}
-(NSString*)NSDateToNSString:(NSDate*)data1
{
    //日期转字符串
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    
    //zhu edit 20130104
    //[dateFormatter setAMSymbol:@"AM"];
    //[dateFormatter setPMSymbol:@"PM"];
    //[dateFormatter setDateFormat:@"dd/MM/yyyy hh:mmaaa"];
    [dateFormatter setAMSymbol:@"上午"];
    [dateFormatter setPMSymbol:@"下午"];
    [dateFormatter setDateFormat:@"yyyy / MM / dd aah:mm:ss"];  //2013 / 01 / 04 上午 11:10:08
    
    NSString *strDate=[dateFormatter stringFromDate:data1];
#if !__has_feature(objc_arc)
    [dateFormatter release];
#endif
    
    
    return strDate;
}
-(NSString*)UIColorToNSString:(UIColor*)color
{
    // uicolor rgba 转 string
    const CGFloat* components = CGColorGetComponents([color CGColor]);
    int r=components[0]*255;
    int g=components[1]*255;
    int b=components[2]*255;
    int a=components[3]*255;
    NSString *strColor=[NSString stringWithFormat:@"%02X%02X%02X%02X",a,r, g, b];
    
    return strColor;
}
-(UIColor*)NSStringToUIColor:(NSString*)strColor
{
    // string 转 uicolor rgba
    if ([strColor length] != 8)
    {
        return [UIColor clearColor];
    }
    
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    //a
    NSString *aString = [strColor substringWithRange:range];
    if ([aString isEqualToString:@"00"]) {
        aString=@"ff";
    }
    //r
    range.location = 2;
    NSString *rString = [strColor substringWithRange:range];
    
    //g
    range.location = 4;
    NSString *gString = [strColor substringWithRange:range];
    
    //b
    range.location = 6;
    NSString *bString = [strColor substringWithRange:range];
    
    unsigned int r, g, b,a;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    [[NSScanner scannerWithString:aString] scanHexInt:&a];
    
    return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:((float) a / 255.0f)];
}
-(UIColor*)UIColorFromRGBString:(NSString*)strRGB
{
    UIColor *ret=nil;
    
    NSString *rgb=[strRGB stringByReplacingOccurrencesOfString:@"#" withString:@""];
    NSString *rgba=nil;
    if ([rgb length] == 6) {
        rgba=[NSString stringWithFormat:@"ff%@",rgb];
    }
    else if ([rgb length] == 8)
    {
        rgba=rgb;
    }
    
    if (rgba) {
        ret=[self NSStringToUIColor:rgba];
    }
    
    return ret;
}
-(NSString*)fileFindFullPathWithFileName:(NSString*)fileName InDirectory:(NSString*)inDirectory
{
    //根据名称，返回绝对路径
    NSString *ret=nil;
    NSRange r1=[fileName rangeOfString:@"."];
    if (r1.location != NSNotFound )
    {
        NSString *name=[fileName substringToIndex:r1.location];
        NSString *fileExt=[fileName pathExtension];
        ret = [[NSBundle mainBundle] pathForResource:name ofType:fileExt inDirectory:inDirectory];
    }
    
    return ret;
    
}

-(BOOL)isFileExist:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:path];
}

-(BOOL)createDirectory:(NSString*)strFolderPath
{
    //创建文件夹
    BOOL bDo1=YES;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:strFolderPath] == NO) {
        bDo1=[fileManager createDirectoryAtPath:strFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return bDo1;
}

-(BOOL)deleteFileAtPath:(NSString*)path
{
    BOOL bDo1=NO;
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path])
    {
        bDo1=[fileManager removeItemAtPath:path error:nil];
    }
    
    return bDo1;
}
-(NSString*)trimWhiteSpace:(NSString*)strContent
{
    //去除空格
    return [strContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}
-(NSString*)trimWhiteSpaceAndNewLine:(NSString*)strContent
{
    //去除空格和换行
    return [strContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}
-(NSString*)getFileMD5WithPath:(NSString*)path
{
    return [self FileMD5HashCreateWithPath:path WithSize:(1024*8)];
}
-(NSString*)FileMD5HashCreateWithPath:(NSString*)filePath WithSize:(size_t)chunkSizeForReadingData
{
    // Declare needed variables
    //CFStringRef result = NULL;
    NSMutableString *result=nil;
    CFReadStreamRef readStream = NULL;
    
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    
    CC_MD5_CTX hashObject;
    bool hasMoreData = true;
    bool didSucceed;
    
    if (!fileURL) goto done;
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    
    // Initialize the hash object
    CC_MD5_Init(&hashObject);
    
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = 1024*8;
    }
    
    // Feed the data to the hash object
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                  (UInt8 *)buffer,
                                                  (CFIndex)sizeof(buffer));
        if (readBytesCount == -1)break;
        if (readBytesCount == 0) {
            hasMoreData =false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    
    // Compute the string result
    //    char hash[22 *sizeof(digest) + 1];
    //    for (size_t i =0; i < sizeof(digest); ++i) {
    //        snprintf(hash + (22 * i),3, "%02x", (int)(digest[i]));
    //    }
    //
    //    //这里 运行的result 返回不对
    //    result = CFStringCreateWithCString(kCFAllocatorDefault,
    //                                       (const char *)hash,
    //                                       kCFStringEncodingUTF8);
    
    result = [NSMutableString string];
    for(int i=0;i<CC_MD5_DIGEST_LENGTH;i++){
        [result appendFormat:@"%02x",digest[i]];
    }
    
    
done:
    
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
    
}
-(BOOL)imageSaveFile:(NSString*)strSaveFile withImage:(UIImage*)img
{
    //图片保存文件
    BOOL bRet=NO;
    NSString *fileExt=[[strSaveFile pathExtension] lowercaseString];
    
    if (img && strSaveFile && ([fileExt compare:@"png"] == NSOrderedSame) )
    {
        //save png
        NSData *imgData =UIImagePNGRepresentation(img);
        bRet=[imgData writeToFile:strSaveFile atomically:YES];
    }
    else
    {
        //save jpg
        NSData *imgData=UIImageJPEGRepresentation(img, 0);
        bRet=[imgData writeToFile:strSaveFile atomically:YES];
    }
    
    return bRet;
}
-(NSMutableDictionary*)getDictionaryFromString:(NSString*)str1 WithSeparatedString:(NSString*)sep
{
    //转换
    NSMutableDictionary *dictRet=nil;
    NSArray *params=[str1 componentsSeparatedByString:sep];
    if ([params count]>0)
    {
        dictRet=[NSMutableDictionary dictionaryWithCapacity:[params count]];
        for (NSString *one in params)
        {
            NSRange range = [one rangeOfString:@"="];
            
            if (range.location !=NSNotFound && range.length > 0)
            {
                NSString *key1=[one substringToIndex:range.location];
                NSString *value1=[one substringFromIndex:range.location+1];
                
                [dictRet setObject:[self trimWhiteSpace:value1] forKey:[self trimWhiteSpace:key1]];
            }
        }
    }
    
    return dictRet;
}
-(NSString*)getStringFromDictionary:(NSDictionary*)dict1 WithSeparatedString:(NSString*)sep
{
    //转换
    NSString *strResult=nil;
    NSMutableArray *params=[NSMutableArray array];
    for (NSString *key1 in [dict1 allKeys])
    {
        NSString *value1=[dict1 objectForKey:key1];
        
        [params addObject:[NSString stringWithFormat:@"%@=%@",key1,value1]];
        
    }
    
    if ([params count]>0)
    {
        strResult=[params componentsJoinedByString:sep];
    }
    
    return strResult;
}
-(int)openURLWithString:(NSString*)strURL
{
    //
    int iResult=0;
    
    UIApplication *app= [UIApplication sharedApplication];
    
    NSString *str1=[strURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:str1];
    
    if ([app canOpenURL:url])
    {
        [app openURL:url];
        iResult=1;
    }
    
    return iResult;
}
-(NSString*)parentFolderWithFilePath:(NSString*)fileFullPath
{
    //当前文件 或 文件夹的 父文件夹
    if ([fileFullPath length]<1) {
        return nil;
    }
    NSInteger lastSlash = [fileFullPath rangeOfString:@"/" options:NSBackwardsSearch].location;
    NSString *parentPath = [fileFullPath substringToIndex:(lastSlash +1)];
    return parentPath;
}
-(NSMutableArray*)fontLists
{
    //字体列表 测试ok
    NSMutableArray *fontArray = [NSMutableArray arrayWithCapacity:246];
    for (NSString * familyName in [UIFont familyNames]) {
        
        //NSLog(@"Font FamilyName = %@",familyName); //*输出字体族科名字
        for (NSString * fontName in [UIFont fontNamesForFamilyName:familyName]) {
            //NSLog(@"%@",fontName);
            [fontArray addObject:fontName];
        }
    }
    return fontArray;
}
-(BOOL)UnRegisterCustomFont:(NSString*)path
{
    BOOL bDO=YES;
    NSURL *fontUrl = [NSURL fileURLWithPath:path];
    CGDataProviderRef fontDataProvider = CGDataProviderCreateWithURL((__bridge CFURLRef)fontUrl);
    CGFontRef fontRef = CGFontCreateWithDataProvider(fontDataProvider);
    CGDataProviderRelease(fontDataProvider);
    bDO = CTFontManagerUnregisterGraphicsFont(fontRef, NULL);
    CGFontRelease(fontRef);
    return bDO;
    
}
-(UIFont*)customFontWithPath:(NSString*)path size:(CGFloat)size
{
    //测试ok
/*
 方法对于TTF、OTF的字体都有效，但是对于TTC字体，只取出了一种字体。因为TTC字体是一个相似字体的集合体，一般是字体的组合。所以如果对字体要求比较高，所以可以用下面的方法把所有字体取出来
 */
    NSURL *fontUrl = [NSURL fileURLWithPath:path];
    CGDataProviderRef fontDataProvider = CGDataProviderCreateWithURL((__bridge CFURLRef)fontUrl);
    CGFontRef fontRef = CGFontCreateWithDataProvider(fontDataProvider);
    CGDataProviderRelease(fontDataProvider);
    CTFontManagerRegisterGraphicsFont(fontRef, NULL);
    NSString *fontName = CFBridgingRelease(CGFontCopyPostScriptName(fontRef));
    UIFont *font = [UIFont fontWithName:fontName size:size];
    CGFontRelease(fontRef);
    return font;
}
//-(NSArray*)customFontArrayWithPath:(NSString*)path size:(CGFloat)size
//{
//    CFStringRef fontPath = CFStringCreateWithCString(NULL, [path UTF8String], kCFStringEncodingUTF8);
//    CFURLRef fontUrl = CFURLCreateWithFileSystemPath(NULL, fontPath, kCFURLPOSIXPathStyle, 0);
//    CFArrayRef fontArray =CTFontManagerCreateFontDescriptorsFromURL(fontUrl);
//    CTFontManagerRegisterFontsForURL(fontUrl, kCTFontManagerScopeNone, NULL);
//    NSMutableArray *customFontArray = [NSMutableArray array];
//    for (CFIndex i = 0 ; i < CFArrayGetCount(fontArray); i++){
//        CTFontDescriptorRef  descriptor = CFArrayGetValueAtIndex(fontArray, i);
//        CTFontRef fontRef = CTFontCreateWithFontDescriptor(descriptor, size, NULL);
//        NSString *fontName = CFBridgingRelease(CTFontCopyName(fontRef, kCTFontPostScriptNameKey));
//        UIFont *font = [UIFont fontWithName:fontName size:size];
//        [customFontArray addObject:font];
//    }
//    
//    return customFontArray;
//}
-(void)closeMsg
{
    //关闭指示符
    if (m_msg)
    {
        [m_msg removeFromSuperview];
        
#if !__has_feature(objc_arc)
        [m_msg release];
#endif
        
    }
    m_msg=nil;
    
}
-(int)showMsgInView:(UIView*)inView ContentString:(NSString*)strContent isActivity:(BOOL)isA HideAfter:(NSTimeInterval)delay
{
    //显示指示符
    
    if (!m_msg)
    {
        m_msg = [[MBProgressHUD alloc] initWithView:inView];
        [inView addSubview:m_msg];
        m_msg.delegate = self;
        
    }
    
    //[inView bringSubviewToFront:m_msg];
    
    if (isA)
    {
        m_msg.mode = MBProgressHUDModeIndeterminate;
        m_msg.labelText = strContent;
        [m_msg show:YES];
    }
    else
    {
        
        {
            UILabel *lb1=[[UILabel alloc] init];   //运行ok， 没有大小空位
            //            UILabel *lb1=[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];//运行ok,有大小空位
            //            lb1.text=strContent;
            //            lb1.textColor=[UIColor redColor];
            m_msg.customView=lb1;
#if !__has_feature(objc_arc)
            [lb1 release];
#endif
        }
        m_msg.mode = MBProgressHUDModeCustomView;//注意顺序, 必须在"m_msg.customView"赋值之后写,否则没有效果
        m_msg.labelText = strContent;
        [m_msg show:YES];
        if (delay>0.0) {
            [m_msg hide:YES afterDelay:delay];
        }
    }
    
    return 1;
}
////////////////////////////////////////////////////////////////////////////////
///////////////////      timer  /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - timer
-(NSTimer *)timerTime{
    if (!_timerTime)
    {
        _timerTime=[NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(timeChange) userInfo:nil repeats:YES];
    }
    return _timerTime;
}
-(void)timeChange
{
    //每次刷新
    if (!self.pageViewController) {
        return;
    }
    
    NSArray *viewControllers=_pageViewController.viewControllers;
    if ([viewControllers count]<1) {
        return;
    }
    
    for (EPUBPageViewController *pageVC in viewControllers) {
        
        pageVC.timeStatusLabel.text=[self getTimeStringWithFormat:@"HH:mm"];
        
    }
}
-(void)startTimerTime
{
    self.timerTime.fireDate=[NSDate distantPast];
}
-(void)pauseTimerTime
{
    self.timerTime.fireDate=[NSDate distantFuture];
}
-(void)closeTimerTime
{
    if (_timerTime) {
        [_timerTime invalidate];
        _timerTime=nil;
    }
}
////////////////////////////////////////////////////////////////////////////////
///////////////////       其他    /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - 其他
-(int)checkLicence
{
    int iResult=0;
    
    NSDate *date1=[NSDate date];
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |NSCalendarUnitWeekday|NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    
    NSDateComponents *comps  = [calendar components:unitFlags fromDate:date1];
    
    NSInteger year = [comps year];
    if (year < 2020)
    {
        iResult=1;
    }
    //    int month = [comps month];
    //    int day = [comps day];
    //    int hour = [comps hour];
    //    int min = [comps minute];
    //    int sec = [comps second];
    //这样获取的hour都是24小时制的, 不管手机实际日期是否是用24小时显示.
    
    
    return iResult;
}
-(NSString*)checkInputs
{
    //检查输入
    NSString *msg=nil;
//    if ( !self.cajParser)
//    {
//        msg=[NSString stringWithFormat:@"参数cajParser,没有赋值 "];
//    }
    
    if ( !self.fileInfo || [self.fileInfo[@"fileFullPath"] length]<2)
    {
        msg=[NSString stringWithFormat:@"参数fileInfo,没有fileFullPath 选项 "];
    }
    
    
    return msg;
}
-(void)refreshPageViewController
{
    [self showPageViewController];
}
-(void)showPageViewController
{
    if (m_initALLFinished <1) {
        return;
    }
    
    
    NSInteger pageRefIndex=_currentPageRefIndex;
    NSInteger offYIndexInPage=_currentOffYIndexInPage;    // 当前滚动索引
    
    if (_pageViewController)
    {
        if ([_pageViewController.viewControllers count]>0) {
            EPUBPageViewController *currentPageVC = (EPUBPageViewController*)[_pageViewController.viewControllers objectAtIndex:0];
            pageRefIndex=currentPageVC.pageRefIndex;
            offYIndexInPage=currentPageVC.offYIndexInPage;
        }
        
        [_pageViewController.view removeFromSuperview];
        [_pageViewController removeFromParentViewController];
        self.pageViewController=nil;
    }

    
//    int isHeng=0;
//    UIDeviceOrientation curOrientation = [UIDevice currentDevice].orientation;
//    if (curOrientation == UIDeviceOrientationLandscapeLeft || curOrientation==UIDeviceOrientationLandscapeRight)
//    {
//        isHeng=1;
//    }
    NSMutableDictionary * options=[NSMutableDictionary dictionary];
//    NSNumber *spineLocationValue= isHeng && _isPhone<1 ?[NSNumber numberWithInteger:UIPageViewControllerSpineLocationMid]:[NSNumber numberWithInteger:UIPageViewControllerSpineLocationMin];
    NSNumber *spineLocationValue= [NSNumber numberWithInteger:UIPageViewControllerSpineLocationMin];
    
    [options setObject:spineLocationValue forKey:UIPageViewControllerOptionSpineLocationKey];
    
    _pageViewController = [[UIPageViewController alloc]initWithTransitionStyle:m_pageViewTransitionStyle navigationOrientation:m_pageViewNavigationOrientation options:options];
    
    _pageViewController.view.frame=_contentView.bounds;
    _pageViewController.view.backgroundColor=[UIColor clearColor];
    {
        NSString *themeBodyColor=[self.arrTheme[self.themeIndex] objectForKey:@"bodycolor"];
        UIColor *bgColor1=[self UIColorFromRGBString:themeBodyColor];
        self.view.backgroundColor=bgColor1;
        _pageViewController.view.backgroundColor=bgColor1;
    }

    NSArray * viewControllers=nil;
//    if (isHeng && _isPhone<1)
//    {
//        NSInteger page1;
//        if (_curPageIndex % 2 == 1)
//        {
//            page1=_curPageIndex-1;
//            
//        }
//        else
//        {
//            page1=_curPageIndex;
//        }
//        NSInteger page2=page1+1;
//        
//        EPUBPageViewController *firstVC=[EPUBPageViewController new];
//        firstVC.epubVC=self;
//        firstVC.pageRefIndex=page1;
//        firstVC.view.tag=page1;
//        
//        EPUBPageViewController * secondVC =[EPUBPageViewController new];
//        secondVC.epubVC=self;
//        secondVC.pageRefIndex=page2;
//        secondVC.view.tag =page2;
//        
//        viewControllers = [NSArray arrayWithObjects:firstVC,secondVC,nil];
//    }
//    else
    {
        EPUBPageViewController *firstVC=[EPUBPageViewController new];
        firstVC.epubVC=self;
        firstVC.pageRefIndex=pageRefIndex;
        firstVC.offYIndexInPage=offYIndexInPage;
        firstVC.calcPageOffy=1;
        
        viewControllers = [NSArray arrayWithObjects:firstVC,nil];
    }
    
    [_pageViewController setViewControllers:viewControllers direction:(UIPageViewControllerNavigationDirectionForward) animated:NO completion:nil];
    
    _pageViewController.dataSource = self;
    _pageViewController.delegate=self;

    [_contentView addSubview:_pageViewController.view];
    [self addChildViewController:_pageViewController];
    //self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
    
    /*
     webview和其他控件里的单击事件 冲突， 解决:
     htp://blog.csdn.net/kuloveyouwei/article/details/9231411
     5.0以后系统提供的UIPageViewController用来自作电子书之类的很不错，自带的翻页效果很逼真，但在具体做项目的过程中，有时因为需求的关系，在书本的边缘地方需要放置一些控件，比如按钮，但系统的点击边缘自动翻页显然跟我们的控件相冲突，网上找了一会，总结了一下解决的方案，首先获取我们的uipagecontroller里的手势：
     */
    
}
-(void)backDocument
{
    //文档返回
    
    //锁界面
    self.view.userInteractionEnabled=NO;
    //    _headView.userInteractionEnabled=NO;    //比起作用， 后面又变回 YES了 在 btnClick 方法里
    //    _footView.userInteractionEnabled=NO;
    
     //释放监听
    [self removeSomeObserver];
    [self closeTimerTime];
    [self customFontRemove];

    [self CloseTotalReadingTime];   //停止阅读累计
    
    __weak typeof(self) _weakself = self;
    [self showMsgInView:self.view ContentString:NSLocalizedString(@"Saving...", @"Saving...") isActivity:YES HideAfter:0.0];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        sleep(1);

        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self closeMsg];
            
            //返回
            //回调
            if (_weakself.epubReadBackBlock) {
                _weakself.epubReadBackBlock(self.fileInfo);
            }
            //[self dismissViewControllerAnimated:YES completion:nil];
        });
    });
    
}

-(void)btnClick:(id)sender
{
    //上下工具栏响应
    NSInteger btnTag= [sender tag];
    

    _headView.userInteractionEnabled=NO;
    _footView.userInteractionEnabled=NO;
    
    if (btnTag == READ_BUTTON_BACK )
    {
        //back
        if (m_initALLFinished)
        {
            [self backDocument];
        }
    }
    else if (btnTag == READ_BUTTON_CATALOG)
    {
        [self showCatalog];
    }
    else if (btnTag == READ_BUTTON_PROGRESS)
    {
        [self showOrHideHeadAndFoot];

        [self.progressView refresh];
        self.progressView.hidden=NO;
    }
    else if (btnTag == READ_BUTTON_OPTION)
    {
        [self showOrHideHeadAndFoot];
        
        [self.optionView refresh];
        self.optionView.hidden=NO;
    }
    else if (btnTag == READ_BUTTON_FILEINFO)
    {
        [self showFileInfo];
    }
    else if (btnTag == READ_BUTTON_SEARCH)
    {
        [self showSearchText];
    }
    else if (btnTag == READ_BUTTON_STYLE2)
    {

        //[self pauseTimerTime];    //ok
        //m_pageViewTransitionStyle=UIPageViewControllerTransitionStylePageCurl;
        //m_pageViewNavigationOrientation=UIPageViewControllerNavigationOrientationVertical;

//        
//        [self showPageViewController];
        
    }

    
    _headView.userInteractionEnabled=YES;
    _footView.userInteractionEnabled=YES;
}
-(void)CloseTotalReadingTime
{
    //按 home 键   停止阅读累计
#ifdef DEBUG
    NSLog(@"阅读累计 停止");
#endif
    if (self.fileInfo)
    {
        double readTotalTime= [[self.fileInfo objectForKey:@"fileTotalReadingTime"] doubleValue];
        NSTimeInterval readEndTime = [NSDate timeIntervalSinceReferenceDate];
        NSString *str1=[NSString stringWithFormat:@"%0.2f",readTotalTime+readEndTime-m_readStartTime];
        [self.fileInfo setObject:str1 forKey:@"fileTotalReadingTime"];
    }
}
-(void)StartTotalReadingTime
{
    //按 start 键  阅读累计 起始时间
#ifdef DEBUG
    NSLog(@"阅读累计 开启");
#endif
    m_readStartTime = [NSDate timeIntervalSinceReferenceDate];
}
-(NSInteger)pageRefIndexWithCatalogItem:(NSMutableDictionary*)itemCatalog
{
    //根据目录，返回对应的 pageRef
    NSString *itemID=itemCatalog[@"id"];
    
    for (int index=0 ; index< [self.epubPageRefs count]; ++index) {
        NSString *pageRef=self.epubPageRefs[index];
        if ([itemID isEqualToString:pageRef])
        {
            //break;
            return index;
            
        }
    }

    
    return 0;
}
-(NSMutableDictionary*)catalogWithPageRef:(NSInteger)pageRefIndex
{
    //根据 pageRef  返回对应的 目录信息

    NSString *pageRef=[self.epubPageRefs objectAtIndex:pageRefIndex];
    for (NSMutableDictionary *catalog1 in self.epubCatalogs) {
        
        NSString *itemID=catalog1[@"id"];
        //NSString *itemhref=item1[@"src"];
        
        if ([itemID isEqualToString:pageRef]) {
            return catalog1;
        }
    }
    
    return nil;
}
-(NSMutableDictionary*)pageItemWithPageRef:(NSString*)pageRef
{
    //根据 pageRef  返回对应的 pageItem
    
    for (NSMutableDictionary *item1 in self.epubPageItems) {
        
        NSString *itemID=item1[@"id"];
        //NSString *itemhref=item1[@"href"];
        
        if ([itemID isEqualToString:pageRef]) {
            return item1;
        }
        
    }
    
    return nil;
}
-(NSString*)pageURLWithPageRefIndex:(NSInteger)pageRefIndex
{
    //得到当前页码索引的路径
    if (pageRefIndex <0 || pageRefIndex >= [self.epubPageRefs count]) {
        return nil;
    }
    
    
    NSString *pageRef=[self.epubPageRefs objectAtIndex:pageRefIndex];
    NSMutableDictionary *pageItem=[self pageItemWithPageRef:pageRef];
    if (pageItem) {
        
        NSString *href=pageItem[@"href"];
        
        NSString *pageURL=[NSString stringWithFormat:@"%@/%@",[self parentFolderWithFilePath:self.opfFilePath],href];
        if ([self isFileExist:pageURL]) {
            return pageURL;
        }
    }
    
    
    return nil;
}
-(NSString*)jsFontStyle:(NSString*)fontFilePath
{
    //注意 fontName, DFPShaoNvW5.ttf 如果改为 aa.ttf, 那么fontname也应该是“DFPShaoNvW5”，
    //fontName是系统认的名称,非文件名， 我这里把文件名改了，参考本文件的 customFontWithPath 方法得到真正的fontName
    
    NSString *fontFile=[fontFilePath lastPathComponent];
    NSString *fontName=[fontFile stringByDeletingPathExtension];
    //NSString *jsFont=@"<style type=\"text/css\"> @font-face{ font-family: 'DFPShaoNvW5'; src: url('DFPShaoNvW5-GB.ttf'); } </style> ";
    NSString *jsFontStyle=[NSString stringWithFormat:@"<style type=\"text/css\"> @font-face{ font-family: '%@'; src: url('%@'); } </style>",fontName,fontFile];
    
    return jsFontStyle;
}
-(NSString*)jsContentWithViewRect:(CGRect)rectView
{
    //
    //NSString *js0=@"<?xml-stylesheet type=\"text/css\" href=\"font1.css\"?>";
//    NSString *js0=@"<style type=\"text/css\"> @font-face{ font-family: 'DFPShaoNvW5'; src: url('DFPShaoNvW5-GB.ttf'); } </style> ";
    
    NSString *js0=@"";
    if (self.fontSelectIndex == 1) {
        NSString *path1=[self fileFindFullPathWithFileName:@"DFPShaoNvW5.ttf" InDirectory:nil];
        js0=[self jsFontStyle:path1];
    }

    NSString *js1=@"<style>img {  max-width:100% ; }</style>\n";

//    NSArray *arrJs2=@[@"<script>"
//                      ,@"var mySheet = document.styleSheets[0];"
//                      ,@"function addCSSRule(selector, newRule){"
//                      ,@"if (mySheet.addRule){"
//                      ,@"mySheet.addRule(selector, newRule);"
//                      ,@"} else {"
//                      ,@"ruleIndex = mySheet.cssRules.length;"
//                      ,@"mySheet.insertRule(selector + '{' + newRule + ';}', ruleIndex);"
//                      ,@"}"
//                      ,@"}"
//                      ,@"addCSSRule('p', 'text-align: justify;');"
//                      ,@"addCSSRule('highlight', 'background-color: yellow;');"
//                      //,@"addCSSRule('body', '-webkit-text-size-adjust: 100%; font-size:10px;');"
//                      ,@"addCSSRule('body', ' font-size:18px;');"
//                      ,@"addCSSRule('body', ' margin:2.2em 5%% 0 5%%;');"   //上，右，下，左 顺时针
//                      ,@"addCSSRule('html', 'padding: 0px; height: 480px; -webkit-column-gap: 0px; -webkit-column-width: 320px;');"
//                      ,@"</script>"];
    
    NSMutableArray *arrJs=[NSMutableArray array];
    [arrJs addObject:@"<script>"];
    [arrJs addObject:@"var mySheet = document.styleSheets[0];"];
    [arrJs addObject:@"function addCSSRule(selector, newRule){"];
    [arrJs addObject:@"if (mySheet.addRule){"];
    [arrJs addObject:@"mySheet.addRule(selector, newRule);"];
    [arrJs addObject:@"} else {"];
    [arrJs addObject:@"ruleIndex = mySheet.cssRules.length;"];
    [arrJs addObject:@"mySheet.insertRule(selector + '{' + newRule + ';}', ruleIndex);"];
    [arrJs addObject:@"}"];
    [arrJs addObject:@"}"];
    
    
    [arrJs addObject:@"addCSSRule('p', 'text-align: justify;');"];
    [arrJs addObject:@"addCSSRule('highlight', 'background-color: yellow;');"];
    {
        NSString *css1=[NSString stringWithFormat:@"addCSSRule('body', ' font-size:%@px;');",@(self.currentTextSize)];
        [arrJs addObject:css1];
    }
    {

//        NSString *css1=[NSString stringWithFormat:@"addCSSRule('body', ' font-family:\"%@\";');",self.currentTextFontName];
//        NSString *css1=[NSString stringWithFormat:@"addCSSRule('body', ' font-family:\"%@\";');",@"DFPShaoNvW5"];
        

        NSString *fontName= [[self.arrFont objectAtIndex:self.fontSelectIndex] objectForKey:@"fontName"];
        NSString *css1=[NSString stringWithFormat:@"addCSSRule('body', ' font-family:\"%@\";');",fontName];
        
        [arrJs addObject:css1];
    }
    
    //[arrJs addObject:@"addCSSRule('body', ' margin:2.2em 5%% 0 5%%;');"]; //上，右，下，左 顺时针
    [arrJs addObject:@"addCSSRule('body', ' margin:0 0 0 0;');"];
    {
        //[arrJs addObject:@"addCSSRule('html', 'padding: 0px; height: 480px; -webkit-column-gap: 0px; -webkit-column-width: 320px;');"];
        NSString *css1=[NSString stringWithFormat:@"addCSSRule('html', 'padding: 0px; height: %@px; -webkit-column-gap: 0px; -webkit-column-width: %@px;');",@(rectView.size.height),@(rectView.size.width)];
        [arrJs addObject:css1];
    }

    [arrJs addObject:@"</script>"];

    NSString *jsJoin=[arrJs componentsJoinedByString:@"\n"];
    
    //NSString *jsRet=[NSString stringWithFormat:@"%@\n%@",js1,jsJoin];
    NSString *jsRet=[NSString stringWithFormat:@"%@\n%@\n%@",js0,js1,jsJoin];
    return jsRet;
}
-(void)showOrHideHeadAndFoot
{
    //显示工具栏
    
    if ( ! self.progressView.hidden) {
        self.progressView.hidden=YES;
        return;
    }
    
    if ( ! self.optionView.hidden ) {
        self.optionView.hidden=YES;
        return;
    }
    

    CGPoint headCenter=_headView.center;
    CGPoint footCenter=_footView.center;
    CGFloat viewAlpha=0;

    
    if (_headView.center.y > 0)
    {
        viewAlpha=0;
        headCenter.y -=_headView.frame.size.height;
        footCenter.y +=_footView.frame.size.height;
        
        //需要设置info.plist里的 View controller-based status bar appearance 设为NO
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];
        
    }
    else
    {
        viewAlpha=1.0f;
        headCenter.y +=_headView.frame.size.height;
        footCenter.y -=_footView.frame.size.height;
        
        //需要设置info.plist里的 View controller-based status bar appearance 设为NO
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];
    }

    //
    self.contentView.userInteractionEnabled=NO;
    
//    [UIView animateWithDuration:0.75f delay:0.1f usingSpringWithDamping:0.8f initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//        
//        /*
//         usingSpringWithDamping：弹簧动画的阻尼值，也就是相当于摩擦力的大小，该属性的值从0.0到1.0之间，越靠近0，阻尼越小，弹动的幅度越大，反之阻尼越大，弹动的幅度越小，如果大道一定程度，会出现弹不动的情况。
//         initialSpringVelocity：弹簧动画的速率，或者说是动力。值越小弹簧的动力越小，弹簧拉伸的幅度越小，反之动力越大，弹簧拉伸的幅度越大。这里需要注意的是，如果设置为0，表示忽略该属性，由动画持续时间和阻尼计算动画的效果。
//         参考－www.csdn.net/article/2015-07-03/2825122-ios-uiview-animation-2
//         */
//        _headView.alpha=viewAlpha;
//        _footView.alpha=viewAlpha;
//        
//        _headView.center=headCenter;
//        _footView.center=footCenter;
//
//        
//    } completion:^(BOOL finished) {
//        
//        self.contentView.userInteractionEnabled=YES;
//        
//    }];
    
    [UIView animateWithDuration:0.3f animations:^{
        _headView.alpha=viewAlpha;
        _footView.alpha=viewAlpha;
        
        _headView.center=headCenter;
        _footView.center=footCenter;
    } completion:^(BOOL finished) {
        self.contentView.userInteractionEnabled=YES;
    }];
}
-(void)loadEpubTheme
{
    //读取主题
    [_arrTheme removeAllObjects]; //清空
    
    NSString *themeFilePath =[self fileFindFullPathWithFileName:@"epubtheme.xml" InDirectory:nil];

    if (![self isFileExist:themeFilePath]) {
        return;
    }
    
    NSData *xmlData=[[NSData alloc] initWithContentsOfFile:themeFilePath];
    if (xmlData) {
        NSError *err = nil;
        GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&err];
        if ([err code] == 0)
        {
            //根节点
            GDataXMLElement *root = [doc rootElement];
            
            NSError *errXPath=nil;
            NSArray *arrItems=[root nodesForXPath:@"item" error:&errXPath];
            
            for (GDataXMLElement *item1 in arrItems)
            {
                NSString *name= [[item1 attributeForName:@"name"] stringValue];
                
                NSString *bodycolor=nil;
                NSString *textcolor=nil;
                
                {
                    NSArray *arr1=[item1 nodesForXPath:@"bodycolor" error:nil];
                    if ([arr1 count]>0) {
                        GDataXMLElement *child1=arr1[0];
                        bodycolor=[child1 stringValue];
                    }
                }
                {
                    NSArray *arr1=[item1 nodesForXPath:@"textcolor" error:nil];
                    if ([arr1 count]>0) {
                        GDataXMLElement *child1=arr1[0];
                        textcolor=[child1 stringValue];
                    }
                }
                
                //
                if ([textcolor length]>0 && [bodycolor length]>0) {
                    NSMutableDictionary *theme1=[NSMutableDictionary dictionary];
                    [theme1 setObject:name forKey:@"name"];
                    [theme1 setObject:bodycolor forKey:@"bodycolor"];
                    [theme1 setObject:textcolor forKey:@"textcolor"];
                    [_arrTheme addObject:theme1];
                }
            }
        }
    }
    

}

-(void)setPageViewTransitionStyle:(NSInteger)transitionStyle
{
    m_pageViewTransitionStyle=transitionStyle;
}
-(NSInteger)pageViewTransitionStyle
{
    return m_pageViewTransitionStyle;
}
-(CGRect)pageWebViewRect
{
    CGRect rectWeb=CGRectZero;
    
    if ([_pageViewController.viewControllers count]>0) {
        EPUBPageViewController *currentPageVC = (EPUBPageViewController*)[_pageViewController.viewControllers objectAtIndex:0];
        rectWeb=currentPageVC.pageWebView.bounds;
    }
    
    return rectWeb;
}
-(void)gotoPageWithPageRefIndex:(NSInteger)pageRefIndex WithOffYIndexInPage:(NSInteger)offYIndexInPage
{
    //跳转页码
    
    self.currentPageRefIndex=pageRefIndex;
    self.currentOffYIndexInPage=offYIndexInPage;
    
    if (_pageViewController)
    {
        [_pageViewController.view removeFromSuperview];
        [_pageViewController removeFromParentViewController];
        self.pageViewController=nil;
    }

    [self showPageViewController];
}
-(void)increaseTextSize
{
    //文字显示 变大
    NSInteger textSize=self.currentTextSize+ self.stepTextSize;
    textSize = MIN(self.textSizeMax, textSize);
    textSize = MAX(self.textSizeMin, textSize);
    self.currentTextSize=textSize;
    
    [self showPageViewController];

}
-(void)decreaseTextSize
{
    //文字显示 变小
    NSInteger textSize=self.currentTextSize- self.stepTextSize;
    textSize = MIN(self.textSizeMax, textSize);
    textSize = MAX(self.textSizeMin, textSize);
    self.currentTextSize=textSize;
    
    [self showPageViewController];
    
}
-(void)changeThemeAtIndex:(NSInteger)index
{
    //切换主题
    if (self.themeIndex == index ){
        return;
    }
    if (index < [self.arrTheme count])
    {
        self.themeIndex=index;
        
        [self showPageViewController];
        
//        self.themeBodyColor=[self.arrTheme[index] objectForKey:@"bodycolor"];
//        self.themeTextColor=[self.arrTheme[index] objectForKey:@"textcolor"];
//        
//        UIColor *bgColor1=[gLib UIColorFromRGBString:self.themeBodyColor];
//        if (bgColor1) {
//            self.view.backgroundColor=bgColor1;
//            self.pageView.backgroundColor=bgColor1;
//        }
//        //刷新
//        
//        if (m_initALLFinished)
//        {
//            [self.pageView gotoPageNumInChapter:self.currentPageNumInChapter];
//        }
        
    }
}
-(void)showMoreOption
{
    [self showOrHideHeadAndFoot];
    
//    epubVC.epubReadBackBlock=^(NSMutableDictionary *para1){
//        NSLog(@"回调=%@",para1);
//        //[self dismissViewControllerAnimated:YES completion:nil];  //a方式  oK
//        //[self.navigationController popToRootViewControllerAnimated:YES];    //b方式  oK
//        [self dismissViewControllerAnimated:YES completion:nil];
//        
//        return 1;
//    };
//    
//    //[self showViewController:epubVC sender:nil];  //a方式  oK
//    //[self.navigationController pushViewController:epubVC animated:YES];  //b方式  oK
//    [self.navigationController presentViewController:epubVC animated:YES completion:nil];
    
    EPUBPageOptionMoreViewController *popVC=[[EPUBPageOptionMoreViewController alloc] init];
    popVC.epubVC=self;
    popVC.view.backgroundColor=[UIColor whiteColor];
    
    popVC.backBlock=^(NSMutableDictionary *para1){
        
        
        if (para1) {
            NSInteger changed= [[para1 objectForKey:@"changed"] integerValue];
            if (changed) {
                [self showPageViewController];
            }
                
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
        return 1;
    };
    
    //
    if (self.navigationController) {
        [self.navigationController presentViewController:popVC animated:YES completion:nil];
    }
    else
    {
        [self showViewController:popVC sender:nil];
    }

}
-(void)showCatalog
{
    //目录
    
    [self showOrHideHeadAndFoot];
    
    //
    EPUBPageCatalogViewController *popVC=[[EPUBPageCatalogViewController alloc] init];
    popVC.epubVC=self;
    popVC.view.backgroundColor=[UIColor whiteColor];
    popVC.backBlock=^(NSMutableDictionary *para1){

        if (para1) {

            NSInteger pageRefIndex=[[para1 objectForKey:@"pageRefIndex"] integerValue];
            [self gotoPageWithPageRefIndex:pageRefIndex WithOffYIndexInPage:0];
        }

        [self dismissViewControllerAnimated:YES completion:nil];

        return 1;
    };
    
    [self showDetailViewController:popVC sender:nil];
    [popVC refresh];
    
}
-(void)showFileInfo
{
    //文件信息
    
    EPUBFileInfoViewController *popVC=[[EPUBFileInfoViewController alloc] init];
    popVC.epubVC=self;
    popVC.view.backgroundColor=[UIColor whiteColor];
    popVC.backBlock=^(NSMutableDictionary *para1){
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
        return 1;
    };
    
    popVC.modalPresentationStyle=UIModalPresentationFormSheet;
    popVC.modalTransitionStyle=UIModalTransitionStyleCrossDissolve;
    
    [self presentViewController:popVC animated:YES completion:^{
        [popVC refresh];
    }];
    //[self showDetailViewController:popVC sender:nil];
    
}
-(void)showFontSelect
{
    //选择字体
    [self showOrHideHeadAndFoot];
    

    EPUBFontViewController *popVC=[[EPUBFontViewController alloc] init];
    popVC.epubVC=self;
    popVC.view.backgroundColor=[UIColor whiteColor];
    
    popVC.backBlock=^(NSMutableDictionary *para1){
        
        
        if (para1) {
            int fontIndex= [[para1 objectForKey:@"fontIndex"] intValue];
            if (fontIndex != self.fontSelectIndex)
            {
                self.jsContent=@"";
                self.fontSelectIndex=fontIndex;
                [self showPageViewController];
            }
            
        }
        
        //[self dismissViewControllerAnimated:YES completion:nil];  //a方式  oK
        //[self.navigationController popToRootViewControllerAnimated:YES];    //b方式  oK
        [self dismissViewControllerAnimated:YES completion:nil];

        
        return 1;
    };
    
    //
    if (self.navigationController) {

        //[self showViewController:popVC sender:nil];  //a方式  oK
        //[self.navigationController pushViewController:popVC animated:YES];  //b方式  oK
        [self.navigationController presentViewController:popVC animated:YES completion:nil];
    }
    else
    {
        [self showViewController:popVC sender:nil];
    }

}
-(void)showImagePreView:(NSMutableDictionary*)info
{
    //图预览
    EPUBImagePreViewController *imgPreVC=[[EPUBImagePreViewController alloc] init];
    imgPreVC.epubVC=self;
    imgPreVC.info=info;
    imgPreVC.backBlock=^int(NSMutableDictionary *para){
        
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
        return 1;
    };
    
    //imgPreVC.wantsFullScreenLayout=YES;
    imgPreVC.modalTransitionStyle=UIModalTransitionStyleCrossDissolve;

    [self presentViewController:imgPreVC animated:YES completion:^{
        
    }];

    
}
-(void)showSearchText
{
    //全文搜索
    
    [self showOrHideHeadAndFoot];
    
    self.pageIsShowSearchResultText=0;
    
    EPUBPageSearchTextViewController *popVC=[[EPUBPageSearchTextViewController alloc] init];
    popVC.epubVC=self;
    popVC.view.backgroundColor=[UIColor whiteColor];
    
    popVC.backBlock=^(NSMutableDictionary *para1){
        
        if (para1) {
            int fontIndex= [[para1 objectForKey:@"searchResultIndex"] intValue];
            NSMutableDictionary *searchItem=[self.arrSearchResult objectAtIndex:fontIndex];
            
            NSInteger pageRefIndex=[[searchItem objectForKey:@"PageRefIndex"] integerValue];
            NSInteger offYIndexInPage=[[searchItem objectForKey:@"OffYIndexInPage"] integerValue];
            
            self.pageIsShowSearchResultText=1;
            
            [self gotoPageWithPageRefIndex:pageRefIndex WithOffYIndexInPage:offYIndexInPage];

        }
        
        
        //[self dismissViewControllerAnimated:YES completion:nil];  //a方式  oK
        //[self.navigationController popToRootViewControllerAnimated:YES];    //b方式  oK
        [self dismissViewControllerAnimated:YES completion:nil];
        
        
        return 1;
    };
    
    //
    if (self.navigationController) {
        
        //[self showViewController:popVC sender:nil];  //a方式  oK
        //[self.navigationController pushViewController:popVC animated:YES];  //b方式  oK
        [self.navigationController presentViewController:popVC animated:YES completion:nil];
    }
    else
    {
        [self showViewController:popVC sender:nil];
    }
    
}
@end
