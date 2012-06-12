//
//  FITSImageView.m
//  iTelescope
//
//  Created by Roberto Abraham on Wed Jul 31 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "FITSImageView.h"
#import "Mask.h"

@implementation FITSImageView

- (void)drawRect:(NSRect)rect {
    NSRect bounds = [self bounds];
    NSSize imageSize = [[self image] size];
    NSEnumerator *oe = [[self objectsToDraw] objectEnumerator];
    NSEnumerator *ae = [[self annotationPaths] objectEnumerator];
    NSEnumerator *me; //mask enumerator
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    NSFont *messageFont;
    NSBezierPath *pt;
    Mask *mk;
    
    [super drawRect:rect];
    [self setPPXUnit:(bounds.size.width)/imageSize.width];
    [self setPPYUnit:(bounds.size.height)/imageSize.height];

    if(objectsToDraw){
        id thingToDraw;
        while (thingToDraw = [oe nextObject]){
            [thingToDraw drawMe];
        }
    }

    while (pt = [ae nextObject]){
        [[NSColor colorWithDeviceRed:0.7 green:0.3 blue:0.3 alpha:0.3] set];
        [pt fill];
    }

    if(shouldDrawNodAndShuffleExtractionBox){
        [aperture drawMe];
    }

    if(shouldDrawMasks){
        me = [[self masks] objectEnumerator];
        while (mk = [me nextObject]){
			[mk setOpacity:[self maskOpacity]];
			[mk drawMe];
			[[mk message] drawAtPoint:NSMakePoint(1,1) withAttributes:attrs];
			[mk setMessage:@""];
        }
    }
    
    messageFont = [NSFont systemFontOfSize:10];
    [attrs setObject:messageFont forKey:NSFontAttributeName];
    [[aperture message] drawAtPoint:NSMakePoint(1,1) withAttributes:attrs];
    
}

-(void) addMask:(Mask *)m{
        [masks addObject:m];
}


- (void)scaleFrameBy:(float)imscale
{
    NSSize imageSize = [[self image] size];
    NSAffineTransform *at = [NSAffineTransform transform];
    [at scaleBy:imscale];

    [self setFrameSize:[at transformSize:imageSize]];
    [self setScaling:imscale];
    [self setNeedsDisplay:YES];
}


- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint pt;
    Mask *m;
    
    NSLog(@"mouseDown in FITSImageView: %d", [theEvent clickCount]);
    pt=[self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSLog(@"location: %f %f",pt.x,pt.y);
    [self setP:pt];
    [self setPV:[NSValue valueWithPoint:pt]];
    [self setX:pt.x];
    [self setY:pt.y];
    if ([theEvent modifierFlags] & NSAlternateKeyMask){
        NSLog(@"Adding a new mask");
        m = [[[Mask alloc] initWithSuperview:self
                                         atX:pt.x-1.0
                                        andY:pt.y-1.0
                                   withWidth:1.0
                                   andHeight:1.0] autorelease];
        [self addMask:m];
        NSLog(@"This view now has %d masks\n",[[self masks] count]);
        [self setNeedsDisplay:YES];
    }
    [note postNotificationName: @"FITSImageViewMouseDownNotification" object:self];
}


//- (void)mouseDragged:(NSEvent *)event
//{
//    NSLog(@"mouseDragged:");
//}


//- (void)mouseUp:(NSEvent *)event
//{
//    NSLog(@"mouseUp:");
//}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self){
        [self setNote:[NSNotificationCenter defaultCenter]];
        //masks = [[NSMutableArray alloc] init];
        [self setShouldDrawNodAndShuffleExtractionBox:NO];
        [self setShouldDrawMasks:NO];
        [self setShouldCreateMasks:NO];
		[self setMaskOpacity:0.2];
    }
    return self;
}


