//
//  EPUBPageSearchTextViewController.m
//  CommonReader
//
//  Created by fanzhenhua on 15/7/15.
//  Copyright (c) 2015年 zjqzy. All rights reserved.
//

#import "UIWebView+SearchWebView.h"
#import "EPUBParser.h"
#import "EPUBReadMainViewController.h"
#import "EPUBPageWebView.h"
#import "EPUBPageSearchTextViewController.h"

typedef NS_ENUM(NSInteger, EPUBREADBUTTONTAG)
{
    SEARCH_BUTTON_BACK=200,
    
};

@interface EPUBPageSearchTextViewController ()<UITableViewDelegate, UITableViewDataSource,UISearchBarDelegate,UIWebViewDelegate>

@property (strong,nonatomic) EPUBPageWebView *pageWebView;
@property (nonatomic) CGRect rectWeb;
@property (strong,atomic) NSCondition *condition;

@end

@implementation EPUBPageSearchTextViewController

-(void)dealloc
{
    //析构
    
    self.backBlock=nil;
    self.tableView=nil;
    self.pageWebView=nil;
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
    
#ifdef DEBUG
    NSLog(@"析构  EPUBPageSearchTextViewController");
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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self customViewInit:self.view.bounds];

    _pageWebView=[[EPUBPageWebView alloc] init];
    _pageWebView.delegate=self;
    self.rectWeb=[self.epubVC pageWebViewRect];
    _pageWebView.frame=self.rectWeb;
    if ([self.epubVC.jsContent length] <1) {
        self.epubVC.jsContent= [self.epubVC jsContentWithViewRect:self.rectWeb];
    }
    
    _searchBar.text=self.epubVC.currentSearchText;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [self initAfter];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self refresh];
            
        });
    });
    
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
        //
        self.btnBack=[UIButton buttonWithType:UIButtonTypeCustom];
        self.btnBack.tag=SEARCH_BUTTON_BACK;
        [self.btnBack addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_headView addSubview:self.btnBack];
        self.btnBack.titleLabel.font=[UIFont systemFontOfSize:14.0f];
        [self.btnBack setTitle:NSLocalizedString(@"返回", @"") forState:UIControlStateNormal];
        
        //
        _lbTitle=[[UILabel alloc] init];
        _lbTitle.backgroundColor=[UIColor clearColor];
        _lbTitle.textColor=[UIColor whiteColor];
        _lbTitle.textAlignment=NSTextAlignmentCenter;
        _lbTitle.font=[UIFont boldSystemFontOfSize:16.0f];
        _lbTitle.text=NSLocalizedString(@"全文检索", @"");
        [_headView addSubview:_lbTitle];
    }
    
    //
    _contentView=[[UIView alloc] initWithFrame:rectContent];
    [self.view addSubview:_contentView];
    _contentView.backgroundColor=[UIColor clearColor];
    if (_contentView)
    {
        //
        _searchBar=[[UISearchBar alloc] init];
        //        _searchBar.showsCancelButton=YES; //显示一个取消按钮
        //_searchBar.showsSearchResultsButton=YES;
        _searchBar.delegate=self;
        //去掉searchBar的边框
        //[[m_searchBar.subviews objectAtIndex:0] removeFromSuperview];
        [_contentView addSubview:_searchBar];
        
        //
        _lbSearchResult=[[UILabel alloc] init];
        _lbSearchResult.backgroundColor=[UIColor clearColor];
        _lbSearchResult.textAlignment=NSTextAlignmentCenter;
        //_lbResult.textColor=[UIColor greenColor];
        [_contentView addSubview:_lbSearchResult];
        
        //
        _tableView=[[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
//        _tableView.autoresizesSubviews=YES;
        _tableView.dataSource=self;
        _tableView.delegate=self;
        [_contentView addSubview:_tableView];
        
    }
    
    _footView=[[UIView alloc] init];
    _footView.backgroundColor=[UIColor blackColor];
    [self.view addSubview:_footView];
    if (_footView)
    {
        //
        _lbSearchStatus=[[UILabel alloc] init];
        _lbSearchStatus.backgroundColor=[UIColor clearColor];
        _lbSearchStatus.textAlignment=NSTextAlignmentCenter;
        _lbSearchStatus.textColor=[UIColor whiteColor];
        [_footView addSubview:_lbSearchStatus];
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
        CGRect rect1=CGRectMake(10, 20, 60, 44);
        self.btnBack.frame=rect1;
        
        CGRect rect2=rectBound;
        rect2.origin.y=rect1.origin.y;
        rect2.size.height=rect1.size.height;
        _lbTitle.frame=CGRectInset(rect2, 80, 0);
    }
    
    CGRect rectFoot=viewRect;
    rectFoot.size.height=20.0f;
    rectFoot.origin.y=viewRect.size.height-rectFoot.size.height;
    _footView.frame=rectFoot;
    if (_footView) {
        CGRect rectBound=_footView.bounds;
        _lbSearchStatus.frame=CGRectInset(rectBound, 20, 0);
    }
    
    CGRect rectContent=viewRect;
    rectContent.origin.y=rectHead.origin.y+rectHead.size.height;
    rectContent.size.height=rectFoot.origin.y-rectContent.origin.y;
    _contentView.frame=rectContent;
    if (_contentView) {
        CGRect rectBound=_contentView.bounds;
        
        CGRect rectSearchBar=rectBound;
        rectSearchBar.size.height=40;
        _searchBar.frame=rectSearchBar;
        
        CGRect rect1=rectBound;
        rect1.origin.y=rectSearchBar.origin.y+rectSearchBar.size.height;
        rect1.size.height=40;
        _lbSearchResult.frame=rect1;
        
        CGRect rect2=rectBound;
        rect2.origin.y=rect1.origin.y+rect1.size.height;
        rect2.size.height=rectBound.size.height-rect2.origin.y;
        _tableView.frame=rect2;
    }
    
    
}
-(void)dataPrepare
{
    _condition=[[NSCondition alloc] init];
}
-(void)initAfter
{
    //后续初始化
    
}


-(void)refresh
{
    //刷新
    [self.tableView reloadData];
    
    NSUInteger searchResultCount=[self.epubVC.arrSearchResult count];
    if ( searchResultCount>0 ) {
        NSString *text1=[NSString stringWithFormat:@"已找到%@结果",@(searchResultCount)];
        _lbSearchResult.text=text1;
    }
    else
    {
        _lbSearchResult.text=@"";
    }
}
//////////////////////////////////////////////////////////////////////
/////////           UISearchBarDelegate         ///////////////
/////////////////////////////////////////////////////////////////////
#pragma mark - UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    // called when text starts editing
    searchBar.showsCancelButton=YES;
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    // called when text ends editing
    searchBar.showsCancelButton=NO;
}
- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
#ifdef DEBUG
    NSLog(@"点击Cancel");
