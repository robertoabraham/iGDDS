//
//  Slit.m
//  iGDDS
//
//  Created by Roberto Abraham on Mon Aug 26 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "Slit.h"


@implementation Slit


- (void)dealloc
{
    NSLog(@"Destroying %@",self);
    [super dealloc];
}


+(void) initialize
{
    if (self==[Slit class]){
        [self setVersion:11];
    }
}


- (id)copyWithZone:(NSZone *)zone
{
    Slit *newSlit = [[Slit allocWithZone:zone] init];
    [newSlit setObjectNumber:[self objectNumber]];
    [newSlit setRa:[self ra]];
    [newSlit setDec:[self dec]];
    [newSlit setXCCD:[self xCCD]];
    [newSlit setYCCD:[self yCCD]];
    [newSlit setSpecPosX:[self specPosX]];
    [newSlit setSpecPosY:[self specPosY]];
    [newSlit setSlitSizeX:[self slitSizeX]];
    [newSlit setSlitSizeY:[self slitSizeY]];
    [newSlit setSlitTilt:[self slitTilt]];
    [newSlit setMag:[self mag]];
    [newSlit setPriority:[self priority]];
    [newSlit setSlitPosMX:[self slitPosMX]];
    [newSlit setSlitPosMY:[self slitPosMY]];
    [newSlit setSlitTiltM:[self slitTiltM]];
    [newSlit setSlitSizeMR:[self slitSizeMR]];
    [newSlit setSlitSizeMW:[self slitSizeMW]];
    [newSlit setSlitType:[[self slitType] copyWithZone:zone]]; //NSString object
    [newSlit setAperture:[[self aperture] copyWithZone:zone]]; //NodAndShuffleAperture object
    [newSlit setMasks:[[self masks] copyWithZone:zone]]; //NSMutableArray object --- problem here?
    [newSlit setSpec:[[self spec] copyWithZone:zone]]; //LinePlotData object
    [newSlit setOptimallyExtractedSpectrum:[[self optimallyExtractedSpectrum] copyWithZone:zone]]; //LinePlotData object
    [newSlit setSkySpec:[[self skySpec] copyWithZone:zone]]; //LinePlotData object
    [newSlit setProfile:[[self profile] copyWithZone:zone]]; //LinePlotData object
    [newSlit setWavelengthCalibrator:[self wavelengthCalibrator]]; //WavelengthCalibrator object
    [newSlit setWavelengthCalibrationReferencePoints:[[self wavelengthCalibrationReferencePoints] copyWithZone:zone]]; //SymbolPlotData object
    [newSlit setWavelengthCalibrationFit:[[self wavelengthCalibrationFit] copyWithZone:zone]]; //LinePlotData object

    [newSlit setRedshift:[self redshift]];
    [newSlit setNotes:[[self notes] copyWithZone:zone]]; //NSData object

    [newSlit setPositiveGaussianSigma:[self positiveGaussianSigma]];
    [newSlit setPositiveGaussianPosition:[self positiveGaussianPosition]];
    [newSlit setNegativeGaussianSigma:[self negativeGaussianSigma]];
    [newSlit setNegativeGaussianPosition:[self negativeGaussianPosition]];
    [newSlit setOptimallyExtractedVarianceSpectrum:[[self optimallyExtractedVarianceSpectrum] copyWithZone:zone]]; //LinePlotData object
    [newSlit setVarianceSpectrum:[[self varianceSpectrum] copyWithZone:zone]]; //LinePlotData object

    [newSlit setNeedsExtraction:[self needsExtraction]];
    [newSlit setUseGaussianOptimalExtraction:[self useGaussianOptimalExtraction]];

    [newSlit setIsCalibrated:[self isCalibrated]];
    [newSlit setIsSelected:[self isSelected]];
    [newSlit setGrade:[self grade]];
    [newSlit setFlag:[self flag]];

    [newSlit setSignalToNoiseRatio:[self signalToNoiseRatio]];
    [newSlit setSpectrumWave:[[self spectrumWave] copyWithZone:zone]]; //Wave object
    [newSlit setOptimallyExtractedSpectrumWave:[[self optimallyExtractedSpectrumWave] copyWithZone:zone]]; //Wave object
    [newSlit setVarianceSpectrumWave:[[self varianceSpectrumWave] copyWithZone:zone]]; //Wave object
    [newSlit setOptimallyExtractedVarianceSpectrumWave:[[self optimallyExtractedVarianceSpectrumWave] copyWithZone:zone]]; //Wave object

    [newSlit setNumberOfCombinedFrames:[self numberOfCombinedFrames]];
    [newSlit setNormalizedFrameExposureTime:[self normalizedFrameExposureTime]];
    [newSlit setReadNoise:[self readNoise]];

    [newSlit setFractionOfApertureUnmaskedWave:[self fractionOfApertureUnmaskedWave]]; //Wave object

    [newSlit setStartMarkerWavelength:[self startMarkerWavelength]];
    [newSlit setEndMarkerWavelength:[self endMarkerWavelength]];

    [newSlit setCompanionSpectrumWave:[[self companionSpectrumWave] copyWithZone:zone]];
    [newSlit setCompanionSpectrumDictionary:[[self companionSpectrumDictionary] mutableCopyWithZone:zone]];
    [newSlit setUseCompanionSpectrum:[self useCompanionSpectrum]];

    [newSlit setPlotAttributesDictionary:[self plotAttributesDictionary]];
    
    [newSlit setCoAddCompanionSpectrum:[self coAddCompanionSpectrum]];
    [newSlit setNumberOfCombinedFramesInCompanionSpectrum:[self numberOfCombinedFramesInCompanionSpectrum]];


    return newSlit;
}


