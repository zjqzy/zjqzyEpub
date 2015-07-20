//
//  EPUBPageOptionView.m
//  CommonReader
//
//  Created by fanzhenhua on 15/7/9.
//  Copyright (c) 2015年 zjqzy. All rights reserved.
//

#import "EPUBReadMainViewController.h"
#import "EPUBPageOptionView.h"

typedef NS_ENUM(NSInteger, EPUBREADBUTTONTAG)
{
    OPTION_BUTTON_TEXT1=200,
    OPTION_BUTTON_TEXT2,
    OPTION_BUTTON_FONT,
    OPTION_BUTTON_THEME1,
    OPTION_BUTTON_THEME2,
    OPTION_BUTTON_THEME3,
    OPTION_BUTTON_MORE,

};

@implementation EPUBPageOptionView
-(void)dealloc
{
    //析构
    
#if !__has_feature(objc_arc)
    [super dealloc];
    
#endif
    
}
- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code
        [self dataPrepare];
        
        [self customViewInit:self.bounds];
    }
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(void)customViewInit:(CGRect)viewRect
{
    //创建
    UIColor *bgColor=[UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:1.0];
    _lineView1=[[UIView alloc] init];
    _lineView1.backgroundColor=bgColor;
    [self addSubview:_lineView1];
    if (_lineView1)
    {
        //
        _imgViewSun=[[UIImageView alloc] init];
        _imgViewSun.backgroundColor=[UIColor clearColor];
        [_lineView1 addSubview:_imgViewSun];

        //
        _imgViewMoon=[[UIImageView alloc] init];
        _imgViewMoon.backgroundColor=[UIColor clearColor];
        [_lineView1 addSubview:_imgViewMoon];
        
        _lightSlider=[[UISlider alloc] init];
        _lightSlider.maximumValue=1;
        _lightSlider.minimumValue=0;
        [_lightSlider addTarget:self action:@selector(slidingStarted:) forControlEvents:UIControlEventValueChanged];
        [_lightSlider addTarget:self action:@selector(slidingEnded:) forControlEvents:UIControlEventTouchUpInside];
        [_lightSlider addTarget:self action:@selector(slidingEnded:) forControlEvents:UIControlEventTouchUpOutside];
        [_lineView1 addSubview:_lightSlider];
    }
    
    
    _lineView2=[[UIView alloc] init];
    _lineView2.backgroundColor=bgColor;
    [self addSubview:_lineView2];
    if (_lineView2)
    {
        _lbTextSize=[[UILabel alloc] init];
        _lbTextSize.backgroundColor=[UIColor clearColor];
        _lbTextSize.textColor=[UIColor whiteColor];
        _lbTextSize.textAlignment=NSTextAlignmentCenter;
        _lbTextSize.font=[UIFont systemFontOfSize:14.0f];
        _lbTextSize.text=@"20";
        [_lineView2 addSubview:_lbTextSize];
        
        //
        self.btnTextSize1=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnTextSize1.tag=OPTION_BUTTON_TEXT1;
        [self.btnTextSize1 addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_lineView2 addSubview:self.btnTextSize1];
        self.btnTextSize1.titleLabel.font=[UIFont systemFontOfSize:18.0f];
        [self.btnTextSize1 setTitle:NSLocalizedString(@"A-", @"") forState:UIControlStateNormal];
        self.btnTextSize1.showsTouchWhenHighlighted=YES;
        
        //
        self.btnTextSize2=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnTextSize2.tag=OPTION_BUTTON_TEXT2;
        [self.btnTextSize2 addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_lineView2 addSubview:self.btnTextSize2];
        self.btnTextSize2.titleLabel.font=[UIFont systemFontOfSize:18.0f];
        [self.btnTextSize2 setTitle:NSLocalizedString(@"A+", @"") forState:UIControlStateNormal];
        self.btnTextSize2.showsTouchWhenHighlighted=YES;
        
        //
        self.btnFont=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnFont.tag=OPTION_BUTTON_FONT;
        [self.btnFont addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_lineView2 addSubview:self.btnFont];
        self.btnFont.titleLabel.font=[UIFont systemFontOfSize:14.0f];
        [self.btnFont setTitle:NSLocalizedString(@"字体 >", @"") forState:UIControlStateNormal];
        self.btnFont.showsTouchWhenHighlighted=YES;
    }
    
    _lineView3=[[UIView alloc] init];
    _lineView3.backgroundColor=bgColor;
    [self addSubview:_lineView3];
    if (_lineView3)
    {
        self.btnTheme1=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnTheme1.tag=OPTION_BUTTON_THEME1;
        [self.btnTheme1 addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_lineView3 addSubview:self.btnTheme1];
        self.btnTheme1.titleLabel.font=[UIFont systemFontOfSize:14.0f];
        [self.btnTheme1 setTitle:NSLocalizedString(@"白天", @"") forState:UIControlStateNormal];
        self.btnTheme1.showsTouchWhenHighlighted=YES;
        //
        self.btnTheme2=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnTheme2.tag=OPTION_BUTTON_THEME2;
        [self.btnTheme2 addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_lineView3 addSubview:self.btnTheme2];
        self.btnTheme2.titleLabel.font=[UIFont systemFontOfSize:14.0f];
        [self.btnTheme2 setTitle:NSLocalizedString(@"夜间", @"") forState:UIControlStateNormal];
        self.btnTheme2.showsTouchWhenHighlighted=YES;
        //
        self.btnTheme3=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnTheme3.tag=OPTION_BUTTON_THEME3;
        [self.btnTheme3 addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_lineView3 addSubview:self.btnTheme3];
        self.btnTheme3.titleLabel.font=[UIFont systemFontOfSize:14.0f];
        [self.btnTheme3 setTitle:NSLocalizedString(@"护眼", @"") forState:UIControlStateNormal];
        self.btnTheme3.showsTouchWhenHighlighted=YES;
    }
    
    _lineView4=[[UIView alloc] init];
    _lineView4.backgroundColor=bgColor;
    [self addSubview:_lineView4];
    if (_lineView4) {
        self.btnOptionMore=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnOptionMore.tag=OPTION_BUTTON_MORE;
        [self.btnOptionMore addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_lineView4 addSubview:self.btnOptionMore];
        self.btnOptionMore.titleLabel.font=[UIFont systemFontOfSize:14.0f];
        [self.btnOptionMore setTitle:NSLocalizedString(@"更多设置", @"") forState:UIControlStateNormal];
        self.btnOptionMore.showsTouchWhenHighlighted=YES;
    }
    
}

