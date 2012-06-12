//
//  PlotView.m
//  CocoaNXYPlot
//
//  Created by Roberto Abraham on Sun Aug 18 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#ifndef PLOTDEFS
#include "defs.h"
#endif

#import "PlotView.h"
#import "PlotData.h"
#import "LinePlotData.h"
#import "SymbolPlotData.h"
#import "Bobify.h"


// Convenience functions

NSPoint roundPoint(NSPoint pt)
{
    return NSMakePoint(roundf(pt.x)+0.5, roundf(pt.y)+0.5);
}


@implementation PlotView


- (id)initWithFrame:(NSRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {

        [self setShouldDrawFrameBox:YES];
        [self setShouldDrawGrid:YES];
        [self setShouldDrawAxes:YES];
        [self setShouldDrawMajorTicks:YES];
        [self setShouldDrawMinorTicks:YES];
        [self setTickMarkLength:-2.0];
        [self setTickMarkLocation:2];
        [self setTickMarkThickness:1.0];
        [self setGridThickness:1.0];
        [self setIsGridDotted:NO];
        [self setShouldDrawGrid:NO];

        [self setXMin:10.0];
        [self setXMax:100.0];
        [self setXMajorIncrement:10.0];
        [self setXMinorIncrement:2.0];

        [self setYMin:10.0];
        [self setYMax:100.0];
        [self setYMajorIncrement:10.0];
        [self setYMinorIncrement:2.0];

        [self setLeftOffset:50.0];
        [self setBottomOffset:50.0];
        [self setTopOffset:20.0];
        [self setRightOffset:50.0];
        [self setDefaultFontSize:10.0];

        _originalBounds = [self bounds];
        _xLayerShift = 0.0;
        _yLayerShift = 0.0;

        _oldXMin = NAN;
        _oldXMax = NAN;
        _oldYMin = NAN;
        _oldYMax = NAN;
        
        useCachedImage = YES;

        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(refresh)
                                                     name: @"NSViewFocusDidChangeNotification"
                                                   object: self];

        [self setNeedsDisplay:YES];
        
    }
    return self;
}


-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



-(void)calculateCoordinateConversions
{
    NSAffineTransform *translationMatrix, *scalingMatrix, *transformationMatrix;
    NSAffineTransform *tempMatrix;
    NSRect bounds = [self bounds];
    float  xmin = (float)[self xMin];
    float  xmax = (float)[self xMax];
    float  ymin = (float)[self yMin];
    float  ymax = (float)[self yMax];
    float xscale = [self bounds].size.width/_originalBounds.size.width;
    float yscale = [self bounds].size.height/_originalBounds.size.height;
    
    //work out how to tranform physical units to screen pixels
    [self setPixelsPerXUnit:(bounds.size.width-xscale*[self leftOffset]-xscale*[self rightOffset])/(xmax-xmin)];
    [self setPixelsPerYUnit:(bounds.size.height-yscale*[self bottomOffset]-yscale*[self topOffset])/(ymax-ymin)];
    xmin = xmin*[self pixelsPerXUnit]; /* drawing is all in pixel coordinates */
    xmax = xmax*[self pixelsPerXUnit];
    ymin = ymin*[self pixelsPerYUnit];
    ymax = ymax*[self pixelsPerYUnit];
    //the frameRect variable stored within the plot object holds the pixel coordinates of the frame box
    [self setFrameRect:NSMakeRect([self bottomOffset],[self leftOffset],(xmax-xmin),(ymax-ymin))];

    //work out the required translation between the world coordinates and screen coordinates
    translationMatrix = [NSAffineTransform transform];
    [translationMatrix translateXBy:(xscale*[self leftOffset]-xmin) yBy:(yscale*[self bottomOffset]-ymin)];
    scalingMatrix = [NSAffineTransform transform];
    [scalingMatrix scaleXBy:[self pixelsPerXUnit] yBy:[self pixelsPerYUnit]];
    transformationMatrix = [NSAffineTransform transform];
    [transformationMatrix appendTransform:scalingMatrix];
    [transformationMatrix appendTransform:translationMatrix];
    [self setTrans:transformationMatrix];

    //now calculate the inverse transform to go from screen coordinates to world coordinates
    tempMatrix = [[transformationMatrix copy] autorelease];
    [tempMatrix invert];
    [self setInverseTrans:tempMatrix];
}


- (void)drawRect:(NSRect)rect
/*" Two image layers are supported. The primary image layer is assumed to always exist
and contains the frame with tick marks, axes, etc as well as other objects to be
drawn. The secondary image layer is composited independently from the first layer
and does not contain tick marks, axes, etc. "*/
{
    NSDate *start;
    NSTimeInterval drawTime;
    NSSize imsize;
    NSRect imrect;

    start = [NSDate date];
    [self calculateCoordinateConversions];
        if(useCachedImage){

        //main layer
        if(!mainLayerCacheImage){
            [self recachePrimaryLayer:rect];
        }
        imsize = [mainLayerCacheImage size];
        imrect = NSMakeRect(0,0,imsize.width,imsize.height);
        [mainLayerCacheImage drawInRect:rect
                               fromRect:imrect
                               operation:NSCompositeSourceOver
                               fraction:1.0];        
        
        //secondary layer (only if it exists and has something in it!)
        if ([self secondaryLayerData] && [[self secondaryLayerData] count]>0){
            if(!secondaryLayerCacheImage){
                [self recacheSecondaryLayer:rect];
            }
            imsize = [secondaryLayerCacheImage size];
            imrect = NSMakeRect(0,0,imsize.width,imsize.height);
            [secondaryLayerCacheImage drawInRect:NSOffsetRect(rect,_xLayerShift,_yLayerShift)
                                        fromRect:imrect
                                       operation:NSCompositePlusDarker
                                        fraction:1.0];
        }
        
    }
    else{
        [self recachePrimaryLayer:rect];
        [self recacheSecondaryLayer:rect];
    }

    //If user is currently dragging the mouse draw the drag region
    if(_userIsDraggingZoomBox){
        [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.0 alpha:0.2] set]; //transparent green
        [NSBezierPath fillRect:_dragRect];
        [[NSColor orangeColor] set];
        [NSBezierPath strokeRect:_dragRect];
        [[NSColor blackColor] set];

    }

    //Draw a rectangle around the view if it is the first responder
    if ([[self window] firstResponder] == self){
//RGA        [[NSColor blackColor] set];
        [NSBezierPath strokeRect:[self bounds]];
    }
        

    //Report timing results
    drawTime = -[start timeIntervalSinceNow];
    //NSLog(@"Draw time:%g seconds", drawTime);
}