-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeValueOfObjCType:@encode(int) at:&objectNumber];
    [coder encodeValueOfObjCType:@encode(float) at:&ra];
    [coder encodeValueOfObjCType:@encode(float) at:&dec];
    [coder encodeValueOfObjCType:@encode(float) at:&xCCD];
    [coder encodeValueOfObjCType:@encode(float) at:&yCCD];
    [coder encodeValueOfObjCType:@encode(float) at:&specPosX];
    [coder encodeValueOfObjCType:@encode(float) at:&specPosY];
    [coder encodeValueOfObjCType:@encode(float) at:&slitPosX];
    [coder encodeValueOfObjCType:@encode(float) at:&slitPosY];
    [coder encodeValueOfObjCType:@encode(float) at:&slitSizeX];
    [coder encodeValueOfObjCType:@encode(float) at:&slitSizeY];
    [coder encodeValueOfObjCType:@encode(float) at:&slitTilt];
    [coder encodeValueOfObjCType:@encode(float) at:&mag];
    [coder encodeValueOfObjCType:@encode(int) at:&priority];
    [coder encodeValueOfObjCType:@encode(float) at:&slitPosMX];
    [coder encodeValueOfObjCType:@encode(float) at:&slitPosMY];
    [coder encodeValueOfObjCType:@encode(int) at:&slitID];
    [coder encodeValueOfObjCType:@encode(float) at:&slitSizeMX];
    [coder encodeValueOfObjCType:@encode(float) at:&slitSizeMY];
    [coder encodeValueOfObjCType:@encode(float) at:&slitTiltM];
    [coder encodeValueOfObjCType:@encode(float) at:&slitSizeMR];
    [coder encodeValueOfObjCType:@encode(float) at:&slitSizeMW];
    [coder encodeObject:slitType];
    [coder encodeObject:aperture];
    [coder encodeObject:masks];
    [coder encodeObject:spec];
    [coder encodeObject:optimallyExtractedSpectrum];
    [coder encodeObject:skySpec];
    [coder encodeObject:profile];
    [coder encodeObject:wavelengthCalibrator];
    [coder encodeObject:wavelengthCalibrationReferencePoints];
    [coder encodeObject:wavelengthCalibrationFit];
    //New in version 1
    [coder encodeValueOfObjCType:@encode(float) at:&redshift];
    [coder encodeObject:notes];
    //New in version 2
    [coder encodeValueOfObjCType:@encode(float) at:&positiveGaussianSigma];
    [coder encodeValueOfObjCType:@encode(float) at:&positiveGaussianPosition];
    [coder encodeValueOfObjCType:@encode(float) at:&negativeGaussianSigma];
    [coder encodeValueOfObjCType:@encode(float) at:&negativeGaussianPosition];
    [coder encodeObject:optimallyExtractedVarianceSpectrum];
    [coder encodeObject:varianceSpectrum];
    //New in version 3
    [coder encodeValueOfObjCType:@encode(BOOL) at:&needsExtraction];
    [coder encodeValueOfObjCType:@encode(BOOL) at:&useGaussianOptimalExtraction];
    //New in version 4
    [coder encodeValueOfObjCType:@encode(BOOL) at:&isCalibrated];
    [coder encodeValueOfObjCType:@encode(BOOL) at:&isSelected];
    [coder encodeValueOfObjCType:@encode(int) at:&grade];
    [coder encodeValueOfObjCType:@encode(int) at:&flag];
    //New in version 5
    [coder encodeValueOfObjCType:@encode(float) at:&signalToNoiseRatio];
    [coder encodeObject:spectrumWave];
    [coder encodeObject:optimallyExtractedSpectrumWave];
    [coder encodeObject:varianceSpectrumWave];
    [coder encodeObject:optimallyExtractedVarianceSpectrumWave];
    //New in version 6
    [coder encodeValueOfObjCType:@encode(float) at:&numberOfCombinedFrames];
    [coder encodeValueOfObjCType:@encode(float) at:&normalizedFrameExposureTime];
    [coder encodeValueOfObjCType:@encode(float) at:&readNoise];
    //New in version 7
    [coder encodeObject:fractionOfApertureUnmaskedWave];
    //New in version 8
    [coder encodeValueOfObjCType:@encode(float) at:&startMarkerWavelength];
    [coder encodeValueOfObjCType:@encode(float) at:&endMarkerWavelength];
    //New in version 9
    [coder encodeObject:companionSpectrumWave];
    [coder encodeObject:companionSpectrumDictionary];
    [coder encodeValueOfObjCType:@encode(BOOL) at:&useCompanionSpectrum];
    //New in version 10
    [coder encodeObject:plotAttributesDictionary];
    //New in version 11
    [coder encodeValueOfObjCType:@encode(BOOL) at:&coAddCompanionSpectrum];
    [coder encodeValueOfObjCType:@encode(int) at:&numberOfCombinedFramesInCompanionSpectrum];
}

