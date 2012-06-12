//
//  Wave.h
//  iGDDS
//
//  Created by Roberto Abraham on Tue Dec 31 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Categories
#import "BAStringUtilities.h"

// Drawing routines
#import "PlotView.h"

// the following are needed to support fits stuff
#include <string.h>
#include <stdlib.h>
#include "fitsio.h"
#include "fits.h"

// some compile-time settings
#define NMAXCOEFFS 10
#define BADVAL -99999.99

void legendreP(long n, double x, double *p);
void locate(double *xx, long n, double x, long *j);
double *readspectrum(char *filename, int *nx, long *p0, double *pMin, double *pMax, double cf[NMAXCOEFFS],long *ncf, int *error_status);


@interface Wave : NSObject <NSCoding, NSCopying>
{
    PlotView            *_view;
    NSMutableData       *_y;           /* collection of double precision points */
    NSMutableData       *_x;           /* collection of double precision abscissae (explicit or computed & cached) */
    NSMutableData       *_c;           /* coefficients of Legendre polynomial describing the WCS */
    long                 _n;           /* number of data points */
    long                 _order;       /* order of legendre polynomial */
    long                 _p0;          /* physical coordinate of first point (an offset usually set to 0) */
    double               _pMin;        /* lower limit of normalizing physical coordinate */
    double               _pMax;        /* upper limit of normalizing physical coordinate */
    double               _xMin;        /* minimum stored x value */
    double               _xMax;        /* maximum stored x value */
    NSMutableDictionary *_attributes;  /* store anything you want here */
}

-(id)initWithZerosUsingN:(int)n startX:(double)x0 dX:(double)dx offset:(long)p0;
-(id)initWithLinearScale:(double *)ypts nData:(int)n startX:(double)x0 dX:(double)dx offset:(long)p0;
-(id)initWithNonLinearScale:(double *)ypts nData:(int)n coefficients:(double *)legendre order:(long)order offset:(long)p0 pMin:(double)pMin pMax:(double)pMax;
-(id)initWithFITS:(NSString *)file;
-(id)initWithGrid:(double *)xpts y:(double *)ypts nData:(int)n offset:(long)p0;
-(id)initWithTextFile:(NSString *)path xColumn:(int)xcol yColumn:(int)ycol;
-(int)saveAsFITS:(NSString *)file;
-(double)xAtIndexSlow:(long)i;
-(double)xAtIndex:(long)i;
-(double)yAtIndex:(long)i;
-(double)yAtX:(double)x outOfRangeValue:(double)outval;
-(double)dindexAtX:(double)x outOfRangeValue:(double)outval;
-(void) resampleToMatch:(Wave *)w outOfRangeValue:(double)outval;
-(Wave *)duplicate;
-(void)setScaleWithX0:(double)x0 dX:(double)dx p0:(long)p0;
-(void)setScaleWithCoefficients:(NSMutableData *)coeff order:(long) order  p0:(long)p0 pMin:(double)pMin pMax:(double)pMax;
-(void)ramp;
-(void)localGridInPlace;
-(void)cacheAbscissae;

//Arithmetic
-(void)multiplyByScalar:(double)v;
-(void)multiplyByWave:(Wave *)w outOfRangeValue:(double)outval;
-(void)addScalar:(double)v;
-(void)addWave:(Wave *)w outOfRangeValue:(double)outval;
-(void)abs;
-(void)tenToThePower;
-(void)invert;

//Statistics
-(void)boxcar:(int)halfWidth;
-(double)meanInRangeFromX:(double)x0 toX:(double)x1;
-(double)standardDeviationInRangeFromX:(double)x0 toX:(double)x1;
-(double)signalToNoiseInRangeFromX:(double)x0 toX:(double)x1;
-(double)sumInRangeFromX:(double)x0 toX:(double)x1;
-(double)medianInRangeFromX:(double)x0 toX:(double)x1;
-(double)yMaxInRangeFromX:(double)x0 toX:(double)x1 outOfRange:(double)outval;
-(double)yMinInRangeFromX:(double)x0 toX:(double)x1 outOfRange:(double)outval;
-(double)yMin;
-(double)yMax;
-(void)mapGaussianWithSigma:(double)sigma mu:(double)mu;

//Drawing
-(void)plotWithTransform:(NSAffineTransform *)trans;
-(PlotView *)myView;
-(void)setMyView:(PlotView *)v;
-(BOOL)showMe;
-(void)setShowMe:(BOOL)val;

//Accessor methods
-(long)n;
-(long)order;
-(long)p0;
-(double)pMin;
-(double)pMax;
-(double)xMin;
-(double)xMax;
-(NSMutableData *)y;
-(NSMutableData *)c;
-(NSMutableData *)x;
-(NSMutableDictionary *)attributes;
-(void)setY:(NSMutableData *)y;
-(void)setC:(NSMutableData *)c;
-(void)setX:(NSMutableData *)x;
-(void)setP0:(long)p0;
-(void)setPMin:(double)pMin;
-(void)setPMax:(double)pMax;
-(void)setAttributes:(NSMutableDictionary *)attrs;


@end
