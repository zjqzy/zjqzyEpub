//
//  EPUBParser.m
//  CommonReader
//
//  Created by fanzhenhua on 15/7/2.
//  Copyright (c) 2015年 zjqzy. All rights reserved.
//

#import "ZipArchive.h"
#import "GDataXMLNode.h"

#import "EPUBParser.h"

@implementation EPUBParser

-(void)dealloc
{
    //析构
#ifdef DEBUG
    NSLog(@"析构 EPUBParser ");
#endif
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
    
}
-(NSString*)description
{
    //描述
    NSString *strDesc=[NSString stringWithFormat:@"class=%@",[NSString stringWithUTF8String:object_getClassName(self)]];
    return strDesc;
}

-(id)init
{
    //初始化
    if (self = [super init])
    {

    }
    
    return self;
}
////////////////////////////////////////////////////////////////////////////////
///////////////////      通用方法     /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - 通用方法
-(BOOL)isFileExist:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:path];
}

-(BOOL)createDirectory:(NSString*)strFolderPath
{
    //创建文件夹
    BOOL bDo1=YES;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:strFolderPath] == NO) {
        bDo1=[fileManager createDirectoryAtPath:strFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return bDo1;
}
-(BOOL)deleteDirectory:(NSString*)strFolderPath DelSelf:(BOOL)bDelSelf
{
    //删除文件夹（自身是否删除）
    BOOL bDo1=YES;
    
    NSFileManager *localFileManager=[NSFileManager defaultManager];
    if (bDelSelf)
    {
        //删除自身
        if (! [localFileManager removeItemAtPath:strFolderPath error:nil])
        {
#ifdef DEBUG
            NSLog(@"fail del=%@",strFolderPath);
#endif
            bDo1=NO;
        }
    }
    else
    {
        //不删除自身
        NSDirectoryEnumerator *dirEnum =[localFileManager enumeratorAtPath:strFolderPath];
        NSString *file;
        while (file = [dirEnum nextObject])
        {
            NSString *delPath=[strFolderPath stringByAppendingPathComponent:file];
            if (! [localFileManager removeItemAtPath:delPath error:nil])
            {
#ifdef DEBUG
                NSLog(@"fail del=%@",delPath);
#endif
                bDo1=NO;
            }
        }
    }
    
    return bDo1;
}
-(int)unzipWithFileFullPath:(NSString*)fileFullPath WithUnzipFolder:(NSString *)unzipFolder
{
    //解压epub
    int iResult=1;
    
    //开始解压
    ZipArchive* za = [[ZipArchive alloc] init];
    if( [za UnzipOpenFile:fileFullPath])
    {

        //start unzip
        [self deleteDirectory:unzipFolder DelSelf:NO];
        BOOL bUnZip = [za UnzipFileTo:[NSString stringWithFormat:@"%@/",unzipFolder] overWrite:YES];

        [za UnzipCloseFile];
        
        if ( ! bUnZip)
        {
            self.lastError=[NSString stringWithFormat:@"Error while unzipping the epub ,file=%@",fileFullPath];
            
            iResult=0;
        }

    }
    
#if !__has_feature(objc_arc)
    [za release];
#endif
    
    return iResult;
}
////////////////////////////////////////////////////////////////////////////////
///////////////////      公共方法     /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - 公共方法
-(void)closeFile
{
    self.lastError=nil;
}
-(int)openFilePath:(NSString*)fileFullPath WithUnzipFolder:(NSString*)unzipFolder
{
    
    //打开文件 
    int iResult=0;
    
    if ( ! [self isFileExist:fileFullPath] || ![self isFileExist:unzipFolder]) {
        return iResult;
    }
    
    //解压epub
    if ([self unzipWithFileFullPath:fileFullPath WithUnzipFolder:unzipFolder])
    {
        iResult=1;
    }
    
    return iResult;

}

-(NSString*)opfFilePathWithManifestFile:(NSString*)manifestFileFullPath WithUnzipFolder:(NSString*)unzipFolder
{
    //通过container.xml 得到 OPS/epb.opf 的绝对路径
    //container.xml 主要功能是告诉阅读器 电子书的跟文件 rootfile 路径 和打开方式 ， 一般不改
    
    NSString *opfFileFullPath=nil;
    
    NSData *xmlData=[[NSData alloc] initWithContentsOfFile:manifestFileFullPath];
    if (xmlData)
    {
        NSError *err = nil;
        GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&err];
        
        if ([err code] == 0)
        {
            //根节点
            GDataXMLElement *root = [doc rootElement];
            NSArray *nodes=[root nodesForXPath:@"//@full-path[1]" error:nil];
            if ([nodes count]>0)
            {
                GDataXMLElement *opfNode=nodes[0];
                
                opfFileFullPath=[NSString stringWithFormat:@"%@/%@",unzipFolder,[opfNode stringValue]];
            }
            else
            {
                self.lastError=[NSString stringWithFormat:@"解析 manifest 未找到opf路径节点"];
            }
        }
        else
        {
            self.lastError=[NSString stringWithFormat:@"解析 manifest 错误 ,err=%@",err];
        }
#if !__has_feature(objc_arc)
        [doc release];;
#endif
        
    }
    else
    {
        self.lastError=[NSString stringWithFormat:@"manifest 内容为空 ,file=%@",manifestFileFullPath];
        
    }
    
#if !__has_feature(objc_arc)
    [xmlData release];;
#endif
    
    return opfFileFullPath;
}

