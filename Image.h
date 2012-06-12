#import <Cocoa/Cocoa.h>
#include "AccessorMacros.h"

@interface Image : NSObject <NSCopying> {

    NSString *fileName;
    float *data;
    int nx;
    int ny;
    int error_status;

}

// create, describe, and destroy images
- (id) initWithFITS: (NSString *)file;
- (id) initWithValue:(float)val nx:(int)nrow ny:(int)ncol;
- (id) initWithData:(float *)pixels nx:(int)nrow ny:(int)ncol;
- (NSString *)description;
- (void) setValue:(float)val x:(int)xpos y:(int)ypos;
- (void) setValue:(float)val index:(long int)i;
- (void) clear;
//- (Image *) duplicate;
- (void) dealloc;

// get image values
- (float) value:(int)x :(int)y;
- (float) value:(long int)index;
- (NSMutableArray *) row:(int) y;
- (NSMutableArray *) column:(int) x;

// compute basic image statistics
- (float) min;
- (float) max;
- (float) total;

// trivial image processing
- (Image *) boxcar:(int)halfwidth;

//Accessor methods
- (float *) pixelData;
intAccessor_h(nx, setNx)
intAccessor_h(ny, setNy)

//Save as a FITS file
- (void) saveFITS:(NSString *)file;

//An autoreleased representation of the image for use in an NSImageView
- (NSBitmapImageRep *)createRepresentationWithMin:(float)min andMax:(float)max;

@end
