//
//  LinePlotData.m
//  CocoaNXYPlot
//
//  Created by Roberto Abraham on Thu Aug 22 2002.
//  Copyright (c) 2001. All rights reserved.
//

#ifndef PLOTDEFS
#include "defs.h"
#endif

#import "PlotData.h"
#import "LinePlotData.h"

#include "AccessorMacros.h"


@implementation LinePlotData

+(void) initialize
{
    if (self==[LinePlotData class]){
        [self setVersion:1];
    }
}


-(id)init{
    self=[super init];
    if(self){
        [self setStyle:SOLID];
        [self setColor:[NSColor redColor]];
        [self setWidth:1.0];
        [self setHistogram:NO];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    LinePlotData *newLinePlotData = [[LinePlotData allocWithZone:zone] init];
    [newLinePlotData setColor:[self color]];
    [newLinePlotData setHistogram:[self histogram]];
    [newLinePlotData setStyle:[self style]];
    [newLinePlotData setWidth:[self width]];
    [newLinePlotData setData:[[self data] copyWithZone:zone]];
    [newLinePlotData setMyView:[self myView]];
    [newLinePlotData setNPoints:[self nPoints]];
    [newLinePlotData setShowMe:[self showMe]];
    [newLinePlotData setXMin:[self xMin]];
    [newLinePlotData setXMax:[self xMax]];
    [newLinePlotData setYMin:[self yMin]];
    [newLinePlotData setYMax:[self yMax]];

    return newLinePlotData;
}    


-(void)plotWithTransform:(NSAffineTransform *)trans
{
    int i;
    int theStyle = [self style];
    NSColor *theColor = [self color];
    float pattern0[] = {};	              /* solid      */
    float pattern1[] = {3.0, 3.0};            /* dash       */
    float pattern2[] = {1.0, 3.0};            /* dot        */
    float pattern3[] = {7.0, 3.0, 3.0, 3.0};  /* chain dash */
    float pattern4[] = {7.0, 4.0, 1.0, 4.0};  /* chain dot  */
    NSBezierPath *path = [NSBezierPath bezierPath];
    RGAPoint *pointBytes = (RGAPoint *)[[self data] bytes];
    NSPoint p0,p1,p2;
    float halfBinWidth;
    float vxmin = [(PlotView *)[self myView] xMin];
    float vxmax = [(PlotView *)[self myView] xMax];
    float vymin = [(PlotView *)[self myView] yMin];
    float vymax = [(PlotView *)[self myView] yMax];

    if (![self showMe])
        return;

    [theColor set];
    switch(theStyle) {
        case SOLID:
            [path setLineDash:pattern0 count:0 phase:0.0];
            break;
        case DASH:
            [path setLineDash:pattern1 count:2 phase:0.0];
            break;
        case DOT:
            [path setLineDash:pattern2 count:2 phase:0.0];
            break;
        case CHAINDASH:
            [path setLineDash:pattern3 count:4 phase:0.0];
            break;
        case CHAINDOT:
            [path setLineDash:pattern4 count:4 phase:0.0];
            break;
        default:
            NSLog(@"Unknown line style");
            break;
    }

    [path setLineWidth:[self width]];
    for(i=1;i<[self nPoints];i++){
        
        if([self myView]){
            if (pointBytes[i].x < vxmin && pointBytes[i-1].x < vxmin ||
                pointBytes[i].x > vxmax && pointBytes[i-1].x > vxmax ||
                pointBytes[i].y < vymin && pointBytes[i-1].y < vymin ||
                pointBytes[i].y > vymax && pointBytes[i-1].y > vymax)
                continue;
        }

        if([self histogram]){
            p0=pointBytes[i-1].p;
            p1=pointBytes[i].p;  p1.y = p0.y;
            p2=pointBytes[i].p;
            //Shift them all by a half-bin
            halfBinWidth = fabs(p1.x - p0.x)/2.0;
            p0.x = p0.x - halfBinWidth;
            p1.x = p1.x - halfBinWidth;
            p2.x = p2.x - halfBinWidth;
            [path removeAllPoints];
            [path moveToPoint:[trans transformPoint:p0]];
            [path lineToPoint:[trans transformPoint:p1]];
            [path lineToPoint:[trans transformPoint:p2]];
            [path stroke];
        }
        else{
            p0=pointBytes[i-1].p;
            p1=pointBytes[i].p;  
            [path removeAllPoints];
            [path moveToPoint:[trans transformPoint:p0]];
            [path lineToPoint:[trans transformPoint:p1]];
            [path stroke];
        }
    }
}



//NSCoder stuff
-(void)encodeWithCoder:(NSCoder *)coder
{
    //NSLog(@"Encoding the LinePlotData object\n");
    [super encodeWithCoder:coder];
    [coder encodeObject:color];
    [coder encodeValueOfObjCType:@encode(int) at:&style];
    [coder encodeValueOfObjCType:@encode(float) at:&width];
    [coder encodeValueOfObjCType:@encode(unsigned) at:&histogram];
}


-(id)initWithCoder:(NSCoder *)coder
{
    int version;
    if (self=[super initWithCoder:coder]){
        //NSLog(@"Decoding the LinePlotData object\n");
        version = [coder versionForClassName:@"LinePlotData"];
        [self setColor:[coder decodeObject]];
        [coder decodeValueOfObjCType:@encode(int) at:&style];
        [coder decodeValueOfObjCType:@encode(float) at:&width];
        if (version >= 1){
            [coder decodeValueOfObjCType:@encode(unsigned) at:&histogram];
        }
    }
    return self;
}



idAccessor(color,setColor)
intAccessor(style,setStyle)
floatAccessor(width,setWidth)
boolAccessor(histogram,setHistogram)


@end
