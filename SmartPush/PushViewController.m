//
//  PushViewController.m
//  SmartPush
//
//  Created by Jakey on 15/3/15.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#define Push_Developer  "gateway.sandbox.push.apple.com"
#define Push_Production  "gateway.push.apple.com"


#define KEY_CERNAME     @"KEY_CERNAME"
#define KEY_CER         @"KEY_CERPATH"
#define KEY_TOKEN       @"KEY_TOKEN"
#define KEY_Payload     @"KEY_Payload"

#import "PushViewController.h"
#import "SecManager.h"
#import "Sec.h"
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

    for (int i=0;i<[_certificates count];i++) {
        Sec *sec =  [_certificates objectAtIndex:i];
        [self.cerPopUpButton addItemWithTitle:[NSString stringWithFormat:@"%@ %@", sec.name, sec.expire]];
        //        [suffix appendString:@" "];
        if([_cerName length]>0 && [sec.name isEqualToString:_cerName])
        {
            [self log:[NSString stringWithFormat:@"选择证书 %@",_cerName] warning:NO];
            [self.cerPopUpButton selectItemAtIndex:i+2];
            [self resetConnect];
            _currentSec =   sec;
            _cerName = _currentSec.name;
            [self connect:nil];
        }
    }

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
    [self log:@"保存推送信息" warning:NO];
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
    
    // Define result variable.
    //OSStatus result;
    
    // Establish connection to server.
    PeerSpec peer;
    
    //测试开发环境
    if (self.devSelect == self.mode.selectedCell) {
        _connectResult = MakeServerConnection(Push_Developer, 2195, &socket, &peer);
        // NSLog(@"MakeServerConnection(): %d", result);
    }
    
    //生产正式环境
    if (self.productSelect == self.mode.selectedCell) {
        _connectResult = MakeServerConnection(Push_Production, 2195, &socket, &peer);
        // NSLog(@"MakeServerConnection(): %d", result);
    }
    switch (_connectResult) {
        case ioErr: return [self log:[NSString stringWithFormat:@"I/O error (bummers) %d",_connectResult] warning:YES];
    }

    
    // Create new SSL context.
    _connectResult = SSLNewContext(false, &_context);
    // NSLog(@"SSLNewContext(): %d", result);
    if(!_context){
        [self log:[NSString stringWithFormat:@"SSL context不能被创建 %d",_connectResult] warning:YES];
    }
    
    // Set callback functions for SSL context.
    _connectResult = SSLSetIOFuncs(_context, SocketRead, SocketWrite);
    // NSLog(@"SSLSetIOFuncs(): %d", result);
    if(_connectResult != errSecSuccess ){
        [self log:[NSString stringWithFormat:@"SSL回调不能被设置 %d",_connectResult] warning:YES];
    }
    
    // Set SSL context connection.
    _connectResult = SSLSetConnection(_context, socket);
    // NSLog(@"SSLSetConnection(): %d", result);
    if(_connectResult != errSecSuccess ){
        [self log:[NSString stringWithFormat:@"SSL连接不能被设置 %d",_connectResult] warning:YES];
    }
    
    
    //测试环境
    if (self.devSelect == self.mode.selectedCell) {
        // Set server domain name.
        _connectResult = SSLSetPeerDomainName(_context, Push_Developer, 30);
        // NSLog(@"SSLSetPeerDomainName(): %d", result);
    }
    
    //生产正式环境
    if (self.productSelect == self.mode.selectedCell) {
        //生产正式环境
        _connectResult = SSLSetPeerDomainName(_context,Push_Production, 22);
        // NSLog(@"SSLSetPeerDomainName(): %d", result);
    }
    if(_connectResult != errSecSuccess ){
        [self log:[NSString stringWithFormat:@"SSL端点域名不能被设置 %d",_connectResult] warning:YES];
    }
    
    
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
- (NSString*)buildToken:(NSTextField*)text{
    // Validate input.
    NSMutableString* tempString;
    
    if(![text.stringValue rangeOfString:@" "].length)
    {
        //put in spaces in device token
        tempString =  [NSMutableString stringWithString:text.stringValue];
        int offset = 0;
        for(int i = 0; i < tempString.length; i++)
        {
            if(i%8 == 0 && i != 0 && i+offset < tempString.length-1)
            {
                //NSLog(@"i = %d + offset[%d] = %d", i, offset, i+offset);
                [tempString insertString:@" " atIndex:i+offset];
                offset++;
            }
        }
        NSLog(@"格式化token: '%@'", tempString);
        [self log:[NSString stringWithFormat:@"格式化token: '%@'", tempString] warning:NO];

        text.stringValue = tempString;
    }
    return text.stringValue;
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
    if(_connectResult != errSecSuccess ){
        [self log:[NSString stringWithFormat:@"SSL证书不能被设置 %d",_connectResult] warning:YES];
    }
    
    // Perform SSL handshake.
    do {
        _connectResult = SSLHandshake(_context);
        // NSLog(@"SSLHandshake(): %d", result);
        switch (_connectResult) {
            case errSSLWouldBlock: [self log:[NSString stringWithFormat:@"SSL握手超时 %d",_connectResult] warning:YES];
                break;
            case errSecIO:  [self log:[NSString stringWithFormat:@"SSL连接被服务器重置 %d",_connectResult]  warning:YES];
                break;
            case errSecAuthFailed: [self log:[NSString stringWithFormat:@"SSL认证失败 %d",_connectResult]  warning:YES];
                break;
            case errSSLUnknownRootCert: [self log:[NSString stringWithFormat:@"SSL握手未知的根证书 %d",_connectResult]  warning:YES];
                break;
            case errSSLNoRootCert:  [self log:[NSString stringWithFormat:@"SSL握手无根证书 %d",_connectResult]  warning:YES];
                break;
            case errSSLCertExpired: [self log:[NSString stringWithFormat:@"SSL握手证书过期 %d",_connectResult]  warning:YES];
                break;
            case errSSLXCertChainInvalid:  [self log:[NSString stringWithFormat:@"SSL握手无效的证书链 %d",_connectResult]  warning:YES];
                break;
            case errSSLClientCertRequested:  [self log:[NSString stringWithFormat:@"SSL握手期待客户端cert %d",_connectResult]  warning:YES];
                break;
            case errSSLServerAuthCompleted: [self log:[NSString stringWithFormat:@"SSL握手认证被中断 %d",_connectResult]  warning:YES];
                break;
            case errSSLPeerCertExpired:  [self log:[NSString stringWithFormat:@"SSL握手证书过期 %d",_connectResult]  warning:YES];
                break;
            case errSSLPeerCertRevoked :[self log:[NSString stringWithFormat:@"SSL握手证书被撤销 %d",_connectResult]  warning:YES];
                break;
            case errSSLPeerCertUnknown: [self log:[NSString stringWithFormat:@"SSL握手证书未被识别 %d",_connectResult]  warning:YES];
                break;
            case errSSLInternal:  [self log:[NSString stringWithFormat:@"SSL握手内部错误 %d",_connectResult]  warning:YES];
                break;
#if !TARGET_OS_IPHONE
            case errSecInDarkWake:  [self log:[NSString stringWithFormat:@"SSL handshake in dark wake %d",_connectResult]  warning:YES];
                break;
#endif
            case errSSLClosedAbort:  [self log:[NSString stringWithFormat:@"SSL握手因错误关闭 %d",_connectResult]  warning:YES];
                break;

        }

    } while(_connectResult == errSSLWouldBlock);
    
}
- (IBAction)push:(id)sender {
    [self saveUserData];
 
    if (_certificates == NULL){
        [self showMessage:@"读取证书失败!"];
        [self log:@"取证书失败!" warning:YES];
    }
    
    if(_connectResult == -50) {
        [self showMessage:@"未连接服务器"];
        [self log:@"未连接服务器" warning:YES];
        return;
    }
    _token = [self buildToken:self.tokenTextField];

    // Convert string into device token data.
    NSMutableData *deviceToken = [NSMutableData data];
    unsigned value;
    NSScanner *scanner = [NSScanner scannerWithString:_token];
    while(![scanner isAtEnd]) {
        [scanner scanHexInt:&value];
        value = htonl(value);
        [deviceToken appendBytes:&value length:sizeof(value)];
    }
    
    // Create C input variables.
    char *deviceTokenBinary = (char *)[deviceToken bytes];
    char *payloadBinary = (char *)[self.payload.stringValue UTF8String];
    size_t payloadLength = strlen(payloadBinary);
    
    // Define some variables.
    uint8_t command = 0;
    //char message[293]; //限定值
    char message[8000]; //限定值
    char *pointer = message;
    uint16_t networkTokenLength = htons(32);
    uint16_t networkPayloadLength = htons(payloadLength);
    
    // Compose message.
    memcpy(pointer, &command, sizeof(uint8_t));
    pointer += sizeof(uint8_t);
    memcpy(pointer, &networkTokenLength, sizeof(uint16_t));
    pointer += sizeof(uint16_t);
    memcpy(pointer, deviceTokenBinary, 32);
    pointer += 32;
    memcpy(pointer, &networkPayloadLength, sizeof(uint16_t));
    pointer += sizeof(uint16_t);
    memcpy(pointer, payloadBinary, payloadLength);
    pointer += payloadLength;
    
    // Send message over SSL.
    size_t processed = 0;
    OSStatus result = SSLWrite(_context, &message, (pointer - message), &processed);
    NSLog(@"SSLWrite(): %d %zd", result, processed);
    if (result == noErr){
        [self showMessage:@"发送成功"];
        [self log:@"发送成功" warning:NO];
    }else{
        [self showMessage:@"发送失败"];
        [self log:[NSString stringWithFormat:@"SSLWrite(): %d %zd", result, processed] warning:YES];
        [self log:@"发送失败" warning:YES];
        switch (result) {
            case errSecIO: [self log:[NSString stringWithFormat:@"写入连接被服务器丢弃 %d",result] warning:YES];
                break;
            case errSSLClosedAbort:  [self log:[NSString stringWithFormat:@"写入连接错误 %d",result] warning:YES];
                break;
            case errSSLClosedGraceful: [self log:[NSString stringWithFormat:@"写入连接关闭 %d",result] warning:YES];
                break;

        }
        
    }
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
    
//    NSString* fileNameOpened;
//    if ([openDlg runModal] == NSOKButton)
//    {
//        fileNameOpened = [[[openDlg URLs] objectAtIndex:0] path];
//        //[self.productCer setStringValue:fileNameOpened];
//    }
//    return fileNameOpened?:@"";
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
    if(obj.object == self.tokenTextField)
    {
        NSTextField *text =  obj.object;
        [self buildToken:text];
    }
}

- (void)controlTextDidChange:(NSNotification *)obj{
 

}
- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

@end
