//
//  EPUBReadMainViewController.h
//  CommonReader
//
//  Created by fanzhenhua on 15/6/30.
//  Copyright (c) 2015年 zjqzy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EPUBCustomType.h"

@class EPUBParser;

@interface EPUBReadMainViewController : UIViewController

////////////////////////////////////////////////////////////////////////////////
////////////////////    必需输入项   ////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

//require 需要外部环境创建, 之后赋值进来
@property (weak, nonatomic) EPUBParser *epubParser;

//fileInfo的key选项={fileFullPath}
//fileFullPath 本地绝对路径
//(必填项:fileFullPath)
@property (strong, nonatomic) NSMutableDictionary *fileInfo;//require 文件信息

@property (strong, nonatomic) EPUBReadBackBlock epubReadBackBlock; //应该是copy

////////////////////////////////////////////////////////////////////////////////
//////////   私有， 请不要在外部干预  ,当做 readonly 即可 //////////////
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic) int isPhone;  //是否为手机
@property (nonatomic,strong) UIFont *fontCustom1;
@property (strong,nonatomic) NSString *unzipEpubFolder; //epub解压到

@property (nonatomic,strong) NSMutableDictionary *epubInfo; //epub基本信息
@property (nonatomic,strong) NSMutableArray *epubCatalogs;  //epub目录信息
@property (nonatomic,strong) NSMutableArray *epubPageRefs;  //epub页码索引
@property (nonatomic,strong) NSMutableArray *epubPageItems; //epub页码信息

//@property (nonatomic) NSInteger curPageIndex;//当前显示页码, 如果是一屏双页，则需要小心，往前翻则为左侧页码，往后翻则为右侧页码

@property (nonatomic) NSInteger displayStyle;           //当前显示样式改变
@property (nonatomic) NSInteger currentTextSize;              //文字大小
@property (nonatomic) NSInteger currentPageRefIndex;    //当前页码索引
@property (nonatomic) NSInteger currentOffYIndexInPage; //页码内 滚动索引
//@property (nonatomic) NSInteger currentOffCountInPage;  //页码内 滚动索引 总数
@property (strong,nonatomic) NSMutableDictionary *dictPageWithOffYCount;    //记录 ［页码，滚动次数］

@property (nonatomic,strong) NSString *jsContent;           //js脚本

@property (nonatomic,strong) NSMutableArray *arrTheme;  //主题数据
@property (nonatomic) NSInteger themeIndex;             //当前主题索引

@property (nonatomic,strong) UIView *maskLightView; //亮度遮罩层
@property (nonatomic) double maskValue;                 //范围[0 - 1.0]

@property (nonatomic,strong) NSMutableArray *arrFont;   //字体
@property int fontSelectIndex;

@property (nonatomic,strong) NSMutableArray *arrSearchResult;   //查找结果数组
@property (nonatomic,strong) NSString *currentSearchText;
@property (nonatomic) NSInteger pageIsShowSearchResultText;  //查找内容是否在页面上进行特殊显示

@property (nonatomic,strong) NSMutableArray *arrNotes;      //笔记数组
///////////////////////////////////////////////////////////////////////////
/////////////////  公共方法  /////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
-(NSString*)getTimeStringWithFormat:(NSString*)formatString;
-(NSString*)getNowTimeIntervalString;
-(NSString*)getDateStringFromTimeInterval:(NSString*)strTimeInterval;
-(NSString*)NSDateToNSString:(NSDate*)data1;
-(NSString*)UIColorToNSString:(UIColor*)color;
-(UIColor*)NSStringToUIColor:(NSString*)strColor;
-(UIColor*)UIColorFromRGBString:(NSString*)strRGB;
-(NSString*)fileFindFullPathWithFileName:(NSString*)fileName InDirectory:(NSString*)inDirectory;
-(BOOL)isFileExist:(NSString *)path;
-(BOOL)createDirectory:(NSString*)strFolderPath;
-(BOOL)deleteFileAtPath:(NSString*)path;
-(NSString*)trimWhiteSpace:(NSString*)strContent;
-(NSString*)trimWhiteSpaceAndNewLine:(NSString*)strContent;
-(NSString*)getFileMD5WithPath:(NSString*)path;
-(BOOL)imageSaveFile:(NSString*)strSaveFile withImage:(UIImage*)img;
-(NSMutableDictionary*)getDictionaryFromString:(NSString*)str1 WithSeparatedString:(NSString*)sep;
-(NSString*)getStringFromDictionary:(NSDictionary*)dict1 WithSeparatedString:(NSString*)sep;
-(int)openURLWithString:(NSString*)strURL;
-(NSString*)parentFolderWithFilePath:(NSString*)fileFullPath;
-(NSMutableArray*)fontLists;

-(void)closeMsg;     //消息关闭
-(int)showMsgInView:(UIView*)inView ContentString:(NSString*)strContent isActivity:(BOOL)isA HideAfter:(NSTimeInterval)delay;    //消息显示
////////////////////////////////////////////////////////////////////////////////
////////////////////   其他   ////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
-(void)refresh;   //刷新
-(void)refreshPageViewController;
-(void)CloseTotalReadingTime;//按 home 键   停止阅读累计
-(void)StartTotalReadingTime;//按 start 键  阅读累计 起始时间
-(NSInteger)pageRefIndexWithCatalogItem:(NSMutableDictionary*)itemCatalog;//根据目录，返回对应的 pageRef
-(NSMutableDictionary*)catalogWithPageRef:(NSInteger)pageRefIndex;//根据当前页码索引  返回对应的 目录信息
-(NSMutableDictionary*)pageItemWithPageRef:(NSString*)pageRef;//根据 pageRef  返回对应的 pageItem
-(NSString*)pageURLWithPageRefIndex:(NSInteger)pageRefIndex;//得到当前页码索引的路径
-(NSString*)jsContentWithViewRect:(CGRect)rectView;
-(void)showOrHideHeadAndFoot;       //显示工具栏
-(void)loadEpubTheme;               //读取主题
-(void)setPageViewTransitionStyle:(NSInteger)transitionStyle;
-(NSInteger)pageViewTransitionStyle;
-(CGRect)pageWebViewRect;
-(void)gotoPageWithPageRefIndex:(NSInteger)pageRefIndex WithOffYIndexInPage:(NSInteger)offYIndexInPage;//跳转页码
-(void)increaseTextSize;    //文字大小
-(void)decreaseTextSize;    //文字大小
-(void)changeThemeAtIndex:(NSInteger)index;  //切换主题
-(void)showMoreOption;      //更多设置
-(void)showCatalog;         //目录
-(void)showFileInfo;        //文件信息
-(void)showFontSelect;      //选择字体
-(void)showImagePreView:(NSMutableDictionary*)info; //图片预览
-(void)showSearchText;      //全文搜索

@end