-(NSString*)ncxFilePathWithOpfFile:(NSString*)opfFilePath WithUnzipFolder:(NSString*)unzipFolder
{
    //通过opf  得到 ncx 的绝对路径
    NSString *ncxFileName=nil;
    NSData *xmlData=[[NSData alloc] initWithContentsOfFile:opfFilePath];
    if (xmlData)
    {
        NSError *err = nil;
        GDataXMLDocument *opfXmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&err];
        
        if ([err code] == 0)
        {
            //根节点
            GDataXMLElement *root = [opfXmlDoc rootElement];
            
            //opf 的 "item" 标签
            NSError *errXPath = nil;
            NSDictionary *namespaceMappings=[NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"];
            
            NSArray* itemsArray =[root nodesForXPath:@"//opf:item[@id='ncx']" namespaces:namespaceMappings error:&errXPath];
            if ([itemsArray count]<1)
            {
                itemsArray =[root nodesForXPath:@"//item[@id='ncx']" namespaces:namespaceMappings error:&errXPath];
            }
            
            if ([itemsArray count]>0)
            {
                GDataXMLElement *element=itemsArray[0];
                NSString *itemhref=[[element attributeForName:@"href"] stringValue];
                ncxFileName = itemhref;
            }
        }
        
#if !__has_feature(objc_arc)
        [opfXmlDoc release];;
#endif
    }
    
#if !__has_feature(objc_arc)
    [xmlData release];;
#endif
    
    if (ncxFileName && [ncxFileName length]>0)
    {
        NSInteger lastSlash = [opfFilePath rangeOfString:@"/" options:NSBackwardsSearch].location;
        NSString *ebookBasePath = [opfFilePath substringToIndex:(lastSlash +1)];
        NSString *ncxFileFullPath=[NSString stringWithFormat:@"%@%@", ebookBasePath, ncxFileName];
        return ncxFileFullPath;
    }
    
    return nil;
}
-(NSString*)coverFilePathWithOpfFile:(NSString*)opfFilePath WithUnzipFolder:(NSString*)unzipFolder
{
    //通过opf  得到 封面 的绝对路径
    NSString *coverFileName=nil;
    NSData *xmlData=[[NSData alloc] initWithContentsOfFile:opfFilePath];
    if (xmlData)
    {
        NSError *err = nil;
        GDataXMLDocument *opfXmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&err];
        
        if ([err code] == 0)
        {
            //根节点
            GDataXMLElement *root = [opfXmlDoc rootElement];
            
            //opf 的 "item" 标签
            NSError *errXPath = nil;
            NSDictionary *namespaceMappings=[NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"];
            
            NSArray* itemsArray =[root nodesForXPath:@"//opf:item[@id='cover']" namespaces:namespaceMappings error:&errXPath];
            if ([itemsArray count]<1)
            {
                itemsArray =[root nodesForXPath:@"//item[@id='cover']" namespaces:namespaceMappings error:&errXPath];
            }
            
            if ([itemsArray count]>0)
            {
                GDataXMLElement *element=itemsArray[0];
                NSString *itemhref=[[element attributeForName:@"href"] stringValue];
                coverFileName = itemhref;
            }
        }
        
#if !__has_feature(objc_arc)
        [opfXmlDoc release];;
#endif
    }
    
#if !__has_feature(objc_arc)
    [xmlData release];;
#endif
    
    if (coverFileName && [coverFileName length]>0)
    {
        NSInteger lastSlash = [opfFilePath rangeOfString:@"/" options:NSBackwardsSearch].location;
        NSString *ebookBasePath = [opfFilePath substringToIndex:(lastSlash +1)];
        NSString *coverFileFullPath=[NSString stringWithFormat:@"%@%@", ebookBasePath, coverFileName];
        return coverFileFullPath;
    }

    return nil;
}
-(NSMutableDictionary*)epubFileInfoWithOpfFile:(NSString*)opfFilePath
{
    //得到epub 文件信息 ， 如 作者，标题
    NSMutableDictionary *epubInfo=nil;
    NSData *xmlData=[[NSData alloc] initWithContentsOfFile:opfFilePath];
    if (xmlData)
    {
        NSError *err = nil;
        GDataXMLDocument *opfXmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&err];
        
        if ([err code] == 0)
        {
            //根节点
            GDataXMLElement *root = [opfXmlDoc rootElement];
            
            NSError *errXPath = nil;
            NSDictionary *namespaceMappings=[NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"];
            
            NSArray* itemsMetadata=[root nodesForXPath:@"//opf:metadata" namespaces:namespaceMappings error:&errXPath];
            if ([itemsMetadata count]>0)
            {
                epubInfo=[NSMutableDictionary dictionary];
                
                GDataXMLElement *nodeMetadata=itemsMetadata[0];
                for (GDataXMLElement *child in [nodeMetadata children])
                {
                    NSString *nodeName=[child name];
                    NSString *nodeValue=[child stringValue];
                    
                    [epubInfo setObject:nodeValue forKey:nodeName];
                }
            }
            
        }
        
#if !__has_feature(objc_arc)
        [opfXmlDoc release];;
#endif
    }
    
#if !__has_feature(objc_arc)
    [xmlData release];;
#endif
    
    
    return epubInfo;
}
-(NSMutableArray*)epubCatalogWithNcxFile:(NSString*)ncxFilePath
{
    //根据 ncx文件， 得到目录信息
    NSMutableArray *arrCatalog=nil;
    NSData *xmlData=[[NSData alloc] initWithContentsOfFile:ncxFilePath];
    if (xmlData) {
        
        NSError *err = nil;
        GDataXMLDocument *ncxXmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&err];
        if ([err code] == 0)
        {
            arrCatalog=[NSMutableArray array];
            
            //根节点
            GDataXMLElement *root = [ncxXmlDoc rootElement];

            NSDictionary *dictNameSpace=[NSDictionary dictionaryWithObject:@"http://www.daisy.org/z3986/2005/ncx/" forKey:@"ncx"];
            NSError *errXPath = nil;
            NSArray *navPoints= [root nodesForXPath:@"ncx:navMap/ncx:navPoint" namespaces:dictNameSpace error:&errXPath];
            
            for (GDataXMLElement *navPoint in navPoints)
            {
                NSString *id1=[[navPoint attributeForName:@"id"] stringValue];
                
                NSString *playOrder=[[navPoint attributeForName:@"playOrder"] stringValue];

                
                NSArray *textNodes=[navPoint nodesForXPath:@"ncx:navLabel/ncx:text" namespaces:dictNameSpace error:nil];
                NSString *ncx_text=@"";
                if ([textNodes count]>0) {
                    GDataXMLElement *nodeLabel=textNodes[0];
                    ncx_text=[nodeLabel stringValue];
                }
                
                NSArray *contentNodes=[navPoint nodesForXPath:@"ncx:content" namespaces:dictNameSpace error:nil];
                NSString *ncx_src=@"";
                if ([contentNodes count]>0) {
                    GDataXMLElement *nodeContent=contentNodes[0];
                    ncx_src=[[nodeContent attributeForName:@"ncx:src"] stringValue];
                }

                //添加
                NSMutableDictionary *oneChapter=[NSMutableDictionary dictionary];
                [oneChapter setObject:[id1 length]>0?id1:@"" forKey:@"id"];
                [oneChapter setObject:[playOrder length]>0?playOrder:@"" forKey:@"playOrder"];
                [oneChapter setObject:[ncx_text length]>0?ncx_text:@"" forKey:@"text"];
                [oneChapter setObject:[ncx_src length]>0?ncx_src:@"" forKey:@"src"];
                
                [arrCatalog addObject:oneChapter];
            }
        }
        
        
#if !__has_feature(objc_arc)
        [ncxXmlDoc release];;
#endif
        
    }
    