- (void)recachePrimaryLayer:(NSRect)bounds
    /*" This method draws the data either directly to the screen, or draws to an image cache,
    depending the useImageCache variable "*/
{
    NSSize size;
    int i;
    
    if(useCachedImage){
        size= bounds.size;
       if (mainLayerCacheImage){
            [mainLayerCacheImage release];
        }
        mainLayerCacheImage = [[NSImage alloc] initWithSize:size];
        [mainLayerCacheImage lockFocus];
    }

    // Drawing code starts here.
    [[NSGraphicsContext currentContext] setShouldAntialias:YES];
    [NSBezierPath setDefaultLineWidth:0.0];

    //Draw the View's background
    [[NSColor whiteColor] set];
    [[NSBezierPath bezierPathWithRect:[self bounds]] fill];
    [[NSColor blackColor] set];

    //Plot data
    if(mainLayerData){
        for(i=0;i<[[self mainLayerData] count];i++){
            [[[self mainLayerData] objectAtIndex:i] plotWithTransform:[self trans]];
        }
    }

    //Draw axes.
    [[NSColor blackColor] set];
    if([self shouldDrawAxes]) {
        [self drawAxes];
    }
        
    //Draw rectangles to clip regions outside the boundary of the plot
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:NSMakeRect(0,0,[self leftOffset],bounds.size.height)];
    [NSBezierPath fillRect:NSMakeRect(0,0,bounds.size.width,[self bottomOffset])];
    [NSBezierPath fillRect:NSMakeRect(bounds.size.width-[self rightOffset],0,[self rightOffset],bounds.size.height)];
    [NSBezierPath fillRect:NSMakeRect(0,bounds.size.height-[self topOffset],bounds.size.width,[self topOffset])];
    [[NSColor blackColor] set];

    //Draw frame
    if([self shouldDrawFrameBox]) {
        [self drawFrame];
    }

    //Draw tickmarks
    [self drawTicMarks];

    //Sort out cache
    if(useCachedImage){
        [mainLayerCacheImage unlockFocus];
    }


    //store original bounds
    _originalBounds = bounds;
    
    [self setNeedsDisplay:YES];

}


- (void)recacheSecondaryLayer:(NSRect)bounds
{
    NSSize size;
    int i;

    //if no layer exists simply exit
    if (![self secondaryLayerData] || [[self secondaryLayerData] count]<1)
        return;

    // Drawing code starts here.
    [[NSGraphicsContext currentContext] setShouldAntialias:YES];
    [NSBezierPath setDefaultLineWidth:0.0];
    
    if(useCachedImage){
        size= bounds.size;
        if (secondaryLayerCacheImage){
            [secondaryLayerCacheImage release];
        }
        secondaryLayerCacheImage = [[NSImage alloc] initWithSize:size];
        [secondaryLayerCacheImage lockFocus];
        
        //Draw the View's background as white if this going to be composited on a separate image
        [[NSColor whiteColor] set];
        [[NSBezierPath bezierPathWithRect:[self bounds]] fill];
        [[NSColor blackColor] set];
    }

    
    //Plot layer
    if(secondaryLayerData){
        for(i=0;i<[[self secondaryLayerData] count];i++){
            [[[self secondaryLayerData] objectAtIndex:i] plotWithTransform:[self trans]];
        }
    }

    //Draw rectangles to clip regions outside the boundary of the plot
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:NSMakeRect(0,0,[self leftOffset],bounds.size.height)];
    [NSBezierPath fillRect:NSMakeRect(0,0,bounds.size.width,[self bottomOffset])];
    [NSBezierPath fillRect:NSMakeRect(bounds.size.width-[self rightOffset],0,[self rightOffset],bounds.size.height)];
    [NSBezierPath fillRect:NSMakeRect(0,bounds.size.height-[self topOffset],bounds.size.width,[self topOffset])];
    [[NSColor blackColor] set];
    
    //Sort out cache
    if(useCachedImage){
        [secondaryLayerCacheImage unlockFocus];
    }
    else{
        //If we're not drawing to the image cache we need to redraw axes and frame box
        if([self shouldDrawAxes]){
            [self drawAxes];
        }
        if([self shouldDrawFrameBox]){
            [self drawFrame];
        }
        [self drawTicMarks];
    }

    [self setNeedsDisplay:YES];

}


-(void)drawFrame
{
    NSBezierPath *framePath = [[NSBezierPath alloc] init];
    float xmin = [self xMin];
    float xmax = [self xMax];
    float ymin = [self yMin];
    float ymax = [self yMax];
    [framePath setLineWidth:1.0];
    [framePath moveToPoint:[[self trans] transformPoint:NSMakePoint(xmin,ymin)]];
    [framePath lineToPoint:[[self trans] transformPoint:NSMakePoint(xmax,ymin)]];
    [framePath lineToPoint:[[self trans] transformPoint:NSMakePoint(xmax,ymax)]];
    [framePath lineToPoint:[[self trans] transformPoint:NSMakePoint(xmin,ymax)]];
    [framePath lineToPoint:[[self trans] transformPoint:NSMakePoint(xmin,ymin)]];
    if([[NSGraphicsContext currentContext] isDrawingToScreen])
        [framePath bobify];
    [framePath stroke];
    [framePath release];
}