-(id)initWithCoder:(NSCoder *)coder
{
    int version;
    if (self=[super init]){
        version = [coder versionForClassName:@"Slit"];
        [coder decodeValueOfObjCType:@encode(int) at:&objectNumber];
        [coder decodeValueOfObjCType:@encode(float) at:&ra];
        [coder decodeValueOfObjCType:@encode(float) at:&dec];
        [coder decodeValueOfObjCType:@encode(float) at:&xCCD];
        [coder decodeValueOfObjCType:@encode(float) at:&yCCD];
        [coder decodeValueOfObjCType:@encode(float) at:&specPosX];
        [coder decodeValueOfObjCType:@encode(float) at:&specPosY];
        [coder decodeValueOfObjCType:@encode(float) at:&slitPosX];
        [coder decodeValueOfObjCType:@encode(float) at:&slitPosY];
        [coder decodeValueOfObjCType:@encode(float) at:&slitSizeX];
        [coder decodeValueOfObjCType:@encode(float) at:&slitSizeY];
        [coder decodeValueOfObjCType:@encode(float) at:&slitTilt];
        [coder decodeValueOfObjCType:@encode(float) at:&mag];
        [coder decodeValueOfObjCType:@encode(int) at:&priority];
        [coder decodeValueOfObjCType:@encode(float) at:&slitPosMX];
        [coder decodeValueOfObjCType:@encode(float) at:&slitPosMY];
        [coder decodeValueOfObjCType:@encode(int) at:&slitID];
        [coder decodeValueOfObjCType:@encode(float) at:&slitSizeMX];
        [coder decodeValueOfObjCType:@encode(float) at:&slitSizeMY];
        [coder decodeValueOfObjCType:@encode(float) at:&slitTiltM];
        [coder decodeValueOfObjCType:@encode(float) at:&slitSizeMR];
        [coder decodeValueOfObjCType:@encode(float) at:&slitSizeMW];
        [self setSlitType:[coder decodeObject]];
        [self setAperture:[coder decodeObject]];
        [self setMasks:[coder decodeObject]];
        [self setSpec:[coder decodeObject]];
        [self setOptimallyExtractedSpectrum:[coder decodeObject]];
        [self setSkySpec:[coder decodeObject]];
        [self setProfile:[coder decodeObject]];
        [self setWavelengthCalibrator:[coder decodeObject]];
        [self setWavelengthCalibrationReferencePoints:[coder decodeObject]];
        [self setWavelengthCalibrationFit:[coder decodeObject]];
    
        if (version>=1){
            [coder decodeValueOfObjCType:@encode(float) at:&redshift];
            [self setNotes:[coder decodeObject]];
        }
        else{
            [self setRedshift:0.0];
            [self setNotes:[[NSData alloc] init]];
        }

        if (version>=2){
            [coder decodeValueOfObjCType:@encode(float) at:&positiveGaussianSigma];
            [coder decodeValueOfObjCType:@encode(float) at:&positiveGaussianPosition];
            [coder decodeValueOfObjCType:@encode(float) at:&negativeGaussianSigma];
            [coder decodeValueOfObjCType:@encode(float) at:&negativeGaussianPosition];
            [self setVarianceSpectrum:[coder decodeObject]];
            [self setOptimallyExtractedVarianceSpectrum:[coder decodeObject]];
        }
        else{
            [self setPositiveGaussianSigma:2.5];
            [self setPositiveGaussianPosition:8.5];
            [self setNegativeGaussianSigma:2.5];
            [self setNegativeGaussianPosition:25.5];
            [self setVarianceSpectrum:[[LinePlotData alloc] init]];
            [self setOptimallyExtractedVarianceSpectrum:[[LinePlotData alloc] init]];
        }

        if (version>=3){
            [coder decodeValueOfObjCType:@encode(BOOL) at:&needsExtraction];
            [coder decodeValueOfObjCType:@encode(BOOL) at:&useGaussianOptimalExtraction];
        }
        else{
            [self setNeedsExtraction:YES];
            [self setUseGaussianOptimalExtraction:NO];
        }            

        if (version>=4){
            [coder decodeValueOfObjCType:@encode(BOOL) at:&isCalibrated];
            [coder decodeValueOfObjCType:@encode(BOOL) at:&isSelected];
            [coder decodeValueOfObjCType:@encode(int) at:&grade];
            [coder decodeValueOfObjCType:@encode(int) at:&flag];
        }
        else{
            [self setIsCalibrated:NO];
            [self setIsSelected:NO];
            [self setGrade:-1];
            [self setFlag:0];
        }

        if (version>=5){
            [coder decodeValueOfObjCType:@encode(float) at:&signalToNoiseRatio];
            [self setSpectrumWave:[coder decodeObject]];
            [self setOptimallyExtractedSpectrumWave:[coder decodeObject]];
            [self setVarianceSpectrumWave:[coder decodeObject]];
            [self setOptimallyExtractedVarianceSpectrumWave:[coder decodeObject]];
        }
        else{
            [self setSignalToNoiseRatio:-1];
            [self setSpectrumWave:[[Wave alloc] init]];
            [self setOptimallyExtractedSpectrumWave:[[Wave alloc] init]];
            [self setVarianceSpectrumWave:[[Wave alloc] init]];
            [self setOptimallyExtractedVarianceSpectrumWave:[[Wave alloc] init]];
        }

        if (version>=6){
            [coder decodeValueOfObjCType:@encode(float) at:&numberOfCombinedFrames];
            [coder decodeValueOfObjCType:@encode(float) at:&normalizedFrameExposureTime];
            [coder decodeValueOfObjCType:@encode(float) at:&readNoise];  
        }
        else{
            numberOfCombinedFrames = 51;
            normalizedFrameExposureTime = 1800;
            readNoise = 0.95;
        }

        if (version>=7){
            [self setFractionOfApertureUnmaskedWave:[coder decodeObject]];
        }
        else{
            [self setFractionOfApertureUnmaskedWave:[[Wave alloc] init]];
        }

        if (version>=8){
            [coder decodeValueOfObjCType:@encode(float) at:&startMarkerWavelength];
            [coder decodeValueOfObjCType:@encode(float) at:&endMarkerWavelength];
        }
        else{
            startMarkerWavelength = 0.0;
            endMarkerWavelength = 0.0;
        }
        if (version>=9){
            [self setCompanionSpectrumWave:[coder decodeObject]];
            [self setCompanionSpectrumDictionary:[coder decodeObject]];
            [coder decodeValueOfObjCType:@encode(BOOL) at:&useCompanionSpectrum];
        }
        else{
            [self setCompanionSpectrumWave:[[Wave alloc] initWithZerosUsingN:128 startX:5000 dX:30.0 offset:0]];
            [self setCompanionSpectrumDictionary:[[NSMutableDictionary alloc] init]];
            [[self companionSpectrumDictionary] takeValue:@"No external spectrum stored." forKey:@"Message"];
            useCompanionSpectrum = NO;
        }

        if (version>=10){
            [self setPlotAttributesDictionary:[coder decodeObject]];
        }
        else{
            [self setPlotAttributesDictionary:[[NSMutableDictionary alloc] init]];
        }
        if (version>=11){
            [coder decodeValueOfObjCType:@encode(BOOL) at:&coAddCompanionSpectrum];
            [coder decodeValueOfObjCType:@encode(int) at:&numberOfCombinedFramesInCompanionSpectrum];
        }
        else{
            coAddCompanionSpectrum = NO;
            numberOfCombinedFramesInCompanionSpectrum = 1;
        }
        
    }
    
    return self;
}


