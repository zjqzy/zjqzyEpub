//
//  EPUBFileInfoViewController.m
//  CommonReader
//
//  Created by fanzhenhua on 15/7/14.
//  Copyright (c) 2015年 zjqzy. All rights reserved.
//
#import "EPUBReadMainViewController.h"
#import "EPUBFileInfoViewController.h"

typedef NS_ENUM(NSInteger, EPUBREADBUTTONTAG)
{
    FILEINFO_BUTTON_BACK=200,
    
};
@interface EPUBFileInfoViewController ()

@end

@implementation EPUBFileInfoViewController
-(void)dealloc
{
    //析构
    self.backBlock=nil;
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
    
#ifdef DEBUG
    NSLog(@"析构 EPUBFileInfoViewController");
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
    
    
    //界面
    [self customViewInit:self.view.bounds];
    
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
    
    _headView=[[UIView alloc] init];
    _headView.backgroundColor=[UIColor blackColor];
    [self.view addSubview:_headView];
    if (_headView)
    {
        
        _lbTitle=[[UILabel alloc] init];
        _lbTitle.backgroundColor=[UIColor clearColor];
        _lbTitle.textColor=[UIColor whiteColor];
        _lbTitle.textAlignment=NSTextAlignmentCenter;
        _lbTitle.font=[UIFont boldSystemFontOfSize:16.0f];
        _lbTitle.text=NSLocalizedString(@"文件信息", @"");
        [_headView addSubview:_lbTitle];
        
        self.btnBack=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnBack.tag=FILEINFO_BUTTON_BACK;
        [self.btnBack addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_headView addSubview:self.btnBack];
        self.btnBack.titleLabel.font=[UIFont systemFontOfSize:14.0f];
        [self.btnBack setTitle:NSLocalizedString(@"返回", @"") forState:UIControlStateNormal];
    }

    //
    _contentView=[[UIView alloc] initWithFrame:viewRect];
    [self.view addSubview:_contentView];
    _contentView.backgroundColor=[UIColor clearColor];
    if (_contentView)
    {
        
        _txtView=[[UITextView alloc] init];
//        _txtView.layer.borderColor=[[UIColor grayColor] CGColor];
//        _txtView.layer.borderWidth=1;
        _txtView.backgroundColor=[UIColor whiteColor];
        _txtView.textAlignment=NSTextAlignmentLeft;
        _txtView.font=[UIFont boldSystemFontOfSize:18.0f];
        _txtView.editable=NO;
        [_contentView addSubview:_txtView];

        
    }
    
}

-(void)resizeViews:(CGRect)viewRect
{
    //整体界面调整
    
    if (viewRect.size.width<1 || viewRect.size.height<1) {
        return;
    }
    
    CGRect rectHead=viewRect;
    rectHead.size.height=64.0f;
    _headView.frame=rectHead;
    if (_headView) {
        CGRect rectBound=_headView.bounds;
        
        CGRect rectTitle=CGRectMake(80, 20, 0, 44);
        rectTitle.size.width=rectBound.size.width-rectTitle.origin.x*2;
        _lbTitle.frame=rectTitle;
        
        CGRect rect1=CGRectMake(10, 20, 60, 44);
        self.btnBack.frame=rect1;
    }

    CGRect rectContent=viewRect;
    rectContent.origin.y=rectHead.origin.y+rectHead.size.height;
    rectContent.size.height=viewRect.size.height-rectContent.origin.y;
    _contentView.frame=rectContent;
    if (_contentView) {
        CGRect rectContentBound=_contentView.bounds;
        _txtView.frame=rectContentBound;
    }
    
}
-(void)dataPrepare
{
    
}
-(void)initAfter
{
    //后续初始化
    
}


-(void)refresh
{
    //刷新
    if (self.epubVC.epubInfo) {
        NSString *title=[self.epubVC.epubInfo objectForKey:@"dc:title"];
        NSString *creator=[self.epubVC.epubInfo objectForKey:@"dc:creator"];
        NSString *fileFullPath=[self.epubVC.fileInfo objectForKey:@"fileFullPath"];
        NSString *fileName=[fileFullPath lastPathComponent];
        
        NSString *strContent=[NSString stringWithFormat:@"标题＝%@\n作者＝%@\n文件名＝%@\n\n\nThanks for using\nzhu.jian.qi@163.com",title,creator,fileName];
        _txtView.text=strContent;
        
    }
    
    
}
////////////////////////////////////////////////////////////////////////
//////////////////////        其他         ///////////////
////////////////////////////////////////////////////////////////////////
#pragma mark - 其他
-(void)btnClick:(id)sender
{
    //上下工具栏响应
    NSInteger btnTag= [sender tag];
    
    if (btnTag == FILEINFO_BUTTON_BACK )
    {
        if (self.backBlock) {
            self.backBlock(nil);
        }
    }
    
    
}
@end
