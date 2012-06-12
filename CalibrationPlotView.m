//
//  CalibrationPlotView.m
//  iGDDS
//
//  Created by Roberto Abraham on Sun Aug 17 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CalibrationPlotView.h"
//#import "ExtractionWindowController.h"

@implementation CalibrationPlotView

- (void) flagLine:(id)sender
{
    float xValue0;
    float xValue[5];

    NSLog(@"Menu opened at %d %d",[self xMouse],[self yMouse]);
    NSLog(@"selected = %@ with tag %d",[(NSMenuItem*)sender title],[sender tag]);
    xValue[0]  = 1000; 
    xValue[1]  = 2000;
    xValue[2]  = 3000;
    xValue[3]  = 4000;
    xValue[4]  = 5000;

    //Determine the lowest wavelength plotted
    xValue0 = [self xMin];

    //Work out redshift
    [self refresh];
}


- (NSMenu*) menuForEvent:(NSEvent*)evt {
    NSMenu        *contextMenu = [[NSMenu alloc] initWithTitle:@"Sky Lines"];
    NSMenuItem    *line0 = [[NSMenuItem alloc] initWithTitle:@"1000"
                                                      action:@selector(flagLine:)
                                                    keyEquivalent:@""];
    NSMenuItem    *line1 = [[NSMenuItem alloc] initWithTitle:@"2000"
                                                      action:@selector(flagLine:)
                                               keyEquivalent:@""];
    NSMenuItem    *line2 = [[NSMenuItem alloc] initWithTitle:@"3000"
                                                      action:@selector(flagLine:)
                                               keyEquivalent:@""];
    NSMenuItem    *line3 = [[NSMenuItem alloc] initWithTitle:@"4000"
                                                      action:@selector(flagLine:)
                                               keyEquivalent:@""];
    NSMenuItem    *line4 = [[NSMenuItem alloc] initWithTitle:@"5000"
                                                      action:@selector(flagLine:)
                                               keyEquivalent:@""];
    
    //Get and store position of the click
    NSPoint pt=[self convertPoint:[evt locationInWindow] fromView:nil];
    pt=[[self inverseTrans] transformPoint:pt];
    [self setXMouse:pt.x];
    [self setYMouse:pt.y];

    //set tags
    [line0 setTag:0];
    [line1 setTag:1];
    [line2 setTag:2];
    [line3 setTag:3];
    [line4 setTag:4];


    //setup the menu
    [contextMenu addItem:line0];
    [contextMenu addItem:line1];
    [contextMenu addItem:line2];
    [contextMenu addItem:line3];
    [contextMenu addItem:line4];

    //tidy up
    [line0 release];
    [line1 release];
    [line2 release];
    [line3 release];
    [line4 release];
    [contextMenu autorelease];

    return contextMenu;
}

@end
