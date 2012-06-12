#import "Spectrum.h"


@implementation Spectrum
- (void)dealloc
{
    NSLog(@"Destroying %@",self);
    [image release];
    [slit release];
    [flux release];
    [wavelength release];
    [super dealloc];
}
    

//Accessor methods
idAccessor(image,setImage);
idAccessor(slit,setSlit);
idAccessor(flux,setFlux);
idAccessor(wavelength,setWavelength);
idAccessor(annotation,setAnnotation);
intAccessor(yPositiveStart,setYPositiveStart);
intAccessor(yPositiveEnd,setYPositiveEnd);
intAccessor(yNegativeStart,setYNegativeStart);
intAccessor(yNegativeEnd,setYNegativeEnd);
floatAccessor(yWidth,setYWidth);
intAccessor(xMin,setXMin);
intAccessor(xMax,setXMax);
floatAccessor(redshift,setRedshift);
boolAccessor(isSelected,setIsSelected);

@end
             