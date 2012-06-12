//
//  NodAndShuffleAperture.m
//  iGDDS
//
//  Created by Roberto Abraham on Thu Aug 29 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "NodAndShuffleAperture.h"
#include "FITSImageView.h"
#include "Image.h"


@implementation NodAndShuffleAperture

//Set version information
+(void) initialize
{
    if (self==[NodAndShuffleAperture class]){
        [self setVersion:3];
    }
}


//If initialized without a view as an argument the aperture will receive notifications
//from all FITSImageView objects in the view's hierarchy and the object will return nil
//if sent the view message.
-(id)init{
    [self initWithSuperview:nil];
    [self setOpacity:0.2];
    return self;
}


//If initialized with a view as an argument the aperture will only receive notifications
//from a specific instance of FITSImageView.
- (id)initWithSuperview:(FITSImageView *)sv {

    if (self = [super init]){

        upperExtractionRegion = [[NSBezierPath alloc] init];
        lowerExtractionRegion = [[NSBezierPath alloc] init];
        
        //Set defaults that make an invisible aperture
        [self setDYUpper:0];
        [self setDYLower:0];
        [self setGap:0];
        points[0] = NSMakePoint( 50.0, 100.0);
        points[1] = NSMakePoint(150.0, 100.0);
        points[2] = NSMakePoint(300.0, 100.0);
        points[3] = NSMakePoint(450.0, 100.0);

        //Listen out for mouse clicks
        [self setNote:[NSNotificationCenter defaultCenter]];

        //User has clicked mouse in a view. But not just *any* view, since its
        //quite possible a window will have many instances of FITSImageView which
        //will in turn be sending mouseHasBeenClickedNotifications all over the 
        //placeand we only are interested in getting notified of clicks 
        //in the FITSImageView that we are a property of. So we will designate
        //a specific view it listens out for.
        if (view != nil) {
            [[self note] addObserver: self
                            selector: @selector(processMouseClick:)
                                name: @"FITSImageViewMouseDownNotification"
                              object: sv];
        }
        view = sv; // so the object can respond with the view it is listening to.
		_delegate = nil; 
    }
    return self;
}


- (id)copyWithZone:(NSZone *)zone
{
    NodAndShuffleAperture *newAperture = [[NodAndShuffleAperture allocWithZone:zone] init];
    NSPoint p;

    [newAperture setDYLower:[self dYLower]];
    [newAperture setDYUpper:[self dYUpper]];
    [newAperture setGap:[self gap]];
    [newAperture setLowerExtractionRegion:[[self lowerExtractionRegion] copyWithZone:NULL]];
    [newAperture setUpperExtractionRegion:[[self upperExtractionRegion] copyWithZone:NULL]];
    [newAperture setMessage:[[self message] copyWithZone:NULL]];
    [newAperture setOpacity:[self opacity]];
	[newAperture setShowControlPoints:[self showControlPoints]];
	
    p = [self getWCSPoint:0]; [newAperture setWCSPoint:0 x:p.x y:p.y];
    p = [self getWCSPoint:1]; [newAperture setWCSPoint:1 x:p.x y:p.y];
    p = [self getWCSPoint:2]; [newAperture setWCSPoint:2 x:p.x y:p.y];
    p = [self getWCSPoint:3]; [newAperture setWCSPoint:3 x:p.x y:p.y];
    
    [newAperture setView:[self view]]; // do not copy! just want the pointer
    [newAperture setNote:[self note]]; // do not copy! just want the pointer
    
    return newAperture;
}




