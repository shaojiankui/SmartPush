//
//  HelpViewController.m
//  SmartPush
//
//  Created by Jakey on 15/3/15.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#import "HelpViewController.h"

@interface HelpViewController ()

@end

@implementation HelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
     [[self.webview mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.skyfox.org/ios-apns-use-and-debug.html"]]];
}

- (IBAction)pushTouched:(id)sender {
     [[self.webview mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.skyfox.org/ios-smartpush-apns-mac.html"]]];
}

- (IBAction)cerTouched:(id)sender {
     [[self.webview mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.skyfox.org/ios-apns-use-and-debug.html"]]];
}

@end