// Converts view coordinates to world coordinates
-(NSPoint) pointInWCS:(NSPoint)pt {
    NSPoint wcsPt;
    NSRect bounds = [self bounds];
    NSSize imageSize = [[self image] size];
    float ppxunit, ppyunit;

    ppxunit = (bounds.size.width)/imageSize.width;
    ppyunit = (bounds.size.height)/imageSize.height;
    
    wcsPt.x = x0 + pt.x/ppxunit;
    wcsPt.y = y0 + pt.y/ppyunit;
    
    return wcsPt;

}

// Converts world coordinates to view coordinates
-(NSPoint) pointInVCS:(NSPoint)wpt {
    NSPoint vcsPt;
    NSRect bounds = [self bounds];
    NSSize imageSize = [[self image] size];
    
    float ppxunit, ppyunit;

    ppxunit = (bounds.size.width)/imageSize.width;
    ppyunit = (bounds.size.height)/imageSize.height;
    
    vcsPt.x = (wpt.x - x0)*ppxunit;
    vcsPt.y = (wpt.y - y0)*ppyunit;

    return vcsPt;

}

//scrolls to bring a point specified in WCS units into view.
-(void) zoomInOn:(NSPoint)pt
{
    NSPoint spt = [self pointInVCS:pt];
    NSScrollView *scrollView = (NSScrollView *)[[self superview] superview];
    NSSize supersize;
    
    supersize = [scrollView contentSize];
    [self scrollPoint:NSMakePoint(spt.x - supersize.width/2,spt.y-supersize.height/2)];
}


//Accessor methods
idAccessor(note,setNote)
idAccessor(annotationPaths, setAnnotationPaths)
idAccessor(objectsToDraw, setObjectsToDraw)
idAccessor(masks, setMasks)
intAccessor(x,setX)
intAccessor(y,setY)
idAccessor(pV,setPV);
floatAccessor(scaling,setScaling)
floatAccessor(pPXUnit,setPPXUnit)
floatAccessor(pPYUnit,setPPYUnit)
floatAccessor(x0,setX0)
floatAccessor(y0,setY0)
boolAccessor(shouldDrawNodAndShuffleExtractionBox,setShouldDrawNodAndShuffleExtractionBox)
boolAccessor(shouldDrawMasks,setShouldDrawMasks)
boolAccessor(shouldCreateMasks,setShouldCreateMasks)
idAccessor(aperture,setAperture)
floatAccessor(maskOpacity,setMaskOpacity)

-(void)setP:(NSPoint)point{
    p = point;
}

-(NSPoint)p{
    return p;
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


- (void)copyPDFToPasteboard
{
    NSRect r;
    NSData *data;
    NSArray *myPboardTypes;
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    //Declare types of data you'll be putting onto the pasteboard
    myPboardTypes = [NSArray arrayWithObject:NSPDFPboardType];
    [pb declareTypes:myPboardTypes owner:self];
    //Copy the data to the pastboard
    r = [self bounds];
    data = [self dataWithPDFInsideRect:r];
    [pb setData:data forType:NSPDFPboardType];
}


- (void)copyEPSToPasteboard
{
    NSRect r;
    NSData *data;
    NSArray *myPboardTypes;
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    //Declare types of data you'll be putting onto the pasteboard
    myPboardTypes = [NSArray arrayWithObject:NSPostScriptPboardType];
    [pb declareTypes:myPboardTypes owner:self];
    r = [self bounds];
    data = [self dataWithEPSInsideRect:r];
    [pb setData:data forType:NSPostScriptPboardType];
}


- (void)copyTIFFToPasteboard
{
    NSRect r;
    NSData *data;
    NSArray *myPboardTypes;
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSImage *image;
    myPboardTypes = [NSArray arrayWithObject:NSTIFFPboardType];
    [pb declareTypes:myPboardTypes owner:self];
    r = [self bounds];
    data = [self dataWithPDFInsideRect:r];
    image = [[NSImage alloc] initWithData:data];
    [pb setData:[image TIFFRepresentation] forType:NSTIFFPboardType];
    [image autorelease];
}


@end
