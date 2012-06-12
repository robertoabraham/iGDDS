//
//  Slit.h
//  iGDDS
//
//  Created by Roberto Abraham on Mon Aug 26 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "AccessorMacros.h"
#import "NodAndShuffleAperture.h"
#import "PlotData.h"
#import "LinePlotData.h"
#import "SymbolPlotData.h"
#import "WavelengthCalibrator.h"

#define BalmerLinesKey (1 << 0)
#define OIIKey (1 << 1)
#define OIIIKey (1 << 2)
#define KPlusA (1 << 3)


//Declare a function defined in fits.c
void writeFITS1D(char *filename, float *lambda, float *arr, float *optarr,
                 float *skyarr, float *electrons, long nx, int *error_status);


@interface Slit : NSObject <NSCoding>
{

    //Properties from MDF
    int objectNumber;
    float ra;
    float dec;
    float xCCD;
    float yCCD;
    float specPosX;
    float specPosY;
    float slitPosX;
    float slitPosY;
    float slitSizeX;
    float slitSizeY;
    float slitTilt;
    float mag;
    int priority;
    float slitPosMX;
    float slitPosMY;
    int slitID;
    float slitSizeMX;
    float slitSizeMY;
    float slitTiltM;
    float slitSizeMR;
    float slitSizeMW;
    NSString *slitType;
    //Computed quantities
    NodAndShuffleAperture *aperture;
    NSMutableArray *masks;
    LinePlotData *spec;
    LinePlotData *optimallyExtractedSpectrum;
    LinePlotData *skySpec;
    LinePlotData *profile;
    SymbolPlotData *wavelengthCalibrationReferencePoints;
    LinePlotData *wavelengthCalibrationFit;
    WavelengthCalibrator *wavelengthCalibrator;
	BOOL errorStatus;
    //New in version 1
    float redshift;
    NSData *notes;
    //New in version 2
    float positiveGaussianSigma;
    float positiveGaussianPosition;
    float negativeGaussianSigma;
    float negativeGaussianPosition;
    LinePlotData *varianceSpectrum;
    LinePlotData *optimallyExtractedVarianceSpectrum;
    //New in version 3
    BOOL needsExtraction;
    BOOL useGaussianOptimalExtraction;
    //New in version 4
    BOOL isCalibrated;
    BOOL isSelected;
    int grade;
    int flag;
    //New in version 5
    float signalToNoiseRatio;
    Wave *spectrumWave;
    Wave *optimallyExtractedSpectrumWave;
    Wave *varianceSpectrumWave;
    Wave *optimallyExtractedVarianceSpectrumWave;
    //New in version 6
    float numberOfCombinedFrames;
    float normalizedFrameExposureTime;
    float readNoise;
    //New in version 7
    Wave *fractionOfApertureUnmaskedWave;
    //New in version 8
    float startMarkerWavelength;
    float endMarkerWavelength;
    //New in version 9
    Wave *companionSpectrumWave;
    NSMutableDictionary *companionSpectrumDictionary;
    BOOL useCompanionSpectrum;
    //New in version 10
    NSMutableDictionary *plotAttributesDictionary;
    //New in version 11
    BOOL coAddCompanionSpectrum;
    int numberOfCombinedFramesInCompanionSpectrum;
}

//Flagging and testing
- (void) toggleFlag:(int)theFlag;
- (BOOL) checkFlag:(int)theFlag;
- (BOOL) calibratedExtractionExists;

//Importing and exporting
- (void) exportToFile:(NSString *)filename fluxCalibration:(Wave *)fw redFix:(Wave *)rw atmosphericAbsorption:(Wave *)aw;
- (void) exportCompanionToFile:(NSString *)filename fluxCalibration:(Wave *)fw redFix:(Wave *)rw atmosphericAbsorption:(Wave *)aw;
- (void) exportToFITS:(NSString *)filename fluxCalibration:(Wave *)fw redFix:(Wave *)rw atmosphericAbsorption:(Wave *)aw;
- (NSMutableDictionary *) calibratedWaves:(Wave *)fw redFix:(Wave *)rw atmosphericAbsorption:(Wave *)aw;


//Comparator methods
- (int) compareObjectNumber:(Slit *)other;
- (int) compareMag:(Slit *)other;
- (int) compareRedshift:(Slit *)other;
- (int) compareIsCalibrated:(Slit *)other;
- (int) compareXCCD:(Slit *)other;
- (int) compareYCCD:(Slit *)other;
- (int) compareSlitSizeX:(Slit *)other;
- (int) compareSlitSizeX:(Slit *)other;
- (int) compareGrade:(Slit *)other;

