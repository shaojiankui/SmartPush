//
//  PushViewController.m
//  SmartPush
//
//  Created by Jakey on 15/3/15.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#define Push_Developer  "api.sandbox.push.apple.com"
#define Push_Production  "api.push.apple.com"


#define KEY_CERNAME     @"KEY_CERNAME"
#define KEY_CER         @"KEY_CERPATH"
#define KEY_TOKEN       @"KEY_TOKEN"
#define KEY_Payload     @"KEY_Payload"

#import "PushViewController.h"
#import "SecManager.h"
#import "Sec.h"
#import "NetworkManager.h"
@implementation PushViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.payload.stringValue = @"{\"aps\":{\"alert\":\"This is some fancy message.\",\"badge\":6,\"sound\": \"default\"}}";
    //    [[ NSUserDefaults  standardUserDefaults] removeObjectForKey:KEY_CERNAME];
    //    [[ NSUserDefaults  standardUserDefaults] removeObjectForKey:KEY_CER];
    
    _connectResult = -50;
    _closeResult = -50;
    [self modeSwitch:self.devSelect];
    [self loadUserData];
    [self loadKeychain];
    
}

- (IBAction)devPopButtonSelect:(DragPopUpButton*)sender {
    
    if (sender.indexOfSelectedItem ==0) {
        _cerName = nil;
        _lastCerPath = nil;
    }
    else if (sender.indexOfSelectedItem ==1) {
        //        [self devCerBrowse:nil];
        [self browseDone:^(NSString *url) {
            [self applyWithCerPath:url];
        }];
    }else{
        [self log:[NSString stringWithFormat:@"选择证书 %@",_cerName] warning:NO];
        [self resetConnect];
        _currentSec =   [_certificates objectAtIndex:sender.indexOfSelectedItem-2];
        _cerName = _currentSec.name;
        [self connect:nil];
        
    }
    [self saveUserData];
}
- (void)applyWithCerPath:(NSString*)cerPath{
    SecCertificateRef secRef =  [SecManager certificatesWithPath:cerPath];
    if ([SecManager isPushCertificate:secRef]) {
        _lastCerPath = cerPath;
        if (secRef) {
            for (Sec *sec in _certificates) {
                if ([sec.key isEqualToString:@"lastSelected"]) {
                    [_certificates removeObject:sec];
                    break;
                }
            }
            _currentSec = [SecManager secModelWithRef:secRef];
            _currentSec.key = @"lastSelected";
            _cerName = _currentSec.name;
            [self resetConnect];
            [_certificates addObject:_currentSec];
            [self reloadPopButton];
        }
    }else{
        [self showMessage:@"不是有效的推送证书"];
        [self log:@"不是有效的推送证书" warning:YES];
    }
    [self saveUserData];
    
}
- (void)reloadPopButton{
    [self.cerPopUpButton dragPopUpButtonDragEnd:^(NSString *text) {
        [self applyWithCerPath:text];
    }];
    
    [self.cerPopUpButton removeAllItems];
    [self.cerPopUpButton addItemWithTitle:@"从下拉列表选择或者拖拽推送证书到选择框"];
    [self.cerPopUpButton addItemWithTitle:@"从文件选择推送证书(.cer)"];
    
    int selectIndex= -1;
    for (int i=0;i<[_certificates count];i++) {
        Sec *sec =  [_certificates objectAtIndex:i];
        [self.cerPopUpButton addItemWithTitle:[NSString stringWithFormat:@"%@ %@ %@", sec.name, sec.expire,[sec.key isEqualToString:@"lastSelected"]?@"文件":@""]];
        //        [suffix appendString:@" "];
        if([_cerName length]>0 && [sec.name isEqualToString:_cerName])
        {
            [self log:[NSString stringWithFormat:@"选择证书 %@",_cerName] warning:NO];
            [self resetConnect];
            selectIndex = i+2;
            _currentSec =   sec;
            _cerName = _currentSec.name;
            [self connect:nil];
        }
    }
    [self.cerPopUpButton selectItemAtIndex:selectIndex];
    
    
}
- (void)loadKeychain{
    _certificates = [[SecManager allPushCertificatesWithEnvironment:YES] mutableCopy];
    if (_lastCerPath.length>0)
    {
        Sec *sec = [SecManager secModelWithRef:[SecManager certificatesWithPath:_lastCerPath]];
        sec.key = @"lastSelected";
        [_certificates addObject:sec];
    }
    [self log:@"读取Keychain中证书" warning:NO];
    [self reloadPopButton];
}
#pragma mark Private
- (void)loadUserData{
    NSLog(@"load userdefaults");
    [self log:@"读取保存的信息" warning:NO];
    
    _defaults = [NSUserDefaults standardUserDefaults];
    if ([_defaults valueForKey:KEY_TOKEN])
        [self.tokenTextField setStringValue:[_defaults valueForKey:KEY_TOKEN]];
    
    if ([[_defaults valueForKey:KEY_Payload] description].length>0)
        [self.payload setStringValue:[_defaults valueForKey:KEY_Payload]];
    
    if ([[_defaults valueForKey:KEY_CERNAME] description].length>0)
        _cerName = [_defaults valueForKey:KEY_CERNAME];
    
    if ([[_defaults valueForKey:KEY_CER] description].length>0)
        _lastCerPath = [_defaults valueForKey:KEY_CER];
}
- (void)saveUserData{
    [_defaults setValue:_lastCerPath forKey:KEY_CER];
    [_defaults setValue:self.tokenTextField.stringValue forKey:KEY_TOKEN];
    [_defaults setValue:self.payload.stringValue forKey:KEY_Payload];
    [_defaults setValue:_cerName forKey:KEY_CERNAME];
    [_defaults synchronize];
}
- (void)disconnect {
    NSLog(@"disconnect");
    [self log:@"断开链接" warning:NO];
    [self log:@"---------------------------------" warning:NO];
    
    // OSStatus result;
    
    // NSLog(@"SSLClose(): %d", _closeResult);
    if (_closeResult != 0) {
        return;
    }
    // 关闭SSL会话
    _closeResult = SSLClose(_context);
    //NSLog(@"SSLClose(): %d", _closeResult);
    
    // Release identity.
    if (_identity != NULL)
        CFRelease(_identity);
    
    //    // Release certificate.
    //    if (_currentSec.certificateRef != NULL)
    //        CFRelease(_currentSec.certificateRef);
    
    // Release keychain.
    if (_keychain != NULL)
        CFRelease(_keychain);
    
    // Close connection to server.
    close((int)socket);
    
    // Delete SSL context.
    _closeResult = SSLDisposeContext(_context);
    // NSLog(@"SSLDisposeContext(): %d", result);
    
}

