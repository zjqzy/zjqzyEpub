//
//  EPUBPageProgressView.h
//  CommonReader
//
//  Created by fanzhenhua on 15/7/9.
//  Copyright (c) 2015年 zjqzy. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EPUBReadMainViewController;
@interface EPUBPageProgressView : UIView

@property (weak,nonatomic) EPUBReadMainViewController *epubVC;

@property (nonatomic,strong) UISlider *pageSlider;      //
@property (nonatomic,strong) UILabel *pageLabel;        //

-(void)customViewInit:(CGRect)viewRect;     //创建
-(void)resizeViews:(CGRect)viewRect;        //布局
-(void)dataPrepare;                         //数据
-(void)initAfter;                           //线程初始化
-(void)refresh;                             //刷新

@end