#if !__has_feature(objc_arc)
    [xmlData release];;
#endif
    
    
    return arrCatalog;
}
-(NSMutableArray*)epubPageRefWithOpfFile:(NSString*)opfFilePath
{
    //得到页码索引
    NSMutableArray *arrPageRef=nil;
    NSData *xmlData=[[NSData alloc] initWithContentsOfFile:opfFilePath];
    if (xmlData)
    {
        NSError *err = nil;
        GDataXMLDocument *opfXmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&err];
        
        if ([err code] == 0)
        {
            //根节点
            GDataXMLElement *root = [opfXmlDoc rootElement];
            
            NSError *errXPath = nil;
            NSDictionary *namespaceMappings=[NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"];

            NSArray* itemRefsArray =[root nodesForXPath:@"//opf:itemref" namespaces:namespaceMappings error:&errXPath];

            if(itemRefsArray.count < 1)
            {
                NSString* xpath = [NSString stringWithFormat:@"//spine[@toc='ncx']/itemref"];
                //NSString* xpath = [NSString stringWithFormat:@"//spine/itemref"];
                //itemRefsArray = [opfXmlDoc nodesForXPath:@"//itemref" namespaceMappings:[NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"] error:nil];
                itemRefsArray = [root nodesForXPath:xpath namespaces:namespaceMappings error:&errXPath];
            }
            
            arrPageRef=[NSMutableArray array];
            for (GDataXMLElement* element in itemRefsArray)
            {
                NSString *idref1=[[element attributeForName:@"idref"] stringValue];
                if (idref1 && [idref1 length] > 0) {
                    [arrPageRef addObject:idref1];
                }
            
            }
            
        }
        
#if !__has_feature(objc_arc)
        [opfXmlDoc release];
#endif
    }
    
#if !__has_feature(objc_arc)
    [xmlData release];
#endif
    
    return arrPageRef;
}