#pragma mark --IBAction
- (IBAction)connect:(id)sender {
    [self saveUserData];
    if (_currentSec.certificateRef == NULL){
        [self showMessage:@"读取证书失败!"];
        [self log:@"读取证书失败!" warning:YES];
        return;
    }
    [self log:@"连接服务器!" warning:NO];
    
    NSLog(@"connect");
    
    // Open keychain.
    _connectResult = SecKeychainCopyDefault(&_keychain);
    NSLog(@"SecKeychainOpen(): %d", _connectResult);
    
    
    [self prepareCerData];
    
}
- (void)resetConnect{
    [self log:@"重置连接" warning:NO];
    _connectResult = -50;
    [self disconnect];
}

- (void)prepareCerData{
    
    if (_currentSec.certificateRef == NULL){
        [self showMessage:@"读取证书失败!"];
        [self log:@"读取证书失败!" warning:YES];
        return;
    }
    
    // Create identity.
    _connectResult = SecIdentityCreateWithCertificate(_keychain, _currentSec.certificateRef, &_identity);
    // NSLog(@"SecIdentityCreateWithCertificate(): %d", result);
    if(_connectResult != errSecSuccess ){
        [self log:[NSString stringWithFormat:@"SSL端点域名不能被设置 %d",_connectResult] warning:YES];
    }
    
    if(_connectResult == errSecItemNotFound ){
        [self log:[NSString stringWithFormat:@"Keychain中不能找到证书 %d",_connectResult] warning:YES];
    }
    
    // Set client certificate.
    CFArrayRef certificates = CFArrayCreate(NULL, (const void **)&_identity, 1, NULL);
    _connectResult = SSLSetCertificate(_context, certificates);
    // NSLog(@"SSLSetCertificate(): %d", result);
    CFRelease(certificates);
    
    [[NetworkManager sharedManager] setIdentity:_identity];
    
}
- (IBAction)push:(id)sender {
    [self saveUserData];
    
    if (_certificates == NULL){
        [self showMessage:@"读取证书失败!"];
        [self log:@"取证书失败!" warning:YES];
    }
    
    if(self.cerPopUpButton.indexOfSelectedItem <2) {
        [self showMessage:@"未选择推送证书"];
        [self log:@"未选择推送证书" warning:YES];
        return;
    }
    [self log:@"发送推送信息" warning:NO];
    
    
    NSString *token = [self.tokenTextField.stringValue stringByReplacingOccurrencesOfString:@" " withString:@""];
    

    [[NetworkManager sharedManager] postWithPayload:self.payload.stringValue
                                            toToken:token
                                          withTopic:_currentSec?_currentSec.topicName:@""
                                           priority:self.prioritySegmentedControl.selectedTag
                                         collapseID:@""
                                        payloadType:self.payloadTypeButton.selectedItem.title
                                          inSandbox:(self.devSelect == self.mode.selectedCell)
                                         exeSuccess:^(id  _Nonnull responseObject) {
        [self showMessage:@"发送成功"];
        [self log:@"发送成功" warning:NO];
    } exeFailed:^(NSString * _Nonnull error) {
        [self showMessage:@"发送失败"];
        [self log:error warning:YES];
        [self log:@"发送失败" warning:YES];
    }];
}
//环境切换
- (IBAction)modeSwitch:(id)sender {
    [self resetConnect];
    //测试环境
    if (self.devSelect == self.mode.selectedCell) {
        [self log:@"切换到开发环境" warning:NO];
    }
    //生产正式环境
    if (self.productSelect == self.mode.selectedCell) {
        //_cerPath = [[NSBundle mainBundle] pathForResource:self.productCer.stringValue ofType:@"cer"];
        [self log:@"切换到生产正式环境" warning:NO];
    }
}