#endif
    [searchBar endEditing:YES];
    searchBar.text=@"";
    
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
#ifdef DEBUG
    NSLog(@"searchBarSearchButtonClicked searchText=%@", searchBar.text);
#endif
    
    [searchBar endEditing:YES];
    if ([searchBar.text length] >0 )
    {
        [self doSearch:searchBar.text];
    }
    
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    //文本改变触发
    //#ifdef DEBUG
    //    NSLog(@"searchBar textDidChange  searchText=%@", searchText);
    //#endif
    //
}
////////////////////////////////////////////////////////////////////////////////
////////////// UITableViewDataSource  /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    return NSLocalizedString(@"同步设置", @"");
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.epubVC.arrSearchResult count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //int sectionIndex=indexPath.section;
    NSInteger rowIndex =indexPath.row;
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    
    if(cell == nil)
    {

        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
    }
    
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    
    NSMutableDictionary *searchItem=[self.epubVC.arrSearchResult objectAtIndex:rowIndex];
    int pageRefIndex=[searchItem[@"PageRefIndex"] intValue]+1;
    int offYIndexInPage=[searchItem[@"OffYIndexInPage"] intValue]+1;
    cell.textLabel.text = [NSString stringWithFormat:@"第 %@ 页 -  第 %@ 分页", @(pageRefIndex),@(offYIndexInPage)];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"...%@...", searchItem[@"NeighboringText"]];
    
