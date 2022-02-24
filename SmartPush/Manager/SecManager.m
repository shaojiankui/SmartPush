//
//  SecManager.m
//  SmartPush
//
//  Created by Jakey on 2017/2/22.
//  Copyright © 2017年 www.skyfox.org. All rights reserved.
//

#import "SecManager.h"
#import "Sec.h"
#import <CommonCrypto/CommonDigest.h>

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
    secModel.topicName =  [self topicNameWithCertificate:sec];

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
        [name rangeOfString:@"WatchKit Services:"].location != NSNotFound||
        [name rangeOfString:@"Apple Sandbox Push Services:"].location != NSNotFound ) {
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
        [name rangeOfString:@"WatchKit Services:"].location != NSNotFound ||
        [name rangeOfString:@"Apple Sandbox Push Services:"].location != NSNotFound) {
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
+ (NSString *)topicNameWithCertificate:(SecCertificateRef)certificate
{
    NSArray *nameArray = [self valueWithCertificate:certificate key:(__bridge id)kSecOIDX509V1SubjectName];
    NSString *topicName = @"";
    for (NSDictionary* nameDict in nameArray) {
        if ([[nameDict objectForKey:(NSString*)kSecPropertyKeyLabel] isEqualToString:@"0.9.2342.19200300.100.1.1"])
            topicName = [nameDict objectForKey:(NSString*)kSecPropertyKeyValue];
    }
    return topicName;
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


+ (NSMutableArray*)readCertificateAllInfo:(SecCertificateRef)certificateRef{
    const void *keys[] = {kSecOIDX509V1SubjectName};
//
//    const void *keys[] = {kSecOIDADC_CERT_POLICY,
//          kSecOIDAPPLE_CERT_POLICY,
//          kSecOIDAPPLE_EKU_CODE_SIGNING,
//          kSecOIDAPPLE_EKU_CODE_SIGNING_DEV,
//          kSecOIDAPPLE_EKU_ICHAT_ENCRYPTION,
//          kSecOIDAPPLE_EKU_ICHAT_SIGNING,
//          kSecOIDAPPLE_EKU_RESOURCE_SIGNING,
//          kSecOIDAPPLE_EKU_SYSTEM_IDENTITY,
//          kSecOIDAPPLE_EXTENSION,
//          kSecOIDAPPLE_EXTENSION_ADC_APPLE_SIGNING,
//          kSecOIDAPPLE_EXTENSION_ADC_DEV_SIGNING,
//          kSecOIDAPPLE_EXTENSION_APPLE_SIGNING,
//          kSecOIDAPPLE_EXTENSION_CODE_SIGNING,
//          kSecOIDAPPLE_EXTENSION_INTERMEDIATE_MARKER,
//          kSecOIDAPPLE_EXTENSION_WWDR_INTERMEDIATE,
//          kSecOIDAPPLE_EXTENSION_ITMS_INTERMEDIATE,
//          kSecOIDAPPLE_EXTENSION_AAI_INTERMEDIATE,
//          kSecOIDAPPLE_EXTENSION_APPLEID_INTERMEDIATE,
//          kSecOIDAuthorityInfoAccess,
//          kSecOIDAuthorityKeyIdentifier,
//          kSecOIDBasicConstraints,
//          kSecOIDBiometricInfo,
//          kSecOIDCSSMKeyStruct,
//          kSecOIDCertIssuer,
//          kSecOIDCertificatePolicies,
//          kSecOIDClientAuth,
//          kSecOIDCollectiveStateProvinceName,
//          kSecOIDCollectiveStreetAddress,
//          kSecOIDCommonName,
//          kSecOIDCountryName,
//          kSecOIDCrlDistributionPoints,
//          kSecOIDCrlNumber,
//          kSecOIDCrlReason,
//          kSecOIDDOTMAC_CERT_EMAIL_ENCRYPT,
//          kSecOIDDOTMAC_CERT_EMAIL_SIGN,
//          kSecOIDDOTMAC_CERT_EXTENSION,
//          kSecOIDDOTMAC_CERT_IDENTITY,
//          kSecOIDDOTMAC_CERT_POLICY,
//          kSecOIDDeltaCrlIndicator,
//          kSecOIDDescription,
//          kSecOIDEKU_IPSec,
//          kSecOIDEmailAddress,
//          kSecOIDEmailProtection,
//          kSecOIDExtendedKeyUsage,
//          kSecOIDExtendedKeyUsageAny,
//          kSecOIDExtendedUseCodeSigning,
//          kSecOIDGivenName,
//          kSecOIDHoldInstructionCode,
//          kSecOIDInvalidityDate,
//          kSecOIDIssuerAltName,
//          kSecOIDIssuingDistributionPoint,
//          kSecOIDIssuingDistributionPoints,
//          kSecOIDKERBv5_PKINIT_KP_CLIENT_AUTH,
//          kSecOIDKERBv5_PKINIT_KP_KDC,
//          kSecOIDKeyUsage,
//          kSecOIDLocalityName,
//          kSecOIDMS_NTPrincipalName,
//          kSecOIDMicrosoftSGC,
//          kSecOIDNameConstraints,
//          kSecOIDNetscapeCertSequence,
//          kSecOIDNetscapeCertType,
//          kSecOIDNetscapeSGC,
//          kSecOIDOCSPSigning,
//          kSecOIDOrganizationName,
//          kSecOIDOrganizationalUnitName,
//          kSecOIDPolicyConstraints,
//          kSecOIDPolicyMappings,
//          kSecOIDPrivateKeyUsagePeriod,
//          kSecOIDQC_Statements,
//          kSecOIDSerialNumber,
//          kSecOIDServerAuth,
//          kSecOIDStateProvinceName,
//          kSecOIDStreetAddress,
//          kSecOIDSubjectAltName,
//          kSecOIDSubjectDirectoryAttributes,
//          kSecOIDSubjectEmailAddress,
//          kSecOIDSubjectInfoAccess,
//          kSecOIDSubjectKeyIdentifier,
//          kSecOIDSubjectPicture,
//          kSecOIDSubjectSignatureBitmap,
//          kSecOIDSurname,
//          kSecOIDTimeStamping,
//          kSecOIDTitle,
//          kSecOIDUseExemptions,
//          kSecOIDX509V1CertificateIssuerUniqueId,
//          kSecOIDX509V1CertificateSubjectUniqueId,
//          kSecOIDX509V1IssuerName,
//          kSecOIDX509V1IssuerNameCStruct,
//          kSecOIDX509V1IssuerNameLDAP,
//          kSecOIDX509V1IssuerNameStd,
//          kSecOIDX509V1SerialNumber,
//          kSecOIDX509V1Signature,
//          kSecOIDX509V1SignatureAlgorithm,
//          kSecOIDX509V1SignatureAlgorithmParameters,
//          kSecOIDX509V1SignatureAlgorithmTBS,
//          kSecOIDX509V1SignatureCStruct,
//          kSecOIDX509V1SignatureStruct,
//          kSecOIDX509V1SubjectName,
//          kSecOIDX509V1SubjectNameCStruct,
//          kSecOIDX509V1SubjectNameLDAP,
//          kSecOIDX509V1SubjectNameStd,
//          kSecOIDX509V1SubjectPublicKey,
//          kSecOIDX509V1SubjectPublicKeyAlgorithm,
//          kSecOIDX509V1SubjectPublicKeyAlgorithmParameters,
//          kSecOIDX509V1SubjectPublicKeyCStruct,
//          kSecOIDX509V1ValidityNotAfter,
//          kSecOIDX509V1ValidityNotBefore,
//          kSecOIDX509V1Version,
//          kSecOIDX509V3Certificate,
//          kSecOIDX509V3CertificateCStruct,
//          kSecOIDX509V3CertificateExtensionCStruct,
//          kSecOIDX509V3CertificateExtensionCritical,
//          kSecOIDX509V3CertificateExtensionId,
//          kSecOIDX509V3CertificateExtensionStruct,
//          kSecOIDX509V3CertificateExtensionType,
//          kSecOIDX509V3CertificateExtensionValue,
//          kSecOIDX509V3CertificateExtensionsCStruct,
//          kSecOIDX509V3CertificateExtensionsStruct,
//          kSecOIDX509V3CertificateNumberOfExtensions,
//          kSecOIDX509V3SignedCertificate,
//          kSecOIDX509V3SignedCertificateCStruct,
//          kSecOIDSRVName
//      };
    CFArrayRef keysArray = CFArrayCreate(NULL, keys , sizeof(keys)/sizeof(keys[0]), &kCFTypeArrayCallBacks);
     
    
    CFErrorRef error;
    CFDictionaryRef valuesDict = SecCertificateCopyValues(certificateRef, keysArray, &error);
    NSMutableArray* items = [NSMutableArray new];
    
    for(int i = 0; i < sizeof(keys)/sizeof(keys[0]); i++) {
        CFDictionaryRef dict = CFDictionaryGetValue(valuesDict, keys[i]);
        if(dict!=NULL){
            [items addObject:(__bridge NSDictionary*) dict];
        }
    }
    CFRelease(valuesDict);
    return items;
    
}
@end
