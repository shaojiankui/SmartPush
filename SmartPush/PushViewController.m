//
//  PushViewController.m
//  SmartPush
//
//  Created by Jakey on 15/3/15.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#define Push_Developer  "gateway.sandbox.push.apple.com"
#define Push_Production  "gateway.push.apple.com"



#define KEY_Developer_CER   @"KEY_Developer_CER"
#define KEY_Production_CER @"KEY_Production_CER"
#define KEY_Developer_TOKEN @"KEY_Developer_TOKEN"
#define KEY_Production_TOKEN @"KEY_Production_TOKEN"
#define KEY_Payload         @"KEY_Payload"

#import "PushViewController.h"

@implementation PushViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.payload.stringValue = @"{\"aps\":{\"alert\":\"This is some fancy message.\",\"badge\":1,\"sound\": \"default\"}}";
    
    _connectResult = -50;
    _closeResult = -50;
    [self loadUserData];
    [self modeSwitch:self.devSelect];
}

#pragma mark Private
-(void)loadUserData{
    NSLog(@"load userdefaults");
    _defaults = [NSUserDefaults standardUserDefaults];
    if ([_defaults valueForKey:KEY_Developer_CER])
        [self.devCer setStringValue:[_defaults valueForKey:KEY_Developer_CER]];
    if ([_defaults valueForKey:KEY_Production_CER])
        [self.productCer setStringValue:[_defaults valueForKey:KEY_Production_CER]];
    if ([_defaults valueForKey:KEY_Developer_TOKEN])
        [self.devToken setStringValue:[_defaults valueForKey:KEY_Developer_TOKEN]];
    if ([_defaults valueForKey:KEY_Production_TOKEN])
        [self.productToken setStringValue:[_defaults valueForKey:KEY_Production_TOKEN]];
    
    if ([_defaults valueForKey:KEY_Payload])
        [self.payload setStringValue:[_defaults valueForKey:KEY_Payload]];
    
}
-(void)saveUserData{
    [_defaults setValue:self.devCer.stringValue forKey:KEY_Developer_CER];
    [_defaults setValue:self.productCer.stringValue forKey:KEY_Production_CER];
    [_defaults setValue:self.devToken.stringValue forKey:KEY_Developer_TOKEN];
    [_defaults setValue:self.productToken.stringValue forKey:KEY_Production_TOKEN];
    [_defaults setValue:self.payload.stringValue forKey:KEY_Payload];
    [_defaults synchronize];
}
- (void)disconnect {
    NSLog(@"disconnect");
    
    // OSStatus result;
    
   // NSLog(@"SSLClose(): %d", _closeResult);
    if (_closeResult != 0) {
        return;
    }
    // 关闭SSL会话
    _closeResult = SSLClose(context);
    //NSLog(@"SSLClose(): %d", _closeResult);
    
    // Release identity.
    if (identity != NULL)
        CFRelease(identity);
    
    // Release certificate.
    if (certificate != NULL)
        CFRelease(certificate);
    
    // Release keychain.
    if (keychain != NULL)
        CFRelease(keychain);
    
    // Close connection to server.
    close((int)socket);
    
    // Delete SSL context.
    _closeResult = SSLDisposeContext(context);
    // NSLog(@"SSLDisposeContext(): %d", result);
    
}