//Draw the aperture
-(void)drawMe{

    NSRect bounds = [[self view] bounds];
    NSSize imageSize = [[[self view] image] size];
    NSBezierPath *curve = [NSBezierPath bezierPath];
    float ppyunit = (bounds.size.height)/imageSize.height;
    float dyu,dyl,gp;
    dyu=ppyunit*dYUpper;
    dyl=ppyunit*dYLower;
    gp=ppyunit*gap;

    //Get points in view coordinates from storage in world coordinates
    [self setPointsFromWCSPointsUsingView:[self view]];
    
	
	if (_showControlPoints){
		
		//Draw line connecting endpoints and control points
		[[NSColor blackColor] set];
		[curve moveToPoint:points[0]];
		[curve lineToPoint:points[1]];
		[curve lineToPoint:points[2]];
		[curve lineToPoint:points[3]];
		[curve setLineWidth:1.0];
		[curve stroke];
		[curve removeAllPoints];
		
		//Draw dots at endpoints and control points
		[[NSColor blackColor] set];
		[curve appendBezierPathWithArcWithCenter:points[0] radius:4.0 startAngle:0.0 endAngle:360.];
		[curve fill];[[NSColor whiteColor] set];[curve stroke];[[NSColor blackColor] set];[curve removeAllPoints];
		[curve appendBezierPathWithArcWithCenter:points[1] radius:4.0 startAngle:0.0 endAngle:360.];
		[curve fill];[[NSColor whiteColor] set];[curve stroke];[[NSColor blackColor] set];[curve removeAllPoints];
		[curve appendBezierPathWithArcWithCenter:points[2] radius:4.0 startAngle:0.0 endAngle:360.];
		[curve fill];[[NSColor whiteColor] set];[curve stroke];[[NSColor blackColor] set];[curve removeAllPoints];
		[curve appendBezierPathWithArcWithCenter:points[3] radius:4.0 startAngle:0.0 endAngle:360.];
		[curve fill];[[NSColor whiteColor] set];[curve stroke];[[NSColor blackColor] set];[curve removeAllPoints];
		
		//Draw curve
		[[NSColor redColor] set];
		[curve moveToPoint:points[0]];
		[curve curveToPoint:points[3] controlPoint1:points[1]  controlPoint2:points[2]];
		[curve stroke];[curve removeAllPoints];
		
    }
	
    //Draw upper extraction region
    [curve moveToPoint:NSMakePoint(points[0].x,points[0].y+dyu)];
    [curve curveToPoint:NSMakePoint(points[3].x,points[3].y+dyu)
          controlPoint1:NSMakePoint(points[1].x,points[1].y+dyu)
          controlPoint2:NSMakePoint(points[2].x,points[2].y+dyu)];
    [curve lineToPoint:NSMakePoint(points[3].x,points[3].y-dyu)];
    [curve curveToPoint:NSMakePoint(points[0].x,points[0].y-dyu)
          controlPoint1:NSMakePoint(points[2].x,points[2].y-dyu)
          controlPoint2:NSMakePoint(points[1].x,points[1].y-dyu)];
    [curve closePath];
    [self setUpperExtractionRegion:[curve copyWithZone:NULL]];
    
    //Draw lower extraction region
    [curve removeAllPoints];
    [curve moveToPoint:NSMakePoint(points[0].x,points[0].y-dyu-gp)];
    [curve curveToPoint:NSMakePoint(points[3].x,points[3].y-dyu-gp)
              controlPoint1:NSMakePoint(points[1].x,points[1].y-dyu-gp)
              controlPoint2:NSMakePoint(points[2].x,points[2].y-dyu-gp)];
    [curve lineToPoint:NSMakePoint(points[3].x,points[3].y-dyu-gp-2*dyl)];
    [curve curveToPoint:NSMakePoint(points[0].x,points[0].y-dyu-gp-2*dyl)
          controlPoint1:NSMakePoint(points[2].x,points[2].y-dyu-gp-2*dyl)
          controlPoint2:NSMakePoint(points[1].x,points[1].y-dyu-gp-2*dyl)];
    [curve closePath];
    [self setLowerExtractionRegion:[curve copyWithZone:NULL]];
    
    //Draw the curves
    [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.0 alpha:opacity] set]; //transparent yellow
    [[self upperExtractionRegion] fill];
    [[NSColor colorWithDeviceRed:1.0 green:0.0 blue:1.0 alpha:opacity] set]; //transparent magenta
    [[self lowerExtractionRegion] fill];

}


//Return index of first NSPoint within HITDIST of a specified point
- (int)pointAtPoint:(NSPoint)p
{
    int n = NUMPOINTS;
    int i;
    for (i = 0; i < n; i++) {
        float dx = p.x - points[i].x;
        float dy = p.y - points[i].y;
        float dist = sqrt(dx*dx + dy*dy);
        if (dist < HITDIST)
            return i;
    }
    return -1;
}


