//
//  MyDocument.h
//  iGDDS
//
//  Created by Roberto Abraham on Sat Aug 24 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "YesNoFormatter.h"
#import "PreferenceController.h"

#import "Image.h"
#import "NodAndShuffleAperture.h"
#import "Wave.h"
@class ExtractionWindowController;


@interface MyDocument : NSDocument
{
    NSMutableArray *mask;    // An array of Slit objects. This is the central repository of information with data for each object.
    Image *imageOf2DSpectrum;
    Image *imageOfSkySpectrum;
    Wave *fluxCalibrationWave;
    Wave *redEndCorrectionWave;
    Wave *atmosphericTransmissionWave;
    NSMutableArray *goodSkyLines;
    NSMutableDictionary *spectralTemplates;
    NSMutableArray *spectralTemplateLabels;
    ExtractionWindowController *extractionWindowController;
    NSString *defaultFluxCalibrationFile;
    NSString *defaultRedfixCalibrationFile;
    NSString *defaultAtmosphericCalibrationFile;
    BOOL extractionWindowControllerHasBeenDisplayedBefore;
    IBOutlet NSTableView *tableView;
    IBOutlet NSTextField *statusField;
    IBOutlet NSTextField *preimagingField;
    IBOutlet NSTextField *twoDSpectraField;
    IBOutlet NSTextField *skySpectraField;
    IBOutlet NSTextField *numberOfCombinedFramesField;
    IBOutlet NSTextField *normalizedFrameExposureTimeField;
    IBOutlet NSTextField *readNoiseField;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSMatrix *redfixCalibrationMatrix;
    IBOutlet NSMatrix *atmosphericCalibrationMatrix;
    IBOutlet NSMatrix *fluxCalibrationMatrix;
    IBOutlet NSTextField *redfixCalibrationField;
    IBOutlet NSTextField *fluxCalibrationField;
    IBOutlet NSTextField *atmosphericCalibrationField;
    IBOutlet NSButton *loadRedfixCalibrationFileButton;
    IBOutlet NSButton *loadFluxCalibrationFileButton;
    IBOutlet NSButton *loadAtmosphericCalibrationFileButton;


    NSMutableArray *objectsToSave;

    //variables used for sorting
    bool showSubsetOnly;
    bool upSort;
    NSImage *upSortImage;
    NSImage *downSortImage;
    NSString *currentSortedColumn;

    //variables used for timing
    NSDate *start;

    //Added in version 1
    float numberOfCombinedFrames;
    float normalizedFrameExposureTime;
    float readNoise;

    //Added in version 2
    BOOL useDefaultFluxCalibration;
    BOOL useDefaultRedfixCalibration;
    BOOL useDefaultAtmosphericCalibration;
    NSMutableString *externalFluxCalibrationFile;
    NSMutableString *externalRedfixCalibrationFile;
    NSMutableString *externalAtmosphericCalibrationFile;
    
    //Added in version 3.
    int len;
    int slit;
    float xBin;
    float yBin;
    int xOffset;
    int yOffset;
    int naxis1; 
    int naxis2;
    
}

//Action methods
- (IBAction)display:(id)sender;
- (IBAction)importMDF:(id)sender;
- (IBAction)browseForTwoDSpectraFile:(id)sender;
- (IBAction)browseForSkySpectraFile:(id)sender;
- (IBAction)browseForPreimagingFile:(id)sender;
- (IBAction)storeCalibrationInfo:(id)sender;
- (IBAction)exportExtractionsToASCIIFiles:(id)sender;
- (IBAction)exportExtractionsToFITSFiles:(id)sender;
- (IBAction)loadCalibrationFiles:(id)sender;

//Data source methods
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex;

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(int)rowIndex;

//Private methods
- (void) updateUI;

//Accessor methods so I can browse stuff with FScript Anywhere
idAccessor_h(mask, setMask)
boolAccessor_h(extractionWindowControllerHasBeenDisplayedBefore,setExtractionWindowControllerHasBeenDisplayedBefore);
idAccessor_h(fluxCalibrationWave,setFluxCalibrationWave)
idAccessor_h(redEndCorrectionWave,setRedEndCorrectionWave)
idAccessor_h(atmosphericTransmissionWave,setAtmosphericTransmissionWave)
idAccessor_h(goodSkyLines, setGoodSkyLines)
idAccessor_h(spectralTemplates, setSpectralTemplates)
idAccessor_h(spectralTemplateLabels, setSpectralTemplateLabels)


//Added in version 1
floatAccessor_h(numberOfCombinedFrames,setNumberOfCombinedFrames)
floatAccessor_h(normalizedFrameExposureTime,setNormalizedFrameExposureTime)
floatAccessor_h(readNoise,setReadNoise)

//Added in version 2
boolAccessor_h(useDefaultFluxCalibration,setUseDefaultFluxCalibration);
boolAccessor_h(useDefaultRedfixCalibration,setUseDefaultRedfixCalibration);
boolAccessor_h(useDefaultAtmosphericCalibration,setUseDefaultAtmosphericCalibration);
idAccessor_h(externalFluxCalibrationFile,setExternalFluxCalibrationFile);
idAccessor_h(externalRedfixCalibrationFile,setExternalRedfixCalibrationFile);
idAccessor_h(externalAtmosphericCalibrationFile,setExternalAtmosphericCalibrationFile);

@end
