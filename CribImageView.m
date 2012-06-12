//
//  CribImageView.m
//  iGDDS
//
//  Created by Roberto Abraham on Thu Oct 31 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "CribImageView.h"
#include "AccessorMacros.h"


@implementation CribImageView


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self){
    }
    return self;
}

- (void) drawRect:(NSRect) rect{
    NSRect r = [self bounds];
    NSSize s = [[self image] size];
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:r];
    if ([self image]) {
        NSLog(@"In CribImageView... trying to composite the crib image\n");
        [[self image] drawInRect:r fromRect:NSMakeRect(0.0,0.0,s.width,s.height) operation:NSCompositeSourceAtop fraction:1.0];
    }
}

@end