//User has clicked a mouse... whoopee!
- (void)processMouseClick:(NSNotification *)instruction{
    NSEvent *event;
    NSPoint pp;
    NSPoint pt;
    int pointIndex;
    int i;
    float xshift, yshift;
    FITSImageView *fv;

    fv = [instruction object];
    pt = [[fv pV] pointValue]; 
    pointIndex = [self pointAtPoint:pt];

    NSLog(@"Aperture is processing the mouse click.\n");
    NSLog(@"Upper and lower region counts: %d %d\n",[upperExtractionRegion elementCount],[lowerExtractionRegion elementCount]);

    if (pointIndex>-1) {
        //mouse click is near a control point
        do {
            event = [[fv window] nextEventMatchingMask:NSLeftMouseDraggedMask
                | NSLeftMouseUpMask];
            pp = [fv convertPoint:[event locationInWindow] fromView:nil];
            points[pointIndex] = pp;
            [self setWCSPointsFromPointsUsingView:fv]; // Crucial to update this!
            [fv setNeedsDisplayInRect:[fv bounds]];
			[[self delegate] mirrorNodAndShuffleAperture:self];
            [self setMessage:@"Dragging control point"];
        } while ([event type] == NSLeftMouseDragged);
    }
    else if ([upperExtractionRegion containsPoint:pt] || [lowerExtractionRegion containsPoint:pt]) {
        //mouse click was inside one of the regions but not near a control point
        NSLog(@"Clicked inside a region.\n");
        do {
            event = [[fv window] nextEventMatchingMask:NSLeftMouseDraggedMask
                | NSLeftMouseUpMask];
            pp = [fv convertPoint:[event locationInWindow] fromView:nil];
            xshift = pp.x - pt.x;
            yshift = pp.y - pt.y;
            for(i=0;i<NUMPOINTS;i++){
                points[i].x = points[i].x + xshift;
                points[i].y = points[i].y + yshift;
            }
            pt.x = pp.x;
            pt.y = pp.y;
            [self setWCSPointsFromPointsUsingView:fv]; // Crucial to update this!
			[[self delegate] mirrorNodAndShuffleAperture:self];
            [fv setNeedsDisplayInRect:[fv bounds]];
            [self setMessage:@"Dragging aperture"];
        } while ([event type] == NSLeftMouseDragged);       
    }
    [self setMessage:@""];
    NSLog(@"Leaving processMouseClick\n");

}


-(void)dealloc{
    [note removeObserver:self];
    [upperExtractionRegion release];
    [lowerExtractionRegion release];
	
	//Remove delegate observer too
	if (_delegate)
        [note removeObserver:_delegate name:nil object:self];
    [note removeObserver:self];
	
	[super dealloc];
}


-(void) setWCSPointsFromPointsUsingView:(FITSImageView *)v{
    int i;
    for(i=0;i<NUMPOINTS;i++) {
        wcspoints[i]=[v pointInWCS:points[i]];
    }
}


-(void) setPointsFromWCSPointsUsingView:(FITSImageView *)v{
    int i;
    for(i=0;i<NUMPOINTS;i++) {
        points[i]=[v pointInVCS:wcspoints[i]];
    }
}         


// Delegate method. 
- (void)mirrorNodAndShuffleAperture:(NodAndShuffleAperture *)a
{
	NSPoint p0,p1,p2,p3;
	
	p0 = [a getWCSPoint:0];
	p1 = [a getWCSPoint:1];
	p2 = [a getWCSPoint:2];
	p3 = [a getWCSPoint:3];
	[self setDYUpper:[a dYUpper]];
	[self setDYLower:[a dYLower]];	
	[self setGap:[a gap]];
	[self setWCSPoint:0 x:p0.x y:p0.y];
	[self setWCSPoint:1 x:p1.x y:p1.y];
	[self setWCSPoint:2 x:p2.x y:p2.y];
	[self setWCSPoint:3 x:p3.x y:p3.y];
	[[self view] setNeedsDisplay:YES];
}



//Special accessor methods

-(void) setPoint:(int)num x:(float)x y:(float)y{
    points[num].x = x;
    points[num].y = y;
}

