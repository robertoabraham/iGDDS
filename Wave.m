//
//  Wave.m
//  iGDDS
//
//  Created by Roberto Abraham on Tue Dec 31 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

// Note: Order for this class means the highest exponent in the power law expansion. Thus
// the number of coefficients is order + 1.

#import "Wave.h"


#pragma mark FUNCTIONS

//Sort order function
int compar(const double *a, const double *b){
    if(*a < *b){
        return(-1);
    }
    else if(*a > *b){
        return(1);
    }
    else{
        return(0);
    }
}


//standard definition --- see numerical recipes
void legendreP(long n, double x, double *p)
{
    int i;
    p[0] = 1.0;  if(n == 0) return;
    p[1] = x;  if(n == 1) return;
    for(i=1; i<n; i++ ){
        p[i+1] = (2*i + 1.0)*x*p[i] - i*p[i-1];
        p[i+1] /= i + 1.0;
    }
}


//somewhat modified from numerical recipes in C++
void locate(double *xx, long n, double x, long *j)
{
    long ju,jm,jl;
    BOOL ascnd;
    jl=-1;
    ju=n;
    ascnd=(xx[n-1] >= xx[0]);
    while (ju-jl > 1) {
        jm=(ju+jl) >> 1;
        if (x >= xx[jm] == ascnd)
            jl=jm;
        else
            ju=jm;
    }
    if (x == xx[0]) *j=0;
    else if (x == xx[n-1]) *j=n-2;
    else *j=jl;
}


