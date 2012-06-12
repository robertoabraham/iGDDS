//
//  PlotView.h
//  CocoaNXYPlot
//
//  Created by Roberto Abraham on Sun Aug 18 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#ifndef PLOTDEFS
#include "defs.h"
#endif

#import <AppKit/AppKit.h>
#include "AccessorMacros.h"


NSPoint roundPoint(NSPoint pt);


/*" Some convenient macros "*/
#ifndef MIN
#define MIN(x,y) ((x)<(y)? (x) : (y))
#endif

#ifndef MAX
#define MAX(x,y) ((x)>(y)? (x) : (y))
#endif

/*" Auxiliary functions cribbed from PGPLOT analogs "*/
float nicenum(float x, float *nsub);

/*" Additional auxiliary functions that are defined in auxil.m: "*/
extern void count_labels(int *, double *, double, double, double);
extern void autoformat(double, double, double, int *);
extern void handformat(float, char *, int *);
extern void computeNiceLinInc(float *pmin, float *pmax, float *pinc);


/*" PlotView plots data along with labeled axes and frames. It is intended to
offer basic PGPLOT-like capability.

Delegate methods:

  processPlotViewMouseDownAtWCSPoint:(NSPoint *)
  processPlotViewLayerDragFrom:(NSPoint)p0 to:(NSPoint)p1

"*/

@interface PlotView : NSView {

    NSAffineTransform *trans;                     /*" world coords to view pixel coords "*/
    NSAffineTransform *inverseTrans;              /*" view pixel coords to world coords "*/
    NSMutableArray    *mainLayerData;             /*" main objects to plot "*/
    NSMutableArray    *secondaryLayerData;        /*" overlay layer objects to plot "*/
    NSImage           *mainLayerCacheImage;
    NSImage           *secondaryLayerCacheImage;
    bool               useCachedImage;
    IBOutlet id        delegate;

    BOOL    shouldDrawFrameBox;
    BOOL    shouldDrawGrid;
    BOOL    shouldDrawAxes;
    BOOL    shouldDrawMajorTicks;
    BOOL    shouldDrawMinorTicks;
    float   tickMarkLength;
    int     tickMarkLocation;
    float   tickMarkThickness;
    float   gridThickness;
    BOOL    isGridDotted;

    float   xMin;
    float   xMax;
    float   xMajorIncrement;
    float   xMinorIncrement;

    float   yMin;
    float   yMax;
    float   yMajorIncrement;
    float   yMinorIncrement;

    int     xNumberFormatLeft;
    int     xNumberFormatRight;
    int     xNumberFormatExponent;
    int     yNumberFormatLeft;
    int     yNumberFormatRight;
    int     yNumberFormatExponent;;
    BOOL    shouldHandFormatXAxis;
    BOOL    shouldHandFormatYAxis;

    NSColor *backgroundColor;
    NSColor *textColor;
    NSColor *curveColors;

    NSFont  *xAxisTickFont;
    NSFont  *yAxisTickFont;
    NSFont  *xAxisLabelFont;
    NSFont  *yAxisLabelFont;
    NSFont  *plotTitleFont;
    NSFont  *legendFont;

    float   leftOffset, bottomOffset, rightOffset, topOffset;
    float   defaultFontSize;
    float   pixelsPerXUnit, pixelsPerYUnit;
    
    NSRect  frameRect;

    bool    _userIsDraggingZoomBox;
    NSRect  _dragRect;
    NSRect  _dragRectWCS;
    NSRect  _originalBounds;
    float   _xLayerShift;
    float   _yLayerShift;

    float   _oldXMin;
    float   _oldXMax;
    float   _oldYMin;
    float   _oldYMax;

    float xMouse;   // X position of last mouse click in world coordinates
    float yMouse;   // Y position of last mouse click in world coordinates
    
}


/*" Re-caching the drawing commands to images "*/
- (void)recachePrimaryLayer:(NSRect)rect; 
- (void)recacheSecondaryLayer:(NSRect)bounds;


/*" Contextual menu "*/
- (void)copyPDFToPasteboard;
- (void)copyEPSToPasteboard;
- (void)copyTIFFToPasteboard;
- (NSData *)PDFForView:(NSView *)aView;

