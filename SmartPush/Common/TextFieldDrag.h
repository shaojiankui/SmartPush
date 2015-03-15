//
//  TextFieldDrag.h
//  PushMeBaby-Enhance
//
//  Created by Jakey on 15/3/14.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
typedef void (^DidDragEnd)(NSString *result,NSTextField *text);
typedef void (^DidEnterDraging)();

@interface TextFieldDrag : NSTextField
{
    DidDragEnd _didDragEnd;
    DidEnterDraging _didEnterDraging;

}
-(void)didDragEndBlock:(DidDragEnd)didDragEnd;
-(void)didEnterDragingBlock:(DidEnterDraging)didEnterDraging;

@end