//reads in a FITS spectrum in MULTISPEC format
double *readspectrum(char *filename, int *nx, long *p0, double *pMin, double *pMax, double cf[NMAXCOEFFS],
                     long *ncf, int *error_status)
{
    double *arr;
    fitsfile *fptr;       /* pointer to the FITS file, defined in fitsio.h */
    long npixels, firstelem;
    int anynull, status;
    double nullval;
    char comment[73];  // Changed to 73 from 72 by RGA June 2010
    char filestring[FLEN_FILENAME];
    char wat0line[69]; // Changed to 69 from 68 by RGA June 2010
    char wat2line[69]; // Changed to 69 from 68 by RGA June 2010
    char wat2[1024] = "";
    char *wat2stripped;
    char wat2final[1024] = "";
    char key[9]; // Changed to 9 from 8 by RGA June 2010
    int nread;
    int i;
    BOOL linear = 0;
    //Equispec variables
    double crval1, cdelt1;
    long crpix1;
    //Multispec variables
    long ap,beam,dtype,nw,ftype,aplow=-1,aphigh=-1;
    double w1,dw,z,wt,w0;
    //Legendre polynomial variables
    long ncoeff;
    double pmin,pmax;
    double coeff[10] = {0.,0.,0.,0.,0.,0.,0.,0.,0.,0.};
    strncpy(filestring,filename,FLEN_FILENAME);

    status = 0;
    *nx = 0;

    if(fits_open_file(&fptr, filestring, READONLY, &status)){
        NSLog(@"Error calling fits_open_file()");
        fits_close_file(fptr, &status);
        *error_status = status;
        return (arr);
    }

    if(fits_read_key(fptr,TLONG,"NAXIS1",nx,comment,&status)){
        NSLog(@"Error calling fits_read_key() to get NAXIS1");
        fits_close_file(fptr, &status);
        *error_status = status;
        return(arr);
    }

    if(fits_read_key(fptr,TSTRING,"WAT0_001",wat0line,comment,&status)){
        if (status == KEY_NO_EXIST){
            // NSLog(@"Error calling fits_read_key() to get WAT0_001. Assume this is a linear EQUISPEC FILE.");
            status = 0;
            linear = 1;
        }
        else{
            fits_close_file(fptr, &status);
            *error_status = status;
            return(arr);
        }
    }
    else {
        if(!strcmp(wat0line,"system=equispec") || !strcmp(wat0line,"SYSTEM=EQUISPEC")) { // NB. 0 == a match for strcmp. Bah.
            linear=1;
        }
    }
           

    if(linear){

        //EQUISPEC CASE
        
        if(fits_read_key(fptr,TDOUBLE,"CRVAL1",&crval1,comment,&status)){
            NSLog(@"Error calling fits_read_key() to get CRVAL1");
            fits_close_file(fptr, &status);
            *error_status = status;
            return(arr);
        }

        if(fits_read_key(fptr,TDOUBLE,"CDELT1",&cdelt1,comment,&status)){
            NSLog(@"Error calling fits_read_key() to get CDELT1");
            fits_close_file(fptr, &status);
            *error_status = status;
            return(arr);
        }

        if(fits_read_key(fptr,TLONG,"CRPIX1",&crpix1,comment,&status)){
            NSLog(@"Error calling fits_read_key() to get CRPIX1");
            fits_close_file(fptr, &status);
            *error_status = status;
            return(arr);
        }

        *p0 = crpix1-1;
        *pMin = crpix1;
        *pMax = *nx+1;
        *ncf = 2;
        cf[0] = crval1; cf[1] = cdelt1;
        cf[1] = cf[1]* *nx/2.0;
        cf[0] = cf[0] + cf[1];
    }
    
    else{
        
        //MULTISPEC CASE
        
        //Extract the WCS information
        for(i=1;i<10;i++){
            sprintf(key,"WAT2_00%d",i);
            //NSLog(@"Looking for %s",key);
            if(fits_read_key(fptr,TSTRING,key,wat2line,comment,&status)){
                if (status == KEY_NO_EXIST){
                    status = 0;
                }
                else{
                    NSLog(@"Error calling fits_read_key() to get WAT2_00X");
                    fits_close_file(fptr, &status);
                    *error_status = status;
                    return(arr);
                }
                break;
            }
            else{
                if(strlen(wat2line)!=68)
                    strcat(wat2line," "); //FITSIO does not return trailing spaces... and sometimes you need one!
                strcat(wat2,wat2line);
            }
        }
        wat2stripped = strstr(wat2,"\""); //remove leading bumpf. This just leaves the stuff in quotes
        strncat(wat2final,wat2stripped+1,strlen(wat2stripped)-2); //extract stuff between quotes
                                                                  //NSLog(@"Final string: %s",wat2final);

        //Parse this incredibly long string...

        //First try to extract the information that supposedly HAS to be there if this is a WCS file
        nread=sscanf(wat2final,"%ld %ld %ld %lf %lf %ld %lf %ld %ld",&ap,&beam,&dtype,&w1,&dw,&nw,&z,&aplow,&aphigh);
        if(nread==9){
            //NSLog(@"Successfully read in all 9 lead MULTISPEC fields");
        }
        else if (nread==7){
            //NSLog(@"WARNING: Only read in 7 of 9 lead MULTISPEC fields. Are aplow and aphigh set?");
            if(aplow==-1)
                aplow=1;
            if(aphigh==-1)
                aphigh=nw;
            //NSLog(@"I'm fudging aplow and aphigh if necessary. Check: aplow=%d aphigh=%d",aplow,aphigh);
        }
        else{
            NSLog(@"ERROR. Unable to read in even a basic MULTISPEC WCS wavelength calibration.");
            fits_close_file(fptr, &status);
            *error_status = status;
            return(arr);
        }

        //Now try to extract the information that supposedly HAS to be there if this a Legendre polynomial
        nread=sscanf(wat2final,"%*s %*s %*s %*s %*s %*s %*s %*s %*s %lf %lf %ld %ld %lf %lf",&wt,&w0,&ftype,&ncoeff,&pmin,&pmax);
        if(nread==6){
            //NSLog(@"Successfully read in wt,w0,ftype,ncoeff,pmin,pmax fields");
        }
        else{
            NSLog(@"ERROR. Unable to read at least one of the MULTISPEC WCS wt,w0,ftype,ncoeff,pmin,pmax fields");
            fits_close_file(fptr, &status);
            *error_status = status;
            return(arr);
        }

        //Is this a legendre polynomial?
        if(ftype !=2){
            NSLog(@"ERROR. Wavelength calibration is not given by a legendre polynomial.");
            fits_close_file(fptr, &status);
            *error_status = status;
            return(arr);
        }

        //Is the number of orders too big for this function??
        if(ncoeff > NMAXCOEFFS){
            NSLog(@"ERROR. Maximum number of polynomial coefficients exceeded.");
            fits_close_file(fptr, &status);
            *error_status = status;
            return(arr);
        }

        //Extract the coefficients of the legendre polynomial. We can handle up to NMAXCOEFF coefficients (which is presently set to
        //be 10. If you change it you'll want to change the next line too.
        nread=sscanf(wat2final,"%*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %lf %lf %lf %lf %lf %lf %lf %lf %lf %lf", 	&coeff[0],&coeff[1],&coeff[2],&coeff[3],&coeff[4],&coeff[5],&coeff[6],&coeff[7],&coeff[8],&coeff[9]);
        if(nread != ncoeff){
            NSLog(@"ERROR. Could not read coefficients.");
            fits_close_file(fptr, &status);
            *error_status = status;
            return(arr);
        }

        //Set the physical offset
        if(fits_read_key(fptr,TLONG,"LTV1",p0,comment,&status)){
            if(status == KEY_NO_EXIST){
                //Try to use the CRPIX1 keyword instead
                if(fits_read_key(fptr,TLONG,"CRPIX1",p0,comment,&status)){
                    if(status==KEY_NO_EXIST){
                        //Keyword doesn't exist. File is probably written by WSPECTEXT. Bodge it.
                        *p0 = -1;
                        status = 0;
                    }
                    else{
                        NSLog(@"Error calling fits_read_key() to get LTV1 or CRPIX1");
                        fits_close_file(fptr, &status);
                        *error_status = status;
                        return(arr);
                    }
                }
                status = 0;
            }
            else{
                NSLog(@"Error when calling fits_read_key()");
                fits_close_file(fptr, &status);
                *error_status = status;
                return(arr);
            }
        }
        *p0 = -1* *p0;
        
        //Store the other output parameters for the wavelength calibration. Look for a
        //potential screw-up in pMin/pMax not being set properly and fix it.
        if((fabs(pmin - 1.0)<1e-5) && (fabs(pmax - *nx)<1e-5) ){
            *pMin = *p0;
            *pMax = *p0 + *nx;
        }
        else{
            *pMin = pmin;
            *pMax = pmax;
        }
        *ncf = ncoeff;
        //cf = (double *)malloc(ncoeff*sizeof(double));
        for(i=0;i<ncoeff;i++){
            *(cf + i)=coeff[i];
        }
    }
    
    //Extract the spectrum
    firstelem = 1;
    npixels  = *nx;    /* number of pixels in the spectrum */
    nullval  = 0;           /* don't check for null values  */
    arr = (double *) malloc(sizeof(double)*npixels);
    if(fits_read_img(fptr,TDOUBLE,firstelem,npixels,&nullval,arr,&anynull,&status)){
        NSLog(@"Error calling fits_read_img()");
        fits_close_file(fptr, &status);
        *error_status = status;
        return(arr);
    }

    if(fits_close_file(fptr, &status)){
        NSLog(@"Error calling fits_close_file()");
        *error_status = status;
        return(arr);
    }
    *error_status = status;

    return(arr);
};


    
@implementation Wave