/*" Master function to work out mapping from world coordinates to screen coordinates  "*/
- (void)calculateCoordinateConversions;

/*" Basic drawing commands "*/
- (void)drawTicMarks;
- (void)drawFrame;
- (void)drawAxes;
- (void)setNiceTicks;
- (void)refresh;


/*" Navigation commands "*/
- (void)zoomOut;
- (void)zoomIn;
- (void)moveUp;
- (void)moveDown;
- (void)moveLeft;
- (void)moveRight;

/*" Accessor methods "*/
-(NSRect)frameRect;
-(void)setFrameRect:(NSRect)rect;

idAccessor_h(mainLayerData,setMainLayerData)
idAccessor_h(secondaryLayerData,setSecondaryLayerData)
idAccessor_h(mainLayerCacheImage,setMainLayerCacheImage)
idAccessor_h(secondaryLayerCacheImage,setSecondaryLayerCacheImage)
idAccessor_h(delegate,setDelegate)

boolAccessor_h(shouldDrawFrameBox,setShouldDrawFrameBox)
boolAccessor_h(shouldDrawGrid,setShouldDrawGrid)
boolAccessor_h(shouldDrawAxes,setShouldDrawAxes)
boolAccessor_h(shouldDrawMajorTicks,setShouldDrawMajorTicks)
boolAccessor_h(shouldDrawMinorTicks,setShouldDrawMinorTicks)
floatAccessor_h(tickMarkLength,setTickMarkLength)
intAccessor_h(tickMarkLocation,setTickMarkLocation)
floatAccessor_h(tickMarkThickness,setTickMarkThickness)
floatAccessor_h(gridThickness,setGridThickness)
boolAccessor_h(isGridDotted,setIsGridDotted)

floatAccessor_h(xMin,setXMin)
floatAccessor_h(xMax,setXMax)
floatAccessor_h(xMajorIncrement,setXMajorIncrement)
floatAccessor_h(xMinorIncrement,setXMinorIncrement)

floatAccessor_h(yMin,setYMin)
floatAccessor_h(yMax,setYMax)
floatAccessor_h(yMajorIncrement,setYMajorIncrement)
floatAccessor_h(yMinorIncrement,setYMinorIncrement)

intAccessor_h(xNumberFormatLeft,setXNumberFormatLeft)
intAccessor_h(xNumberFormatRight,setXNumberFormatRight)
intAccessor_h(xNumberFormatExponent,setXNumberFormatExponent)
intAccessor_h(yNumberFormatLeft,setYNumberFormatLeft)
intAccessor_h(yNumberFormatRight,setYNumberFormatRight)
intAccessor_h(yNumberFormatExponent,setYNumberFormatExponent)
boolAccessor_h(shouldHandFormatXAxis,setShouldHandFormatXAxis)
boolAccessor_h(shouldHandFormatYAxis,setShouldHandFormatYAxis)

idAccessor_h(backgroundColor,setBackgroundColor)
idAccessor_h(textColor,setTextColor)
idAccessor_h(curveColors,CurveColors)

idAccessor_h(xAxisTickFont,setXAxisTickFont)
idAccessor_h(yAxisTickFont,setYAxisTickFont)
idAccessor_h(xAxisLabelFont,setXAxisLabelFont)
idAccessor_h(yAxisLabelFont,setYAxisLabelFont)
idAccessor_h(plotTitleFont,setPlotTitleFont)
idAccessor_h(legendFont,setLegendFont)

floatAccessor_h(leftOffset,setLeftOffset)
floatAccessor_h(bottomOffset,setBottomOffset)
floatAccessor_h(rightOffset,setRightOffset)
floatAccessor_h(topOffset,setTopOffset)
floatAccessor_h(defaultFontSize,setDefaultFontSize)
floatAccessor_h(pixelsPerXUnit,setPixelsPerXUnit)
floatAccessor_h(pixelsPerYUnit,setPixelsPerYUnit)
idAccessor_h(trans,setTrans)
idAccessor_h(inverseTrans,setInverseTrans)

floatAccessor_h(xMouse,setXMouse)
floatAccessor_h(yMouse,setYMouse)


@end