//    EpubSearchResult* hit = (EpubSearchResult*)[self.epubVC.arrSearchResult objectAtIndex:rowIndex];
//    
//    cell.textLabel.text = [NSString stringWithFormat:@"...%@...", hit.neighboringText];
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"Chapter %d - page %d", hit.chapterIndex, hit.pageIndex+1];
    //cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    
    return cell;
}

//- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(3_0)
//{
//    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
//
//    if(cell.accessoryType==UITableViewCellAccessoryCheckmark)
//    {
//        cell.accessoryType=UITableViewCellAccessoryNone;
//    }
//}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //选中行
    NSInteger rowIndex =indexPath.row;
    
    //跳转章节
    if (self.backBlock)
    {
        NSMutableDictionary *para=[NSMutableDictionary dictionary];
        [para setObject:[NSString stringWithFormat:@"%@",@(rowIndex)] forKey:@"searchResultIndex"];
        self.backBlock(para);
    }
}
////////////////////////////////////////////////////////////////////////////////
/////////////////     UIWebViewDelegate     ///////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIWebViewDelegate
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    
#ifdef DEBUG
    NSLog(@"%@", error);
#endif
    
    [self.condition unlock];
}

-(void)webViewDidFinishLoad:(UIWebView*)theWebView
{
    
    NSInteger pageRefIndex=theWebView.tag;
    
    NSString *insertRule1 = [NSString stringWithFormat:@"addCSSRule('html', 'padding: 0px; height: %fpx; -webkit-column-gap: 0px; -webkit-column-width: %fpx;')", theWebView.frame.size.height, theWebView.frame.size.width];
    
    NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', ' font-size:%@px;')", @(self.epubVC.currentTextSize)];
    NSString *setTextSizeRule2 = [NSString stringWithFormat:@"addCSSRule('p', ' font-size:%@px;')", @(self.epubVC.currentTextSize)];
    
    [theWebView stringByEvaluatingJavaScriptFromString:insertRule1];
    [theWebView stringByEvaluatingJavaScriptFromString:setTextSizeRule];
    [theWebView stringByEvaluatingJavaScriptFromString:setTextSizeRule2];


    NSInteger iFind=[(EPUBPageWebView*)theWebView highlightAllOccurencesOfString:self.epubVC.currentSearchText];
    if (iFind)
    {
        NSString *foundHits = [theWebView stringByEvaluatingJavaScriptFromString:@"results"];
        
        //NSLog(@"find=%@ ,chapterIndex=%d,( w:%f h:%f ),foundHits = %@", self.searchText,chapterIndex,webView.bounds.size.width, webView.bounds.size.height,foundHits);
        
        
        NSMutableArray* objects = [[NSMutableArray alloc] init];
        
        NSArray* stringObjects = [foundHits componentsSeparatedByString:@";"];
        for(int i=0; i<[stringObjects count]; i++){
            NSArray* strObj = [[stringObjects objectAtIndex:i] componentsSeparatedByString:@","];
            if([strObj count]==3){
                [objects addObject:strObj];
            }
        }
        
        NSArray* orderedRes = [objects sortedArrayUsingComparator:^(id obj1, id obj2){
            int x1 = [[obj1 objectAtIndex:0] intValue];
            int x2 = [[obj2 objectAtIndex:0] intValue];
            int y1 = [[obj1 objectAtIndex:1] intValue];
            int y2 = [[obj2 objectAtIndex:1] intValue];
            if(y1<y2){
                return NSOrderedAscending;
            } else if(y1>y2){
                return NSOrderedDescending;
            } else {
                if(x1<x2){
                    return NSOrderedAscending;
                } else if (x1>x2){
                    return NSOrderedDescending;
                } else {
                    return NSOrderedSame;
                }
            }
        }];
        

        
        
        //NSLog(@"find chapterIndex=%d,orderedResCount=%d",chapterIndex,[orderedRes count]);
        
        @synchronized(self.epubVC.arrSearchResult)
        {
            for(int i=0; i<[orderedRes count]; i++)
            {
                NSArray* currObj = [orderedRes objectAtIndex:i];
                int offYIndexInPage=[[currObj objectAtIndex:1] intValue]/theWebView.bounds.size.height;
                
                {
                    NSMutableDictionary *searchItem=[NSMutableDictionary dictionary];
                    [searchItem setObject:[NSString stringWithFormat:@"%@",@(pageRefIndex)] forKey:@"PageRefIndex"];
                    [searchItem setObject:[NSString stringWithFormat:@"%@",@(offYIndexInPage)] forKey:@"OffYIndexInPage"];
                    
                    NSString *neighboringText=[theWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"unescape('%@')", [currObj objectAtIndex:2]]] ;
                    [searchItem setObject:neighboringText forKey:@"NeighboringText"];
                    
                    [searchItem setObject:self.epubVC.currentSearchText forKey:@"QueryText"];
                    
                    [self.epubVC.arrSearchResult addObject:searchItem];
                }
                
            }
        }
    }

    
    [self.condition lock];
    [self.condition signal];
    [self.condition unlock];
    
    [self refresh];
}