- (IBAction)prioritySwitch:(id)sender {
    
}

- (IBAction)playLoadTypeTouched:(id)sender {
    
}

- (IBAction)payLoadButtonTouched:(NSPopUpButton*)sender {
    switch (sender.indexOfSelectedItem) {
        case 1:
            self.payload.stringValue = @"{\"aps\":{\"alert\":\"This is some fancy message.\"}}";
            break;
        case 2:
            self.payload.stringValue = @"{\"aps\":{\"alert\":\"This is some fancy message.\",\"badge\":6}}";
            break;
        case 3:
            self.payload.stringValue = @"{\"aps\":{\"alert\":\"This is some fancy message.\",\"badge\":6,\"sound\": \"default\"}}";
            break;
        default:
            self.payload.stringValue = @"{\"aps\":{\"alert\":\"This is some fancy message.\",\"badge\":6,\"sound\": \"default\"}}";
            break;
    }
    
}

- (void)browseDone:(void (^)(NSString *url))complete{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    [openDlg setCanChooseFiles:TRUE];
    [openDlg setCanChooseDirectories:FALSE];
    [openDlg setAllowsMultipleSelection:FALSE];
    [openDlg setAllowsOtherFileTypes:FALSE];
    [openDlg setAllowedFileTypes:@[@"cer", @"CER"]];
    
    [openDlg beginSheetModalForWindow:[[NSApplication sharedApplication] windows].firstObject completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK)
        {
            complete( [[[openDlg URLs] objectAtIndex:0] path]);
        }else {
            complete(nil);
        }
    }];
}
#pragma mark --alert
- (void)showMessage:(NSString*)message{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:message];
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        
    }];
    
}
- (void)showAlert:(NSAlertStyle)style title:(NSString *)title message:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert setAlertStyle:style];
    [alert runModal];
}
#pragma mark - Logging

- (void)log:(NSString *)message warning:(BOOL)warning
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (message.length>0) {
            NSDictionary *attributes = @{NSForegroundColorAttributeName:warning?[NSColor redColor]:[NSColor blackColor] , NSFontAttributeName: [NSFont systemFontOfSize:12]};
            NSAttributedString *string = [[NSAttributedString alloc] initWithString:message attributes:attributes];
            [self.logTextView.textStorage appendAttributedString:string];
            [self.logTextView.textStorage.mutableString appendString:@"\n"];
            [self.logTextView scrollRangeToVisible:NSMakeRange(self.logTextView.textStorage.length - 1, 1)];
        }
    });
}

#pragma mark -- text field delegate

- (void)controlTextDidEndEditing:(NSNotification *)obj{
    
}

- (void)controlTextDidChange:(NSNotification *)obj{
    
    
}
- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

@end