#pragma mark
#pragma mark INITIALIZERS


+(void) initialize
{
    if (self==[Wave class]){
        [self setVersion:1];
    }
}


-(id)init
{
    self = [super init];
    if (self) {
        _n = 0;
        _attributes = [[NSMutableDictionary alloc] init];
        //[_attributes takeValue:[NSNumber numberWithBool:YES] forKey:@"ShowMe"];
        [_attributes takeValue:[NSColor blackColor] forKey:@"Color"];
        [_attributes takeValue:[NSNumber numberWithBool:YES] forKey:@"Visible"];
        [_attributes takeValue:@"CityScape" forKey:@"LineStyle"];
    }
    return self;
}

-(BOOL) showMe
{
    return [[_attributes objectForKey:@"Visible"] boolValue];
}

-(void) setShowMe:(BOOL)val
{
    [_attributes takeValue:[NSNumber numberWithBool:val] forKey:@"Visible"];
}

-(id)initWithCoder:(NSCoder *)coder
{
    int version;
    if (self=[super init]){
        version = [coder versionForClassName:@"Wave"];

        [self setY:[coder decodeObject]];
        [self setC:[coder decodeObject]];
        [coder decodeValueOfObjCType:@encode(long) at:&_n];
        [coder decodeValueOfObjCType:@encode(long) at:&_order];
        [coder decodeValueOfObjCType:@encode(long) at:&_p0];
        [coder decodeValueOfObjCType:@encode(double) at:&_pMin];
        [coder decodeValueOfObjCType:@encode(double) at:&_pMax];
        [coder decodeValueOfObjCType:@encode(double) at:&_xMin];
        [coder decodeValueOfObjCType:@encode(double) at:&_xMax];
        [self setX:[coder decodeObject]];

        if (version>=1){
            [self setAttributes:[coder decodeObject]];
        }
        else{
            [self setAttributes:[[NSMutableDictionary alloc] init]];
            [_attributes takeValue:[NSColor blackColor] forKey:@"Color"];
        }

    }
    return self;
}

-(id)initWithNonLinearScale:(double *)ypts nData:(int)n coefficients:(double *)legendre order:(long)order offset:(long)p0 pMin:(double)pMin pMax:(double)pMax
{
    self = [super init];
    if (self) {

        [self init];
        
        _n = n;
        _order = order;

        if(_y) {[_y release]; _y=nil;}
        if(_c) {[_c release]; _c=nil;}
        if(_x) {[_x release]; _x=nil;}

        _y = [[NSMutableData alloc] init];
        _c = [[NSMutableData alloc] init];
        _p0 = p0;
        _pMin = pMin;
        _pMax = pMax;
        [_y appendBytes:ypts length:n*sizeof(double)];
        [_c appendBytes:legendre length:(order+1)*sizeof(double)];
        [self cacheAbscissae];
        _xMin = [self xAtIndex:_p0];
        _xMax = [self xAtIndex:_p0+_n-1];
    }
    return self;
}


-(id)initWithZerosUsingN:(int)n startX:(double)x0 dX:(double)dx offset:(long)p0
{
    double *ypts = (double *) malloc(n*sizeof(double));
    double *cbuffer = (double *) malloc(2*sizeof(double));
    int i;
    for(i=0;i<n;i++){
        *(ypts + i) = 0.0;
    }
    self = [super init];
    if (self) {

        [self init];
        
        _n = n;
        _order = 1;

        if(_y) {[_y release]; _y=nil;}
        if(_c) {[_c release]; _c=nil;}
        if(_x) {[_x release]; _x=nil;}

        _y = [[NSMutableData alloc] init];
        _c = [[NSMutableData alloc] init];
        _p0 = p0;
        _pMin = 0.0;
        _pMax = (double)(_n-1.0);
        [_y appendBytes:ypts length:n*sizeof(double)];
        cbuffer[0] = x0; cbuffer[1] = dx;
        cbuffer[1] = cbuffer[1]*(n-1)/2.0;
        cbuffer[0] = cbuffer[0] + cbuffer[1];
        [_c appendBytes:cbuffer length:2*sizeof(double)];
        [self cacheAbscissae];
        _xMin = [self xAtIndex:_p0];
        _xMax = [self xAtIndex:_p0+_n-1];
    }
    free(cbuffer);
    free(ypts);
    return self;
}


-(id)initWithLinearScale:(double *)ypts nData:(int)n startX:(double)x0 dX:(double)dx offset:(long)p0
{
    double *cbuffer = (double *) malloc(2*sizeof(double));
    self = [super init];
    if (self) {

        [self init];
        
        _n = n;
        _order = 1;

        if(_y) {[_y release]; _y=nil;}
        if(_c) {[_c release]; _c=nil;}
        if(_x) {[_x release]; _x=nil;}

        _y = [[NSMutableData alloc] init];
        _c = [[NSMutableData alloc] init];
        _p0 = p0;
        _pMin = 0.0;
        _pMax = (double)(_n-1.0);
        [_y appendBytes:ypts length:n*sizeof(double)];
        cbuffer[0] = x0; cbuffer[1] = dx;
        cbuffer[1] = cbuffer[1]*(n-1)/2.0;
        cbuffer[0] = cbuffer[0] + cbuffer[1];
        [_c appendBytes:cbuffer length:2*sizeof(double)];
        [self cacheAbscissae];
        _xMin = [self xAtIndex:_p0];
        _xMax = [self xAtIndex:_p0+_n-1];
    }
    free(cbuffer);
    return self;
}