-(id) init{
    NSLog(@"In slit initializer\n");
    if (self = [super init]){
        //Minimal subset for now... make this better.
        NSLog(@"Allocating slit\n");
        [self setAperture:[[NodAndShuffleAperture alloc] init]];
        [self setMasks:[[NSMutableArray alloc] init]];
        [self setSpec:[[LinePlotData alloc] init]];
        [self setOptimallyExtractedSpectrum:[[LinePlotData alloc] init]];
        [self setSkySpec:[[LinePlotData alloc] init]];
        [self setProfile:[[LinePlotData alloc] init]];
        [self setWavelengthCalibrationReferencePoints:[[SymbolPlotData alloc] init]];
        [self setWavelengthCalibrationFit:[[LinePlotData alloc] init]];
        [self setWavelengthCalibrator:[[WavelengthCalibrator alloc] init]];

        //Added at version 1
        [self setRedshift:0.0];
        [self setNotes:[[NSData alloc] init]];

        //Added at version 2
        [self setPositiveGaussianSigma:2.5];
        [self setPositiveGaussianPosition:8.5];
        [self setNegativeGaussianSigma:2.5];
        [self setNegativeGaussianPosition:25.5];
        [self setVarianceSpectrum:[[LinePlotData alloc] init]];
        [self setOptimallyExtractedVarianceSpectrum:[[LinePlotData alloc] init]];

        //Added at version 3
        [self setNeedsExtraction:YES];
        [self setUseGaussianOptimalExtraction:NO];

        //Added at version 4
        [self setIsCalibrated:NO];
        [self setIsSelected:NO];
        [self setGrade:-1];
        [self setFlag:0];

        //Added at version 5
        [self setSignalToNoiseRatio:-1];
        [self setSpectrumWave:[[Wave alloc] init]];
        [self setOptimallyExtractedSpectrumWave:[[Wave alloc] init]];
        [self setVarianceSpectrumWave:[[Wave alloc] init]];
        [self setOptimallyExtractedVarianceSpectrumWave:[[Wave alloc] init]];

        //Added at version 6
        numberOfCombinedFrames = -1; // Must be set on-the-fly
        normalizedFrameExposureTime = -1; // Must be set on-the-fly
        readNoise = -1; // Must be set on-the-fly

        //Added in version 7
        [self setFractionOfApertureUnmaskedWave:[[Wave alloc] init]];

        //Added in version 8
        startMarkerWavelength = 0.0;
        endMarkerWavelength = 0.0;

        //Added in version 9
        [self setCompanionSpectrumWave:[[Wave alloc] initWithZerosUsingN:128 startX:5000 dX:30.0 offset:0]];
        [self setCompanionSpectrumDictionary:[[NSMutableDictionary alloc] init]];
        [[self companionSpectrumDictionary] takeValue:@"No external spectrum stored." forKey:@"Message"];
        [self setUseCompanionSpectrum:NO];

        //Added in version 10
        [self setPlotAttributesDictionary:[[NSMutableDictionary alloc] init]];
        
        //Added in version 11
        [self setCoAddCompanionSpectrum:NO];
        [self setNumberOfCombinedFramesInCompanionSpectrum:25];
        
    }
    return self;
}


-(void)toggleFlag:(int)theFlag
{
    int f;
    f = theFlag ^ (0xFFFFFFFF);
    [self setFlag:([self flag] ^ f)];
}


-(BOOL)checkFlag:(int)theFlag
{
    return (BOOL)(theFlag & [self flag]);
}


-(BOOL)calibratedExtractionExists
{
    if ([[self wavelengthCalibrator] numberOfReferencePoints]>=2 && [[self spec] nPoints]>0)
        return YES;
    else
        return NO;
}


- (void) exportToFile:(NSString *)filename fluxCalibration:(Wave *)fw redFix:(Wave *)rw atmosphericAbsorption:(Wave *)aw;
{
    int npts = [[self spec] nPoints];
    RGAPoint *specBytes = (RGAPoint *)[[[self spec] data] bytes];
    RGAPoint *optimallyExtractedSpectrumBytes = (RGAPoint *)[[[self optimallyExtractedSpectrum] data] bytes];
    RGAPoint *varianceSpectrumBytes = (RGAPoint *)[[[self varianceSpectrum] data] bytes];
    RGAPoint *optimallyExtractedVarianceSpectrumBytes = (RGAPoint *)[[[self optimallyExtractedVarianceSpectrum] data] bytes];
    RGAPoint *skySpectrumBytes = (RGAPoint *)[[[self skySpec] data] bytes];
    NSString *line;
    float *x,*y,*yo,*ysky,*yvar,*yovar,*fc,*rf,*atm,*electrons;
    float localPixscale;
    int i,count;
    char *cline;
    char *clines;
    float exptime = [self normalizedFrameExposureTime];
    
    //Start creating the long string that gets output with the data
    cline = malloc(1000);
    clines = malloc(1000000);
    line = [NSString stringWithString:@""];

    //Allocate memory for objects
    electrons = (float *) malloc(npts*sizeof(float));
    y = (float *) malloc(npts*sizeof(float));
    x = (float *) malloc(npts*sizeof(float));
    ysky = (float *) malloc(npts*sizeof(float));
    yvar = (float *) malloc(npts*sizeof(float));
    yo = (float *) malloc(npts*sizeof(float));
    yovar = (float *) malloc(npts*sizeof(float));
    fc = (float *) malloc(npts*sizeof(float));
    rf = (float *) malloc(npts*sizeof(float));
    atm = (float *) malloc(npts*sizeof(float));

    //Populate the data arrays
    NSLog(@"Populating data arrays");
    count = 0;
    for(i=0;i<npts;i+=1){
        *(electrons+count) = specBytes[i].y;
        *(y+count) = specBytes[i].y;
        *(yo+count) = optimallyExtractedSpectrumBytes[i].y;
        *(ysky+count) = skySpectrumBytes[i].y;
        *(yvar+count) = varianceSpectrumBytes[i].y;
        *(yovar+count) = optimallyExtractedVarianceSpectrumBytes[i].y;
        *(x+count) = specBytes[i].x;
        count++;
    }

    //Wavelength calibrate the data arrays
    NSLog(@"Wavelength calibrating");
    [[self wavelengthCalibrator] solve];
    for(i=0;i<count;i++){
        x[i]=[[self wavelengthCalibrator] wavelengthAtCCDPosition:x[i]];
    }

    //Apply a red-end correction
    NSLog(@"Applying red-end correction");
    line = [line stringByAppendingString:@"# Red-end correction used?: YES (except for electrons)\n"];
    for(i=0;i<count;i++){
        rf[i] = [rw yAtX:x[i] outOfRangeValue:0.0];
        y[i] += rf[i];
        yo[i] += rf[i];
        ysky[i] += rf[i];
    }

    //Apply an atmospheric correction
    NSLog(@"Applying atmospheric correction");
    line = [line stringByAppendingString:@"# Atmospheric correction used?: YES (except for electrons)\n"];
    for(i=0;i<count;i++){
        atm[i] = [aw yAtX:x[i] outOfRangeValue:1.0];
        y[i] /= atm[i];
        yo[i] /= atm[i];
        ysky[i] /= atm[i];
    }

    //Convert from variances to RMS, allowing for zero flux bits etc.
    for(i=0;i<count;i++){

        if (yvar[i]<1e29){
            yvar[i] = sqrt(yvar[i]);
        }

        if (yovar[i]<1e29){
            yovar[i] = sqrt(yovar[i]);
        }

    }

    //Flux calibrate the spectra
    line = [line stringByAppendingString:@"# Flux calibration used?: YES (except for electrons)\n"];
    for(i=0;i<count;i++){
        
        fc[i] = [fw yAtX:x[i] outOfRangeValue:1.0];
        
        y[i] /= pow(10.,fc[i]/2.5);
        yo[i] /= pow(10.,fc[i]/2.5);
        yvar[i] /= pow(10.,fc[i]/2.5);
        yovar[i] /= pow(10.,fc[i]/2.5);
        ysky[i] /= pow(10.,fc[i]/2.5);

        y[i] /= exptime;
        yo[i] /= exptime;
        yvar[i] /= exptime;
        yovar[i] /= exptime;
        ysky[i] /= exptime;
        
        if (i==0) {
            localPixscale = x[i+1]-x[i]; // treat lower endpoint of spectrum as a special case
        }
        else{
            localPixscale = x[i]-x[i-1]; 
        }
        
        y[i] /= localPixscale;
        yo[i] /= localPixscale;
        yvar[i] /= localPixscale;
        yovar[i] /= localPixscale;
        ysky[i] /= localPixscale;       
            
    }

    //Report aperture width information for Sandra
    line = [line stringByAppendingString:[NSString stringWithFormat:@"# Upper aperture width: %f\n",2.0*[[self aperture] dYUpper]]];
    line = [line stringByAppendingString:[NSString stringWithFormat:@"# Lower aperture width: %f\n",2.0*[[self aperture] dYLower]]];

    // Now write out the information for each wavelength point
    line = [line stringByAppendingString:@"#    Lambda           Flux          Sigma        SkyFlux        "];
    line = [line stringByAppendingString:@"OptFlux       OptSigma         RedFix        FluxCal          Atmos         Frac            Electrons\n"];

    //Write data to a file (skipping first data point)
    NSLog(@"Creating output string");
    for(i=1;i<count;i++){
        // Next bit is very slow if done using the NSString class so do it using native C strings
        sprintf(cline,"%14.6f %14.6e %14.6e %14.6e %14.6e %14.6e %14.6e %14.6e %14.6e %14.6e %14.3f\n",
                *(x+i),*(y+i),*(yvar+i),*(ysky+i),*(yo+i),*(yovar+i),*(rf+i),*(fc+i),*(atm+i),
                [[self fractionOfApertureUnmaskedWave] yAtIndex:i],*(electrons+i));
        strcat(clines,cline);

    }

    NSLog(@"Writing data");
    
    line = [line stringByAppendingString:[NSString stringWithCString:clines]];

    if (![line writeToFile:filename atomically:YES]) {
        NSLog(@"Error saving file.");
    }


    //tidy
    free(electrons);
    free(x);
    free(y);
    free(ysky);
    free(yvar);
    free(yo);
    free(yovar);
    free(rf);
    free(fc);
    free(atm);
    free(cline);
    free(clines);
}