-(void)resizeViews:(CGRect)viewRect
{
    //布局
    if (viewRect.size.width <1 || viewRect.size.height < 1) {
        return;
    }
    
    CGRect rect1=viewRect;
    rect1.size.height=60;
    _lineView1.frame=CGRectInset(rect1, 0, 1);
    if (_lineView1)
    {
        CGRect rectBound=_lineView1.bounds;

        CGRect rectMoon=CGRectMake(10, 10, 40, 40);
        _imgViewMoon.frame=rectMoon;
        
        CGRect rectSun=rectMoon;
        rectSun.origin.x=rectBound.size.width -rectSun.size.width -10;
        _imgViewSun.frame=rectSun;
        
        CGRect rectSlider=CGRectMake(0, 10, 0, 40);
        rectSlider.origin.x=rectMoon.origin.x + rectMoon.size.width+10;
        rectSlider.size.width =rectSun.origin.x-rectSlider.origin.x-10;
        _lightSlider.frame=rectSlider;
    }
    
    CGRect rect2=rect1;
    rect2.origin.y=rect1.origin.y+rect1.size.height;
    //_lineView2.frame=rect2;
    _lineView2.frame=CGRectInset(rect2, 0, 1);
    if (_lineView2) {
        
        CGRect rectBound=_lineView2.bounds;
        CGFloat width=60;
        CGFloat height=40;
        int offx=(rectBound.size.width-60*4)/5;
        int offy=(rectBound.size.height-height) *0.5f;

        CGRect rectBtn1=CGRectMake(offx, offy, width, height);
        self.btnTextSize1.frame=rectBtn1;
        
        CGRect rectBtn2=rectBtn1;
        rectBtn2.origin.x=rectBtn1.origin.x+rectBtn1.size.width+offx;
        _lbTextSize.frame=rectBtn2;
     
        CGRect rectBtn3=rectBtn2;
        rectBtn3.origin.x=rectBtn2.origin.x+rectBtn2.size.width+offx;
        self.btnTextSize2.frame=rectBtn3;
        
        CGRect rectBtn4=rectBtn3;
        rectBtn4.origin.x=rectBtn3.origin.x+rectBtn3.size.width+offx;
        self.btnFont.frame=rectBtn4;
    }
    
    CGRect rect3=rect2;
    rect3.origin.y=rect2.origin.y+rect2.size.height;
    //_lineView3.frame=rect3;
    _lineView3.frame=CGRectInset(rect3, 0, 1);
    if (_lineView3) {
        CGRect rectBound=_lineView3.bounds;
        CGFloat width=60;
        CGFloat height=40;
        int offx=(rectBound.size.width-60*3)/4;
        int offy=(rectBound.size.height-height) *0.5f;
        
        CGRect rectBtn1=CGRectMake(offx, offy, width, height);
        self.btnTheme1.frame=rectBtn1;
        
        CGRect rectBtn2=rectBtn1;
        rectBtn2.origin.x=rectBtn1.origin.x+rectBtn1.size.width+offx;
        self.btnTheme2.frame=rectBtn2;
        
        CGRect rectBtn3=rectBtn2;
        rectBtn3.origin.x=rectBtn2.origin.x+rectBtn2.size.width+offx;
        self.btnTheme3.frame=rectBtn3;
    }
    
    CGRect rect4=rect3;
    rect4.origin.y=rect3.origin.y+rect3.size.height;
    _lineView4.frame=rect4;
    _lineView4.frame=CGRectInset(rect4, 0, 1);
    if (_lineView4) {
        CGRect rectBound=_lineView4.bounds;
        
        CGRect rectBtn1=CGRectMake(0, 0, 60, 40);
        rectBtn1.origin.x=rectBound.size.width-rectBtn1.size.width - 20;
        rectBtn1.origin.y=(rectBound.size.height-rectBtn1.size.height) *0.5f;
        self.btnOptionMore.frame=rectBtn1;
        
    }
    
}

