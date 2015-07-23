# zjqzyEpub

介绍

epub 阅读功能模块 ， 以“QQ阅读”和"追书神器" 的epub阅读功能为基础，
进行百分百模仿。目前几乎已实现全部功能。单击上方“click me"即可看到效果。模块已封装，方便开发人员进行使用。

Usage(用法)

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


Contact

https://github.com/zjqzy  (GitHub)

zhu.jian.qi@163.com  (Email)


License

Copyright ©2012 zhiyu zheng all rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
