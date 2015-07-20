//
//  EPUBReadPageViewController.h
//  CommonReader
//
//  Created by fanzhenhua on 15/6/30.
//  Copyright (c) 2015年 zjqzy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EPUBReadMainViewController;
@class EPUBPageWebView;

@interface EPUBPageViewController : UIViewController

@property (weak,nonatomic) EPUBReadMainViewController *epubVC;

@property (strong,nonatomic) UIView *contentView;
@property (strong,nonatomic) EPUBPageWebView *pageWebView;  // in contentView
@property (strong,nonatomic) UIView *titleView;     // in contentView
@property (strong,nonatomic) UIView *statusView;    // in contentView
@property (strong,nonatomic) UILabel *titleLabel;   //
@property (strong,nonatomic) UILabel *pageStatusLabel;  //
@property (strong,nonatomic) UILabel *timeStatusLabel;  //

@property (nonatomic) NSInteger calcPageOffy;   //是否计算 页码的滚动总数
@property (nonatomic) NSInteger pageRefIndex;    //当前页码索引
@property (nonatomic) NSInteger offYIndexInPage;    //页码内 滚动索引
@property (nonatomic) NSInteger isPrePage;          //翻上一页

-(void)customViewInit:(CGRect)viewRect;     //创建
-(void)resizeViews:(CGRect)viewRect;        //布局
-(void)dataPrepare;                         //数据
-(void)initAfter;                           //线程初始化
-(void)refresh;                             //刷新

-(void)GestureRecognizerTapAddOrRemove:(BOOL)isAdd InView:(UIView*)inView;

-(id)getContentFromPoint:(CGPoint)pt1;  //得到 webview点击位置的内容
-(void)addNote:(NSString*)noteContent;

@end
