//
//  EPUBPageWebView.h
//  CommonReader
//
//  Created by fanzhenhua on 15/7/1.
//  Copyright (c) 2015年 zjqzy. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EPUBPageViewController;
@interface EPUBPageWebView : UIWebView

@property (weak,nonatomic) EPUBPageViewController *parentVC;

- (NSInteger)highlightAllOccurencesOfString:(NSString*)str;
- (void)removeAllHighlights;

- (NSInteger)underlineAllOccurencesOfString:(NSString*)str;
@end
