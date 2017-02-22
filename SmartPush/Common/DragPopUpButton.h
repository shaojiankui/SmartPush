//
//  DragPopUpButton.h
//  SmartPush
//
//  Created by Jakey on 2017/2/22.
//  Copyright © 2017年 www.skyfox.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
typedef void (^DragPopUpButtonDragEnd)(NSString *text);

@interface DragPopUpButton : NSPopUpButton
{
    DragPopUpButtonDragEnd _dragPopUpButtonDragEnd;
}

-(void)dragPopUpButtonDragEnd:(DragPopUpButtonDragEnd)dragPopUpButtonDragEnd;

@end