-(void) setWCSPoint:(int)num x:(float)x y:(float)y{
    wcspoints[num].x = x;
    wcspoints[num].y = y;
}

-(NSPoint) getWCSPoint:(int)num {
    return wcspoints[num];
}


-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeValueOfObjCType:@encode(float) at:&dYUpper];
    [coder encodeValueOfObjCType:@encode(float) at:&dYLower];
    [coder encodeValueOfObjCType:@encode(float) at:&gap];
    [coder encodeObject:[NSValue valueWithPoint:points[0]]];
    [coder encodeObject:[NSValue valueWithPoint:points[1]]];
    [coder encodeObject:[NSValue valueWithPoint:points[2]]];
    [coder encodeObject:[NSValue valueWithPoint:points[3]]];
    [coder encodeObject:[NSValue valueWithPoint:wcspoints[0]]];
    [coder encodeObject:[NSValue valueWithPoint:wcspoints[1]]];
    [coder encodeObject:[NSValue valueWithPoint:wcspoints[2]]];
    [coder encodeObject:[NSValue valueWithPoint:wcspoints[3]]];
    //added at version 2
    [coder encodeValueOfObjCType:@encode(float) at:&opacity];
	//added at version 3
    [coder encodeValueOfObjCType:@encode(BOOL) at:&_showControlPoints];


}


-(id)initWithCoder:(NSCoder *)coder
{
    int version;
    if (self=[super init]){
        version = [coder versionForClassName:@"NodAndShuffleAperture"];
        
        [coder decodeValueOfObjCType:@encode(float) at:&dYUpper];
        [coder decodeValueOfObjCType:@encode(float) at:&dYLower];
        [coder decodeValueOfObjCType:@encode(float) at:&gap];
        points[0]=[[coder decodeObject] pointValue];
        points[1]=[[coder decodeObject] pointValue];
        points[2]=[[coder decodeObject] pointValue];
        points[3]=[[coder decodeObject] pointValue];
        wcspoints[0]=[[coder decodeObject] pointValue];
        wcspoints[1]=[[coder decodeObject] pointValue];
        wcspoints[2]=[[coder decodeObject] pointValue];
        wcspoints[3]=[[coder decodeObject] pointValue];

        if (version >= 2){
            [coder decodeValueOfObjCType:@encode(float) at:&opacity];
        }
        else {
            [self setOpacity:0.2];
        }
		
		if (version >= 3){
            [coder decodeValueOfObjCType:@encode(BOOL) at:&_showControlPoints];
        }
        else {
            [self setShowControlPoints:YES];
        }
        
    }    
    return self;
}

- (NSString *) description
{
    NSString *result = [[NSString alloc] initWithFormat:@"aperture with dYUpper:%f dYLower: %f gap:%f",
        [self dYUpper],[self dYLower],[self gap]];
    [result autorelease];
    return result;
}


//Accessor methods
idAccessor(note,setNote)
floatAccessor(dYUpper,setDYUpper)
floatAccessor(dYLower,setDYLower)
floatAccessor(gap,setGap)
idAccessor(upperExtractionRegion,setUpperExtractionRegion)
idAccessor(lowerExtractionRegion,setLowerExtractionRegion)
idAccessor(view,setView)
floatAccessor(opacity,setOpacity)
idAccessor(message,setMessage)

- (BOOL)showControlPoints
{
	return _showControlPoints;
}

- (void)setShowControlPoints:(BOOL) val
{
	_showControlPoints = val;
}


//Delegate accessor methods. Note that the delegate class is *not* retained and this is
//on purpose. See http://cocoadevcentral.com/articles/000075.php for discussion
//of this point. Note also that the etiquette is that the delegate should 
//automatically be registered for any notifications that the delegator posts.
//We add this behaviour to the set method. We must also remember to remove
//the delegate from the notification centre when the class is deallocated
//in the dealloc method.
- (id)delegate
{
    return _delegate;
}

- (void)setDelegate:(id)new_delegate
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    if (_delegate)
        [nc removeObserver:_delegate name:nil object:self];
    
    _delegate = new_delegate;
    
    // if the NodAndShuffleAperture object posted any notifications we would register
	// the deligate to listen out for these here.... but the aperture only
	// listens for notifications and doesn't post any.

}


@end



