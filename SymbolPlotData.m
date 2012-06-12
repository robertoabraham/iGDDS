//
//  SymbolPlotData.m
//  CocoaNXYPlot
//
//  Created by Roberto Abraham on Thu Aug 22 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#ifndef PLOTDEFS
#include "defs.h"
#endif

#import "PlotData.h"
#import "SymbolPlotData.h"


@implementation SymbolPlotData

+(void) initialize
{
    if (self==[SymbolPlotData class]){
        [self setVersion:1];
    }
}


-(id)init{
    self=[super init];
    if(self){
        [self setStyle:CIRCLE];
        [self setColor:[NSColor redColor]];
        [self setSize:5.0];
        [self setFilled:YES];
    }
    return self;
}


- (id)copyWithZone:(NSZone *)zone
{
    SymbolPlotData *newSymbolPlotData = [[SymbolPlotData allocWithZone:zone] init];
    [newSymbolPlotData setColor:[self color]];
    [newSymbolPlotData setFilled:[self filled]];
    [newSymbolPlotData setStyle:[self style]];
    [newSymbolPlotData setSize:[self size]];
    [newSymbolPlotData setData:[[self data] copyWithZone:zone]];
    [newSymbolPlotData setMyView:[self myView]];
    [newSymbolPlotData setNPoints:[self nPoints]];
    [newSymbolPlotData setShowMe:[self showMe]];
    [newSymbolPlotData setXMin:[self xMin]];
    [newSymbolPlotData setXMax:[self xMax]];
    [newSymbolPlotData setYMin:[self yMin]];
    [newSymbolPlotData setYMax:[self yMax]];

    return newSymbolPlotData;
} 

-(void)plotWithTransform:(NSAffineTransform *)trans;
{
    int i;
    int theStyle = [self style];
    float theSize = [self size];
    NSColor *theColor = [self color];
    NSBezierPath *path = [NSBezierPath bezierPath];
    RGAPoint *pointBytes = (RGAPoint *)[[self data] bytes];
    NSPoint p0;
    float vxmin = [(PlotView *)[self myView] xMin];
    float vxmax = [(PlotView *)[self myView] xMax];
    float vymin = [(PlotView *)[self myView] yMin];
    float vymax = [(PlotView *)[self myView] yMax];
    
    if (![self showMe])
        return;
    
    [theColor set];
    switch(theStyle) {
        case CIRCLE:
            for(i=0;i<[self nPoints];i++){
                if ([self myView]){
                    if (pointBytes[i].x < vxmin || pointBytes[i].x > vxmax || pointBytes[i].y < vymin || pointBytes[i].y > vymax) continue;
                }
                p0=pointBytes[i].p;
                p0 = [trans transformPoint:p0];
                [path removeAllPoints];
                //[path moveToPoint:[trans transformPoint:p0]];
                [path appendBezierPathWithArcWithCenter:p0 radius:theSize startAngle:0. endAngle:360.];
                if(filled){
                    [path fill];
                }
                else{
                    [path stroke];
                }
            }
            break;
         default:
            NSLog(@"Unknown symbol style");
            break;
    }
}


//NSCoder stuff
-(void)encodeWithCoder:(NSCoder *)coder
{
    //NSLog(@"Encoding the LinePlotData object\n");
    [super encodeWithCoder:coder];
    [coder encodeObject:color];
    [coder encodeValueOfObjCType:@encode(int) at:&style];
    [coder encodeValueOfObjCType:@encode(float) at:&size];
    [coder encodeValueOfObjCType:@encode(unsigned) at:&filled];
}


-(id)initWithCoder:(NSCoder *)coder
{
    if (self=[super initWithCoder:coder]){
        //NSLog(@"Decoding the LinePlotData object\n");
        [self setColor:[coder decodeObject]];
        [coder decodeValueOfObjCType:@encode(int) at:&style];
        [coder decodeValueOfObjCType:@encode(float) at:&size];
        [coder decodeValueOfObjCType:@encode(unsigned) at:&filled];
    }
    return self;
}



idAccessor(color,setColor);
intAccessor(style,setStyle);
floatAccessor(size,setSize)
boolAccessor(filled,setFilled)


@end