-(id)initWithGrid:(double *)xpts y:(double *)ypts nData:(int)n offset:(long)p0
{
    double *cbuffer = (double *) malloc(1*sizeof(double)); // dummy
    self = [super init];
    if (self) {

        [self init];
        
        _n = n;
        _order = 0;

        if(_y) {[_y release]; _y=nil;}
        if(_c) {[_c release]; _c=nil;}
        if(_x) {[_x release]; _x=nil;}

        _x = [[NSMutableData alloc] init];
        _y = [[NSMutableData alloc] init];
        _c = [[NSMutableData alloc] init];

        _p0 = p0;
        _pMin = 0.0;
        _pMax = (double)(_n-1.0);
        cbuffer[0] = 0.0; //dummy
        [_x appendBytes:xpts length:n*sizeof(double)];
        [_y appendBytes:ypts length:n*sizeof(double)];
        [_c appendBytes:cbuffer length:1*sizeof(double)];
        _xMin = [self xAtIndex:_p0];
        _xMax = [self xAtIndex:_p0+_n-1];
    }
    free(cbuffer);
    return self;
}


-(id)initWithTextFile:(NSString *)path xColumn:(int)xcol yColumn:(int)ycol;
{

    if (self = [super init]) {

        NSArray *lines;
        NSArray *headerRowStrings;
        NSArray *dataRowStrings;
        NSArray *tokens;
        NSString *aRowString;
        NSEnumerator *enumerator;
        int numberOfHeaderRows;
        int numberOfDataRows;
        int currentDataLine;
        double *x;
        double *y;
        int i;

        lines = [[NSString stringWithContentsOfFile:path] componentsSeparatedByCharacter:'\n'];
        enumerator = [lines objectEnumerator];

        /* break the file up into header lines and data lines */
        numberOfHeaderRows=0;
        aRowString = [enumerator nextObject];
        while([aRowString characterAtIndex:0] == '#') {
            aRowString = [enumerator nextObject];
            numberOfHeaderRows++;
        }

        numberOfDataRows = [lines count] - numberOfHeaderRows;
        x=(double *)malloc(sizeof(double)*numberOfDataRows);
        y=(double *)malloc(sizeof(double)*numberOfDataRows);

        /* Create arrays with header rows and data rows */
        headerRowStrings = [lines subarrayWithRange:NSMakeRange(0,numberOfHeaderRows)];
        dataRowStrings = [lines subarrayWithRange:NSMakeRange(numberOfHeaderRows,numberOfDataRows)];

        /* Extract the first relevant columns of the file */
        currentDataLine = 0;
        for(i=0;i<numberOfDataRows;i++){
            aRowString = [dataRowStrings objectAtIndex:i];
            tokens = [aRowString componentsSeparatedByCharacter:' '];
            *(x + currentDataLine) = [[tokens objectAtIndex:xcol] doubleValue];
            *(y + currentDataLine) = [[tokens objectAtIndex:ycol] doubleValue];
            currentDataLine++;
        }

        [self initWithGrid:x y:y nData:numberOfDataRows offset:0];
    }
    return self;
}




- (id) initWithFITS:(NSString *)file
{
    if (self = [super init]) {
        double *data;
        double coeffs[NMAXCOEFFS];
        char *cFileName;
        int error_status;
        int nx;
        long ncoeffs;
        long p0;
        double pMin, pMax;
        cFileName = (char *)[file UTF8String];

        [self init];

        if(_y) {[_y release]; _y=nil;}
        if(_c) {[_c release]; _c=nil;}
        if(_x) {[_x release]; _x=nil;}

        //NSLog(@"Attempting to read in %@",file);
        data = (double *)readspectrum(cFileName, &nx, &p0, &pMin, &pMax, coeffs, &ncoeffs, &error_status);
        _n = (long)nx;
        _y = [[NSMutableData alloc] init];
        [_y appendBytes:data length:_n*sizeof(double)];
        _c = [[NSMutableData alloc] init];
        [_c appendBytes:coeffs length:ncoeffs*sizeof(double)];
        _order = ncoeffs-1;
        _p0 = p0+1;
        _pMin = pMin;
        _pMax = pMax;
        [self cacheAbscissae];
        _xMin = [self xAtIndex:_p0];
        _xMax = [self xAtIndex:_p0+_n-1];
        free(data);
    }
    return self;
}


-(void)setScalarsNData:(long)n order:(long)order p0:(long)p0 pMin:(double)pMin pMax:(double)pMax xMin:(double)xMin xMax:(double)xMax
{
    _n = n;
    _order = order;
    _p0 = p0;
    _pMin = pMin;
    _pMax = pMax;
    _xMin = xMin;
    _xMax = xMax;
}


- (id)copyWithZone:(NSZone *)zone
{
    Wave *newWave = [Wave allocWithZone:zone];
    [newWave setScalarsNData:[self n]
                       order:[self order]
                          p0:[self p0]
                        pMin:[self pMin]
                        pMax:[self pMax]
                        xMin:[self xMin]
                        xMax:[self xMax]];
        
    // Add objects using Key-Value coding
    [newWave takeValue:[_y copyWithZone:zone] forKey:@"_y"];
    [newWave takeValue:[_c copyWithZone:zone] forKey:@"_c"];
    [newWave takeValue:[_x copyWithZone:zone] forKey:@"_x"];
    [newWave takeValue:[_attributes mutableCopyWithZone:zone] forKey:@"_attributes"];

    return newWave;
}

