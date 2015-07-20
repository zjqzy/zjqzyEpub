
#import <UIKit/UIKit.h>

@interface UIWebView (SearchWebView)

- (NSInteger)highlightAllOccurencesOfString:(NSString*)str;
- (void)removeAllHighlights;

- (NSInteger)underlineAllOccurencesOfString:(NSString*)str;
@end