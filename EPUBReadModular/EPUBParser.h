//
//  EPUBParser.h
//  CommonReader
//
//  Created by fanzhenhua on 15/7/2.
//  Copyright (c) 2015年 zjqzy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EPUBParser : NSObject


@property (strong,nonatomic) NSString *lastError;

/**
 *  关闭 ,清空数据
 *
 */
-(void)closeFile;

/**
 *  打开文件 epub
 *
 *  @param fileFullPath   文件本地绝对路径
 *
 *  @return 返回 操作是否成功
 */
-(int)openFilePath:(NSString*)fileFullPath WithUnzipFolder:(NSString*)unzipFolder;

/**
 *  得到opf文件路径
 *
 *  @param manifestFileFullPath   文件绝对路径
 *  @param unzipFolder   解压文件夹
 *
 *  @return 返回 opf的文件路径
 */
-(NSString*)opfFilePathWithManifestFile:(NSString*)manifestFileFullPath WithUnzipFolder:(NSString*)unzipFolder;

/**
 *  得到ncx文件路径
 *
 *  @param opfFilePath   文件绝对路径
 *  @param unzipFolder   解压文件夹
 *
 *  @return 返回 ncx的文件路径
 */
-(NSString*)ncxFilePathWithOpfFile:(NSString*)opfFilePath WithUnzipFolder:(NSString*)unzipFolder;

/**
 *  得到 封面 文件路径
 *
 *  @param opfFilePath   文件绝对路径
 *  @param unzipFolder   解压文件夹
 *
 *  @return 返回 封面的文件路径
 */
-(NSString*)coverFilePathWithOpfFile:(NSString*)opfFilePath WithUnzipFolder:(NSString*)unzipFolder;

/**
 *  得到epub文件 基本信息
 *
 *  @param opfFilePath   文件绝对路径
 *
 *  @return 返回 基本信息
 */
-(NSMutableDictionary*)epubFileInfoWithOpfFile:(NSString*)opfFilePath;

/**
 *  得到epub文件 目录信息
 *
 *  @param opfFilePath   文件绝对路径
 *
 *  @return 返回 目录信息
 */
-(NSMutableArray*)epubCatalogWithNcxFile:(NSString*)ncxFilePath;


/**
 *  得到epub文件 页码索引
 *
 *  @param opfFilePath   文件绝对路径
 *
 *  @return 返回 页码索引
 */
-(NSMutableArray*)epubPageRefWithOpfFile:(NSString*)opfFilePath;

/**
 *  得到epub文件 页码信息
 *
 *  @param opfFilePath   文件绝对路径
 *
 *  @return 返回 页码信息
 */
-(NSMutableArray*)epubPageItemWithOpfFile:(NSString*)opfFilePath;

/**
 *  html内容 ＋ js内容 ＝ 新的html内容
 *
 *  @param fileFullPath   文件html绝对路径
 *  @param jsContent      脚本js内容
 *
 *  @return 返回 整理后html内容
 */
-(NSString*)HTMLContentFromFile:(NSString*)fileFullPath AddJsContent:(NSString*)jsContent;
@end