#pragma mark
#pragma mark INPUT/OUTPUT

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_y];
    [coder encodeObject:_c];
    [coder encodeValueOfObjCType:@encode(long) at:&_n];
    [coder encodeValueOfObjCType:@encode(long) at:&_order];
    [coder encodeValueOfObjCType:@encode(long) at:&_p0];
    [coder encodeValueOfObjCType:@encode(double) at:&_pMin];
    [coder encodeValueOfObjCType:@encode(double) at:&_pMax];
    [coder encodeValueOfObjCType:@encode(double) at:&_xMin];
    [coder encodeValueOfObjCType:@encode(double) at:&_xMax];
    [coder encodeObject:_x];
    [coder encodeObject:_attributes];
}

- (int) saveAsFITS:(NSString *)file
{
    char *cFileName = (char *)[file UTF8String];
    int err;
    err=savespectrum(cFileName,
                     (int)_n,
                     [_y bytes],
                     TDOUBLE,
                     (int)_p0-1,
                     (double)_pMin,
                     (double)_pMax,
                     [_c bytes],
                     (int)_order+1);
    return(err);
}


#pragma mark
#pragma mark STATISTICS

-(double)yMin
{
    long i;
    double ymin, val;
    double *p = (double *)[_y bytes];
    ymin = 1.E300;
    for(i=0;i<_n;i++){
        val = *(p+i);
        if (val<ymin)
            ymin=val;
    }
    return ymin;
}


-(double)yMax
{
    long i;
    double ymax, val;
    double  *p = (double *)[_y bytes];
    ymax = -1.E300;
    for(i=0;i<_n;i++){
        val = *(p+i);
        if (val>ymax)
            ymax=val;
    }
    return ymax;
}

-(double) medianInRangeFromX:(double)x0 toX:(double)x1
{
    long i0, i1;
    long count, i;
    double *temp;
    double med;
    i0 = (int)[self dindexAtX:x0 outOfRangeValue:-1];
    i1 = (int)[self dindexAtX:x1 outOfRangeValue:-1];
    if (i0<0 || i1<0)
        return NAN; //error is flagged by NAN
    temp = (double *)malloc((i1-i0+1)*sizeof(double));
    count = 0;
    for(i=i0;i<=i1;i++){
        *(temp+count) = [self yAtIndex:i];
        count++;
    }
    qsort(temp, count, sizeof(double),(void *)*compar);
    med = *(temp + count/2);
    free(temp);
    return med;
}

  

-(double) sumInRangeFromX:(double)x0 toX:(double)x1
{
    long i0, i1;
    long count, i;
    double sum;
    i0 = (int)[self dindexAtX:x0 outOfRangeValue:-1];
    i1 = (int)[self dindexAtX:x1 outOfRangeValue:-1];
    if (i0<0 || i1<0)
        return NAN; //error is flagged by NAN
    
    //calculate total
    sum = 0.0;
    count = 0;
    for(i=i0;i<=i1;i++){
        sum += [self yAtIndex:i];
        count++;
    }

    return sum;
}


-(double) meanInRangeFromX:(double)x0 toX:(double)x1
{
    long i0, i1;
    long count, i;
    double sum;
    i0 = (int)[self dindexAtX:x0 outOfRangeValue:-1];
    i1 = (int)[self dindexAtX:x1 outOfRangeValue:-1];
    if (i0<0 || i1<0)
        return NAN; //error is flagged by NAN

    //calculate mean
    sum = 0.0;
    count = 0;
    for(i=i0;i<=i1;i++){
        sum += [self yAtIndex:i];
        count++;
    }

    return sum/count;
}


-(double)signalToNoiseInRangeFromX:(double)x0 toX:(double)x1
{
    long i0, i1;
    long count, i;
    double avg, rms;
    i0 = (int)[self dindexAtX:x0 outOfRangeValue:-1];
    i1 = (int)[self dindexAtX:x1 outOfRangeValue:-1];
    if (i0<0 || i1<0)
        return NAN; //error is flagged by NAN
    
    //calculate mean
    avg = 0.0;
    count = 0;
    for(i=i0;i<=i1;i++){
        avg += [self yAtIndex:i];
        count++;
    }
    avg /= count;

    //calculate standard deviation
    rms = 0.0;
    for(i=i0;i<=i1;i++){
        rms += pow([self yAtIndex:i] - avg,2.0);
    }
    rms = sqrt(rms/(count-1));
    
    return avg/rms;
}


-(double)standardDeviationInRangeFromX:(double)x0 toX:(double)x1
{
    long i0, i1;
    long count, i;
    double sum, rms;
    i0 = (int)[self dindexAtX:x0 outOfRangeValue:-1];
    i1 = (int)[self dindexAtX:x1 outOfRangeValue:-1];
    if (i0<0 || i1<0)
        return NAN; //error is flagged by NAN

    //calculate mean
    sum = 0.0;
    count = 0;
    for(i=i0;i<=i1;i++){
        sum += [self yAtIndex:i];
        count++;
    }
    sum /= count;

    //calculate standard deviation
    rms = 0.0;
    for(i=i0;i<=i1;i++){
        rms += pow([self yAtIndex:i] - sum,2.0);
    }
    rms = sqrt(rms/(count-1));

    return rms;
}