-(void)drawAxes
{
    NSBezierPath *axesPath = [[NSBezierPath alloc] init];
    float xmin = [self xMin];
    float xmax = [self xMax];
    float ymin = [self yMin];
    float ymax = [self yMax];
    [axesPath setLineWidth:1.0];
    [axesPath moveToPoint:[[self trans] transformPoint:NSMakePoint(xmin,0.)]];
    [axesPath lineToPoint:[[self trans] transformPoint:NSMakePoint(xmax,0.)]];
    [axesPath moveToPoint:[[self trans] transformPoint:NSMakePoint(0.,ymin)]];
    [axesPath lineToPoint:[[self trans] transformPoint:NSMakePoint(0.,ymax)]];
    if([[NSGraphicsContext currentContext] isDrawingToScreen])
        [axesPath bobify];
    [axesPath stroke];
    [axesPath release];
}




//This routine is much uglier than it has to be. Unlike the methods to draw the axes and
//the frame box, it doesn't use the generic transformtion between world and pixel coords,
//instead relying on some hacky calculations. However, it works, and I'm scared that if
//I screw around much more with it I'll break it. So I will use it as-is for now.
-(void)drawTicMarks
{
    //coordinates of corners of frame box in pixel coordinates (modulo offset)
    float xmin = [self xMin]*[self pixelsPerXUnit]; /* drawing is all in pixel coordinates */
    float xmax = [self xMax]*[self pixelsPerXUnit];
    float ymin = [self yMin]*[self pixelsPerYUnit]; /* drawing is all in pixel coordinates */
    float ymax = [self yMax]*[self pixelsPerYUnit];
    NSAffineTransform *translationMatrix;
    //coordinates of corners of frame box in world coordinates
    double xmin_unscaled = [self xMin];
    double ymin_unscaled = [self yMin];
    double xmax_unscaled = [self xMax];
    double ymax_unscaled = [self yMax];
    //It is useful in some fairly extreme cases to have the increments
    //not in pixel coordinates (otherwise one can get "bad" labels).
    double xinc_unscaled = [self xMajorIncrement];
    double yinc_unscaled = [self yMajorIncrement];
    char ticlabel[32];
    float x, y, xticloc, yticloc;
    BOOL drawGrid = [self shouldDrawGrid];
    BOOL drawMajorTics = [self shouldDrawMajorTicks];
    BOOL drawMinorTics = [self shouldDrawMinorTicks];
    int  ticLocation;		/* 0=axes, 1=2 sides, 2=4 sides */
    NSFont *ticFont;
    NSString *ticString;
    NSPoint ticPoint;
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    float  ticmarklen = [self tickMarkLength];
    int    j, i;
    float  ticloc, xwid, yhgt;
    double first;
    int    nlabels;
    int    axformat[3];
    NSBezierPath *path;
    NSBezierPath *pathInWCS,*pathInSCS;
    float dash[2];
    translationMatrix = [NSAffineTransform transform];
    
    [translationMatrix translateXBy:([self leftOffset]-xmin) yBy:([self bottomOffset]-ymin)];
    path = [NSBezierPath bezierPath];
    pathInWCS = [NSBezierPath bezierPath];
    pathInSCS = [NSBezierPath bezierPath];

    ticLocation = [self tickMarkLocation];
    ticFont = [NSFont systemFontOfSize:[self defaultFontSize]];
    [ticFont set];
    [attrs setObject:ticFont forKey:NSFontAttributeName];

    //path = [[NSBezierPath alloc] init];
    [path setLineWidth:[self tickMarkThickness]];
 

    if (drawMajorTics){

        //X-axis
        
        yticloc = (ticLocation > 0 ? ymin : 2.0*ticmarklen) ;
        /* If inc is big, skip tic marks entirely */

        if (fabs(xinc_unscaled) < fabs(xmax_unscaled - xmin_unscaled)) {
            count_labels(&nlabels, &first, xmin_unscaled, xinc_unscaled, xmax_unscaled);
            if ([self shouldHandFormatXAxis] == 1) {
                axformat[0] = [self xNumberFormatLeft];
                axformat[1] = [self xNumberFormatRight];
                axformat[2] = [self xNumberFormatExponent];
            }
            else {
                autoformat(xmin_unscaled, xinc_unscaled, xmax_unscaled, axformat);
                [self setXNumberFormatLeft:axformat[0]];
                [self setXNumberFormatRight:axformat[1]];
                [self setXNumberFormatExponent:axformat[2]];
            }
            
            //next loop starts at -1 because there may be room for minor tic
            //marks to the left of the first major tic mark (after a zoom, e.g.)
            
            for (i = -1; i < nlabels; i++) {
    
                // Special test here for what should be exact 0 (but isn't sometimes
                // due to floating-point arithmetic.
                if (fabs(first/xinc_unscaled + (float)i) < 4.0e-7) {
                    x = 0.0;
                }
                else {
                    x = (first + (xinc_unscaled)*(float)i) * [self pixelsPerXUnit];
                }
                if (x >= xmin) {
                    //ensure major tic mark won't be off edge
                    if (drawGrid) {
                        [pathInSCS setLineWidth:[self gridThickness]];
                        if ([self isGridDotted]){
                            dash[0]=2.0;
                            dash[1]=2.0;
                        }
                        else{
                            dash[0]=0.0;
                            dash[1]=0.0;
                        }
                //RGA       [pathInSCS setLineDash:dash count:2 phase:0.0];
                        [pathInWCS removeAllPoints];
                        [pathInSCS removeAllPoints];
                        [pathInWCS moveToPoint:NSMakePoint(x,ymin)];
                        [pathInWCS lineToPoint:NSMakePoint(x,ymax)];
                        [pathInSCS appendBezierPath:[translationMatrix transformBezierPath:pathInWCS]];
                        if([[NSGraphicsContext currentContext] isDrawingToScreen])
                            [pathInSCS bobify];
                        [pathInSCS stroke];
                        [pathInSCS setLineWidth:[self tickMarkThickness]];
                    }
                    // Nothing at 0 if we're putting tic marks on axes: 
                    if (ticLocation > 0 || x != 0.0) {
                        [pathInSCS setLineWidth:[self gridThickness]];
                        [pathInWCS removeAllPoints];
                        [pathInSCS removeAllPoints];
                        dash[0]=0.0;dash[1]=0.0;
         //RGA               [pathInSCS setLineDash:dash count:2 phase:0.0];
                        [pathInWCS moveToPoint:NSMakePoint(x, yticloc - ticmarklen*4.0)];
                        [pathInWCS lineToPoint:NSMakePoint(x,yticloc)];
                        if (ticLocation == 2) { 
                            //tics on right and top
                            [pathInWCS moveToPoint:NSMakePoint(x,ymax)];
                            [pathInWCS lineToPoint:NSMakePoint(x,ymax + ticmarklen*4.0)];
                        }
                        [pathInSCS appendBezierPath:[translationMatrix transformBezierPath:pathInWCS]];
                        [pathInSCS setLineWidth:[self tickMarkThickness]];
                        if([[NSGraphicsContext currentContext] isDrawingToScreen])
                            [pathInSCS bobify];
                        [pathInSCS stroke];

                        handformat(x/[self pixelsPerXUnit], ticlabel, axformat);
                        ticString = [NSString stringWithCString:ticlabel];
                        xwid = [ticString sizeWithAttributes:attrs].width;
                        yhgt = [ticString sizeWithAttributes:attrs].height;
                        ticPoint = [translationMatrix transformPoint:NSMakePoint(x,yticloc)];
                        [ticString drawAtPoint:NSMakePoint(ticPoint.x - xwid/2.0,
                                                           ticPoint.y - yhgt - MAX(5.0, 5.0*ticmarklen))
                                withAttributes:attrs];

                    }
                }
                if (drawMinorTics) {
                    [pathInSCS setLineWidth:[self tickMarkThickness]];
                    if (ticLocation > 0) {
                        //tic marks on frame
                        for (j=1; j<=9; j++) {
                            ticloc = x + ((xinc_unscaled/10.0)*(float)j)*[self pixelsPerXUnit];
                            if (ticloc>xmin && ticloc<xmax) {
                                [pathInWCS removeAllPoints];
                                [pathInSCS removeAllPoints];
                                [pathInWCS moveToPoint:NSMakePoint(ticloc, yticloc - ticmarklen*2.0)];
                                [pathInWCS lineToPoint:NSMakePoint(ticloc,yticloc)];
                                if (ticLocation == 2) {
                                    //tics on right and top
                                    [pathInWCS moveToPoint:NSMakePoint(ticloc,ymax)];
                                    [pathInWCS lineToPoint:NSMakePoint(ticloc,ymax + ticmarklen*2.0)];
                                }
                                [pathInSCS appendBezierPath:[translationMatrix transformBezierPath:pathInWCS]];
                                if([[NSGraphicsContext currentContext] isDrawingToScreen])
                                    [pathInSCS bobify];
                                [pathInSCS stroke];
                            }
                        }
                    }
                    else {
                        //tic marks on axis
                        for (j=1; j<=9; j++) {
                            ticloc = x + ((xinc_unscaled/10.0)*(float)j)*[self pixelsPerXUnit];
                            if (ticloc>xmin && ticloc<xmax) {
                                [pathInWCS removeAllPoints];
                                [pathInSCS removeAllPoints];
                                [pathInWCS moveToPoint:NSMakePoint(ticloc, ticmarklen)];
                                [pathInWCS lineToPoint:NSMakePoint(ticloc,-ticmarklen)];
                                [pathInSCS appendBezierPath:[translationMatrix transformBezierPath:pathInWCS]];
                                if([[NSGraphicsContext currentContext] isDrawingToScreen])
                                    [pathInSCS bobify];
                                [pathInSCS stroke];
                            }
                        }
                    }
                }	
            }	
        }

        // Y-Axis

        xticloc = (ticLocation > 0 ? xmin : 2.0*ticmarklen) ;
        NSLog(@"Y scale info: %f %f %f",fabs(yinc_unscaled),fabs(ymax_unscaled),fabs(ymin_unscaled));

        //If inc is big, skip tic marks entirely
        if (fabs(yinc_unscaled) < fabs(ymax_unscaled - ymin_unscaled)) {

//            count_labels(int *pn, double *pfirst, double min, double inc, double max)

            count_labels(&nlabels, &first, ymin_unscaled, yinc_unscaled, ymax_unscaled);
            if ([self shouldHandFormatYAxis] == 1) {
                axformat[0] = [self yNumberFormatLeft];
                axformat[1] = [self yNumberFormatRight];
                axformat[2] = [self yNumberFormatExponent];
            }
            else {
                autoformat(ymin_unscaled, yinc_unscaled, ymax_unscaled, axformat);
                [self setYNumberFormatLeft:axformat[0]];
                [self setYNumberFormatRight:axformat[1]];
                [self setYNumberFormatExponent:axformat[2]];
            }
            /*
             * next loop starts at -1 because there may be room for minor tic
             * marks to the left of the first major tic mark (after a zoom, e.g.)
             */
            for (i = -1; i < nlabels; i++) {

                /* Special test here for what should be exact 0 (but isn't sometimes
                * due to floating-point arithmetic.
                */
                if (fabs(first/yinc_unscaled + (float)i) < 4.0e-7) { /* ugly */
                    y = 0.0;
                }
                else {
                    y = (first + (yinc_unscaled)*(float)i) * [self pixelsPerYUnit];
                }

                if (y >= ymin) {
                    /* ensure major tic mark won't be off edge */
                    if (drawGrid) {
                        [pathInSCS setLineWidth:[self gridThickness]];
                        if ([self isGridDotted]){
                            dash[0]=2.0;
                            dash[1]=2.0;
                        }
                        else{
                            dash[0]=0.0;
                            dash[1]=0.0;
                        }
              //RGA          [pathInSCS setLineDash:dash count:2 phase:0.0];
                        [pathInWCS removeAllPoints];
                        [pathInSCS removeAllPoints];
                        [pathInWCS moveToPoint:NSMakePoint(xmin,y)];
                        [pathInWCS lineToPoint:NSMakePoint(xmax,y)];
                        [pathInSCS appendBezierPath:[translationMatrix transformBezierPath:pathInWCS]];
                        if([[NSGraphicsContext currentContext] isDrawingToScreen])
                            [pathInSCS bobify];
                        [pathInSCS stroke];
                        [pathInSCS setLineWidth:[self tickMarkThickness]];
                    }
                    /* Nothing at 0 if we're putting tic marks on axes:  */
                    if (ticLocation > 0 || y != 0.0) {

                        [pathInWCS removeAllPoints];
                        [pathInSCS removeAllPoints];
                        dash[0]=0.0;dash[1]=0.0;
         //RGA               [pathInSCS setLineDash:dash count:2 phase:0.0];
                        [pathInWCS moveToPoint:NSMakePoint(xticloc - ticmarklen*4.0, y)];
                        [pathInWCS lineToPoint:NSMakePoint(xticloc,y)];
                        if (ticLocation == 2) { /* tics on right and top */
                            [pathInWCS moveToPoint:NSMakePoint(xmax,y)];
                            [pathInWCS lineToPoint:NSMakePoint(xmax+ticmarklen*4.0,y)];
                        }
                        [pathInSCS appendBezierPath:[translationMatrix transformBezierPath:pathInWCS]];
                        [pathInSCS setLineWidth:[self tickMarkThickness]];
                        if([[NSGraphicsContext currentContext] isDrawingToScreen])
                            [pathInSCS bobify];
                        [pathInSCS stroke];

                        handformat(y/[self pixelsPerYUnit], ticlabel, axformat);
                        ticString = [NSString stringWithCString:ticlabel];
                        xwid = [ticString sizeWithAttributes:attrs].width;
                        yhgt = [ticString sizeWithAttributes:attrs].height;
                        ticPoint = [translationMatrix transformPoint:NSMakePoint(xticloc,y)];
                        [ticString drawAtPoint:NSMakePoint(ticPoint.x - xwid - MAX(5.0, 5.0*ticmarklen),
                                                           ticPoint.y - yhgt/2.0)
                                withAttributes:attrs];
                    }
                }

                if (drawMinorTics) {
                    if (ticLocation > 0) {
                        /* tic marks on frame */
                        for (j=1; j<=9; j++) {
                            ticloc = y + ((yinc_unscaled/10.0)*(float)j)*[self pixelsPerYUnit];
                            if (ticloc>ymin && ticloc<ymax) {
                                [pathInWCS removeAllPoints];
                                [pathInSCS removeAllPoints];
                                [pathInWCS moveToPoint:NSMakePoint(xmin - ticmarklen*2.0, ticloc)];
                                [pathInWCS lineToPoint:NSMakePoint(xmin,ticloc)];
                                if (ticLocation == 2) { /* tics on right and top */
                                    [pathInWCS moveToPoint:NSMakePoint(xmax,ticloc)];
                                    [pathInWCS lineToPoint:NSMakePoint(xmax + ticmarklen*2.0,ticloc)];
                                }
                                [pathInSCS appendBezierPath:[translationMatrix transformBezierPath:pathInWCS]];
                                if([[NSGraphicsContext currentContext] isDrawingToScreen])
                                    [pathInSCS bobify];
                                [pathInSCS stroke];
                            }
                        }
                    }
                    else {
                    /* tic marks on axis */
                        for (j=1; j<=9; j++) {
                            ticloc = y + ((yinc_unscaled/10.0)*(float)j)*[self pixelsPerYUnit];
                            if (ticloc>ymin && ticloc<xmax) {
                                [pathInWCS removeAllPoints];
                                [pathInSCS removeAllPoints];
                                [pathInWCS moveToPoint:NSMakePoint(ticmarklen,ticloc)];
                                [pathInWCS lineToPoint:NSMakePoint(-ticmarklen,ticloc)];
                                [pathInSCS appendBezierPath:[translationMatrix transformBezierPath:pathInWCS]];
                                if([[NSGraphicsContext currentContext] isDrawingToScreen])
                                    [pathInSCS bobify];
                                [pathInSCS stroke];
                            }
                        }
                    }
                }	
            }		
        }
    }
}


