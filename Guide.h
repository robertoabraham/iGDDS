//
//  Guide.h
//  iGDDS
//
//  Created by Roberto Abraham on Sat Nov 02 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "AccessorMacros.h"
#import "FITSImageView.h"

@interface Guide : NSObject {
    float left;
    float right;
    float bottom;
    float top;
    FITSImageView *view;
}

- (void) drawMe;
- (id) initWithView:(id)v;

floatAccessor_h(left,setLeft)
floatAccessor_h(right,setRight)
floatAccessor_h(bottom,setBottom)
floatAccessor_h(top,setTop)
idAccessor_h(view,setView)

@end
