//
//  SymbolPlotData.h
//  CocoaNXYPlot
//
//  Created by Roberto Abraham on Thu Aug 22 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#include "AccessorMacros.h"

@interface SymbolPlotData : PlotData <NSCoding>
{
    NSColor *color;
    int style;
    float size;
    bool filled;
}

-(void)plotWithTransform:(NSAffineTransform *)trans;

idAccessor_h(color,setColor)
intAccessor_h(style,setStyle)
boolAccessor_h(filled,setFilled)
floatAccessor_h(size,setSize)

@end
