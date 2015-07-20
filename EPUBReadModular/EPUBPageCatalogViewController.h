//
//  EPUBPageCatalogViewController.h
//  CommonReader
//
//  Created by fanzhenhua on 15/7/9.
//  Copyright (c) 2015年 zjqzy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPUBCustomType.h"

@class EPUBReadMainViewController;
@interface EPUBPageCatalogViewController : UIViewController

@property (weak,nonatomic) EPUBReadMainViewController *epubVC;
@property (strong, nonatomic) EPUBReadBackBlock backBlock; //应该是copy

@property (strong,nonatomic) UIView *headView;
@property (strong,nonatomic) UIView *contentView;
@property (strong,nonatomic) UIView *footView;

@property (strong,nonatomic) UILabel *lbTitle;  //in headView
@property (strong,nonatomic) UIButton *btnBack; //in footView
@property (strong,nonatomic) UITableView *tableView;    //in contentView

-(void)customViewInit:(CGRect)viewRect;     //创建
-(void)resizeViews:(CGRect)viewRect;        //布局
-(void)dataPrepare;                         //数据
-(void)initAfter;                           //线程初始化
-(void)refresh;                             //刷新


@end