#pragma mark --IBAction
- (IBAction)connect:(id)sender {
    
    //测试开发环境
    if (self.devSelect == self.mode.selectedCell) {
        _cerPath = self.devCer.stringValue;
    }
    //生产正式环境
    if (self.productSelect == self.mode.selectedCell) {
        _cerPath = self.productCer.stringValue;
    }
    if(_cerPath == nil || [_cerPath isEqualToString:@""]) {
        [self showMessage:@"APNS证书.cer文件路径未指定"];
        return;
    }
    
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
    
    
    // Create new SSL context.
    _connectResult = SSLNewContext(false, &context);
    // NSLog(@"SSLNewContext(): %d", result);
    
    // Set callback functions for SSL context.
    _connectResult = SSLSetIOFuncs(context, SocketRead, SocketWrite);
    // NSLog(@"SSLSetIOFuncs(): %d", result);
    
    // Set SSL context connection.
    _connectResult = SSLSetConnection(context, socket);
    // NSLog(@"SSLSetConnection(): %d", result);
    
    
    
    //测试环境
    if (self.devSelect == self.mode.selectedCell) {
        // Set server domain name.
        _connectResult = SSLSetPeerDomainName(context, Push_Developer, 30);
        // NSLog(@"SSLSetPeerDomainName(): %d", result);
    }
    
    //生产正式环境
    if (self.productSelect == self.mode.selectedCell) {
        //生产正式环境
        _connectResult = SSLSetPeerDomainName(context,Push_Production, 22);
        // NSLog(@"SSLSetPeerDomainName(): %d", result);
    }
    
    
    // Open keychain.
    _connectResult = SecKeychainCopyDefault(&keychain);
    // NSLog(@"SecKeychainOpen(): %d", result);
    [self prepareCerData];
    
    
}
-(void)resetConnect{
    _connectResult = -50;
    [self disconnect];
}
-(NSString*)buildToken:(NSTextField*)text{
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
        text.stringValue = tempString;
    }
    return text.stringValue;
}
-(void)prepareCerData{
    
    // Create certificate.
    if (self.devSelect == self.mode.selectedCell) {
        _cerPath = self.devCer.stringValue;
    }
    
    //生产正式环境
    if (self.productSelect == self.mode.selectedCell) {
        _cerPath = self.productCer.stringValue;
    }
    
    NSData *certificateData = [NSData dataWithContentsOfFile:_cerPath];
    
    certificate = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)certificateData);
    if (certificate == NULL){
        [self showMessage:@"读取证书失败!"];
    }

    
    // Create identity.
    _connectResult = SecIdentityCreateWithCertificate(keychain, certificate, &identity);
    // NSLog(@"SecIdentityCreateWithCertificate(): %d", result);
    
    // Set client certificate.
    CFArrayRef certificates = CFArrayCreate(NULL, (const void **)&identity, 1, NULL);
    _connectResult = SSLSetCertificate(context, certificates);
    // NSLog(@"SSLSetCertificate(): %d", result);
    CFRelease(certificates);
    
    // Perform SSL handshake.
    do {
        _connectResult = SSLHandshake(context);
        // NSLog(@"SSLHandshake(): %d", result);
    } while(_connectResult == errSSLWouldBlock);
    
}
- (IBAction)push:(id)sender {
    [self saveUserData];

    if (self.devSelect == self.mode.selectedCell) {
        _cerPath = self.devCer.stringValue;
    }
    //生产正式环境
    if (self.productSelect == self.mode.selectedCell) {
        _cerPath = self.productCer.stringValue;
    }
    if(_cerPath == nil || [_cerPath isEqualToString:@""]) {
        [self showMessage:@"APNS证书.cer文件路径未指定"];

        return;
    }
    
    if(_connectResult == -50) {
        [self showMessage:@"未连接服务器"];
        return;
    }
    
    //测试环境
    if (self.devSelect == self.mode.selectedCell) {
        _token = [self buildToken:self.devToken];
        
    }
    
    //生产正式环境
    if (self.productSelect == self.mode.selectedCell) {
        _token = [self buildToken:self.productToken];
    }
    
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
    OSStatus result = SSLWrite(context, &message, (pointer - message), &processed);
    NSLog(@"SSLWrite(): %d %zd", result, processed);
    if (result == noErr){
        [self showMessage:@"发送成功"];
    }else{
        [self showMessage:@"发送失败"];
    }
}
//环境切换
- (IBAction)modeSwitch:(id)sender {
    [self resetConnect];
    //测试环境
    if (self.devSelect == self.mode.selectedCell) {
        //_cerPath = [[NSBundle mainBundle] pathForResource:self.devCer.stringValue ofType:@"cer"];
        _cerPath = self.devCer.stringValue;
        _token = [self buildToken:self.devToken];
        
    }
    
    //生产正式环境
    if (self.productSelect == self.mode.selectedCell) {
        //_cerPath = [[NSBundle mainBundle] pathForResource:self.productCer.stringValue ofType:@"cer"];
        _cerPath = self.productCer.stringValue;
        _token = [self buildToken:self.productToken];
        
        
    }
}
#pragma mark -- 证书浏览
- (IBAction)devCerBrowse:(id)sender {
    [self resetConnect];
    [self.devCer setStringValue:[self browseDone]];
}
- (IBAction)productCerBrowse:(id)sender {
    [self resetConnect];
    [self.productCer setStringValue:[self browseDone]];
}
-(NSString*)browseDone{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    [openDlg setCanChooseFiles:TRUE];
    [openDlg setCanChooseDirectories:FALSE];
    [openDlg setAllowsMultipleSelection:FALSE];
    [openDlg setAllowsOtherFileTypes:FALSE];
    [openDlg setAllowedFileTypes:@[@"cer", @"CER"]];
    
    NSString* fileNameOpened;
    if ([openDlg runModal] == NSOKButton)
    {
        fileNameOpened = [[[openDlg URLs] objectAtIndex:0] path];
        //[self.productCer setStringValue:fileNameOpened];
    }
    return fileNameOpened?:@"";
}
#pragma mark --alert
-(void)showMessage:(NSString*)message{
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

#pragma mark -- text field delegate

- (void)controlTextDidEndEditing:(NSNotification *)obj{
    if(obj.object == self.devToken || obj.object == self.productToken)
    {
        NSTextField *text =  obj.object;
        [self buildToken:text];
    }
    if(obj.object == self.devCer || obj.object == self.productCer)
    {
        [self resetConnect];
    }
}

- (void)controlTextDidChange:(NSNotification *)obj{
    if(obj.object == self.devCer || obj.object == self.productCer)
    {
        [self resetConnect];

    }

}
- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

@end