- (void) exportCompanionToFile:(NSString *)filename fluxCalibration:(Wave *)fw redFix:(Wave *)rw atmosphericAbsorption:(Wave *)aw;
{
    Wave *electrons, *flux, *tempWave1, *inverseLocalPixelScale;
    char *cline;
    char *clines;
    double *xs,*ys;
    NSString *line;
    NSDictionary *dict;
    double x;
    int i;
    
    // Do we co-add or substitute? 
    if([self coAddCompanionSpectrum]==NO) {
        //substitute
        electrons = [[self companionSpectrumWave] copyWithZone:NULL];
    }
    else {
        //co-add
        int E = [self numberOfCombinedFramesInCompanionSpectrum];
        int M = [self numberOfCombinedFrames];
        tempWave1 = [[self companionSpectrumWave] copyWithZone:NULL];
        [tempWave1 multiplyByScalar:(float)E];
        dict = [self calibratedWaves:NULL redFix:NULL atmosphericAbsorption:NULL];
        [dict retain];
        electrons = [dict objectForKey:@"Electrons"];
        [electrons multiplyByScalar:(float)M];
        [electrons addWave:tempWave1 outOfRangeValue:0.0];
        [electrons multiplyByScalar:(float)1.0/(float)(E+M)];
        [tempWave1 release]; tempWave1 = nil;
    }
    
    //Determine the value of 1/(local pixel scale) and store this in a wave
    xs = (double *)malloc(sizeof(double)*[electrons n]);
    ys = (double *)malloc(sizeof(double)*[electrons n]);
    
    for(i=0;i<[electrons n];i++){
        *(xs + i) = [electrons xAtIndex:i];
    }    
    
    *ys = 1.0/([electrons xAtIndex:1]-[electrons xAtIndex:0]);
    for(i=1;i<[electrons n];i++){
        *(ys + i) = 1.0/([electrons xAtIndex:i]-[electrons xAtIndex:(i-1)]);
    }
    inverseLocalPixelScale = [[Wave alloc] initWithGrid:xs y:ys nData:[electrons n] offset:[electrons p0]];
    
    
    // Now calibrate the spectrum
    flux = [electrons copyWithZone:NULL];
    [flux addWave:rw outOfRangeValue:0.0]; // red end correction
    tempWave1 = [aw copyWithZone:NULL]; // start flux cal
    [tempWave1 invert];
    [flux multiplyByWave:tempWave1 outOfRangeValue:1.0]; // atmospheric correction
    [tempWave1 release];
    tempWave1 = [fw copyWithZone:NULL]; // start flux cal
    [tempWave1 multiplyByScalar:(1.0/2.5)];
    [tempWave1 tenToThePower];
    [tempWave1 invert];
    [flux multiplyByWave:tempWave1 outOfRangeValue:0.0];
    [flux multiplyByScalar:(1.0/[self normalizedFrameExposureTime])];
    [flux multiplyByWave:inverseLocalPixelScale outOfRangeValue:0.0];  // end flux cal
    [tempWave1 release];
    
    cline = malloc(1000);
    clines = malloc(1000000);
    line = [NSString stringWithString:@""];
    line = [line stringByAppendingString:@"# NOTE: THIS IS AN EXPORTED *COMPANION* SPECTRUM.\n"];
    line = [line stringByAppendingString:@"# Red-end correction used?: YES (except for electrons)\n"];
    line = [line stringByAppendingString:@"# Atmospheric correction used?: YES (except for electrons)\n"];
    line = [line stringByAppendingString:@"# Flux calibration used?: YES (except for electrons)\n"];
    if ([self coAddCompanionSpectrum])
        line = [line stringByAppendingString:@"# Co-add companion spectrum?: YES\n"];
    else    
        line = [line stringByAppendingString:@"# Co-add companion spectrum?: NO\n"];
    line = [line stringByAppendingString:@"#    Lambda           Flux         RedFix        FluxCal          Atmos           Electrons\n"];

    //Write data to a file (skipping first data point)
    NSLog(@"Creating output string");
    for(i=1;i<[flux n];i++){
        x = [flux xAtIndex:i];
        sprintf(cline,"%14.6f %14.6e %14.6e %14.6e %14.6e %14.3f\n",
                x,[flux yAtIndex:i],[rw yAtX:x outOfRangeValue:0.0],[fw yAtX:x outOfRangeValue:0.0],[aw yAtX:x outOfRangeValue:0.0],[electrons yAtIndex:i]);
        strcat(clines,cline);
    }

    NSLog(@"Writing data");
    line = [line stringByAppendingString:[NSString stringWithCString:clines]];

    if (![line writeToFile:filename atomically:YES]) {
        NSLog(@"Error saving file.");
    }

    //tidy
    [electrons release];
    [flux release];
    [inverseLocalPixelScale release];
    free(cline);
    free(clines);
}




