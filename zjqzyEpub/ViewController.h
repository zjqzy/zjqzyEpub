//
//  ViewController.h
//  zjqzyEpub
//
//  Created by fanzhenhua on 15/7/20.
//  Copyright (c) 2015年 zhujianqi. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EPUBParser;
@interface ViewController : UIViewController

@property (strong, nonatomic) EPUBParser *epubParser; //epub解析器，成员变量或全局

-(IBAction)btnClick:(id)sender;

@end