//Mouse event processing
- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint pixelPoint0=[self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSPoint worldPoint0=[[self inverseTrans] transformPoint:pixelPoint0];
    NSPoint worldDragPoint;
    NSPoint pixelPoint1;
    NSPoint worldPoint1;
    NSPoint ll,ur;
    NSEvent *event;
    bool wasADrag;
    SEL theMouseDownSelector = @selector(processPlotViewMouseDownAtWCSPoint:);
    SEL theLayerDraggedSelector = @selector(processPlotViewLayerDragFrom:to:);
    bool shiftKeyUsed = [theEvent modifierFlags] & NSShiftKeyMask;
    bool commandKeyUsed = [theEvent modifierFlags] & NSCommandKeyMask;
    bool optionKeyUsed = [theEvent modifierFlags] & NSAlternateKeyMask;

    _userIsDraggingZoomBox = NO;
    wasADrag = NO;


    //Store the position of the click
    [self setXMouse:worldPoint0.x];
    [self setYMouse:worldPoint0.y];

    //Check for modifier keys
    if(commandKeyUsed)
        NSLog(@"Command key was pressed");
    if(optionKeyUsed)
        NSLog(@"Option key was pressed");

    if(shiftKeyUsed){
        //Modifier was used...
        do {
            event = [[self window] nextEventMatchingMask:NSLeftMouseDraggedMask | NSLeftMouseUpMask];
            if([event type]==NSLeftMouseDragged){
                wasADrag = YES;
                pixelPoint1 = [self convertPoint:[event locationInWindow] fromView:nil];
                _xLayerShift = pixelPoint1.x - pixelPoint0.x;
                _yLayerShift = pixelPoint1.y - pixelPoint0.y;
                [self setNeedsDisplay:YES];
            }
        } while ([event type] == NSLeftMouseDragged);

        if (!wasADrag){
           NSLog(@"Shift-clicked at %@",NSStringFromPoint(worldPoint0));
        }
        else{
            //Drag now finished. Send notification to delegate.
            worldDragPoint = [[self inverseTrans] transformPoint:pixelPoint1];
            NSLog(@"Notifying delegate of a shift from (%f,%f) to (%f,%f)",
                  worldPoint0.x,worldPoint0.y,worldDragPoint.x,worldDragPoint.y);
            if ([delegate respondsToSelector:theLayerDraggedSelector]){
                //These shifts should be in world coords
                [delegate processPlotViewLayerDragFrom:worldPoint0 to:worldDragPoint];
            }
            _xLayerShift = 0.0;
            _yLayerShift = 0.0;
            [self setNeedsDisplay:YES];
        }
    
    }
    
    //If no modifier keys are pressed then a single click sends a notification to the delegate while
    //a drag zooms the window
    if(!shiftKeyUsed && !commandKeyUsed && !optionKeyUsed){
        do {
            event = [[self window] nextEventMatchingMask:NSLeftMouseDraggedMask | NSLeftMouseUpMask];
            if([event type]==NSLeftMouseDragged){
                _userIsDraggingZoomBox = YES;
                wasADrag = YES;
                pixelPoint1 = [self convertPoint:[event locationInWindow] fromView:nil];
                worldPoint1 = [[self inverseTrans] transformPoint:pixelPoint1];
                _dragRect = NSMakeRect(MIN(pixelPoint0.x,pixelPoint1.x),
                                       MIN(pixelPoint0.y,pixelPoint1.y),
                                       fabs(pixelPoint1.x - pixelPoint0.x),
                                       fabs(pixelPoint1.y - pixelPoint0.y));
                [self setNeedsDisplay:YES];
            }
        } while ([event type] == NSLeftMouseDragged);

        if (!wasADrag || (_dragRect.size.width < 5 && _dragRect.size.height < 5)){
            //User wasn't dragging, so see if the delegate wants to process the mouse click. Note
            //that I'm assuming a tiny drag is a mistake and counts as a single mouse click! This
            //will leave a tiny drag box polluting the window which only goes away with the next
            //window refresh, but I figure it's better than the alternative of an almost certain
            //accidental rescaling to a huge magnification of tiny area.
            if ([delegate respondsToSelector:theMouseDownSelector]){
                [delegate processPlotViewMouseDownAtWCSPoint:worldPoint0];
            }
            NSLog(@"Clicked at %@. Sending this info to the delegate.",NSStringFromPoint(worldPoint0));
        }
        else{
            //User was dragging but is now finished
            _userIsDraggingZoomBox = NO;
            [self setNeedsDisplay:YES];
            NSLog(@"Dragged from %@ to %@",NSStringFromPoint(worldPoint0),NSStringFromPoint(worldPoint1));
            ll = [[self inverseTrans] transformPoint:NSMakePoint(_dragRect.origin.x,_dragRect.origin.y)];
            ur = [[self inverseTrans] transformPoint:NSMakePoint(_dragRect.origin.x+_dragRect.size.width,
                                                                 _dragRect.origin.y+_dragRect.size.height)];

            _oldXMin = xMin;
            _oldXMax = xMax;
            _oldYMin = yMin;
            _oldYMax = yMax;
            
            [self setXMin:ll.x];
            [self setXMax:ur.x];
            [self setYMin:ll.y];
            [self setYMax:ur.y];
            [self setNiceTicks];
            _originalBounds = [self bounds];
            [self calculateCoordinateConversions];
            [self recachePrimaryLayer:[self bounds]];
            [self recacheSecondaryLayer:[self bounds]];
        }
    }
    
}



