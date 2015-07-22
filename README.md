# zjqzyEpub

介绍

epub 阅读功能模块 ， 以“QQ阅读”和"追书神器" 的epub阅读功能为基础，
进行百分百模仿。目前几乎已实现全部功能。单击上方“click me"即可看到效果。模块已封装，方便开发人员进行使用。

Usage

1 添加文件夹 EPUBReadModular 和 thirdparty 到工程 。 其中 thirdparty 里所用到的开源工程， 如果工程已有，则不用添加

2 EPUBReadModular 文件夹 为 arc 编译

3 工程的 info.plist 里 添加 "View controller-based status bar appearance" 值为NO

4 添加framework ： libz.dylib , libxml2.dylib, libstdc++.dylib 

5 build setting 里 设置 header search paths 追加 “/usr/include/libxml2”

6 查看 demo工程的  -(IBAction)btnClick:(id)sender 方法，即可， 注意 epubParser 为成员变量

{

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




