//
//  Plot.m
//  CocoaNXYPlot
//
//  Created by Roberto Abraham on Sun Aug 18 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "Plot.h"

@implementation Plot

+(void) initialize
{
    if (self==[Plot class]){
        [self setVersion:1];
    }
}


- (id)init {
    self = [super init];
    if (self) {
        [self setShouldDrawFrameBox:YES];
        [self setShouldDrawGrid:YES];
        [self setShouldDrawAxes:YES];
        [self setShouldDrawMajorTicks:YES];
        [self setShouldDrawMinorTicks:YES];
        [self setShouldDrawData:YES];
        [self setTickMarkLength:2.0];
        [self setTickMarkLocation:2];
        [self setTickMarkThickness:1.0];
        [self setGridThickness:1.0];
        [self setIsGridDotted:NO];
        
        [self setXMin:10.0];
        [self setXMax:100.0];
        [self setXMajorIncrement:10.0];
        [self setXMinorIncrement:2.0];
        [self setIsXLogarithmic:NO];
        
        [self setYMin:10.0];
        [self setYMax:100.0];
        [self setYMajorIncrement:10.0];
        [self setYMinorIncrement:2.0];
        [self setIsYLogarithmic:NO];

        [self setPlotData:[[NSMutableArray alloc] init]];
    }
    return self;
}

//Accessor macros
idAccessor(plotData,setPlotData)
boolAccessor(shouldDrawFrameBox,setShouldDrawFrameBox)
boolAccessor(shouldDrawGrid,setShouldDrawGrid)
boolAccessor(shouldDrawAxes,setShouldDrawAxes)
boolAccessor(shouldDrawMajorTicks,setShouldDrawMajorTicks)
boolAccessor(shouldDrawMinorTicks,setShouldDrawMinorTicks)
boolAccessor(shouldDrawData,setShouldDrawData)
floatAccessor(tickMarkLength,setTickMarkLength)
intAccessor(tickMarkLocation,setTickMarkLocation)
floatAccessor(tickMarkThickness,setTickMarkThickness)
floatAccessor(gridThickness,setGridThickness)
boolAccessor(isGridDotted,setIsGridDotted)

floatAccessor(xMin,setXMin)
floatAccessor(xMax,setXMax)
floatAccessor(xMajorIncrement,setXMajorIncrement)
floatAccessor(xMinorIncrement,setXMinorIncrement)
boolAccessor(isXLogarithmic,setIsXLogarithmic)

floatAccessor(yMin,setYMin)
floatAccessor(yMax,setYMax)
floatAccessor(yMajorIncrement,setYMajorIncrement)
floatAccessor(yMinorIncrement,setYMinorIncrement);
boolAccessor(isYLogarithmic,setIsYLogarithmic)

intAccessor(xNumberFormatLeft,setXNumberFormatLeft)
intAccessor(xNumberFormatRight,setXNumberFormatRight)
intAccessor(xNumberFormatExponent,setXNumberFormatExponent)
intAccessor(yNumberFormatLeft,setYNumberFormatLeft)
intAccessor(yNumberFormatRight,setYNumberFormatRight)
intAccessor(yNumberFormatExponent,setYNumberFormatExponent)
boolAccessor(shouldHandFormatXAxis,setShouldHandFormatXAxis)
boolAccessor(shouldHandFormatYAxis,setShouldHandFormatYAxis)
intAccessor(xTickLabelWidth,setXTickLabelWidth)
intAccessor(yTickLabelWidth,setYTickLabelWidth)

idAccessor(backgroundColor,setBackgroundColor)
idAccessor(textColor,setTextColor)
idAccessor(curveColors,CurveColors)

idAccessor(xAxisTickFont,setXAxisTickFont)
idAccessor(yAxisTickFont,setYAxisTickFont)
idAccessor(xAxisLabelFont,setXAxisLabelFont)
idAccessor(yAxisLabelFont,setYAxisLabelFont)
idAccessor(plotTitleFont,setPlotTitleFont)
idAccessor(legendFont,setLegendFont)

@end