- (void) exportToFITS:(NSString *)filename fluxCalibration:(Wave *)fw redFix:(Wave *)rw atmosphericAbsorption:(Wave *)aw;
{
    int npts = [[self spec] nPoints];
    RGAPoint *specBytes = (RGAPoint *)[[[self spec] data] bytes];
    RGAPoint *optimallyExtractedSpectrumBytes = (RGAPoint *)[[[self optimallyExtractedSpectrum] data] bytes];
    RGAPoint *varianceSpectrumBytes = (RGAPoint *)[[[self varianceSpectrum] data] bytes];
    RGAPoint *optimallyExtractedVarianceSpectrumBytes = (RGAPoint *)[[[self optimallyExtractedVarianceSpectrum] data] bytes];
    RGAPoint *skySpectrumBytes = (RGAPoint *)[[[self skySpec] data] bytes];
    float *electrons,*x,*y,*yo,*ysky,*yvar,*yovar,*fc,*rf,*atm;
    float localPixscale;
    int i,count,err;
    float exptime = [self normalizedFrameExposureTime];
    //Wave *testWave;

    //Allocate memory for objects
    electrons = (float *) malloc(npts*sizeof(float));
    y = (float *) malloc(npts*sizeof(float));
    x = (float *) malloc(npts*sizeof(float));
    ysky = (float *) malloc(npts*sizeof(float));
    yvar = (float *) malloc(npts*sizeof(float));
    yo = (float *) malloc(npts*sizeof(float));
    yovar = (float *) malloc(npts*sizeof(float));
    fc = (float *) malloc(npts*sizeof(float));
    rf = (float *) malloc(npts*sizeof(float));
    atm = (float *) malloc(npts*sizeof(float));

    //Populate the data arrays
    count = 0;
    for(i=0;i<npts;i+=1){
        *(electrons+count) = specBytes[i].y;
        *(y+count) = specBytes[i].y;
        *(yo+count) = optimallyExtractedSpectrumBytes[i].y;
        *(ysky+count) = skySpectrumBytes[i].y;
        *(yvar+count) = varianceSpectrumBytes[i].y;
        *(yovar+count) = optimallyExtractedVarianceSpectrumBytes[i].y;
        *(x+count) = specBytes[i].x;
        count++;
    }

    //Wavelength calibrate the data arrays
    [[self wavelengthCalibrator] solve];
    for(i=0;i<count;i++){
        x[i]=[[self wavelengthCalibrator] wavelengthAtCCDPosition:x[i]];
    }

    //Apply a red-end correction
    for(i=0;i<count;i++){
        rf[i] = [rw yAtX:x[i] outOfRangeValue:0.0];
        y[i] += rf[i];
        yo[i] += rf[i];
        ysky[i] += rf[i];
    }

    //Apply an atmospheric correction
    for(i=0;i<count;i++){
        atm[i] = [aw yAtX:x[i] outOfRangeValue:1.0];
        y[i] /= atm[i];
        yo[i] /= atm[i];
        ysky[i] /= atm[i];
    }

    //Convert from variances to RMS, allowing for zero flux bits etc.
    for(i=0;i<count;i++){

        if (yvar[i]<1e29){
            yvar[i] = sqrt(yvar[i]);
        }

        if (yovar[i]<1e29){
            yovar[i] = sqrt(yovar[i]);
        }

    }

    //Flux calibrate the spectra
    for(i=0;i<count;i++){
        fc[i] = [fw yAtX:x[i] outOfRangeValue:1.0];
        y[i] /= pow(10.,fc[i]/2.5);
        yo[i] /= pow(10.,fc[i]/2.5);
        yvar[i] /= pow(10.,fc[i]/2.5);
        yovar[i] /= pow(10.,fc[i]/2.5);
        ysky[i] /= pow(10.,fc[i]/2.5);

        y[i]/=exptime;
        yo[i]/=exptime;
        yvar[i] /= exptime;
        yovar[i] /= exptime;
        ysky[i]/=exptime;
        
        if (i==0) {
            localPixscale = x[i+1]-x[i]; // treat lower endpoint of spectrum as a special case
        }
        else{
            localPixscale = x[i]-x[i-1]; 
        }
        
        y[i] /= localPixscale;
        yo[i] /= localPixscale;
        yvar[i] /= localPixscale;
        yovar[i] /= localPixscale;
        ysky[i] /= localPixscale;       
        
        
    }

    writeFITS1D((char *)[filename UTF8String], x, y, yo, ysky, electrons, count, &err);
    //NSLog(@"Embedding this wavelength calibration information into the FITS file");
    //NSLog(@"%@",[self wavelengthCalibrator]);
    //savespectrum((char *) [filename cString], count, y, TFLOAT,
    //             [(WavelengthCalibrator *)[self wavelengthCalibrator] pMin],
    //             [(WavelengthCalibrator *)[self wavelengthCalibrator] pMin],
    //             [(WavelengthCalibrator *)[self wavelengthCalibrator] pMax],
    //             [(WavelengthCalibrator *)[self wavelengthCalibrator] coefficients],
    //             [(WavelengthCalibrator *)[self wavelengthCalibrator] nCoeff]);
    //NSLog(@"Wavelengths: {%f,%f,...,%f}",(double)x[0],(double)x[1],(double)x[count-1]);
    //NSLog(@"Fluxes: {%le,%le,...,%le}",(double)y[0],(double)y[1],(double)y[count-1]);
    //NSLog(@"Reading in the file as a temporary wave to verify information...");
    //testWave = [[Wave alloc] initWithFITS:filename];
    //NSLog(@"%@",testWave);
    //[testWave release];
    
    //tidy
    free(electrons);
    free(x);
    free(y);
    free(ysky);
    free(yvar);
    free(yo);
    free(yovar);
    free(rf);
    free(fc);
    free(atm);
}


