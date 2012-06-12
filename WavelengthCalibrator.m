//
//  WavelengthCalibrator.m
//  iGDDS
//
//  Created by Roberto Abraham on Mon Oct 28 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "WavelengthCalibrator.h"


// Polynomial regression methods from Karl

int fitpoly(double* xx, double* yy, int n, double* coeffs,int m);
int matinv( double M[MAX_ORDER][MAX_ORDER], int n);

/* Fit m coeffs, i.e. polymomial up to x^(m-1)  to data in vectors xx[n], yy[n] */

int fitpoly(double* xx, double* yy, int n, double* coeffs,int m) {

    double C[MAX_ORDER][MAX_ORDER], R[MAX_ORDER];
    int i,j,k;
    //int incoeff[MAX_ORDER];

    /* Make the correlations matrix */
    for (i=0; i<m; i++) { for (j=0; j<m; j++) {
        C[i][j] = 0.0;
        for (k=0; k<n; k++) {
            /*  printf("i j k = %d %d %d   %lf   ", i,j, k, C[i][j]);
            printf("   hmm %lf %lf",  xx[k], pow( xx[k], (double)i     )             );
            printf("   hmm %lf %lf \n",  xx[k], pow( xx[k], (double)j     )             ); */
            C[i][j] += pow( xx[k], (double)i     ) * pow( xx[k], (double)j     );
        }
    }}
    /* Make the RHS vector */
    for  (i=0; i<m; i++) {
        R[i] = 0;
        for (k=0; k<n; k++) {
            R[i] += yy[k] * pow( xx[k], (double)i     );
        }
    }

    /* Invert C */

    if(matinv(C,m)==0){
        /* Now multiply rhough the RHS */
        for (i=0; i<m; i++) {
            coeffs[i] = 0;
            for (j=0; j<m; j++)
                coeffs[i] += C[i][j] * R[j];
        }
    }
    else{
        return(-1);
    }
    return(0);
}


/* Invert a matrix (in-place) by Gauss Redux */

int matinv( double M[MAX_ORDER][MAX_ORDER], int n) {

    int i,j,k;
    double W[MAX_ORDER][MAX_ORDER*2];  /* Work array */
    double a,b;

    /* Init work martix */

    for(i=0; i<n; i++) {
        for(j=0; j<n; j++) {
            W[i][j] =  M[i][j];
            W[i][n+j] = 0.0;
        }
        W[i][n+i] = 1.0;
    }

    /* Perform Gaussian reduction */

    for(i=0; i<n; i++) {
        a = W[i][i];
        if (fabs(a) < 1E-30) {
            //singular matrix... return with error code
            return(-1);
        }
        for(j=0; j<2*n; j++)
            W[i][j] = W[i][j]/a;

        for(k=0; k<n; k++) {
            if (k!=i) {
                b = W[k][i];
                for(j=0; j<2*n; j++)
                    W[k][j] -= b * W[i][j];
            }
        }
    }

    /* Copy final result */

    for(i=0; i<n; i++) {
        for(j=0; j<n; j++) {
            M[i][j] = W[i][j+n];
        }
    }
    return(0);

}


@implementation WavelengthCalibrator

- (NSString *)description{
    NSString *desc = [NSString stringWithFormat:@"\nWavelength Calibrator Properties\n  numberOfReferencePoints:%d\n  pMin:%d\n  pMax:%d\n  ncoeff:%d\n",
        [self numberOfReferencePoints],
        _pmin,_pmax,ncoeff];
    int i;
    for(i=0;i<ncoeff;i++)
        desc = [desc stringByAppendingFormat:@"  Polynmial coeff %d: %f\n",i,c[i]];
    return(desc);

}

-(int) numberOfReferencePoints
{
    return [referencePoints count];
}


-(void) addReferencePointAtCCDPosition:(float)x withWavelength:(float)lambda
{
    NSMutableDictionary *cal;
    cal = [[NSMutableDictionary alloc] init];
    [cal setObject:[NSNumber numberWithFloat:x] forKey:@"ccdPosition"];
    [cal setObject:[NSNumber numberWithFloat:lambda] forKey:@"wavelength"];
    [[self referencePoints] addObject:cal];
    [self setNeedsUpdate:YES];
}


-(float) wavelength:(int)n
{
    return [[[referencePoints objectAtIndex:n] objectForKey:@"wavelength"] floatValue];
}


-(float) ccdPosition:(int)n
{
    return [[[referencePoints objectAtIndex:n] objectForKey:@"ccdPosition"] floatValue];
}

-(double) coefficient:(int)n
{
    return c[n];
}

// Creator and destructor methods
-(id) init
{
    int i;
    if (self = [super init]){
        [self setNeedsUpdate:NO];
        [self setNCoeff:0];
        for(i=0;i<MAX_ORDER;i++){
            c[i]=0.0;
        }
        [self setReferencePoints:[[NSMutableArray alloc] init]];
    }
    return self;
}


- (void) dealloc
{
    int i;
    for(i=0;i<[self numberOfReferencePoints];i++)
        [[referencePoints objectAtIndex:i] release];
    [[self referencePoints] release];
    [super dealloc];
}


// Storage methods

+(void) initialize
{
    if (self==[WavelengthCalibrator class]){
        [self setVersion:3];
    }
}


