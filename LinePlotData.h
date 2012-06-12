//
//  LinePlotData.h
//  CocoaNXYPlot
//
//  Created by Roberto Abraham on Thu Aug 22 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#include "AccessorMacros.h"
#import "PlotView.h"

@interface LinePlotData : PlotData <NSCoding>
{
    NSColor *color;
    int style;
    float width;
    bool histogram;
}

-(void)plotWithTransform:(NSAffineTransform *)trans;

idAccessor_h(color,setColor)
intAccessor_h(style,setStyle)
boolAccessor_h(histogram,setHistogram)
floatAccessor_h(width,setWidth)

@end
