//
//  Guide.m
//  iGDDS
//
//  Created by Roberto Abraham on Sat Nov 02 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "Guide.h"


@implementation Guide

-(void) drawMe
{
    NSBezierPath *curve = [NSBezierPath bezierPath];
    float ppxu = [[self view] pPXUnit];
    float ppyu = [[self view] pPYUnit];

    //Draw box
    //NSLog(@"Inside guide trying to draw this rectangle in the view. left: %f right %f top %f bottom %f",left*ppxu,right*ppxu,top*ppyu,bottom*ppyu);
    [[NSColor greenColor] set];
    [[NSColor colorWithDeviceRed:0.0 green:1.0 blue:0.0 alpha:0.2] set]; //transparent green
    [curve moveToPoint:NSMakePoint(left*ppxu,bottom*ppyu)];
    [curve lineToPoint:NSMakePoint(left*ppxu,top*ppyu)];
    [curve lineToPoint:NSMakePoint(right*ppxu,top*ppyu)];
    [curve lineToPoint:NSMakePoint(right*ppxu,bottom*ppyu)];
    [curve closePath];
    [curve fill];
}

-(id)initWithView:(id)v
{
    if(self = [super init]){
        [self setLeft:0.0];
        [self setRight:0.0];
        [self setBottom:0.0];
        [self setTop:0.0];
        [self setView:v];
    }
    return self;
}

-(id)init
{
    [self initWithView:nil];
    return self;
}


floatAccessor(left,setLeft)
floatAccessor(right,setRight)
floatAccessor(bottom,setBottom)
floatAccessor(top,setTop)
idAccessor(view,setView)

@end