-(void) encodeWithCoder:(NSCoder *)coder
{
    int i;
    [coder encodeObject:referencePoints];
    for(i=0;i<MAX_ORDER;i++){
        [coder encodeValueOfObjCType:@encode(double) at:(c+i)];
        [coder encodeValueOfObjCType:@encode(double) at:(d+i)];
    }
    //New in version 2
    [coder encodeValueOfObjCType:@encode(int) at:&_pmin];
    [coder encodeValueOfObjCType:@encode(int) at:&_pmax];
    //New in version 3
    [coder encodeValueOfObjCType:@encode(int) at:&ncoeff];
}


-(id) initWithCoder:(NSCoder *)coder
{
    int i;
    if (self=[super init]){
        int version = [coder versionForClassName:@"WavelengthCalibrator"];
        [self setReferencePoints:[coder decodeObject]];
        for(i=0;i<MAX_ORDER;i++){
            [coder decodeValueOfObjCType:@encode(double) at:(c+i)];
            [coder decodeValueOfObjCType:@encode(double) at:(d+i)];
        }
        if (version>=2){
            [coder decodeValueOfObjCType:@encode(int) at:&_pmin];
            [coder decodeValueOfObjCType:@encode(int) at:&_pmax];
        }
        else{
            [self setPMin:-1000];
            [self setPMax:-1000];
        }
        if (version>=3){
            [coder decodeValueOfObjCType:@encode(int) at:&ncoeff];
        }
        else{
            [self setNCoeff:-1000];
        }
        
    }
    return self;
}


// Datasource methods
-(int) numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [referencePoints count];
}


- (id) tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex
{
    NSString *identifier = [aTableColumn identifier];
    NSMutableDictionary *dic = [referencePoints objectAtIndex:rowIndex];
    return [dic valueForKey:identifier];
}


- (void) tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(int)rowIndex
{
    NSString *identifier= [aTableColumn identifier];
    NSMutableDictionary *dic = [referencePoints objectAtIndex:rowIndex];
    [dic takeValue:anObject forKey:identifier];
}


// Straight polynomial fits
- (float) wavelengthAtCCDPosition:(float)x
{
    int i;
    double val;
    double p = ((double)x  - (double)((double)_pmax + (double)_pmin)/2.0)/(double)(((double)_pmax - (double)_pmin)/2.0);
    val = 0.0;
    for(i=0;i<[self nCoeff];i++)
        val += (c[i])*(double)pow(p,i);
    return val;
}

- (float) ccdPositionAtWavelength:(float)x
{
    int i;
    float val;
    val = 0.0;
    for(i=0;i<[self nCoeff];i++)
        val += ((float)d[i])*pow(x,i);
    return(val);
}

- (void) solve {
    double *x, *y, *p;       // data
    int npts;
    int i;
    double rms;
    float val;
    
    //allocate
    npts = [self numberOfReferencePoints];
    x = (double *)malloc(npts*sizeof(double));
    y = (double *)malloc(npts*sizeof(double));
    p = (double *)malloc(npts*sizeof(double));
    for(i=0;i<npts;i++){
        *(x+i)=(double)[self ccdPosition:i];
        *(y+i)=(double)[self wavelength:i];
        // rescale x to lie in the range (-1,1)
        *(p + i) = (*(x+i) - (_pmax + _pmin)/2.0)/((_pmax - _pmin)/2.0); 
    }
    

    // check that doing a fit is even possible
    if (npts <2){
        [self setNCoeff:0];
        [self setSolutionExists:NO];
        return; // need at least two points
    }

    // deafult is linear
    if ([self nCoeff]==0){
        [self setNCoeff:2];
    }
    
    //wavelength given a ccd position in scaled coords.
    if(fitpoly(p, y, npts, c, [self nCoeff])==0){
        [self setNeedsUpdate:NO];
        [self setSolutionExists:YES];
        //Work out the RMS
        rms=0.0;
        for (i=0;i<npts;i++){
            val = [self wavelengthAtCCDPosition:[self ccdPosition:i]];
            rms += pow((double) (*(y+i)-val),2.);
        }
        //store RMS
        rms = sqrt(rms)/(npts-1);
        [self setRms:rms];
    }
    else{
        NSRunAlertPanel(@"Wavelength Calibration Error!",
                        @"Solution not found. I suggest you check your wavelength calibration points.",
                        @"OK", nil, nil);
        [self setRms:1000.0];
        [self setNeedsUpdate:YES];
        [self setSolutionExists:NO];
        return;
    }
    
    //ccd position given a wavelength (returns UNSCALED coords)
    if(fitpoly(y, x, npts, d, [self nCoeff])==0){
        [self setNeedsUpdate:NO];
        [self setSolutionExists:YES];
    }
    else{
        NSRunAlertPanel(@"Wavelength Calibration Error!",
                        @"Solution not found. I suggest you check your wavelength calibration points.",
                        @"OK", nil, nil);
        [self setNeedsUpdate:YES];
        [self setSolutionExists:NO];
        return;
    }

    free(x);free(y);free(p);
}


// Accessor methods

-(double)rms
{
    return _rms;
}

-(void)setRms:(float)rms
{
    _rms = rms;
}

-(int)pMin{
    return _pmin;
}

-(void)setPMin:(int)p
{
    _pmin = p;
}

-(int)pMax{
    return _pmax;
}

-(void)setPMax:(int)p
{
    _pmax = p;
}

-(int)nCoeff{
    return ncoeff;
}

-(void)setNCoeff:(int) n
{
    ncoeff = n;
}

-(double *)coefficients
{
    return c;
}

boolAccessor(needsUpdate,setNeedsUpdate);
boolAccessor(solutionExists,setSolutionExists);
idAccessor(referencePoints,setReferencePoints);




@end