//Keyboard event processing
- (BOOL) acceptsFirstResponder{
    return YES;
}

- (BOOL) resignFirstResponder{
    [self setNeedsDisplay:YES];
    return YES;
}

- (BOOL) becomeFirstResponder{
    [self setNeedsDisplay:YES];
    return YES;
}

- (void) keyDown: (NSEvent *) event{
    NSString *input = [event characters];
    //Is it a tab?
    if ([input isEqual:@"\t"]){
        [[self window] selectNextKeyView:nil];
        return;
    }
    //Is it a shift-tab?
    if ([input isEqual:@"\031"]){
        [[self window] selectPreviousKeyView:nil];
        return;
    }
    //Is it a zoom out?
    if ([input isEqual:@"o"]){
        [self zoomOut];
        return;
    }
    //Is it a zoom in?
    if ([input isEqual:@"i"]){
        [self zoomIn];
        return;
    }
    //Is it a refresh?
    if ([input isEqual:@"r"]){
        [self refresh];
        return;
    }
    //Is it an undo?
    if ([input isEqual:@"u"]){
        if (!(isnan(_oldXMin) || isnan(_oldXMax) || isnan(_oldYMin) || isnan(_oldYMax))) {
            
            float tXMin = xMin;
            float tXMax = xMax;
            float tYMin = yMin;
            float tYMax = yMax;
            
            [self setXMin:_oldXMin];
            [self setXMax:_oldXMax];
            [self setYMin:_oldYMin];
            [self setYMax:_oldYMax];
            [self setNiceTicks];
            [self refresh];
            _oldXMin = tXMin; _oldXMax = tXMax; _oldYMin = tYMin; _oldYMax = tYMax;
        }
        return;
    }    
    //Is it an up arrow?
    if ([input characterAtIndex:0]==NSUpArrowFunctionKey){
        [self moveUp];
        return;
    }
    //Is it a down arrow?
    if ([input characterAtIndex:0]==NSDownArrowFunctionKey){
        [self moveDown];
        return;
    }
    //Is it a right arrow?
    if ([input characterAtIndex:0]==NSRightArrowFunctionKey){
        [self moveLeft];
        return;
    }
    //Is it a left arrow?
    if ([input characterAtIndex:0]==NSLeftArrowFunctionKey){
        [self moveRight];
        return;
    }
}


