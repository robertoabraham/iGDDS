//
//  PreferenceController.h
//  iGDDS
//
//  Created by Roberto Abraham on Wed Oct 30 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

extern NSString *RGASpecColorWellKey;
extern NSString *RGASkyColorWellKey;
extern NSString *RGAOutputFilePrefixKey;
extern NSString *RGAOutputFileLocationKey;
extern NSString *RGAInputFileLocationKey;
extern NSString *RGAFluxCalibrationFilenameKey;
extern NSString *RGARedEndCorrectionFilenameKey;
extern NSString *RGAAtmosphericCorrectionFilenameKey;

@interface PreferenceController : NSWindowController {
    IBOutlet NSColorWell *specColorWell;
    IBOutlet NSColorWell *skyColorWell;
    IBOutlet NSTextField *outputFilePrefixField;
    IBOutlet NSTextField *outputFileLocationField;
    IBOutlet NSTextField *inputFileLocationField;
    IBOutlet NSTextField *fluxCalibrationFilenameField;
    IBOutlet NSTextField *redEndCorrectionFilenameField;
    IBOutlet NSTextField *atmosphericCorrectionFilenameField;
}

- (IBAction)changeSpecColor:(id)sender;
- (IBAction)changeSkyColor:(id)sender;
- (IBAction)changeOutputFilePrefix:(id)sender;
- (IBAction)changeOutputFileLocation:(id)sender;
- (IBAction)changeInputFileLocation:(id)sender;
- (IBAction)changeFluxCalibrationFilename:(id)sender;
- (IBAction)changeRedEndCorrectionFilename:(id)sender;
- (IBAction)changeAtmosphericCorrectionFilename:(id)sender;

@end