//Accessors
intAccessor_h(objectNumber,setObjectNumber);
floatAccessor_h(ra,setRa);
floatAccessor_h(dec,setDec);
floatAccessor_h(xCCD,setXCCD);
floatAccessor_h(yCCD,setYCCD);
floatAccessor_h(specPosX,setSpecPosX);
floatAccessor_h(specPosY,setSpecPosY);
floatAccessor_h(slitPosX,setSlitPosX);
floatAccessor_h(slitPosY,setSlitPosY);
floatAccessor_h(slitSizeX,setSlitSizeX);
floatAccessor_h(slitSizeY,setSlitSizeY);
floatAccessor_h(slitTilt,setSlitTilt);
floatAccessor_h(mag,setMag);
intAccessor_h(priority,setPriority);
floatAccessor_h(slitPosMX,setSlitPosMX);
floatAccessor_h(slitPosMY,setSlitPosMY);
intAccessor_h(slitID,setSlitID);
floatAccessor_h(slitSizeMX,setSlitSizeMX);
floatAccessor_h(slitSizeMY,setSlitSizeMY);
floatAccessor_h(slitTiltM,setSlitTiltM);
floatAccessor_h(slitSizeMR,setSlitSizeMR);
floatAccessor_h(slitSizeMW,setSlitSizeMW);
idAccessor_h(slitType,setSlitType);
idAccessor_h(aperture,setAperture);
idAccessor_h(masks,setMasks);
idAccessor_h(spec,setSpec);
idAccessor_h(optimallyExtractedSpectrum,setOptimallyExtractedSpectrum);
idAccessor_h(varianceSpectrum,setVarianceSpectrum);
idAccessor_h(optimallyExtractedVarianceSpectrum,setOptimallyExtractedVarianceSpectrum);
idAccessor_h(skySpec,setSkySpec);
idAccessor_h(profile,setProfile);
idAccessor_h(wavelengthCalibrationReferencePoints,setWavelengthCalibrationReferencePoints);
idAccessor_h(wavelengthCalibrationFit,setWavelengthCalibrationFit);
idAccessor_h(wavelengthCalibrator,setWavelengthCalibrator);
boolAccessor_h(errorStatus,setErrorStatus);

//Added in version 1
floatAccessor_h(redshift,setRedshift);
idAccessor_h(notes,setNotes);

//Added in version 2
floatAccessor_h(positiveGaussianSigma,setPositiveGaussianSigma);
floatAccessor_h(positiveGaussianPosition,setPositiveGaussianPosition);
floatAccessor_h(negativeGaussianSigma,setNegativeGaussianSigma);
floatAccessor_h(negativeGaussianPosition,setNegativeGaussianPosition);
//idAccessor_h(positiveGaussianWave,setPositiveGaussianWave);
//idAccessor_h(negativeGaussianWave,setNegativeGaussianWave);

//Added in version 3
boolAccessor_h(needsExtraction,setNeedsExtraction);
boolAccessor_h(useGaussianOptimalExtraction,setUseGaussianOptimalExtraction);

//added in version 4
boolAccessor_h(isCalibrated,setIsCalibrated);
boolAccessor_h(isSelected,setIsSelected);
intAccessor_h(grade,setGrade);
intAccessor_h(flag,setFlag);

//added in version 5
floatAccessor_h(signalToNoiseRatio,setSignalToNoiseRatio)
idAccessor_h(spectrumWave,setSpectrumWave);
idAccessor_h(optimallyExtractedSpectrumWave,setOptimallyExtractedSpectrumWave);
idAccessor_h(varianceSpectrumWave,setVarianceSpectrumWave);
idAccessor_h(optimallyExtractedVarianceSpectrumWave,setOptimallyExtractedVarianceSpectrumWave);

//added in version 6
floatAccessor_h(numberOfCombinedFrames,setNumberOfCombinedFrames)
floatAccessor_h(normalizedFrameExposureTime,setNormalizedFrameExposureTime)
floatAccessor_h(readNoise,setReadNoise)

//added in version 7
idAccessor_h(fractionOfApertureUnmaskedWave,setFractionOfApertureUnmaskedWave);

//added in version 8
floatAccessor_h(startMarkerWavelength,setStartMarkerWavelength)
floatAccessor_h(endMarkerWavelength,setEndMarkerWavelength)

//added in version 9
idAccessor_h(companionSpectrumWave,setCompanionSpectrumWave);
idAccessor_h(companionSpectrumDictionary,setCompanionSpectrumDictionary);
boolAccessor_h(useCompanionSpectrum,setUseCompanionSpectrum);

//added in version 10
idAccessor_h(plotAttributesDictionary,setPlotAttributesDictionary);

//added in version 11
boolAccessor_h(coAddCompanionSpectrum,setCoAddCompanionSpectrum)
intAccessor_h(numberOfCombinedFramesInCompanionSpectrum,setNumberOfCombinedFramesInCompanionSpectrum)


@end
