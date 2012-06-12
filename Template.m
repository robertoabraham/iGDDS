//
//  Template.m
//  iGDDS
//
//  Created by Roberto Abraham on Mon Sep 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "Template.h"


@implementation Template


-(id) init{
    if (self = [super init]){
        _wave = nil;
        _description = nil;
        _isDisplayed = NO;
        _color = [NSColor blackColor];
    }
    return self;
}



//Accessor methods
-(NSString *)description
{
    return _description;
}

-(BOOL)isDisplayed
{
    return _isDisplayed;
}

-(Wave *)wave
{
    return _wave;
}

-(NSColor *)color
{
    return _color;
}

-(void)setDescription:(NSString *)desc
{
    [desc retain];
    [_description release];
    _description = desc;
}

-(void)setIsDisplayed:(BOOL)isdisp
{
    _isDisplayed = isdisp;
}

-(void)setWave:(Wave *)w
{
    [w retain];
    [_wave release];
    _wave = w;
}

-(void)setColor:(NSColor *)c
{
    [c retain];
    [_color release];
    _color = c;
}


@end
