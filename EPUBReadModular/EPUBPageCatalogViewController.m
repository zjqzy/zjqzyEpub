//
//  EPUBPageCatalogViewController.m
//  CommonReader
//
//  Created by fanzhenhua on 15/7/9.
//  Copyright (c) 2015年 zjqzy. All rights reserved.
//
#import "EPUBReadMainViewController.h"
#import "EPUBPageCatalogViewController.h"

typedef NS_ENUM(NSInteger, EPUBREADBUTTONTAG)
{
    OPTION_BUTTON_BACK=200,
    
};

@interface EPUBPageCatalogViewController ()<UITableViewDelegate, UITableViewDataSource>

@end

@implementation EPUBPageCatalogViewController
-(void)dealloc
{
    //析构
    self.backBlock=nil;
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
    
#ifdef DEBUG
    NSLog(@"析构 EPUBPageCatalogViewController");
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
    
    //
    if (self.epubVC.epubInfo) {
        NSString *title=[self.epubVC.epubInfo objectForKey:@"dc:title"];
        _lbTitle.text=title;
    }
    
    [self performSelector:@selector(refreshSelectRow) withObject:nil afterDelay:0.5f];
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
        [_headView addSubview:_lbTitle];
    }
    
    //
    _footView=[[UIView alloc] init];
    _footView.backgroundColor=[UIColor blackColor];
    [self.view addSubview:_footView];
    if (_footView) {
        self.btnBack=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnBack.tag=OPTION_BUTTON_BACK;
        [self.btnBack addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_footView addSubview:self.btnBack];
        self.btnBack.titleLabel.font=[UIFont systemFontOfSize:14.0f];
        [self.btnBack setTitle:NSLocalizedString(@"返回", @"") forState:UIControlStateNormal];

    }
    
    //
    _contentView=[[UIView alloc] initWithFrame:rectContent];
    [self.view addSubview:_contentView];
    _contentView.backgroundColor=[UIColor clearColor];
    if (_contentView)
    {
        _tableView=[[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.autoresizesSubviews=YES;
        _tableView.dataSource=self;
        _tableView.delegate=self;
        [_contentView addSubview:_tableView];
        
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
        
        CGRect rectTitle=CGRectMake(60, 20, 0, 44);
        rectTitle.size.width=rectBound.size.width-rectTitle.origin.x*2;
        _lbTitle.frame=rectTitle;
    }
    
    CGRect rectFoot=CGRectMake(0, 0, viewRect.size.width, 44.0f);
    rectFoot.origin.y=viewRect.size.height-rectFoot.size.height;
    _footView.frame=rectFoot;
    if (_footView) {
        
        CGRect rectBound=_footView.bounds;
        
        CGRect rect1=CGRectMake(0, 2, 60, 40);
        rect1.origin.x=(rectBound.size.width-rect1.size.width) * 0.5f;
        self.btnBack.frame=rect1;
    }
    
    CGRect rectContent=viewRect;
    rectContent.origin.y=rectHead.origin.y+rectHead.size.height;
    rectContent.size.height=rectFoot.origin.y-rectContent.origin.y;
    _contentView.frame=rectContent;
    if (_contentView) {
        CGRect rectBound=_contentView.bounds;
        
        _tableView.frame=rectBound;
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

    
}
-(void)refreshSelectRow
{
    //currentPageRefIndex
    NSMutableDictionary *item=[self.epubVC catalogWithPageRef:self.epubVC.currentPageRefIndex];
    if (item)
    {
        NSUInteger rowIndex= [self.epubVC.epubCatalogs indexOfObject:item];
        
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:rowIndex inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    }

}
////////////////////////////////////////////////////////////////////////
///////// Table view data source ///////////////
////////////////////////////////////////////////////////////////////////
#pragma mark - TableView data source delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return [self.epubVC.epubCatalogs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    //int sectionIndex=indexPath.section;
    NSInteger rowIndex =indexPath.row;
    UITableViewCell *cell=nil;
    
    static NSString *CellIdentifier = @"Cell";
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if( !cell )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    NSMutableDictionary *item1=self.epubVC.epubCatalogs[rowIndex];

    NSString *strContent=[NSString stringWithFormat:@"%@",[item1 objectForKey:@"text"]];
    cell.textLabel.text = strContent;
    cell.textLabel.font=[UIFont boldSystemFontOfSize:14.0f];
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowIndex =indexPath.row;
    
    NSMutableDictionary *item1=self.epubVC.epubCatalogs[rowIndex];
    
    if (item1) {
        NSInteger pageRefIndex=[self.epubVC pageRefIndexWithCatalogItem:item1];
        NSMutableDictionary *para=[NSMutableDictionary dictionary];
        [para setObject:[NSString stringWithFormat:@"%@",@(pageRefIndex)] forKey:@"pageRefIndex"];
        if (self.backBlock) {
            self.backBlock(para);
        }
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
    
    if (btnTag == OPTION_BUTTON_BACK )
    {
        if (self.backBlock) {
            self.backBlock(nil);
        }
    }

    
}
@end
