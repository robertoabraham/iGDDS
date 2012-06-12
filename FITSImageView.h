//
//  FITSImageView.h
//  iTelescope
//
//  Created by Roberto Abraham on Wed Jul 31 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#include "AccessorMacros.h"
#import "NodAndShuffleAperture.h"
#import "Mask.h"

@interface FITSImageView : NSImageView {
    NSNotificationCenter *note;
    NSMutableArray *annotationPaths;
    NSMutableArray *objectsToDraw;
    NSPoint p;     // NSPoint position of last mouse click
    int x;         // X position of last mouse click
    int y;         // Y position of last mouse click
    NSValue *pV;   // wrapped NSPoint position of last mouse click.
    float scaling; // Scaling of NSImage image within the view
    float pPXUnit; // Pixels per WCS x unit
    float pPYUnit; // Pixels per WCS y unit
    float x0;      // WCS x-coordinate of the bottom-left pixel in the view
    float y0;      // WCS y-coordinate of the bottom-right pixel in the view
	float maskOpacity; // Opacity of the masks

    NodAndShuffleAperture *aperture; //careful with name... remember nsapp is a reserved global
    NSMutableArray *masks;
    bool shouldDrawNodAndShuffleExtractionBox;
    bool shouldDrawMasks;
    bool shouldCreateMasks;
}

- (void)scaleFrameBy:(float)scale;
- (NSPoint)pointInWCS:(NSPoint)pt;
- (NSPoint)pointInVCS:(NSPoint)pt;
- (void)addMask:(Mask *)m;
- (void)zoomInOn:(NSPoint)pt;
- (void)copyPDFToPasteboard;
- (void)copyEPSToPasteboard;
- (void)copyTIFFToPasteboard;

//Accessor methods
idAccessor_h(note,setNote)
idAccessor_h(annotationPaths, setAnnotationPaths)
idAccessor_h(objectsToDraw, setObjectsToDraw)
idAccessor_h(masks, setMasks)
intAccessor_h(x,setX)
intAccessor_h(y,setY)
idAccessor_h(pV,setPV);
floatAccessor_h(scaling,setScaling)
floatAccessor_h(pPXUnit,setPPXUnit)
floatAccessor_h(pPYUnit,setPPYUnit)
floatAccessor_h(x0,setX0)
floatAccessor_h(y0,setY0)
boolAccessor_h(shouldDrawNodAndShuffleExtractionBox,setShouldDrawNodAndShuffleExtractionBox)
boolAccessor_h(shouldDrawMasks,setShouldDrawMasks)
boolAccessor_h(shouldCreateMasks,setShouldCreateMasks)
idAccessor_h(aperture,setAperture)
floatAccessor_h(maskOpacity,setMaskOpacity)

-(void)setP:(NSPoint)point;
-(NSPoint)p;


@end
