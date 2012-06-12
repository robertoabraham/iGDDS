//
//  Mask.m
//  iGDDS
//
//  Created by Roberto Abraham on Tue Sep 03 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "Mask.h"
#include "FITSImageView.h"
#include "Image.h"

@implementation Mask

//If initialized without a view as an argument the aperture will receive notifications
//from all FITSImageView objects in the view's hierarchy and the object will return nil
//if sent the view message.
-(id)init{
    [self initWithSuperview:nil atX:10 andY:10 withWidth:10 andHeight:10];
    [self setSelfDestruct:NO];
	[self setOpacity:0.2];
    return self;
}


//If initialized with a view as an argument the aperture will only receive notifications
//from a specific instance of FITSImageView. We have two initializers depending on whether
//or not view or world coordinates are being used.

//Initializer to use if input points are given in view coordinates.
- (id)initWithSuperview:(FITSImageView *)sv
                    atX:(float)x
                   andY:(float)y
              withWidth:(float)w
              andHeight:(float)h
{
    int i;
    
    if (self = [super init]){

        box = [[NSBezierPath alloc] init];
		[self setOpacity:0.2];

        points[0] = NSMakePoint(x,y); 
        points[1] = NSMakePoint(x,y+h);
        points[2] = NSMakePoint(x+w,y+h);
        points[3] = NSMakePoint(x+w,y);

        for(i=0;i<NUMPOINTS;i++)
            wcspoints[i] = [sv pointInWCS:points[i]];

        //Listen out for mouse clicks
        [self setNote:[NSNotificationCenter defaultCenter]];

        //User has clicked mouse in a view. But not just *any* view, since its
        //quite possible a window will have many instances of FITSImageView which
        //will in turn be sending mouseHasBeenClickedNotifications all over the
        //placeand we only are interested in getting notified of clicks
        //in the FITSImageView that we are a property of.
        [[self note] addObserver: self
                        selector: @selector(processMouseClick:)
                            name: @"FITSImageViewMouseDownNotification"
                          object: sv];
        view = sv; // so the object can respond with the view it is listening to.

        //If this ever gets set to YES the mask will obliterate itself next time instead
        //of trying to draw itself.
        [self setSelfDestruct:NO];

    }
    return self;
}


//Initializer to use if input points are given in WCS coordinates.
- (id)initWithSuperview:(FITSImageView *)sv
                 atWCSX:(float)x
                andWCSY:(float)y
           withWCSWidth:(float)w
           andWCSHeight:(float)h
{
    int i;

    if (self = [super init]){

        box = [[NSBezierPath alloc] init];
		[self setOpacity:0.2];

        wcspoints[0] = NSMakePoint(x,y);
        wcspoints[1] = NSMakePoint(x,y+h);
        wcspoints[2] = NSMakePoint(x+w,y+h);
        wcspoints[3] = NSMakePoint(x+w,y);

        for(i=0;i<NUMPOINTS;i++)
            points[i] = [sv pointInVCS:wcspoints[i]];

        //Listen out for mouse clicks
        [self setNote:[NSNotificationCenter defaultCenter]];

        //User has clicked mouse in a view. But not just *any* view, since its
        //quite possible a window will have many instances of FITSImageView which
        //will in turn be sending mouseHasBeenClickedNotifications all over the
        //placeand we only are interested in getting notified of clicks
        //in the FITSImageView that we are a property of.
        [[self note] addObserver: self
                        selector: @selector(processMouseClick:)
                            name: @"FITSImageViewMouseDownNotification"
                          object: sv];
        view = sv; // so the object can respond with the view it is listening to.
    }
    return self;
}


