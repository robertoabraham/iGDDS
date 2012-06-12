//
//  Mask.h
//  iGDDS
//
//  Created by Roberto Abraham on Tue Sep 03 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#include "AccessorMacros.h"

@class FITSImageView;
@class Image;

#define NUMPOINTS 4
#define HITDIST 8

@interface Mask : NSObject <NSCoding>
{

    NSNotificationCenter *note;
    NSPoint points[NUMPOINTS];
    NSPoint wcspoints[NUMPOINTS];
    NSBezierPath *box;
    FITSImageView *view;
    NSString *message;
    BOOL selfDestruct;
	float opacity;
}

- (void) drawMe; 
- (void) processMouseClick:(NSNotification *)instruction;
- (int) pointAtPoint:(NSPoint)p;
- (void) setWCSPointsFromPointsUsingView:(FITSImageView *)v;
- (void) setPointsFromWCSPointsUsingView:(FITSImageView *)v;
- (id) initWithSuperview:(FITSImageView *)sv
                    atX:(float)x
                   andY:(float)y
              withWidth:(float)w
              andHeight:(float)h;
- (id)initWithSuperview:(FITSImageView *)sv
                 atWCSX:(float)x
                andWCSY:(float)y
           withWCSWidth:(float)w
           andWCSHeight:(float)h;
//Special accessor methods
- (void) setPoint:(int)num x:(float)x y:(float)y;
- (void) setWCSPoint:(int)num x:(float)x y:(float)y;
- (NSPoint) getWCSPoint:(int)num;

//Accessor methods
idAccessor_h(note,setNote)
idAccessor_h(box,setBox)
idAccessor_h(view,setView)
idAccessor_h(message,setMessage)
boolAccessor_h(selfDestruct,setSelfDestruct)
floatAccessor_h(opacity,setOpacity)

@end

