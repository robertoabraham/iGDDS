//
//  LineLabelData.m
//  iGDDS
//
//  Created by Roberto Abraham on Wed Nov 06 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "LineLabelData.h"


@implementation LineLabelData

-(void)plotWithTransform:(NSAffineTransform *)trans
{
    NSRect bounds = [[self view] bounds];
    NSFont *labelFont = [NSFont systemFontOfSize:9];
    NSPoint labelPoint;
    NSSize labelSize;
    NSString *labelString;
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSPoint p0,p1;
    float pattern0[] = {};                    /* solid */
    float pattern1[] = {1.0, 3.0};            /* dots */
    float x, y;
    int i;

    NSLog(@"Attempting to draw template");

    if (![self showMe])
        return;
    
    //Set basic attributes for drawing
    [path setLineDash:pattern1 count:2 phase:0.0];
    [path setLineWidth:1];


    [labelFont set];
    [attrs setObject:labelFont forKey:NSFontAttributeName];
    [[NSColor blackColor] set];

    //Draw the labels
    for(i=0;i<[lines count];i++){
        labelString = [[lines objectAtIndex:i] objectForKey:@"Label"];
        labelSize = [labelString sizeWithAttributes:attrs];
        x = [[[lines objectAtIndex:i] objectForKey:@"Wavelength"] floatValue];
        x = (1.0 + [self redshift])*x;
        //x = x*ppxunit;
        y = 0.0; //dummy
        labelPoint = NSMakePoint(x,y);
        labelPoint = [trans transformPoint:labelPoint];
        x = labelPoint.x;
        y = bounds.origin.y + bounds.size.height - 50;
        //label
        [self paintLabel:labelString angle:90 x:x y:y attr:attrs];
        //dotted line
        p0=NSMakePoint(x,y);  p0.y = p0.y - 30;
        p1=p0; p1.y = 30;
        [path removeAllPoints];
        [path moveToPoint:p0];
        [path lineToPoint:p1];
        [path stroke];
    }
    [path setLineDash:pattern0 count:0 phase:0.0];

}

// use tranformations to center a label on a point and optionally rotate it
// the attributes in attr are predefined and set using pixel dimensions
-(void)paintLabel:(NSString *)aLabel angle:(float)anAngle x:(float)anX y:(float)anY attr:(NSMutableDictionary *)attrs
{
    NSGraphicsContext *gc;
    NSAffineTransform *t=[NSAffineTransform transform];
    NSSize size;
    gc=[NSGraphicsContext currentContext];
    [gc saveGraphicsState];
    [t translateXBy:anX yBy:anY ];
    [t rotateByDegrees:anAngle];
    [t concat];
    size=[aLabel sizeWithAttributes:attrs];
    [aLabel drawAtPoint:NSMakePoint(-size.width/2.,-size.height/2.)
         withAttributes:attrs];
    [gc restoreGraphicsState];
}


-(id)initWithView:(id)v
{
    NSBundle *myBundle = [NSBundle mainBundle];
    //unichar lymanAlpha[3] = {0x004C,0x0079,0x03B1};
    //unichar lymanBeta[3] = {0x004C,0x0079,0x03B2};
    //unichar Halpha[2] = {0x0048,0x03B1};
    //unichar Hbeta[2] = {0x0048,0x03B2};
    //unichar Hgamma[2] = {0x0048,0x03B3};
    //unichar Hdelta[2] = {0x0048,0x03B4};
    //unichar Hepsilon[2] = {0x0048,0x03B5}; (//blended with K line)
    //unichar Hzeta[2] = {0x0048,0x03B6};
    //unichar Heta[2] = {0x0048,0x03B7};
    //unichar Htheta[2] = {0x0048,0x03B8};

    NSLog(@"Initializing template");
    
    if(self = [super init]){
        [self setRedshift:0.0];
        [self setView:v];
        
        lines = [NSArray arrayWithContentsOfFile:[myBundle pathForResource:@"features" ofType:@"xml"]];
        [lines retain];

        /*
         
        // Just for reference, here is how the original file was created
         
        lines = [[NSMutableArray alloc] init];

        line = [[NSMutableDictionary alloc] init];
        [line setObject:[NSNumber numberWithFloat:4102.8] forKey:@"Wavelength"];
        [line setObject:[NSString stringWithCharacters:Hdelta length:2] forKey:@"Label"];
        [line setObject:[NSNumber numberWithBool:YES] forKey:@"MovesWithRedshift?"];
        [line setObject:[NSNumber numberWithBool:YES] forKey:@"InEmission?"];
        [line setObject:[NSNumber numberWithFloat:0.0] forKey:@"OscillatorStrength"];
        [lines addObject:line];
        [line release];

        // ... repeat ad nauseaum

        //[lines writeToFile:@"/var/tmp/features.xml" atomically:YES];

        */
        
    }
    return self;
}


-(id)init{
    [self initWithView:nil];
    return self;
}


floatAccessor(redshift,setRedshift)
idAccessor(lines,setLines)
idAccessor(view,setView)

@end