- (NSMutableDictionary *) calibratedWaves:(Wave *)fw redFix:(Wave *)rw atmosphericAbsorption:(Wave *)aw;
{
    int npts = [[self spec] nPoints];
    RGAPoint *specBytes = (RGAPoint *)[[[self spec] data] bytes];
    RGAPoint *optimallyExtractedSpectrumBytes = (RGAPoint *)[[[self optimallyExtractedSpectrum] data] bytes];
    RGAPoint *varianceSpectrumBytes = (RGAPoint *)[[[self varianceSpectrum] data] bytes];
    RGAPoint *optimallyExtractedVarianceSpectrumBytes = (RGAPoint *)[[[self optimallyExtractedVarianceSpectrum] data] bytes];
    RGAPoint *skySpectrumBytes = (RGAPoint *)[[[self skySpec] data] bytes];
    double *electrons,*x,*y,*yo,*ysky,*yvar,*yovar,*fc,*rf,*atm;
    double localPixscale;
    int i,count;
    double exptime = (double)[self normalizedFrameExposureTime];
    NSMutableDictionary *dict;

    //Allocate memory for objects
    electrons = (double *) malloc(npts*sizeof(double));
    y = (double *) malloc(npts*sizeof(double));
    x = (double *) malloc(npts*sizeof(double));
    ysky = (double *) malloc(npts*sizeof(double));
    yvar = (double *) malloc(npts*sizeof(double));
    yo = (double *) malloc(npts*sizeof(double));
    yovar = (double *) malloc(npts*sizeof(double));

    if (fw)
        fc = (double *) malloc(npts*sizeof(double));

    if (rw)
        rf = (double *) malloc(npts*sizeof(double));

    if (aw)
        atm = (double *) malloc(npts*sizeof(double));

    //Populate the data arrays
    count = 0;
    for(i=0;i<npts;i+=1){
        *(electrons+count) = (double) specBytes[i].y;
        *(y+count) = (double) specBytes[i].y;
        *(yo+count) = (double) optimallyExtractedSpectrumBytes[i].y;
        *(ysky+count) = (double) skySpectrumBytes[i].y;
        *(yvar+count) = (double) varianceSpectrumBytes[i].y;
        *(yovar+count) = (double) optimallyExtractedVarianceSpectrumBytes[i].y;
        *(x+count) = (double) specBytes[i].x;
        count++;
    }

    //Wavelength calibrate the data arrays
    [[self wavelengthCalibrator] solve];
    for(i=0;i<count;i++){
        x[i]=[[self wavelengthCalibrator] wavelengthAtCCDPosition:x[i]];
    }

    //Apply a red-end correction
    if (rw) {
        for(i=0;i<count;i++){
            rf[i] = [rw yAtX:x[i] outOfRangeValue:0.0];
            y[i] += rf[i];
            yo[i] += rf[i];
            ysky[i] += rf[i];
        }
    }

    //Apply an atmospheric correction
    if (aw) {
        for(i=0;i<count;i++){
            atm[i] = [aw yAtX:x[i] outOfRangeValue:1.0];
            y[i] /= atm[i];
            yo[i] /= atm[i];
            ysky[i] /= atm[i];
        }
    }

    //Convert from variances to RMS, allowing for zero flux bits etc.
    for(i=0;i<count;i++) {

        if (yvar[i]<1e29){
            yvar[i] = sqrt(yvar[i]);
        }

        if (yovar[i]<1e29){
            yovar[i] = sqrt(yovar[i]);
        }

    }

    //Flux calibrate the spectra
    if (fw) {
        for(i=0;i<count;i++){
            fc[i] = [fw yAtX:x[i] outOfRangeValue:1.0];
            y[i] /= pow(10.,fc[i]/2.5);
            yo[i] /= pow(10.,fc[i]/2.5);
            yvar[i] /= pow(10.,fc[i]/2.5);
            yovar[i] /= pow(10.,fc[i]/2.5);
            ysky[i] /= pow(10.,fc[i]/2.5);

            y[i]/=exptime;
            yo[i]/=exptime;
            yvar[i] /= exptime;
            yovar[i] /= exptime;
            ysky[i]/=exptime;
            
            if (i==0) {
                localPixscale = x[i+1]-x[i]; // treat lower endpoint of spectrum as a special case
            }
            else{
                localPixscale = x[i]-x[i-1]; 
            }
            
            y[i] /= localPixscale;
            yo[i] /= localPixscale;
            yvar[i] /= localPixscale;
            yovar[i] /= localPixscale;
            ysky[i] /= localPixscale;   
        }
    }

    //Now export the dictionary
    dict = [[[NSMutableDictionary alloc] init] autorelease];
    [dict setObject:[[Wave alloc] initWithGrid:x y:y nData:count offset:0] forKey:@"Flux"];
    [dict setObject:[[Wave alloc] initWithGrid:x y:ysky nData:count offset:0] forKey:@"SkyFlux"];
    [dict setObject:[[Wave alloc] initWithGrid:x y:yvar nData:count offset:0] forKey:@"Sigma"];
    [dict setObject:[[Wave alloc] initWithGrid:x y:yo nData:count offset:0] forKey:@"OptFlux"];
    [dict setObject:[[Wave alloc] initWithGrid:x y:yovar nData:count offset:0] forKey:@"OptSigma"];
    [dict setObject:[[Wave alloc] initWithGrid:x y:electrons nData:count offset:0] forKey:@"Electrons"];
    
    //The waves now have a release count of 2 but we want them to go away when dict is released. So
    //we need to decrease their release counts by 1 now.
    [[dict objectForKey:@"Flux"] release];
    [[dict objectForKey:@"SkyFlux"] release];
    [[dict objectForKey:@"Sigma"] release];
    [[dict objectForKey:@"OptFlux"] release];
    [[dict objectForKey:@"OptSigma"] release];
    [[dict objectForKey:@"Electrons"] release];
    
    //The Wave allocation stores copies so we should release the storage
    free(electrons);
    free(y);
    free(x);
    free(ysky);
    free(yvar);
    free(yo);
    free(yovar);    
    
    return(dict);

}




//comparator methods
- (int) compareObjectNumber:(Slit *)other
{
    if ([self objectNumber] > [other objectNumber])
        return NSOrderedDescending;
    if ([self objectNumber] < [other objectNumber])
        return NSOrderedAscending;
    return NSOrderedSame;
}


- (int) compareMag:(Slit *)other
{
    if ([self mag] > [other mag])
        return NSOrderedDescending;
    if ([self mag] < [other mag])
        return NSOrderedAscending;
    return NSOrderedSame;
}


