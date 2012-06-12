//
//  DataPoints.m
//  CocoaNXYPlot
//
//  Created by Roberto Abraham on Sun Aug 18 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "PlotData.h"


@implementation PlotData

+(void) initialize
{
    if (self==[PlotData class]){
        [self setVersion:2];
    }
}


-(id)init
{
    self = [super init];
    if (self) {
        [self setNPoints: 0];
        [self setShowMe:YES];
    }
    return self;
}


-(void)loadDataPoints:(int)npts withXValues:(float *)xpts andYValues:(float *)ypts
{
    int i;
    RGAPoint *buffer;
    RGAPoint temp;
    float xmin,xmax,ymin,ymax;
    NSMutableData *tempData;
    
    xmin=xpts[0]; xmax=xpts[0]; ymin=ypts[0]; ymax=ypts[0];
    buffer = (RGAPoint *) malloc(npts*sizeof(RGAPoint));
    for(i=0;i<npts;i++){
    
        temp.p = NSMakePoint(*(xpts + i),*(ypts + i));
        temp.x = *(xpts + i);
        temp.y = *(ypts + i);
        temp.xErrorLeft = 0.0;
        temp.xErrorRight = 0.0;
        temp.yErrorLeft = 0.0;
        temp.yErrorRight = 0.0;
        temp.symbolColor = [NSColor blackColor];
        temp.symbolIndex = 1;
        temp.symbolAngle = 0.0;
        temp.symbolSize = 1.0;
        *(buffer + i) = temp;
        
        if(temp.x>xmax){xmax=temp.x;}
        if(temp.x<xmin){xmin=temp.x;}
        if(temp.y>ymax){ymax=temp.y;}
        if(temp.y<ymin){ymin=temp.y;}
        
    }
    tempData = [[[NSMutableData alloc] init] autorelease]; // latest RGA hack - Dec 03
    [tempData appendBytes:buffer length:npts*sizeof(RGAPoint)];

    [self setData:tempData];
    [self setNPoints:npts];
    [self setXMin:xmin];
    [self setXMax:xmax];
    [self setYMin:ymin];
    [self setYMax:ymax];

    free(buffer);
}


-(void)loadWave:(Wave *)w withRedshift:(float)z;
{
    int i;
    RGAPoint *buffer;
    RGAPoint temp;
    float xmin,xmax,ymin,ymax;
    float xval, yval;
    NSMutableData *tempData;
    
    xmin=(1.0+z)*[w xAtIndex:[w p0]];
    xmax=(1.0+z)*[w xAtIndex:([w p0] + [w n])];
    ymin=[w yAtIndex:[w p0]];
    ymax=[w yAtIndex:([w p0] + [w n])];

    buffer = (RGAPoint *) malloc([w n]*sizeof(RGAPoint));
    for(i=(int)[w p0];i<(int)([w p0] + [w n]);i++){ //waves return longs not ints!
        xval = (1+z) * (float)[w xAtIndex:i]; //waves return double precision not floats!
        yval = (float)[w yAtIndex:i];
        temp.p = NSMakePoint(xval,yval);
        temp.x = xval;
        temp.y = yval;
        temp.xErrorLeft = 0.0;
        temp.xErrorRight = 0.0;
        temp.yErrorLeft = 0.0;
        temp.yErrorRight = 0.0;
        temp.symbolColor = [NSColor blackColor];
        temp.symbolIndex = 1;
        temp.symbolAngle = 0.0;
        temp.symbolSize = 1.0;
        *(buffer + i) = temp;

        if(temp.x>xmax){xmax=temp.x;}
        if(temp.x<xmin){xmin=temp.x;}
        if(temp.y>ymax){ymax=temp.y;}
        if(temp.y<ymin){ymin=temp.y;}

    }
    tempData = [[[NSMutableData alloc] init] autorelease]; // latest RGA hack - Dec 03
    [tempData appendBytes:buffer length:(int)[w n]*sizeof(RGAPoint)];
    [self setData:tempData];
    [self setNPoints:(int)[w n]];
    [self setXMin:xmin];
    [self setXMax:xmax];
    [self setYMin:ymin];
    [self setYMax:ymax];
    free(buffer);
}



-(NSPoint)pointNearestTo:(NSPoint)pt
{
    int i;
    int indexOfMinimumPoint = 0;
    double currentDistanceSquared = 0.0;
    double minimumDistanceSquared = 1.e100;
    NSPoint currentPoint;
    for(i=0;i<[self nPoints];i++){
        currentPoint = [self getNSPoint:i];
        currentDistanceSquared = pow(currentPoint.x - pt.x,2.0) + pow(currentPoint.y - pt.y,2.0);
        if (currentDistanceSquared < minimumDistanceSquared){
            minimumDistanceSquared = currentDistanceSquared;
            indexOfMinimumPoint = i;
        }
    }
    return [self getNSPoint:indexOfMinimumPoint];
}


//Note zero offset. Using this for accessing many points is probably less efficient than
//glorping through the data all in one go as there is some extra overhead for each
//accessor call. Till I can test it with timings I'd avoid using the next 
//two functions unless only one or two data points are needed for some reason.

-(NSPoint)getNSPoint:(int)n
{
    RGAPoint *pointBytes = (RGAPoint *)[[self data] bytes];
    return pointBytes[n].p;
}

-(RGAPoint)getRGAPoint:(int)n
{
    RGAPoint *pointBytes = (RGAPoint *)[[self data] bytes];
    return pointBytes[n];
}

//NSCoder stuff
-(void)encodeWithCoder:(NSCoder *)coder
{
    //NSLog(@"Encoding the PlotData object\n");
    [coder encodeObject:data];
    [coder encodeValueOfObjCType:@encode(int) at:&nPoints];
    [coder encodeValueOfObjCType:@encode(float) at:&xMin];
    [coder encodeValueOfObjCType:@encode(float) at:&xMax];
    [coder encodeValueOfObjCType:@encode(float) at:&yMin];
    [coder encodeValueOfObjCType:@encode(float) at:&yMax];
    //[coder encodeValueOfObjCType:@encode(typeof(showMe)) at:&showMe]; //added at v2

}


-(id)initWithCoder:(NSCoder *)coder
{
    int version;
    if (self=[super init]){
        //NSLog(@"Decoding the PlotData object\n");
        version = [coder versionForClassName:@"PlotData"];
        [self setData:[coder decodeObject]];
        [coder decodeValueOfObjCType:@encode(int) at:&nPoints];
        [coder decodeValueOfObjCType:@encode(float) at:&xMin];
        [coder decodeValueOfObjCType:@encode(float) at:&xMax];
        [coder decodeValueOfObjCType:@encode(float) at:&yMin];
        [coder decodeValueOfObjCType:@encode(float) at:&yMax];

        //version here
        //if (version > 1){
        //    [coder decodeValueOfObjCType:@encode(typeof(showMe)) at:&showMe];
        //}

    }
    return self;
}

- (void) dealloc
{
    [[self data] release];
    [super dealloc];
}


idAccessor(data,setData)
idAccessor(myView,setMyView)
intAccessor(nPoints,setNPoints);
floatAccessor(xMin,setXMin)
floatAccessor(xMax,setXMax)
floatAccessor(yMin,setYMin)
floatAccessor(yMax,setYMax)
boolAccessor(showMe,setShowMe)

@end
