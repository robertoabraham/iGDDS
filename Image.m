#import "Image.h"
#import "Image.h"
#import "fits.h"

@implementation Image

- (id) initWithFITS:(NSString *)file
{
    if (self = [super init]) {
        char *cFileName;
        [file retain];
        [fileName release];
        fileName = file;
        cFileName = (char *)[file UTF8String];
        NSLog(@"Attempting to read in %@",file);
        data = readfloat(cFileName, &nx, &ny, &error_status);
		writefloat("!/var/tmp/tmp.fits", data, nx, ny, &error_status); // Useful for debugging only
	
        NSLog(@"Read in FITS image with size %d %d",nx,ny);
    }
    return self;
}

- (id) initWithValue:(float)val nx:(int)nrow ny:(int)ncol
{
    int i;
    if (self = [super init]) {
        nx = nrow;
        ny = ncol;
        data = (float *) malloc(nx*ny*sizeof(float));
        for(i=0;i<nx*ny;i++){
            *(data+i) = val;
        }
        NSLog(@"Creating zero image with size %d %d",nx,ny);
    }
    return self;
}


- (id) initWithData:(float *)pixels nx:(int)nrow ny:(int)ncol
{
    if (self = [super init]) {
        nx = nrow;
        ny = ncol;
        data = pixels;
    }
    return self;
}


/*
 - (Image *) duplicate
{
    int i;
    float *d;
    d = (float *)malloc(nx*ny*sizeof(float));
    for(i=0;i<nx*ny;i++)
        *(d+i)=*(data+i);
    return [[Image alloc] initWithData:d nx:nx ny:ny];
}
*/


- (id)copyWithZone:(NSZone *)zone
{
    int i;
    float *d;
    d = (float *)malloc(nx*ny*sizeof(float));
    for(i=0;i<nx*ny;i++)
        *(d+i)=*(data+i);
    return [[Image allocWithZone:zone] initWithData:d nx:nx ny:ny];
}



- (void) setValue:(float)val x:(int)x y:(int)y
{
    *((float *)data + nx*y + x) = val;
}


-(float) value:(int)x :(int)y
{
    return *((float *)data + nx*y + x);
}


/* These next two will blow up if an image size greater than 65K x 65K is used */

- (void) setValue:(float)val index:(long int)i
{
    *((float *)data + i) = val;
}


-(float) value:(long int)index
{
    return *((float *)data + index);
}


- (NSMutableArray *) row:(int) y
{
    NSMutableArray *array;
    NSNumber *number;
    int i;

    if((y < 0) || (y >= ny)) {
        return(nil);
    }
    array = [[NSMutableArray alloc] initWithCapacity:nx];
    for(i=0;i<nx;i++){
        number = [[NSNumber alloc] initWithFloat:(*((float *)data + y*nx + i))];
        [array addObject:number];
        [number release];
    }
    return(array);
}


- (NSMutableArray *) column:(int) x
{
    NSMutableArray *array;
    NSNumber *number;
    int j;

    if((x < 0) || (x >= nx)) {
        return(nil);
    }
    array = [[NSMutableArray alloc] initWithCapacity:ny];
    for(j=0;j<ny;j++){
        number = [[NSNumber alloc] initWithFloat:(*((float *)data + j*nx + x))];
        [array addObject:number];
        [number release];
    }
    return(array);
}


- (void) clear{
    int i;
    for(i=0;i<nx*ny;i++) {
        *(data + i) = 0.0;
    }
    
}


- (void) dealloc
{
    //NSLog(@"Destroying %@",self);
    free(data);
    [super dealloc];
}


- (NSString *) description
{
    NSString *result = [[NSString alloc] initWithFormat:@"image with size: %d %d",[self nx],[self ny]];
    [result autorelease];
    return result;
}