//Navigation
- (void)zoomOut
{
    float width = [self xMax]-[self xMin];
    float height = [self yMax]-[self yMin];
    [self setXMin:[self xMin]-0.5*width];
    [self setXMax:[self xMax]+0.5*width];
    [self setYMin:[self yMin]-0.5*height];
    [self setYMax:[self yMax]+0.5*height];
    [self setNiceTicks];
    _originalBounds = [self bounds];
    [self calculateCoordinateConversions];
    [self recachePrimaryLayer:[self bounds]];
    [self recacheSecondaryLayer:[self bounds]];
}

- (void)zoomIn
{
    float width = [self xMax]-[self xMin];
    float height = [self yMax]-[self yMin];
    [self setXMin:[self xMin]+0.25*width];
    [self setXMax:[self xMax]-0.25*width];
    [self setYMin:[self yMin]+0.25*height];
    [self setYMax:[self yMax]-0.25*height];
    [self setNiceTicks];
    _originalBounds = [self bounds];
    [self calculateCoordinateConversions];
    [self recachePrimaryLayer:[self bounds]];
    [self recacheSecondaryLayer:[self bounds]];
}

- (void)moveUp
{
    float height = [self yMax]-[self yMin];
    [self setYMin:[self yMin]+0.2*height];
    [self setYMax:[self yMax]+0.2*height];
    [self setNiceTicks];
    _originalBounds = [self bounds];
    [self calculateCoordinateConversions];
    [self recachePrimaryLayer:[self bounds]];
    [self recacheSecondaryLayer:[self bounds]];
}

