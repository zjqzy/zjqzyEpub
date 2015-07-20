//
//  EPUBPageProgressView.m
//  CommonReader
//
//  Created by fanzhenhua on 15/7/9.
//  Copyright (c) 2015年 zjqzy. All rights reserved.
//

#import "EPUBReadMainViewController.h"
#import "EPUBPageProgressView.h"

@implementation EPUBPageProgressView

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

    _pageLabel=[[UILabel alloc] init];
    _pageLabel.backgroundColor=[UIColor blackColor];
    _pageLabel.textColor=[UIColor whiteColor];
    _pageLabel.textAlignment=NSTextAlignmentCenter;
    _pageLabel.font=[UIFont systemFontOfSize:12.0f];
    [self addSubview:_pageLabel];
    {
        _pageLabel.layer.masksToBounds=YES;
        _pageLabel.layer.cornerRadius=10;
//        _pageLabel.layer.borderWidth=10;
//        _pageLabel.layer.borderColor=[[UIColor redColor] CGColor];
    }
    
    _pageSlider=[[UISlider alloc] init];
    _pageSlider.maximumValue=1;
    _pageSlider.minimumValue=0;
    [_pageSlider addTarget:self action:@selector(slidingStarted:) forControlEvents:UIControlEventValueChanged];
    [_pageSlider addTarget:self action:@selector(slidingEnded:) forControlEvents:UIControlEventTouchUpInside];
    [_pageSlider addTarget:self action:@selector(slidingEnded:) forControlEvents:UIControlEventTouchUpOutside];
    [self addSubview:_pageSlider];
    
}

-(void)resizeViews:(CGRect)viewRect
{
    //布局
    if (viewRect.size.width <1 || viewRect.size.height < 1) {
        return;
    }
    
    CGRect rectLb1=viewRect;
    rectLb1.size.width=55;
    rectLb1.size.height=30;
    rectLb1.origin.x=(viewRect.size.width -rectLb1.size.width)*0.5f;
    rectLb1.origin.y=-rectLb1.size.height-10;
    _pageLabel.frame=rectLb1;

    
    CGRect rectSlider=viewRect;
    _pageSlider.frame=CGRectInset(rectSlider, 20, 0);
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
}
-(void)refresh
{
    //刷新
    NSInteger currentOffCountInPage=[[self.epubVC.dictPageWithOffYCount objectForKey:[NSString stringWithFormat:@"%@",@(self.epubVC.currentPageRefIndex)]] integerValue];
    if (currentOffCountInPage > 0)
    {
        CGFloat progressValue= (float)(self.epubVC.currentOffYIndexInPage+1) / currentOffCountInPage;
        self.pageSlider.value=progressValue;
        
        self.pageLabel.text=[NSString stringWithFormat:@"%.01f%%",progressValue*100];
    }
    
}

////////////////////////////////////////////////////////////////////////////////
///////////////////        pageSlide      /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (IBAction) slidingStarted:(id)sender
{

    float targetPage = self.pageSlider.value;
    NSString *tmp1=[NSString stringWithFormat:@"%.01f%%",targetPage*100];
    self.pageLabel.text=tmp1;
    
}

- (IBAction)slidingEnded:(id)sender
{

    //
    NSInteger currentOffCountInPage=[[self.epubVC.dictPageWithOffYCount objectForKey:[NSString stringWithFormat:@"%@",@(self.epubVC.currentPageRefIndex)]] integerValue];
    CGFloat progressValue=self.pageSlider.value;
    
    NSInteger offYIndexInPage = currentOffCountInPage * progressValue ;
    if (offYIndexInPage >= currentOffCountInPage)
    {
        offYIndexInPage=currentOffCountInPage-1;
    }
    
    if (offYIndexInPage != self.epubVC.currentOffYIndexInPage)
    {
#ifdef DEBUG
        NSLog(@"%@ 跳转到 %@",@(self.epubVC.currentOffYIndexInPage),@(offYIndexInPage));
#endif
        [self.epubVC gotoPageWithPageRefIndex:self.epubVC.currentPageRefIndex WithOffYIndexInPage:offYIndexInPage];
    }
    
    
    
//    if (targetPage > self.currentPageNumInChapter )
//    {
//        //大于当前页
//        [self AddNextChildViewAnimate:_contentView];
//        [self.pageView gotoPageNumInChapter:targetPage];
//    }
//    else if (targetPage < self.currentPageNumInChapter )
//    {
//        [self AddPreChildViewAnimate:_contentView];
//        [self.pageView gotoPageNumInChapter:targetPage];
//    }
    
}
@end
