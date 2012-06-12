//
//  PreferenceController.m
//  iGDDS
//
//  Created by Roberto Abraham on Wed Oct 30 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "PreferenceController.h"

NSString *RGASpecColorWellKey = @"Object spectrum color";
NSString *RGASkyColorWellKey = @"Sky spectrum color";
NSString *RGAOutputFilePrefixKey = @"Output FITS filename prefix";
NSString *RGAOutputFileLocationKey = @"Output files directory name";
NSString *RGAInputFileLocationKey = @"Input files directory name";
NSString *RGAFluxCalibrationFilenameKey = @"Flux calibration filename";
NSString *RGARedEndCorrectionFilenameKey = @"Red-end correction filename";
NSString *RGAAtmosphericCorrectionFilenameKey = @"Atmospheric correction filename";

@implementation PreferenceController

- (id)init
{
    self = [super initWithWindowNibName:@"Preferences"];
    return self;
}

- (void)windowDidLoad
{
    NSUserDefaults *defaults;
    NSData *specColorAsData;
    NSData *skyColorAsData;

    defaults = [NSUserDefaults standardUserDefaults];
    specColorAsData = [defaults objectForKey:RGASpecColorWellKey];
    skyColorAsData = [defaults objectForKey:RGASkyColorWellKey];
    [specColorWell setColor:[NSUnarchiver unarchiveObjectWithData:specColorAsData]];
    [skyColorWell setColor:[NSUnarchiver unarchiveObjectWithData:skyColorAsData]];
    [outputFilePrefixField setStringValue:[defaults objectForKey:RGAOutputFilePrefixKey]];
    [outputFileLocationField setStringValue:[defaults objectForKey:RGAOutputFileLocationKey]];
    [inputFileLocationField setStringValue:[defaults objectForKey:RGAInputFileLocationKey]];
    [fluxCalibrationFilenameField setStringValue:[defaults objectForKey:RGAFluxCalibrationFilenameKey]];
    [redEndCorrectionFilenameField setStringValue:[defaults objectForKey:RGARedEndCorrectionFilenameKey]];
    [atmosphericCorrectionFilenameField setStringValue:[defaults objectForKey:RGAAtmosphericCorrectionFilenameKey]];
}

- (IBAction) changeOutputFilePrefix:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[sender stringValue] forKey:RGAOutputFilePrefixKey];
}

- (IBAction) changeOutputFileLocation:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[sender stringValue] forKey:RGAOutputFileLocationKey];
}


- (IBAction) changeInputFileLocation:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[sender stringValue] forKey:RGAInputFileLocationKey];
}


- (IBAction) changeSpecColor:(id)sender
{
    NSColor *color = [sender color];
    NSData *colorAsData = [NSArchiver archivedDataWithRootObject:color];
    [[NSUserDefaults standardUserDefaults] setObject:colorAsData forKey:RGASpecColorWellKey];
}

- (IBAction) changeSkyColor:(id)sender
{
    NSColor *color = [sender color];
    NSData *colorAsData = [NSArchiver archivedDataWithRootObject:color];
    [[NSUserDefaults standardUserDefaults] setObject:colorAsData forKey:RGASkyColorWellKey];
}

- (IBAction) changeFluxCalibrationFilename:(id)sender
{
    NSFileHandle *fh;
    int status = 0;
    if ([[sender stringValue] compare:@"-default-"]==NSOrderedSame)
        return;
    fh = [NSFileHandle fileHandleForReadingAtPath:[sender stringValue]];
    if (fh==nil){
        status = NSRunAlertPanel(@"Error!",@"File does not exist. Using default.", @"OK",nil, nil);
        [sender setStringValue:@"-default-"];
    }
    else{
        [[NSUserDefaults standardUserDefaults] setObject:[sender stringValue] forKey:RGAFluxCalibrationFilenameKey];
    }
}

- (IBAction) changeRedEndCorrectionFilename:(id)sender
{
    NSFileHandle *fh;
    int status = 0;
    if ([[sender stringValue] compare:@"-default-"]==NSOrderedSame)
        return;
    fh = [NSFileHandle fileHandleForReadingAtPath:[sender stringValue]];
    if (fh==nil){
        status = NSRunAlertPanel(@"Error!",@"File does not exist. Using default.", @"OK",nil, nil);
        [sender setStringValue:@"-default-"];
    }
    else{
        [[NSUserDefaults standardUserDefaults] setObject:[sender stringValue] forKey:RGARedEndCorrectionFilenameKey];
    }
}

- (IBAction) changeAtmosphericCorrectionFilename:(id)sender
{
    NSFileHandle *fh;
    int status = 0;
    if ([[sender stringValue] compare:@"-default-"]==NSOrderedSame)
        return;
    fh = [NSFileHandle fileHandleForReadingAtPath:[sender stringValue]];
    if (fh==nil){
        status = NSRunAlertPanel(@"Error!",@"File does not exist. Using default.", @"OK",nil, nil);
        [sender setStringValue:@"-default-"];
    }
    else{
        [[NSUserDefaults standardUserDefaults] setObject:[sender stringValue] forKey:RGAAtmosphericCorrectionFilenameKey];
    }
}


@end
