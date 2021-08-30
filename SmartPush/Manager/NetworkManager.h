//
//  NetworkManager.h
//  SmartPush
//
//  Created by shao on 2021/8/24.
//  Copyright © 2021 www.skyfox.org. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>


NS_ASSUME_NONNULL_BEGIN
typedef void(^NetworkManagerSuccessBlock)(id responeObject);
typedef void(^NetworkManagerFailBlock)(NSError *error);

@interface NetworkManager : NSObject<NSURLSessionDelegate>
@property (nonatomic, strong, nullable) __attribute__((NSObject)) SecIdentityRef identity;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, copy) NetworkManagerSuccessBlock  successBlock;
@property (nonatomic, copy) NetworkManagerFailBlock  failBlock;

+ (NetworkManager*)sharedManager;
//https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns?language=objc
- (void)postWithPayload:(NSString *)payload
            toToken:(NSString *)token
          withTopic:(nullable NSString *)topic
           priority:(NSUInteger)priority
         collapseID:(NSString *)collapseID
        payloadType:(NSUInteger)payloadType
          inSandbox:(BOOL)sandbox
             exeSuccess:(void(^)(id responseObject))exeSuccess
              exeFailed:(void(^)(NSError *error))exeFailed;
-(void)disconnect;
@end

NS_ASSUME_NONNULL_END
