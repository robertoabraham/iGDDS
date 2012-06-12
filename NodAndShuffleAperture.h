//
//  NodAndShuffleAperture.h
//  iGDDS
//
//  Created by Roberto Abraham on Thu Aug 29 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//


#import <AppKit/AppKit.h>
#include "AccessorMacros.h"

@class FITSImageView;
@class Image;

#define NUMPOINTS 4
#define HITDIST 8

@interface NodAndShuffleAperture : NSObject <NSCoding>
{
    NSNotificationCenter *note;
    NSPoint points[NUMPOINTS];
    NSPoint wcspoints[NUMPOINTS];
    NSBezierPath *upperExtractionRegion;
    NSBezierPath *lowerExtractionRegion;
    FITSImageView *view;
    float dYUpper,dYLower;
    float gap;
    float opacity;
    NSString *message;
	float maskOpacity;
	
	//New in Version 3
	BOOL _showControlPoints;
	IBOutlet id _delegate; 

}

- (void) drawMe;
- (void) processMouseClick:(NSNotification *)instruction;
- (int) pointAtPoint:(NSPoint)p;
- (void) setWCSPointsFromPointsUsingView:(FITSImageView *)v;
- (void) setPointsFromWCSPointsUsingView:(FITSImageView *)v;
- (id) initWithSuperview:(FITSImageView *)sv;

//Special accessor methods
- (void) setPoint:(int)num x:(float)x y:(float)y;
- (void) setWCSPoint:(int)num x:(float)x y:(float)y;
- (NSPoint) getWCSPoint:(int)num;

//Accessor methods
idAccessor_h(note,setNote)
idAccessor_h(upperExtractionRegion,setUpperExtractionRegion)
idAccessor_h(lowerExtractionRegion,setLowerExtractionRegion)
floatAccessor_h(dYUpper,setDYUpper)
floatAccessor_h(dYLower,setDYLower)
floatAccessor_h(gap,setGap)
idAccessor_h(view,setView)
floatAccessor_h(opacity,setOpacity)
idAccessor_h(message,setMessage)

//New accessor methods (added in Version 3)
- (id)delegate;
- (void)setDelegate:(id)new_delegate;
- (BOOL)showControlPoints;
- (void)setShowControlPoints:(BOOL)val;

@end


// Interface for the delegate methods of the NodAndShuffleApertureClass
//
// This defines an informal protocol as a category of the NSObject class. Note that 
// since everything inherits from NSObject every class implements the delegate methods.
// So name them carefully!
//
@interface NSObject (NodAndShuffleApertureDelegate)

- (void) mirrorNodAndShuffleAperture:(NodAndShuffleAperture *)a;

@end


