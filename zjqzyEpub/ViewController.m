//
//  ViewController.m
//  zjqzyEpub
//
//  Created by fanzhenhua on 15/7/20.
//  Copyright (c) 2015年 zhujianqi. All rights reserved.
//

#import "ViewController.h"

#import "EPUBParser.h"
#import "EPUBReadMainViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //前提条件
    _epubParser=[[EPUBParser alloc] init];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction)btnClick:(id)sender
{
    //显示  epub
    
    NSString *fileFullPath=[[NSBundle mainBundle] pathForResource:@"为人处世曾国藩" ofType:@"epub" inDirectory:nil];
    
    //
    NSMutableDictionary *fileInfo=[NSMutableDictionary dictionary];
    [fileInfo setObject:fileFullPath forKey:@"fileFullPath"];
    
    
    EPUBReadMainViewController *epubVC=[EPUBReadMainViewController new];
    epubVC.epubParser=self.epubParser;
    epubVC.fileInfo=fileInfo;
    
    epubVC.epubReadBackBlock=^(NSMutableDictionary *para1){
        NSLog(@"回调=%@",para1);
        //[self dismissViewControllerAnimated:YES completion:nil];  //a方式  oK
        //[self.navigationController popToRootViewControllerAnimated:YES];    //b方式  oK
        [self dismissViewControllerAnimated:YES completion:nil];
        
        return 1;
    };
    
    //[self showViewController:epubVC sender:nil];  //a方式  oK
    //[self.navigationController pushViewController:epubVC animated:YES];  //b方式  oK
    [self.navigationController presentViewController:epubVC animated:YES completion:nil];

    
}
@end