-(void)boxcar:(int)halfWidth
{
    double *yorig,*y;
    int i,j;

    y = (double *)malloc(_n*sizeof(double));
    yorig = (double *)malloc(_n*sizeof(double));

    //create a copy of the original data
    for(i=0;i<_n;i++)
        *(yorig + i) = [self yAtIndex:[self p0]+i];
    
    //null out the endpoints where we've not got enough information to smooth
    for(i=0;i<halfWidth;i++)
        *(y + i) = 0.;

    for(i=_n-halfWidth;i<_n;i++)
        *(y + i) = 0.;

    //do a running boxcar over the rest of the data
    for(i=halfWidth;i<_n-halfWidth;i+=1){
        *(y + i) = 0.;
        if (halfWidth>0){
            for(j=-halfWidth;j<=halfWidth;j++){
                *(y + i) += *(yorig + i + j); 
            }
            *(y + i) /= 2*halfWidth + 1;
        }
        else{
            *(y + i) = *(yorig + i);
        }
    }
    [_y release];
    _y = [[NSMutableData alloc] init];
    [_y appendBytes:y length:_n*sizeof(double)];

    free(yorig);
    free(y);

}    





-(void)cacheAbscissae
{
    int i;
    double *x;
    x = (double *)malloc(_n*sizeof(double));
    if(_x)
        [_x release];
    for(i=0;i<_n;i++)
        *(x+i)=[self xAtIndexSlow:_p0+i];
    _x = [[NSMutableData alloc] init];
    [_x appendBytes:x length:_n*sizeof(double)];
    free(x);
}






//description
- (NSString *)description{
    NSString *desc = [NSString stringWithFormat:@"\nWave Properties\n  n:%d\n  p0:%ld\n  pMin:%lf\n  pMax:%lf\n  order:%d\n  xMin:%f\n  xMax:%f\n",
        _n,_p0,_pMin,_pMax,_order,_xMin,_xMax];
    int i;
    for(i=0;i<_order+1;i++)
        desc = [desc stringByAppendingFormat:@"  Legendre coeff %d: %f\n",i,*((double *)[_c bytes]+i)];
    desc = [desc stringByAppendingFormat:@"   i:{%ld,%ld,...,%ld}\n",_p0,_p0+1,_p0+_n-1];
    desc = [desc stringByAppendingFormat:@"   x:{%f,%f,...,%f}\n",[self xAtIndex:_p0],[self xAtIndex:_p0+1],[self xAtIndex:_p0+_n-1]];
    desc = [desc stringByAppendingFormat:@"   y:{%le,%le,...,%le}",[self yAtIndex:_p0],[self yAtIndex:_p0+1],[self yAtIndex:_p0+_n-1]];
    return(desc);

}


-(void)setScaleWithX0:(double)x0 dX:(double)dx p0:(long)p0
{
    double *cbuffer = (double *) malloc(2*sizeof(double));
    if(_c){
        [_c release];
        _c = [[NSMutableData alloc] init];
    }
    cbuffer[0] = x0; cbuffer[1] = dx;
    cbuffer[1] = cbuffer[1]*_n/2.0;
    cbuffer[0] = cbuffer[0] + cbuffer[1];
    [_c appendBytes:cbuffer length:2*sizeof(double)];
    _p0=p0;
    _pMin = (double)p0;
    _pMax = (double)(_n-1.0);
    [self cacheAbscissae];
    _xMin = [self xAtIndex:_p0];
    _xMax = [self xAtIndex:_p0+_n-1];
}


-(void)setScaleWithCoefficients:(NSMutableData *)coeff order:(long) order  p0:(long)p0 pMin:(double)pMin pMax:(double)pMax
{
    if(_c){
        [_c release];
    }
    _order = order;
    _c = [coeff copy];
    _p0=p0;
    _pMin=pMin;
    _pMax=pMax;
    [self cacheAbscissae];
    _xMin = [self xAtIndex:_p0];
    _xMax = [self xAtIndex:_p0+_n-1];
}


-(double)yAtIndex:(long)i
{
    double *yValues = (double *)[_y bytes];
    return yValues[i-_p0];
}

//This assumes the abscissae have already been cached
-(double)xAtIndex:(long)i
{
    double *xValues = (double *)[_x bytes];
    return xValues[i-_p0];
}

//This calculates an abscissa from the lagrange coefficients
-(double)xAtIndexSlow:(long)i
{
    double *cValues = (double *)[_c bytes];
    double p = (i - (_pMax + _pMin)/2.0)/((_pMax - _pMin)/2.0);
    double *lg = (double *)malloc((_order+1)*sizeof(double));
    long j;
    double x;

    legendreP(_order,p,lg);
    x=0.0;
    for(j=0;j<=_order;j++){
        x += *(cValues + j) * *(lg + j);
    }
    return(x);
    free(lg);
}


/* //OLD VERSION
-(Wave *)duplicate
{
    Wave *w;
    w = [[Wave alloc] initWithNonLinearScale:(double *)[_y bytes]
                                       nData:_n
                                coefficients:(double *)[_c bytes]
                                       order:_order
                                      offset:_p0
                                        pMin:_pMin
                                        pMax:_pMax];
    return w;
}
*/

-(Wave *)duplicate
{
    return [self copyWithZone:NULL];
}


-(void)ramp
{
    int i;
    double *y = (double *)malloc(_n*sizeof(double));
    for(i=0;i<_n;i++)
        *(y + i) = i;
    [_y release];
    _y = [[NSMutableData alloc] init];
    [_y appendBytes:y length:_n*sizeof(double)];
}


