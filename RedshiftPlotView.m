//
//  RedshiftPlotView.m
//  iGDDS
//
//  Created by Roberto Abraham on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "RedshiftPlotView.h"
#import "ExtractionWindowController.h"


@implementation RedshiftPlotView


- (void) flagLine:(id)sender
{
    float lambda0;
    float lambda[14];
    float z;

    NSLog(@"Menu opened at %d %d",[self xMouse],[self yMouse]);
    NSLog(@"selected = %@ with tag %d",[(NSMenuItem*)sender title],[sender tag]);
    lambda[0]  =  912; //Lyman limit
    lambda[1]  = 1216; //Lyman alpha
    lambda[2]  = 2796; //Mg II
    lambda[3]  = 2803; //Mg II
    lambda[4]  = 3727; //[OII]
    lambda[5]  = 3933; //K
    lambda[6]  = 3969; //H
    lambda[7]  = 4000; //4000A break
    lambda[8]  = 4102; //Hdelta
    lambda[9]  = 4304; //G
    lambda[10] = 4861; //Hbeta
    lambda[11] = 5007; //[OIII]
    lambda[12] = 5174; //Mgb
    lambda[13] = 6562; //Halpha

    //Determine the lowest wavelength plotted
    lambda0 = [self xMin];

    //Work out redshift
    z = ([self xMouse] - lambda[[sender tag]])/lambda[[sender tag]];
    NSLog(@"Trial redshift: %f",z);
    [[(ExtractionWindowController *)delegate redshiftTabTrialRedshiftField] setFloatValue:z];
    [[[self mainLayerData] objectAtIndex:2] setRedshift:z]; // labels
    [delegate plotTheRedshiftTabSpectrum:nil];
    [self refresh];
}


- (NSMenu*) menuForEvent:(NSEvent*)evt {
    NSMenu        *contextMenu = [[NSMenu alloc] initWithTitle:@"Quick Edit"];
    NSMenu        *linesMenu =[[NSMenu alloc] initWithTitle:@"Quick Edit"];
    NSMenuItem    *pdfItem = [[NSMenuItem alloc] initWithTitle:@"Copy As PDF"
                                                        action:@selector(copyPDFToPasteboard)
                                                 keyEquivalent:@""];
    NSMenuItem    *epsItem = [[NSMenuItem alloc] initWithTitle:@"Copy As EPS"
                                                        action:@selector(copyEPSToPasteboard)
                                                 keyEquivalent:@""];
    NSMenuItem    *tiffItem = [[NSMenuItem alloc] initWithTitle:@"Copy As TIFF"
                                                         action:@selector(copyTIFFToPasteboard)
                                                  keyEquivalent:@""];
    NSMenuItem    *flagItem = [[NSMenuItem alloc] initWithTitle:@"Set Redshift By Assuming This Line Is"
                                                         action:@selector(flagLine:)
                                                  keyEquivalent:@""];
    NSMenuItem    *lymanLimit = [[NSMenuItem alloc] initWithTitle:@"Lyman limit (912)"
                                                           action:@selector(flagLine:)
                                                    keyEquivalent:@""];
    NSMenuItem    *lymanAlpha = [[NSMenuItem alloc] initWithTitle:@"Lyman alpha (1216)"
                                                           action:@selector(flagLine:)
                                                    keyEquivalent:@""];
    NSMenuItem    *mgII1 = [[NSMenuItem alloc] initWithTitle:@"MgII (2796)"
                                                      action:@selector(flagLine:)
                                               keyEquivalent:@""];
    NSMenuItem    *mgII2 = [[NSMenuItem alloc] initWithTitle:@"MgII (2803)"
                                                      action:@selector(flagLine:)
                                               keyEquivalent:@""];
    NSMenuItem    *oII = [[NSMenuItem alloc] initWithTitle:@"[OII] (3727)"
                                                    action:@selector(flagLine:)
                                             keyEquivalent:@""];
    NSMenuItem    *k = [[NSMenuItem alloc] initWithTitle:@"K (3933)"
                                                  action:@selector(flagLine:)
                                           keyEquivalent:@""];
    NSMenuItem    *h = [[NSMenuItem alloc] initWithTitle:@"H (3969)"
                                                  action:@selector(flagLine:)
                                           keyEquivalent:@""];
    NSMenuItem    *balmerBreak = [[NSMenuItem alloc] initWithTitle:@"4000 Break (4000)"
                                                            action:@selector(flagLine:)
                                                     keyEquivalent:@""];
    NSMenuItem    *hDelta = [[NSMenuItem alloc] initWithTitle:@"Hdelta (4102)"
                                                       action:@selector(flagLine:)
                                                keyEquivalent:@""];
    NSMenuItem    *g = [[NSMenuItem alloc] initWithTitle:@"G (4304)"
                                                  action:@selector(flagLine:)
                                           keyEquivalent:@""];
    NSMenuItem    *hBeta = [[NSMenuItem alloc] initWithTitle:@"Hbeta (4861)"
                                                      action:@selector(flagLine:)
                                               keyEquivalent:@""];
    NSMenuItem    *oIII = [[NSMenuItem alloc] initWithTitle:@"[OIII] (5007)"
                                                     action:@selector(flagLine:)
                                              keyEquivalent:@""];
    NSMenuItem    *mgb = [[NSMenuItem alloc] initWithTitle:@"Mgb (5174)"
                                                    action:@selector(flagLine:)
                                             keyEquivalent:@""];
    NSMenuItem    *hAlpha = [[NSMenuItem alloc] initWithTitle:@"Halpha (6562)"
                                                       action:@selector(flagLine:)
                                                keyEquivalent:@""];

    //Get and store position of the click
    NSPoint pt=[self convertPoint:[evt locationInWindow] fromView:nil];
    pt=[[self inverseTrans] transformPoint:pt];
    [self setXMouse:pt.x];
    [self setYMouse:pt.y];

    //set tags
    [lymanLimit setTag:0];
    [lymanAlpha setTag:1];
    [mgII1 setTag:2];
    [mgII2 setTag:3];
    [oII setTag:4];
    [k setTag:5];
    [h setTag:6];
    [balmerBreak setTag:7];
    [hDelta setTag:8];
    [g setTag:9];
    [hBeta setTag:10];
    [oIII setTag:11];
    [mgb setTag:12];
    [hAlpha setTag:13];

    //setup the menu
    [contextMenu addItem:pdfItem];
    [contextMenu addItem:epsItem];
    [contextMenu addItem:tiffItem];
    [contextMenu addItem:flagItem];
    [flagItem setSubmenu:linesMenu];
    [linesMenu addItem:lymanLimit];
    [linesMenu addItem:lymanAlpha];
    [linesMenu addItem:mgII1];
    [linesMenu addItem:mgII2];
    [linesMenu addItem:oII];
    [linesMenu addItem:k];
    [linesMenu addItem:h];
    [linesMenu addItem:balmerBreak];
    [linesMenu addItem:hDelta];
    [linesMenu addItem:g];
    [linesMenu addItem:hBeta];
    [linesMenu addItem:oIII];
    [linesMenu addItem:mgb];
    [linesMenu addItem:hAlpha];

    //tidy up
    [lymanLimit release];
    [lymanAlpha release];
    [mgII1 release];
    [mgII2 release];
    [oII release];
    [k release];
    [h release];
    [balmerBreak release];
    [hDelta release];
    [g release];
    [hBeta release];
    [oIII release];
    [mgb release];
    [hAlpha release];
    [linesMenu release];
    [flagItem release];
    [contextMenu autorelease];

    return contextMenu;
}

//Accessor macros
boolAccessor(hold,setHold)

@end
