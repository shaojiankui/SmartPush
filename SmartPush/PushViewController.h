//
//  PushViewController.h
//  SmartPush
//
//  Created by Jakey on 15/3/15.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ioSock.h"
#import "TextFieldDrag.h"
#import "DragPopUpButton.h"
#import "Sec.h"
@interface PushViewController : NSViewController<NSTextFieldDelegate>
{
    
    NSString *_token;
    NSString *_lastCerPath;
    NSString *_cerName;

    otSocket socket;
    OSStatus _connectResult;
    OSStatus _closeResult;
    
    SSLContextRef _context;
    SecKeychainRef _keychain;
    Sec *_currentSec;
    SecIdentityRef _identity;
    NSUserDefaults *_defaults;
    NSMutableArray *_certificates;
}
@property (weak) IBOutlet NSTextField *payload;
@property (unsafe_unretained) IBOutlet NSTextView *logTextView;
@property (weak) IBOutlet NSMatrix *mode;
@property (weak) IBOutlet NSButtonCell *devSelect;
@property (weak) IBOutlet NSButtonCell *productSelect;
@property (weak) IBOutlet NSPopUpButton *payLoadPopUpButton;
@property (weak) IBOutlet NSTextField *tokenTextField;
@property (weak) IBOutlet DragPopUpButton *cerPopUpButton;

- (IBAction)connect:(id)sender;
- (IBAction)push:(id)sender;
- (IBAction)modeSwitch:(id)sender;
- (IBAction)payLoadButtonTouched:(id)sender;

@end