- (float) min
{
    int i;
    float pixval;
    float minval=1.e30;
    for(i=0;i<nx*ny;i++)
    {
        pixval = *((float *)data + i);
        if (pixval<=minval)
            minval = pixval;
    }
    return minval;
}


- (float) max
{
    int i;
    float pixval;
    float maxval=-1.e30;
    for(i=0;i<nx*ny;i++)
    {
        pixval = *((float *)data + i);
        if (pixval>=maxval)
            maxval = pixval;
    }
    return maxval;
}


- (float) total
{
    int i;
    float tot;
    tot = 0.0;
    for(i=0;i<nx*ny;i++)
        tot = tot + *((float *)data + i);
    return tot;
}


- (Image *) boxcar:(int)halfwidth
{
    int x,y;
    int i,j;
    float sum;
    float *temp;
    float area = pow(2.0*halfwidth + 1.0,2.0);

    temp = (float *)malloc(nx*ny*sizeof(float));
    for(x=0;x<nx;x++){
        for(y=0;y<ny;y++){
            sum = 0.0;
            if ((x<halfwidth) || x>(nx-halfwidth-1) || (y<halfwidth) || y>(ny-halfwidth-1)) {
                // border pixels remain unchanged
                sum = *(data + nx*y + x);
            }
            else {
                for(i=x-halfwidth;i<=x+halfwidth;i++){
                    for(j=y-halfwidth;j<=y+halfwidth;j++){
                        sum += *(data + nx*j + i);
                    }
                }
            }
            *(temp + nx*y + x) = sum/area;
        }
    }
    return [[[Image alloc] initWithData:temp nx:nx ny:ny] autorelease];

}


- (void) saveFITS:(NSString *)file
{
	writefloat([file UTF8String],data,nx,ny,&error_status);
}


- (NSBitmapImageRep *)createRepresentationWithMin:(float)min andMax:(float)max;
{
    int i,j;
	unsigned int p[1] = {128};
	float temp;
    NSBitmapImageRep *bitmap;
    
    // We allocate the NSBitmapImageRep instance and initialize it.
    // The initialization method has a lot of parameters because it is very versatile.
    // It can handle many different arrangements of pixel data. In this case I
    // have chosen an organization that corresponds to a grayscale.
    //
    // Finally, we let the NSBitmapImageRep instance allocate a buffer of the proper size to handle
    // our image; alternatively, you could allocate your own buffer for the pixel data and pass the
    // address to NSBitmapImageRep when initializing.
	
    bitmap = [[NSBitmapImageRep alloc]
			  initWithBitmapDataPlanes: NULL	// Let the class allocate it
			  pixelsWide: [self nx]
			  pixelsHigh: [self ny]
			  bitsPerSample: 8	// Each component is 8 bits (one byte)
			  samplesPerPixel: 1	// Number of components grayscale
			  hasAlpha: NO
			  isPlanar: NO
			  colorSpaceName: NSCalibratedWhiteColorSpace
			  bytesPerRow: 0	// 0 means: Let the class figure it out
			  bitsPerPixel: 0	// 0 means: Let the class figure it out
			  ];
		
    // Note the funny indexing below. This is because it seems GIF/TIFF/Whatever standard
    // is to have the origin of the coordinate system at the top-left, and I think this is
    // what the NSImageView assumes is going to be used too.
		
    for(i=0;i<nx;i++){
        for(j=0;j<ny;j++){
			temp = (*((float *)data + nx*j + i)-min)/(max-min);
			if (temp<=0.0)
				p[0] = 0;
			else if (temp>=1.0)
				p[0] = 255;
			else
				p[0] = (int)(256*temp);
			[bitmap setPixel:p atX:i y:(ny-j-1)];
        }
    }
	
	
    // Return the bitmap autoreleased
    return [bitmap autorelease];
}



//Accessor methods
//idAccessor(data,setData)
- (float *)pixelData
{
    return data;
}


intAccessor(nx, setNx)
intAccessor(ny, setNy)

@end
