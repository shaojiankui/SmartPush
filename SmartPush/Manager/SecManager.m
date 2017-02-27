//
//  SecManager.m
//  SmartPush
//
//  Created by Jakey on 2017/2/22.
//  Copyright © 2017年 www.skyfox.org. All rights reserved.
//

#import "SecManager.h"
#import "Sec.h"
@implementation SecManager
+ (NSArray<Sec*> *)allPushCertificatesWithEnvironment:(BOOL)isDevelop{
    NSError *error;
    NSArray *allCertificates = [self allKeychainCertificatesWithError:&error];
    NSMutableArray *pushs = [NSMutableArray array];
    
    for (int i =0; i<[allCertificates count]; i++) {
        id obj = [allCertificates objectAtIndex:i];
        
        if(obj != NULL){
//           CFBridgingRetain
            Sec *secModel = [self secModelWithRef:(__bridge_retained void *)(obj)];
            if ([self isPushCertificateWithName:secModel.name]) {
                [pushs addObject:secModel];
            }
        }
    }
    return pushs;
}
+ (Sec*)secModelWithRef:(SecCertificateRef)sec{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    Sec *secModel = [[Sec alloc]init];
    secModel.certificateRef = sec;

    secModel.name = [self subjectSummaryWithCertificate:sec];
    secModel.key = secModel.name;
    secModel.date  = [SecManager expirationWithCertificate:sec];
    secModel.expire = [NSString stringWithFormat:@"  [%@]", secModel.date ? [formatter stringFromDate: secModel.date] : @"expired"];

    return secModel;
}
+ (BOOL)isPushCertificateWithName:(NSString*)name{
    
    if ([name rangeOfString:@"Apple Development IOS Push Services:"].location != NSNotFound ||
        [name rangeOfString:@"Apple Production IOS Push Services:"].location != NSNotFound||
        [name rangeOfString:@"Apple Development Mac Push Services:"].location != NSNotFound||
        [name rangeOfString:@"Apple Production Mac Push Services:"].location != NSNotFound||
        [name rangeOfString:@"Apple Push Services:"].location != NSNotFound||
        [name rangeOfString:@"Website Push ID:"].location != NSNotFound||
        [name rangeOfString:@"VoIP Services:"].location != NSNotFound||
        [name rangeOfString:@"WatchKit Services:"].location != NSNotFound ) {
        return YES;
    }
    return NO;
}
+ (BOOL)isPushCertificate:(SecCertificateRef)sec{
    NSString *name = [self subjectSummaryWithCertificate:sec];

    if ([name rangeOfString:@"Apple Development IOS Push Services:"].location != NSNotFound ||
        [name rangeOfString:@"Apple Production IOS Push Services:"].location != NSNotFound||
        [name rangeOfString:@"Apple Development Mac Push Services:"].location != NSNotFound||
        [name rangeOfString:@"Apple Production Mac Push Services:"].location != NSNotFound||
        [name rangeOfString:@"Apple Push Services:"].location != NSNotFound||
        [name rangeOfString:@"Website Push ID:"].location != NSNotFound||
        [name rangeOfString:@"VoIP Services:"].location != NSNotFound||
        [name rangeOfString:@"WatchKit Services:"].location != NSNotFound ) {
        return YES;
    }
    return NO;
}
+ (NSArray *)allKeychainCertificatesWithError:(NSError *__autoreleasing *)error
{
    NSDictionary *options = @{(__bridge id)kSecClass: (__bridge id)kSecClassCertificate,
                              (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitAll};
    CFArrayRef certs = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)options, (CFTypeRef *)&certs);
    NSArray *certificates = CFBridgingRelease(certs);
    if (status != errSecSuccess || !certs) {
        return nil;
    }
    return certificates;
}
+ (SecCertificateRef)certificatesWithPath:(NSString*)path
{
    NSData *certificateData = [NSData dataWithContentsOfFile:path];
    SecCertificateRef certificate = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)certificateData);
    return certificate;
}

+ (NSString *)subjectSummaryWithCertificate:(SecCertificateRef)certificate
{
    return certificate ? CFBridgingRelease(SecCertificateCopySubjectSummary(certificate)) : nil;
}
+ (NSDate *)expirationWithCertificate:(SecCertificateRef)certificate
{
    return [self valueWithCertificate:certificate key:(__bridge id)kSecOIDInvalidityDate];
}

+ (id)valueWithCertificate:(SecCertificateRef)certificate key:(id)key
{
    return [self valuesWithCertificate:certificate keys:@[key] error:nil][key][(__bridge id)kSecPropertyKeyValue];
}

+ (NSDictionary *)valuesWithCertificate:(SecCertificateRef)certificate keys:(NSArray *)keys error:(NSError **)error
{
    CFErrorRef e = NULL;
    NSDictionary *result = CFBridgingRelease(SecCertificateCopyValues(certificate, (__bridge CFArrayRef)keys, &e));
    if (error) *error = CFBridgingRelease(e);
    return result;
}
@end