//Draw the aperture
-(void)drawMe{

    NSBezierPath *curve = [NSBezierPath bezierPath];

    //Get points in view coordinates from storage in world coordinates
    [self setPointsFromWCSPointsUsingView:[self view]];

    //Draw box
    [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:[self opacity]] set]; //transparent red
    [curve moveToPoint:points[0]];
    [curve lineToPoint:points[1]];
    [curve lineToPoint:points[2]];
    [curve lineToPoint:points[3]];
    [curve closePath];
    [curve fill];
    [self setBox:[curve copyWithZone:NULL]];
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
    int pointIndex,anchorIndex;
    int i;
    float xshift, yshift;
    FITSImageView *fv;
    NSPoint originalPoints[NUMPOINTS];
    
    for(i=0;i<NUMPOINTS;i++)
        originalPoints[i]=points[i];

    fv = [instruction object];
    pt = [[fv pV] pointValue];
    pointIndex = [self pointAtPoint:pt];

    for(i=0;i<NUMPOINTS;i++){
        NSLog(@"point: %i %f %f\n",i,points[i].x,points[i].y);
    }
    

    //Are we dragging? 
    if (pointIndex>-1) {
        //mouse click is near a control point
        if (pointIndex==0) {
            anchorIndex=2;
        }
        else if (pointIndex==1) {
            anchorIndex=3;
        }
        else if (pointIndex==2) {
            anchorIndex=0;
        }
        else {
            anchorIndex=1;
        }
        
        do {
            
            event = [[fv window] nextEventMatchingMask:NSLeftMouseDraggedMask
                | NSLeftMouseUpMask | NSKeyDownMask ];           
            
            pp = [fv convertPoint:[event locationInWindow] fromView:nil];
            points[pointIndex] = pp;
            if (pointIndex==0) {
                points[1].x = points[pointIndex].x;
                points[3].y = points[pointIndex].y;
            }
            else if (pointIndex==1) {
                points[0].x = points[pointIndex].x;
                points[2].y = points[pointIndex].y;
            }
            else if (pointIndex==2) {
                points[3].x = points[pointIndex].x;
                points[1].y = points[pointIndex].y;
            }
            else {
                points[2].x = points[pointIndex].x;
                points[0].y = points[pointIndex].y;
            }
            [self setWCSPointsFromPointsUsingView:fv]; // Crucial to update this!

            if ([event type] == NSKeyDown){
                [self setMessage:@"Mask resizing aborted"];
                for(i=0;i<NUMPOINTS;i++)
                    points[i]=originalPoints[i];
            }
            else{
                [self setMessage:@"Editing in progress: resizing mask"];
            }

            [[fv superview] autoscroll:event];
            [fv setNeedsDisplayInRect:[fv bounds]];


        } while ([event type] == NSLeftMouseDragged);
    }
    else if ([box containsPoint:pt]) {
        //Was mouse click inside one of the regions but not near a control point?
        NSLog(@"Clicked inside a region.\n");
        do {
                        
            event = [[fv window] nextEventMatchingMask:NSLeftMouseDraggedMask
                | NSLeftMouseUpMask | NSKeyDownMask];
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

            if ([event type] == NSKeyDown){
                [self setMessage:@"Mask movement aborted"];
                for(i=0;i<NUMPOINTS;i++)
                    points[i]=originalPoints[i];
            }
            else{
                [self setMessage:@"Editing in progress: moving mask to a new position"];
            }

            [[fv superview] autoscroll:event];
            [fv setNeedsDisplayInRect:[fv bounds]];

        } while ([event type] == NSLeftMouseDragged);
    }
    
    [self setMessage:@"Editing completed"];

    
}


-(void)dealloc{
    [note removeObserver:self];
    [box release];
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

//NSCoding methods

+(void) initialize
{
    if (self==[Mask class]){
        [self setVersion:1];
    }
}


-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[NSValue valueWithPoint:points[0]]];
    [coder encodeObject:[NSValue valueWithPoint:points[1]]];
    [coder encodeObject:[NSValue valueWithPoint:points[2]]];
    [coder encodeObject:[NSValue valueWithPoint:points[3]]];
    [coder encodeObject:[NSValue valueWithPoint:wcspoints[0]]];
    [coder encodeObject:[NSValue valueWithPoint:wcspoints[1]]];
    [coder encodeObject:[NSValue valueWithPoint:wcspoints[2]]];
    [coder encodeObject:[NSValue valueWithPoint:wcspoints[3]]];
}


-(id)initWithCoder:(NSCoder *)coder
{
    if (self=[super init]){
        points[0]=[[coder decodeObject] pointValue];
        points[1]=[[coder decodeObject] pointValue];
        points[2]=[[coder decodeObject] pointValue];
        points[3]=[[coder decodeObject] pointValue];
        wcspoints[0]=[[coder decodeObject] pointValue];
        wcspoints[1]=[[coder decodeObject] pointValue];
        wcspoints[2]=[[coder decodeObject] pointValue];
        wcspoints[3]=[[coder decodeObject] pointValue];
    }
	
	[self setOpacity:0.2];
	
    return self;
}



//Accessor methods
idAccessor(note,setNote)
idAccessor(box,setBox)
idAccessor(view,setView)
idAccessor(message,setMessage)
boolAccessor(selfDestruct,setSelfDestruct)
floatAccessor(opacity,setOpacity)


@end