-(NSMutableArray*)epubPageItemWithOpfFile:(NSString*)opfFilePath
{
    //得到页码信息
    NSMutableArray *arrPageItem=nil;
    NSData *xmlData=[[NSData alloc] initWithContentsOfFile:opfFilePath];
    if (xmlData)
    {
        NSError *err = nil;
        GDataXMLDocument *opfXmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&err];
        
        if ([err code] == 0)
        {
            //根节点
            GDataXMLElement *root = [opfXmlDoc rootElement];
            
            //opf 的 "item" 标签
            NSError *errXPath = nil;
            NSDictionary *namespaceMappings=[NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"];
            
            NSArray* itemsArray =[root nodesForXPath:@"//opf:item" namespaces:namespaceMappings error:&errXPath];
            if ([itemsArray count]<1)
            {
                itemsArray =[root nodesForXPath:@"//item" namespaces:namespaceMappings error:&errXPath];
            }
            
            arrPageItem=[NSMutableArray array];
            for (GDataXMLElement *element in itemsArray)
            {
                NSString *itemID=[[element attributeForName:@"id"] stringValue];
                NSString *itemhref=[[element attributeForName:@"href"] stringValue];
                
                if ([itemID length]>0 && [itemhref length]>0) {
                    NSMutableDictionary *page1=[NSMutableDictionary dictionary];
                    [page1 setObject:itemID forKey:@"id"];
                    [page1 setObject:itemhref forKey:@"href"];
                    
                    [arrPageItem addObject:page1];
                }

            }
            
        }
        
#if !__has_feature(objc_arc)
        [opfXmlDoc release];;
#endif
    }
    
#if !__has_feature(objc_arc)
    [xmlData release];;
#endif

    return arrPageItem;
}
-(NSString*)HTMLContentFromFile:(NSString*)fileFullPath AddJsContent:(NSString*)jsContent
{
    NSString *strHTML=nil;
    
    NSError *error=nil;
    NSStringEncoding encoding;
    NSString *strFileContent = [[NSString alloc] initWithContentsOfFile:fileFullPath usedEncoding:&encoding error:&error];
    
    if (strFileContent && [jsContent length]>1)
    {
        NSRange head1=[strFileContent rangeOfString:@"<head>" options:NSCaseInsensitiveSearch];
        NSRange head2=[strFileContent rangeOfString:@"</head>" options:NSCaseInsensitiveSearch];
        
        if (head1.location != NSNotFound && head2.location !=NSNotFound && head2.location>head1.location )
        {
            NSRange rangeHead=head1;
            rangeHead.length=head2.location - head1.location;
            NSString *strHead=[strFileContent substringWithRange:rangeHead];
            
            NSString *str1=[strFileContent substringToIndex:head1.location];
            NSString *str3=[strFileContent substringFromIndex:head2.location];
 
            NSString *strHeadEdit=[NSString stringWithFormat:@"%@\n%@",strHead,jsContent];

            strHTML=[NSString stringWithFormat:@"%@%@%@",str1,strHeadEdit,str3];
            
        }
    }
    else if ( strFileContent )
    {
        strHTML=[NSString stringWithFormat:@"%@",strFileContent];
    }
    
#if !__has_feature(objc_arc)
    [strFileContent release];
#endif
    
    
    return strHTML;

}
@end