////////////////////////////////////////////////////////////////////////
//////////////////////        其他         ///////////////
////////////////////////////////////////////////////////////////////////
#pragma mark - 其他
-(void)btnClick:(id)sender
{
    //上下工具栏响应
    NSInteger btnTag= [sender tag];
    
    if (btnTag == SEARCH_BUTTON_BACK )
    {
        if (self.backBlock) {

            self.backBlock(nil);
        }
    }

}
-(void)doSearch:(NSString*)strSearch1
{
    //查询
    
    if ( [strSearch1 isEqualToString:self.epubVC.currentSearchText] || [strSearch1 length] < 1 )
    {
        return;
    }
    
    self.epubVC.currentSearchText=strSearch1;
    
    [self.epubVC.arrSearchResult removeAllObjects];
    
    self.lbSearchStatus.text =NSLocalizedString(@"搜索中", @"");
    self.headView.userInteractionEnabled=NO;
    self.contentView.userInteractionEnabled=NO;
    
    __weak typeof(self) _weakself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{

        for (int tempPageRefIndex=0;tempPageRefIndex<[_weakself.epubVC.epubPageRefs count];++tempPageRefIndex)
        {
            NSString *pageURL=[_weakself.epubVC pageURLWithPageRefIndex:tempPageRefIndex];
            
            if ([_weakself.epubVC isFileExist:pageURL])
            {
                NSString *htmlContent=[_weakself.epubVC.epubParser HTMLContentFromFile:pageURL AddJsContent:nil];
                
                NSRange range = NSMakeRange(0, [htmlContent length]);
                range = [htmlContent rangeOfString:_weakself.epubVC.currentSearchText options:NSCaseInsensitiveSearch range:range locale:nil];
                
                int findCount=0;
                while (range.location != NSNotFound)
                {
                    range = NSMakeRange(range.location+range.length, [htmlContent length]-(range.location+range.length));
                    range = [htmlContent rangeOfString:_weakself.epubVC.currentSearchText options:NSCaseInsensitiveSearch range:range locale:nil];
                    ++findCount;
                }

                if (findCount > 0) {
                    // 找到 对应的 html
                    
#ifdef DEBUG
                    NSLog(@"页码=%@,找到=%@",@(tempPageRefIndex),@(findCount));
#endif
                    
                    _pageWebView.tag=tempPageRefIndex;

                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSString *htmlContent=[self.epubVC.epubParser HTMLContentFromFile:pageURL AddJsContent:self.epubVC.jsContent];
                        NSURL* baseURL = [NSURL fileURLWithPath:pageURL];
                        [_pageWebView loadHTMLString:htmlContent baseURL:baseURL];
                    });
                    
                    [_weakself.condition lock];
                    [_weakself.condition wait];
                    [_weakself.condition unlock];
                }

            }

        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _weakself.lbSearchStatus.text =NSLocalizedString(@"", @"");
            self.headView.userInteractionEnabled=YES;
            self.contentView.userInteractionEnabled=YES;
        });
    });

}

@end
