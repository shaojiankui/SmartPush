//
//  HelpViewController.h
//  SmartPush
//
//  Created by Jakey on 15/3/15.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
@interface HelpViewController : NSViewController
@property (weak) IBOutlet WebView *webview;
- (IBAction)pushTouched:(id)sender;
- (IBAction)cerTouched:(id)sender;
@end