-(void)localGridInPlace
{
    double *newY = (double *)malloc(_n*sizeof(double));
    int i;
    [_y release];
    *newY = ([self xAtIndex:1]-[self xAtIndex:0]);
    for(i=1;i<_n;i++){
        *(newY + i) = [self xAtIndex:i] - [self xAtIndex:(i-1)];
    }
    _y = [[NSMutableData alloc] init];
    [_y appendBytes:newY length:_n*sizeof(double)];
    free(newY);
}


-(void)mapGaussianWithSigma:(double)sigma mu:(double)mu
{
    double *newY = (double *)malloc(_n*sizeof(double));
    double x;
    double rootTwoPi = 2.5066282746310005024;
    double twoTimesSigmaSquared = 2.0*pow(sigma,2.0);
    double norm = 1.0/(sigma*rootTwoPi);
    int i;

    for(i=0;i<_n;i++){
        x = [self xAtIndex:i];
        *(newY + i) = norm*exp(-pow(x-mu,2.0)/twoTimesSigmaSquared);
    }
    
    [_y release];
    _y = [[NSMutableData alloc] init];
    [_y appendBytes:newY length:_n*sizeof(double)];
    free(newY);
}


-(double)yAtX:(double)x outOfRangeValue:(double)outval;
{
    double *xx = (double *)[_x bytes];
    long index;
    double m;
    locate(xx,_n,x,&index);
    if (index==-1 || index==(_n-1) ){
        return outval;
    }
    else {
        m = ([self yAtIndex:_p0+(index+1)] - [self yAtIndex:_p0+index])/([self xAtIndex:_p0+(index+1)] - [self xAtIndex:_p0+index]);
        return [self yAtIndex:_p0+index] + m*(x-[self xAtIndex:_p0+index]);
    }
}


-(double)dindexAtX:(double)x outOfRangeValue:(double)outval
{
    double *xx = (double *)[_x bytes];
    long index;
    locate(xx,_n,x,&index);
    if (index==-1 || index==(_n-1) ){
        return outval;
    }
    else {
        return _p0+index+((x-xx[index])/(xx[index+1]-xx[index]));
    }
}



-(void) resampleToMatch:(Wave *)w outOfRangeValue:(double)outval;
{
    long i;
    double *oldX = (double *)[_x bytes];
    double *oldY = (double *)[_y bytes];
    double *newX = (double *)malloc([w n]*sizeof(double));
    double *newY = (double *)malloc([w n]*sizeof(double));
    double m;
    long index;
    
    for(i=[w p0];i<[w p0]+[w n];i++){
        *(newX + i) = [w xAtIndex:i];
    }

    for(i=0;i<[w n];i++){
        locate(oldX,_n,newX[i],&index);

        /* nearest neighbour 
        if (index==-1 || index==(_n-1) ){
            newY[i] = outval;
        }
        else {
            if (fabs(newX[i] - oldX[index]) < fabs(newX[i] - oldX[index+1])) {
                newY[i] = oldY[index];
            }
            else {
                newY[i] = oldY[index+1];
            }
        } */

        //linear interpolation
        if (index==-1 || index==(_n-1) ){
            newY[i] = outval;
        }
        else {
            m = (oldY[_p0+(index+1)] - oldY[_p0+index]) / (oldX[_p0+(index+1)] - oldX[_p0+index]);
            newY[i] = oldY[_p0+index] + m*(newX[i] - oldX[_p0+index]);
        }
                
    }

    //replace old basic information with new basic information
    _n = [w n];
    _order = [w order];
    _p0 = [w p0];
    _pMin = [w pMin];
    _pMax = [w pMax];
    [_c release]; _c = [[NSMutableData alloc] init]; _c = [[w c] copy];
    [_y release]; _y = [[NSMutableData alloc] init]; [_y appendBytes:newY length:_n*sizeof(double)];
    [_x release]; _x = [[NSMutableData alloc] init]; [_x appendBytes:newX length:_n*sizeof(double)];
    
    //tidy
    free(newX);
    free(newY);
}


-(void)dealloc
{
    NSLog(@"Deallocating wave");
    if(_y)
        [_y release];
    if(_x)
        [_x release];
    if(_c)
        [_c release];
    if(_attributes)
        [_attributes release];
    
    [super dealloc];
}


-(double)yMaxInRangeFromX:(double)x0 toX:(double)x1 outOfRange:(double)outval
{
    long i,i1,i2;
    double yMax = -1.E300;
    double val;
    i1 = (long) [self dindexAtX:x0 outOfRangeValue:BADVAL];
    i2 = (long) [self dindexAtX:x0 outOfRangeValue:BADVAL];
    if (i1==BADVAL || i2==BADVAL) {
        return outval;
    }
    else{
        for(i=i1;i<=i2;i++){
            val = [self yAtIndex:i1];
            if(val>yMax) {
                yMax = val;
            }
        }
    }
    return yMax;
}


-(double)yMinInRangeFromX:(double)x0 toX:(double)x1 outOfRange:(double)outval
{
    long i,i1,i2;
    double yMin = 1.E300;
    double val;
    i1 = (long) [self dindexAtX:x0 outOfRangeValue:BADVAL];
    i2 = (long) [self dindexAtX:x0 outOfRangeValue:BADVAL];
    if (i1==BADVAL || i2==BADVAL) {
        return outval;
    }
    else{
        for(i=i1;i<=i2;i++){
            val = [self yAtIndex:i1];
            if(val<yMin) {
                yMin = val;
            }
        }
    }
    return yMin;
}