- (void)moveDown
{
    float height = [self yMax]-[self yMin];
    [self setYMin:[self yMin]-0.2*height];
    [self setYMax:[self yMax]-0.2*height];
    [self setNiceTicks];
    _originalBounds = [self bounds];
    [self calculateCoordinateConversions];
    [self recachePrimaryLayer:[self bounds]];
    [self recacheSecondaryLayer:[self bounds]];
}

- (void)moveLeft
{
    float width = [self xMax]-[self xMin];
    [self setXMin:[self xMin]+0.2*width];
    [self setXMax:[self xMax]+0.2*width];
    [self setNiceTicks];
    _originalBounds = [self bounds];
    [self calculateCoordinateConversions];
    [self recachePrimaryLayer:[self bounds]];
    [self recacheSecondaryLayer:[self bounds]];
}

- (void)moveRight
{
    float width = [self xMax]-[self xMin];
    [self setXMin:[self xMin]-0.2*width];
    [self setXMax:[self xMax]-0.2*width];
    [self setNiceTicks];
    _originalBounds = [self bounds];
    [self calculateCoordinateConversions];
    [self recachePrimaryLayer:[self bounds]];
    [self recacheSecondaryLayer:[self bounds]];
}

- (void)refresh
{
    _originalBounds = [self bounds];
    [self calculateCoordinateConversions];  // If there is a problem this will cause a crash
    [self recachePrimaryLayer:[self bounds]];
    [self recacheSecondaryLayer:[self bounds]];
}


//Contextual menu stuff
- (void)copyPDFToPasteboard
{
    NSRect r;
    NSData *data;
    NSArray *myPboardTypes;
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    BOOL cacheState = useCachedImage;
    //Declare types of data you'll be putting onto the pasteboard
    myPboardTypes = [NSArray arrayWithObject:NSPDFPboardType];
    [pb declareTypes:myPboardTypes owner:self];
    //Do not draw using the cache! This is slow but output is higher quality.
    useCachedImage = NO;
    //Copy the data to the pastboard
    r = [self bounds];
    data = [self dataWithPDFInsideRect:r];
    [pb setData:data forType:NSPDFPboardType];
    //Restore drawing preferences to initial state
    useCachedImage = cacheState;
}

- (void)copyEPSToPasteboard
{
    NSRect r;
    NSData *data;
    NSArray *myPboardTypes;
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    BOOL cacheState = useCachedImage;
    //Declare types of data you'll be putting onto the pasteboard
    myPboardTypes = [NSArray arrayWithObject:NSPostScriptPboardType];
    [pb declareTypes:myPboardTypes owner:self];
    r = [self bounds];
    useCachedImage=NO;
    data = [self dataWithEPSInsideRect:r];
    [pb setData:data forType:NSPostScriptPboardType];
    useCachedImage = cacheState;
}


-(NSData *) PDFForView:(NSView *)aView
{
    NSRect frame = [aView frame];
    NSView *oldSuperview = [aView superview];
    NSWindow *tempWindow;
    NSData *pdf;

    tempWindow = [[NSWindow alloc]
        initWithContentRect:frame
                  styleMask:NSBorderlessWindowMask
                    backing:NSBackingStoreRetained
                      defer:NO];
    [[tempWindow contentView] addSubview:aView];
    pdf = [tempWindow dataWithPDFInsideRect:[tempWindow frame]];
    [oldSuperview addSubview:aView];
    [tempWindow release];
    return pdf;
}


- (void)copyTIFFToPasteboard
{
    NSRect r;
    NSData *data;
    NSArray *myPboardTypes;
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSImage *image;
    BOOL cacheState = useCachedImage;
    myPboardTypes = [NSArray arrayWithObject:NSTIFFPboardType];
    [pb declareTypes:myPboardTypes owner:self];
    r = [self bounds];
    useCachedImage = NO;
    data = [self dataWithPDFInsideRect:r];
    image = [[NSImage alloc] initWithData:data];
    [pb setData:[image TIFFRepresentation] forType:NSTIFFPboardType];
    [image autorelease];
    useCachedImage = cacheState;
}


- (NSMenu*) menuForEvent:(NSEvent*)evt {
    NSMenu        *contextMenu = [[NSMenu alloc] initWithTitle:@"Quick Edit"];
    NSMenuItem    *pdfItem = [[NSMenuItem alloc] initWithTitle:@"Copy As PDF" action:@selector(copyPDFToPasteboard) keyEquivalent:@""];
    NSMenuItem    *epsItem = [[NSMenuItem alloc] initWithTitle:@"Copy As EPS" action:@selector(copyEPSToPasteboard) keyEquivalent:@""];
    NSMenuItem    *tiffItem = [[NSMenuItem alloc] initWithTitle:@"Copy As TIFF" action:@selector(copyTIFFToPasteboard) keyEquivalent:@""];

    //setup the menu
    [contextMenu addItem:pdfItem];
    [contextMenu addItem:epsItem];
    [contextMenu addItem:tiffItem];

    //tidy
    [contextMenu autorelease];

    return contextMenu;
}



