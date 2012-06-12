//
//  Plot.h
//  CocoaNXYPlot
//
//  Created by Roberto Abraham on Sun Aug 18 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Appkit/Appkit.h>
#import "PlotData.h"
#include "AccessorMacros.h"

@interface Plot: NSObject
{
    NSMutableArray *plotData;    /* PlotData objects to plot */

    BOOL    shouldDrawFrameBox;
    BOOL    shouldDrawGrid;
    BOOL    shouldDrawAxes;
    BOOL    shouldDrawMajorTicks;
    BOOL    shouldDrawMinorTicks;
    BOOL    shouldDrawData;
    float   tickMarkLength;
    int     tickMarkLocation;
    int     tickMarkThickness;
    float   gridThickness;
    BOOL    isGridDotted;

    float   xMin;
    float   xMax;
    float   xMajorIncrement;
    float   xMinorIncrement;
    BOOL    isXLogarithmic;

    float   yMin;
    float   yMax;
    float   yMajorIncrement;
    float   yMinorIncrement;
    BOOL    isYLogarithmic;
    
    int     xNumberFormatLeft;
    int     xNumberFormatRight;
    int     xNumberFormatExponent;
    int     yNumberFormatLeft;
    int     yNumberFormatRight;
    int     yNumberFormatExponent;;
    BOOL    shouldHandFormatXAxis;
    BOOL    shouldHandFormatYAxis;
    int     xTickLabelWidth;
    int     yTickLabelWidth;

    NSColor *backgroundColor;
    NSColor *textColor;
    NSColor *curveColors;

    NSFont  *xAxisTickFont;
    NSFont  *yAxisTickFont;
    NSFont  *xAxisLabelFont;
    NSFont  *yAxisLabelFont;
    NSFont  *plotTitleFont;
    NSFont  *legendFont;
    
}

//Accessor macros
idAccessor_h(plotData,setPlotData)
boolAccessor_h(shouldDrawFrameBox,setShouldDrawFrameBox)
boolAccessor_h(shouldDrawGrid,setShouldDrawGrid)
boolAccessor_h(shouldDrawAxes,setShouldDrawAxes)
boolAccessor_h(shouldDrawMajorTicks,setShouldDrawMajorTicks)
boolAccessor_h(shouldDrawMinorTicks,setShouldDrawMinorTicks)
boolAccessor_h(shouldDrawData,setShouldDrawData)
floatAccessor_h(tickMarkLength,setTickMarkLength)
intAccessor_h(tickMarkLocation,setTickMarkLocation)
floatAccessor_h(tickMarkThickness,setTickMarkThickness)
floatAccessor_h(gridThickness,setGridThickness)
boolAccessor_h(isGridDotted,setIsGridDotted)

floatAccessor_h(xMin,setXMin)
floatAccessor_h(xMax,setXMax)
floatAccessor_h(xMajorIncrement,setXMajorIncrement)
floatAccessor_h(xMinorIncrement,setXMinorIncrement)
boolAccessor_h(isXLogarithmic,setIsXLogarithmic)

floatAccessor_h(yMin,setYMin)
floatAccessor_h(yMax,setYMax)
floatAccessor_h(yMajorIncrement,setYMajorIncrement)
floatAccessor_h(yMinorIncrement,setYMinorIncrement)
boolAccessor_h(isYLogarithmic,setIsYLogarithmic)

intAccessor_h(xNumberFormatLeft,setXNumberFormatLeft)
intAccessor_h(xNumberFormatRight,setXNumberFormatRight)
intAccessor_h(xNumberFormatExponent,setXNumberFormatExponent)
intAccessor_h(yNumberFormatLeft,setYNumberFormatLeft)
intAccessor_h(yNumberFormatRight,setYNumberFormatRight)
intAccessor_h(yNumberFormatExponent,setYNumberFormatExponent)
boolAccessor_h(shouldHandFormatXAxis,setShouldHandFormatXAxis)
boolAccessor_h(shouldHandFormatYAxis,setShouldHandFormatYAxis)
intAccessor_h(xTickLabelWidth,setXTickLabelWidth)
intAccessor_h(yTickLabelWidth,setYTickLabelWidth)

idAccessor_h(backgroundColor,setBackgroundColor)
idAccessor_h(textColor,setTextColor)
idAccessor_h(curveColors,CurveColors)

idAccessor_h(xAxisTickFont,setXAxisTickFont)
idAccessor_h(yAxisTickFont,setYAxisTickFont)
idAccessor_h(xAxisLabelFont,setXAxisLabelFont)
idAccessor_h(yAxisLabelFont,setYAxisLabelFont)
idAccessor_h(plotTitleFont,setPlotTitleFont)
idAccessor_h(legendFont,setLegendFont)

@end
