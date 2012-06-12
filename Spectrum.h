/* Spectrum */

#import <Cocoa/Cocoa.h>
#include "AccessorMacros.h"
#import "Image.h"
#import "Slit.h"


@interface Spectrum : NSObject <NSCoding>
{
    Image *image;
    Slit *slit;
    NSArray *flux;
    NSArray *wavelength;
    NSMutableArray *annotation;

    //Extraction box properties
    int yPositiveStart;
    int yPositiveEnd;
    int yNegativeStart;
    int yNegativeEnd;
    float yWidth;
    int xMin;
    int xMax;

    //Derived properties
    float redshift;

    //TableView convenience properties
    BOOL isSelected;
    
}

//Accessor methods
idAccessor_h(image,setImage);
idAccessor_h(slit,setSlit);
idAccessor_h(flux,setFlux);
idAccessor_h(wavelength,setWavelength);
idAccessor_h(annotation,setAnnotation);
intAccessor_h(yPositiveStart,setYPositiveStart);
intAccessor_h(yPositiveEnd,setYPositiveEnd);
intAccessor_h(yNegativeStart,setYNegativeStart);
intAccessor_h(yNegativeEnd,setYNegativeEnd);
floatAccessor_h(yWidth,setYWidth);
intAccessor_h(xMin,setXMin);
intAccessor_h(xMax,setXMax);
floatAccessor_h(redshift,setRedshift);
boolAccessor_h(isSelected,setIsSelected);

//comparator methods


@end

