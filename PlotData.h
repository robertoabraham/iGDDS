//
//  DataPoints.h
//  CocoaNXYPlot
//
//  Created by Roberto Abraham on Sun Aug 18 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#include "AccessorMacros.h"
#import "PlotView.h";
#import "Wave.h";


//I am storing the points as a struct rather than an object, mostly because
//I figure in some cases I may want tens of thousands of points, and there
//might be significant time overhead associated with object creation/destruction.
//I'm simply assuming doing it this way is more efficient. Note that the struct
//contains the union of all elements that might be used for every concievable
//class of plot, which is a bit wasteful. So you can see I am willing to
//trade off on memory even though I'm not willing to trade off on plotting
//speed.
typedef struct _RGAPoint {
    NSPoint  p;
    float    x;                   // sort of redundant, but convenient
    float    y;                   // sort of redundant, but convenient
    float    xErrorLeft;          // error bar
    float    xErrorRight;         // error bar
    float    yErrorLeft;          // error bar
    float    yErrorRight;         // error bar
    NSColor *symbolColor;
    int      symbolIndex;
    float    symbolAngle;
    float    symbolSize;
    char    *symbolFilename;
} RGAPoint;


@interface PlotData : NSObject <NSCoding>
{
    NSMutableData   *data;  /* collection of RGAPoints */
    PlotView        *myView;
    int             nPoints;
    float           xMin;
    float           xMax;
    float           yMin;
    float           yMax;
    BOOL            showMe;
}

-(void)loadDataPoints:(int)npts withXValues:(float *)xpts andYValues:(float *)ypts;
-(void)loadWave:(Wave *)w withRedshift:(float)z;
-(NSPoint)pointNearestTo:(NSPoint)pt;
-(NSPoint)getNSPoint:(int)n;
-(RGAPoint)getRGAPoint:(int)n;

idAccessor_h(data,setData)
idAccessor_h(myView,setMyView)
intAccessor_h(nPoints,setNPoints);
floatAccessor_h(xMin,setXMin)
floatAccessor_h(xMax,setXMax)
floatAccessor_h(yMin,setYMin)
floatAccessor_h(yMax,setYMax)
boolAccessor_h(showMe,setShowMe)


@end