- (int) compareRedshift:(Slit *)other
{
    if ([self redshift] > [other redshift])
        return NSOrderedDescending;
    if ([self redshift] < [other redshift])
        return NSOrderedAscending;
    return NSOrderedSame;
}


- (int) compareIsCalibrated:(Slit *)other
{
    if ([self isCalibrated] > [other isCalibrated])
        return NSOrderedDescending;
    if ([self isCalibrated] < [other isCalibrated])
        return NSOrderedAscending;
    return NSOrderedSame;
}


- (int) compareXCCD:(Slit *)other
{
    if ([self xCCD] > [other xCCD])
        return NSOrderedDescending;
    if ([self xCCD] < [other xCCD])
        return NSOrderedAscending;
    return NSOrderedSame;
}


- (int) compareYCCD:(Slit *)other
{
    if ([self yCCD] > [other yCCD])
        return NSOrderedDescending;
    if ([self yCCD] < [other yCCD])
        return NSOrderedAscending;
    return NSOrderedSame;
}


- (int) compareSlitSizeX:(Slit *)other
{
    if ([self slitSizeX] > [other slitSizeX])
        return NSOrderedDescending;
    if ([self slitSizeX] < [other slitSizeX])
        return NSOrderedAscending;
    return NSOrderedSame;
}


- (int) compareSlitSizeY:(Slit *)other
{
    if ([self slitSizeY] > [other slitSizeY])
        return NSOrderedDescending;
    if ([self slitSizeY] < [other slitSizeY])
        return NSOrderedAscending;
    return NSOrderedSame;
}

- (int) compareRa:(Slit *)other
{
    if ([self ra] > [other ra])
        return NSOrderedDescending;
    if ([self ra] < [other ra])
        return NSOrderedAscending;
    return NSOrderedSame;
}

- (int) compareDec:(Slit *)other
{
    if ([self dec] > [other dec])
        return NSOrderedDescending;
    if ([self dec] < [other dec])
        return NSOrderedAscending;
    return NSOrderedSame;
}


- (int) compareGrade:(Slit *)other
{
    if ([self grade] > [other grade])
        return NSOrderedDescending;
    if ([self grade] < [other grade])
        return NSOrderedAscending;
    return NSOrderedSame;
}

//accessor methods

intAccessor(objectNumber,setObjectNumber);
floatAccessor(ra,setRa);
floatAccessor(dec,setDec);
floatAccessor(xCCD,setXCCD);
floatAccessor(yCCD,setYCCD);
floatAccessor(specPosX,setSpecPosX);
floatAccessor(specPosY,setSpecPosY);
floatAccessor(slitPosX,setSlitPosX);
floatAccessor(slitPosY,setSlitPosY);
floatAccessor(slitSizeX,setSlitSizeX);
floatAccessor(slitSizeY,setSlitSizeY);
floatAccessor(slitTilt,setSlitTilt);
floatAccessor(mag,setMag);
intAccessor(priority,setPriority);
floatAccessor(slitPosMX,setSlitPosMX);
floatAccessor(slitPosMY,setSlitPosMY);
intAccessor(slitID,setSlitID);
floatAccessor(slitSizeMX,setSlitSizeMX);
floatAccessor(slitSizeMY,setSlitSizeMY);
floatAccessor(slitTiltM,setSlitTiltM);
floatAccessor(slitSizeMR,setSlitSizeMR);
floatAccessor(slitSizeMW,setSlitSizeMW);
idAccessor(slitType,setSlitType);
idAccessor(aperture,setAperture);
idAccessor(masks,setMasks);
idAccessor(spec,setSpec);
idAccessor(optimallyExtractedSpectrum,setOptimallyExtractedSpectrum);
idAccessor(skySpec,setSkySpec);
idAccessor(profile,setProfile);
idAccessor(wavelengthCalibrationReferencePoints,setWavelengthCalibrationReferencePoints);
idAccessor(wavelengthCalibrationFit,setWavelengthCalibrationFit);
idAccessor(wavelengthCalibrator,setWavelengthCalibrator);
boolAccessor(errorStatus,setErrorStatus);

//Added in version 1
floatAccessor(redshift,setRedshift);
idAccessor(notes,setNotes);

//Added in version 2
floatAccessor(positiveGaussianSigma,setPositiveGaussianSigma);
floatAccessor(positiveGaussianPosition,setPositiveGaussianPosition);
floatAccessor(negativeGaussianSigma,setNegativeGaussianSigma);
floatAccessor(negativeGaussianPosition,setNegativeGaussianPosition);
idAccessor(varianceSpectrum,setVarianceSpectrum);
idAccessor(optimallyExtractedVarianceSpectrum,setOptimallyExtractedVarianceSpectrum);

//Added in version 3
boolAccessor(needsExtraction,setNeedsExtraction)
boolAccessor(useGaussianOptimalExtraction,setUseGaussianOptimalExtraction);

//Added in version 4
boolAccessor(isCalibrated,setIsCalibrated);
boolAccessor(isSelected,setIsSelected);
intAccessor(grade,setGrade);
intAccessor(flag,setFlag);

//Added in version 5
floatAccessor(signalToNoiseRatio,setSignalToNoiseRatio)
idAccessor(spectrumWave,setSpectrumWave);
idAccessor(optimallyExtractedSpectrumWave,setOptimallyExtractedSpectrumWave);
idAccessor(varianceSpectrumWave,setVarianceSpectrumWave);
idAccessor(optimallyExtractedVarianceSpectrumWave,setOptimallyExtractedVarianceSpectrumWave);

//Added in version 6
floatAccessor(numberOfCombinedFrames,setNumberOfCombinedFrames)
floatAccessor(normalizedFrameExposureTime,setNormalizedFrameExposureTime)
floatAccessor(readNoise,setReadNoise)

//Added in version 7
idAccessor(fractionOfApertureUnmaskedWave,setFractionOfApertureUnmaskedWave);

//Added in version 8
floatAccessor(startMarkerWavelength,setStartMarkerWavelength)
floatAccessor(endMarkerWavelength,setEndMarkerWavelength)

//added in version 9
idAccessor(companionSpectrumWave,setCompanionSpectrumWave);
idAccessor(companionSpectrumDictionary,setCompanionSpectrumDictionary);
boolAccessor(useCompanionSpectrum,setUseCompanionSpectrum);

//added in version 10
idAccessor(plotAttributesDictionary,setPlotAttributesDictionary);

//added in version 11
boolAccessor(coAddCompanionSpectrum,setCoAddCompanionSpectrum)
intAccessor(numberOfCombinedFramesInCompanionSpectrum,setNumberOfCombinedFramesInCompanionSpectrum)

@end