-(void)multiplyByScalar:(double)v
{
    long i;
    double *p = (double *)[_y bytes];
    for(i=0;i<_n;i++){
        *(p+i) *= v;
    }
}


-(void)addScalar:(double)v
{
    long i;
    double *p = (double *)[_y bytes];
    for(i=0;i<_n;i++){
        *(p+i) += v;
    }
}


-(void)abs
{
    long i;
    double *p = (double *)[_y bytes];
    for(i=0;i<_n;i++){
        *(p+i) = fabs(*(p+i));
    }
}

-(void)tenToThePower
{
    long i;
    double *p = (double *)[_y bytes];
    for(i=0;i<_n;i++){
        *(p+i) = pow(10.,(*(p+i)));
    }
}

-(void)invert
{
    long i;
    double *p = (double *)[_y bytes];
    for(i=0;i<_n;i++){
        *(p+i) = 1.0/(*(p+i));
    }
}


-(void)addWave:(Wave *)w outOfRangeValue:(double)outval
{
    long i;
    double *p = (double *)[_y bytes];
    for(i=0;i<_n;i++){
        *(p+i) += [w yAtX:[self xAtIndex:i] outOfRangeValue:outval];
    }
}


-(void)multiplyByWave:(Wave *)w outOfRangeValue:(double)outval
{
    long i;
    double *p = (double *)[_y bytes];
    for(i=0;i<_n;i++){
        *(p+i) *= [w yAtX:[self xAtIndex:i] outOfRangeValue:outval];
    }
}


#pragma mark
#pragma mark ACCESSORS

-(long)n
{
    return _n;
}


-(long)order
{
    return _order;
}


-(long)p0
{
    return _p0;
}


-(double)pMin
{
    return _pMin;
}


-(double)pMax
{
    return _pMax;
}

-(double)xMin
{
    return _xMin;
}


-(double)xMax
{
    return _xMax;
}


-(void)setP0:(long)p0
{
    _p0=p0;
}


-(void)setPMin:(double)pMin
{
    _pMin=pMin;
}


-(void)setPMax:(double)pMax
{
    _pMax=pMax;
}


-(NSMutableData *)y
{
    return _y;
}


-(NSMutableData *)c
{
    return _c;
}


-(NSMutableData *)x
{
    return _x;
}

-(NSMutableDictionary *)attributes
{
    return _attributes;
}

-(void) setY:(NSMutableData *)y
{
    [y retain];
    [_y release];
    _y = y;
}

-(void) setC:(NSMutableData *)c
{
    [c retain];
    [_c release];
    _c = c;
}

-(void) setX:(NSMutableData *)x
{
    [x retain];
    [_x release];
    _x = x;
}

-(void) setAttributes:(NSMutableDictionary *)attrs
{
    [attrs retain];
    [_attributes release];
    _attributes = attrs;
}

-(PlotView *)myView
{
    return _view;
}

-(void) setMyView:(PlotView *)v
{
    [v retain];
    [_view release];
    _view = v;
}


#pragma mark
#pragma mark DRAWING

-(void)plotWithTransform:(NSAffineTransform *)trans
{
    long i;
    float pattern0[] = {};	              /* solid      */
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSPoint p0,p1,p2;
    float vxmin = [(PlotView *)[self myView] xMin];
    float vxmax = [(PlotView *)[self myView] xMax];
    float vymin = [(PlotView *)[self myView] yMin];
    float vymax = [(PlotView *)[self myView] yMax];
    double *xValues = (double *)[_x bytes];
    double *yValues = (double *)[_y bytes];
    float halfBinWidth;
    NSColor *drawColor = [_attributes objectForKey:@"Color"];
    //BOOL showMe = [[_attributes objectForKey:@"Visible"] boolValue];
    NSString *lineStyle = [_attributes objectForKey:@"LineStyle"];

    if (drawColor==nil)
        [[NSColor redColor] set];
    else
        [drawColor set];

    if (![self showMe])
        return;
    
    [path setLineDash:pattern0 count:0 phase:0.0];
    [path setLineWidth:1.0];
    for(i=1;i<[self n];i++){

        if([self myView]){
            if (*(xValues+i) < vxmin && *(xValues+i-1) < vxmin ||
                *(xValues+i) > vxmax && *(xValues+i-1) > vxmax ||
                *(yValues+i) < vymin && *(yValues+i-1) < vymin ||
                *(yValues+i) > vymax && *(yValues+i-1) > vymax)
                continue;
        }

        if([lineStyle compare:@"CityScape"] == NSOrderedSame){
            halfBinWidth = fabs(xValues[i] - xValues[i-1])/2.0;
            p0=NSMakePoint(xValues[i-1]-halfBinWidth,yValues[i-1]);
            p1=NSMakePoint(xValues[i]-halfBinWidth,p0.y);
            p2=NSMakePoint(xValues[i]-halfBinWidth,yValues[i]);
            [path removeAllPoints];
            [path moveToPoint:[trans transformPoint:p0]];
            [path lineToPoint:[trans transformPoint:p1]];
            [path lineToPoint:[trans transformPoint:p2]];
            [path stroke];
        }
        else{
            p0=NSMakePoint(xValues[i-1],yValues[i-1]);
            p1=NSMakePoint(xValues[i],yValues[i]);
            [path removeAllPoints];
            [path moveToPoint:[trans transformPoint:p0]];
            [path lineToPoint:[trans transformPoint:p1]];
            [path stroke];
        }
    }
}


@end