//Tick formatting
- (void) setNiceTicks
{
    float pmin, pmax, pinc;

    //NSLog(@" -------- computing intervals -------- ");

    pmin = [self xMin];
    pmax = [self xMax];
	NSLog(@"x-range: %f %f",pmin,pmax);
    //NSLog(@"---> X pmin:%f  pmax:%f",pmin,pmax);
    computeNiceLinInc(&pmin,&pmax,&pinc);
    //NSLog(@"---> X pinc:%f",pinc);
    [self setXMajorIncrement:pinc];
    [self setXMinorIncrement:pinc/5.0];
    
    pmin = [self yMin];
    pmax = [self yMax];
	NSLog(@"y-range: %f %f",pmin,pmax);
    //NSLog(@"---> Y pmin:%f  pmax:%f",pmin,pmax);
    computeNiceLinInc(&pmin,&pmax,&pinc);
    //NSLog(@"---> Y pinc:%f",pinc);
    [self setYMajorIncrement:pinc];
    [self setYMinorIncrement:pinc/5.0];
    //NSLog(@" -------- done -------- ");
    
}

/*" Find the smallest "round" number greater than x, a "round" number
being 1,2, or 5 times a power of 10. If x is negative then
nicenum(x) = -nicenum(abs(x)). If x is zero, then zero is returned.
The second argument indicates a suitable number of subdivisions
for dividing the nice number (this will be 2 or 5).
Examples: nicenum(8.7) = 10.0, nicenum(-0.4) = -0.5.
Note: this is a straightforward translation of PGPLOT's PGRND function."*/
float nicenum(float x, float *nsub)
{
    float nice[3] = {2.0,5.0,10.};
    float frac,pwr,xlog,xx;
    int i,ilog;

    if (x==0.0){
        *nsub = 2;
        return 0.0;
    }

    xx = fabs(x);
    xlog = log10(xx);
    ilog = xlog;
    if (xlog<0)
        ilog = ilog-1;
    pwr=pow(10.,ilog);
    frac=xx/pwr;
    i = 3;
    if (frac<=nice[1])
        i=2;
    if (frac<=nice[0])
        i=1;
    *nsub=5;
    if (i==1)
        *nsub = 2;
    if(x>=0){
        return abs(pwr*nice[i-1]);
    }
    else{
        return -abs(pwr*nice[i-1]);
    }
}


//Accessor macros
idAccessor(mainLayerData,setMainLayerData)
idAccessor(secondaryLayerData,setSecondaryLayerData)
idAccessor(mainLayerCacheImage,setMainLayerCacheImage)
idAccessor(secondaryLayerCacheImage,setSecondaryLayerCacheImage)
idAccessor(delegate,setDelegate)
    
boolAccessor(shouldDrawFrameBox,setShouldDrawFrameBox)
boolAccessor(shouldDrawGrid,setShouldDrawGrid)
boolAccessor(shouldDrawAxes,setShouldDrawAxes)
boolAccessor(shouldDrawMajorTicks,setShouldDrawMajorTicks)
boolAccessor(shouldDrawMinorTicks,setShouldDrawMinorTicks)
floatAccessor(tickMarkLength,setTickMarkLength)
intAccessor(tickMarkLocation,setTickMarkLocation)
floatAccessor(tickMarkThickness,setTickMarkThickness)
floatAccessor(gridThickness,setGridThickness)
boolAccessor(isGridDotted,setIsGridDotted)

floatAccessor(xMin,setXMin)
floatAccessor(xMax,setXMax)
floatAccessor(xMajorIncrement,setXMajorIncrement)
floatAccessor(xMinorIncrement,setXMinorIncrement)

floatAccessor(yMin,setYMin)
floatAccessor(yMax,setYMax)
floatAccessor(yMajorIncrement,setYMajorIncrement)
floatAccessor(yMinorIncrement,setYMinorIncrement);

intAccessor(xNumberFormatLeft,setXNumberFormatLeft)
intAccessor(xNumberFormatRight,setXNumberFormatRight)
intAccessor(xNumberFormatExponent,setXNumberFormatExponent)
intAccessor(yNumberFormatLeft,setYNumberFormatLeft)
intAccessor(yNumberFormatRight,setYNumberFormatRight)
intAccessor(yNumberFormatExponent,setYNumberFormatExponent)
boolAccessor(shouldHandFormatXAxis,setShouldHandFormatXAxis)
boolAccessor(shouldHandFormatYAxis,setShouldHandFormatYAxis)

idAccessor(backgroundColor,setBackgroundColor)
idAccessor(textColor,setTextColor)
idAccessor(curveColors,CurveColors)

idAccessor(xAxisTickFont,setXAxisTickFont)
idAccessor(yAxisTickFont,setYAxisTickFont)
idAccessor(xAxisLabelFont,setXAxisLabelFont)
idAccessor(yAxisLabelFont,setYAxisLabelFont)
idAccessor(plotTitleFont,setPlotTitleFont)
idAccessor(legendFont,setLegendFont)

floatAccessor(leftOffset,setLeftOffset)
floatAccessor(bottomOffset,setBottomOffset)
floatAccessor(rightOffset,setRightOffset)
floatAccessor(topOffset,setTopOffset)
floatAccessor(defaultFontSize,setDefaultFontSize)
floatAccessor(pixelsPerXUnit,setPixelsPerXUnit)
floatAccessor(pixelsPerYUnit,setPixelsPerYUnit)
idAccessor(trans,setTrans)
idAccessor(inverseTrans,setInverseTrans)

floatAccessor(xMouse,setXMouse)
floatAccessor(yMouse,setYMouse)

-(NSRect)frameRect{
    return frameRect;
}

-(void)setFrameRect:(NSRect)rect{
    frameRect = rect;
}



@end
