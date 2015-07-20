//
//  EPUBPageOptionView.h
//  CommonReader
//
//  Created by fanzhenhua on 15/7/9.
//  Copyright (c) 2015年 zjqzy. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EPUBReadMainViewController;
@interface EPUBPageOptionView : UIView

@property (weak,nonatomic) EPUBReadMainViewController *epubVC;

@property (nonatomic,strong) UIView *lineView1;
@property (nonatomic,strong) UIView *lineView2;
@property (nonatomic,strong) UIView *lineView3;
@property (nonatomic,strong) UIView *lineView4;

@property (nonatomic,strong) UIImageView *imgViewSun;
@property (nonatomic,strong) UISlider *lightSlider;     //调节亮度
@property (nonatomic,strong) UIImageView *imgViewMoon;

@property (nonatomic,strong) UILabel *lbTextSize;       //字体大小
@property (nonatomic,strong) UIButton *btnTextSize1;    //放大
@property (nonatomic,strong) UIButton *btnTextSize2;    //放大
@property (nonatomic,strong) UIButton *btnFont;         //字体
@property (nonatomic,strong) UIButton *btnTheme1;       //主题
@property (nonatomic,strong) UIButton *btnTheme2;       //主题
@property (nonatomic,strong) UIButton *btnTheme3;       //主题
@property (nonatomic,strong) UIButton *btnOptionMore;   //更多设置

-(void)customViewInit:(CGRect)viewRect;     //创建
-(void)resizeViews:(CGRect)viewRect;        //布局
-(void)dataPrepare;                         //数据
-(void)initAfter;                           //线程初始化
-(void)refresh;                             //刷新

@end