//viewWillLayoutSubviews 属于 view controller
-(void)layoutSubviews
{
    [super layoutSubviews];
    [self resizeViews:self.bounds];
}
//-(void)setFrame:(CGRect)frame
//{
//    [super setFrame:frame];
//    [self resizeViews:self.bounds];
//}
-(void)dataPrepare
{
    //数据
    
}
-(void)initAfter
{
    //后续初始化
    {
        NSString *path1=[self.epubVC fileFindFullPathWithFileName:@"epub_button_sun.png" InDirectory:@"epub.bundle"];
        if (path1)
        {
            UIImage *img1=[[UIImage alloc] initWithContentsOfFile:path1];
            _imgViewSun.image=img1;
            _imgViewSun.contentMode=UIViewContentModeCenter;
        }
    }
    {
        NSString *path1=[self.epubVC fileFindFullPathWithFileName:@"epub_button_moon.png" InDirectory:@"epub.bundle"];
        if (path1)
        {
            UIImage *img1=[[UIImage alloc] initWithContentsOfFile:path1];
            _imgViewMoon.image=img1;
            _imgViewMoon.contentMode=UIViewContentModeCenter;
        }
    }
}
-(void)refresh
{
    //刷新
    self.lightSlider.value=1.0-self.epubVC.maskValue;
    
    self.lbTextSize.text=[NSString stringWithFormat:@"%@",@(self.epubVC.currentTextSize)];
    
}
////////////////////////////////////////////////////////////////////////////////
///////////////////        pageSlide      /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (IBAction) slidingStarted:(id)sender
{
    double value1 = 1.0-self.lightSlider.value;
    NSLog(@"%f",value1);
    self.epubVC.maskValue=value1;
    self.epubVC.maskLightView.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:value1];
}

- (IBAction)slidingEnded:(id)sender
{
    
}

-(void)btnClick:(id)sender
{
    //上下工具栏响应
    NSInteger btnTag= [sender tag];

    if (btnTag == OPTION_BUTTON_TEXT1 )
    {
        //
        [self.epubVC decreaseTextSize];
        [self refresh];
    }
    else if(btnTag == OPTION_BUTTON_TEXT2)
    {
        //
        [self.epubVC increaseTextSize];
        [self refresh];
    }
    else if(btnTag == OPTION_BUTTON_FONT)
    {
        [self.epubVC showFontSelect];
    }
    else if(btnTag == OPTION_BUTTON_THEME1)
    {
        //
        [self.epubVC changeThemeAtIndex:0];
    }
    else if(btnTag == OPTION_BUTTON_THEME2)
    {
        //
        [self.epubVC changeThemeAtIndex:1];
    }
    else if(btnTag == OPTION_BUTTON_THEME3)
    {
        //
        [self.epubVC changeThemeAtIndex:2];
    }
    else if(btnTag == OPTION_BUTTON_MORE)
    {
        //
        [self.epubVC showMoreOption];
    }

}

@end
