//
//  MyDocument.m
//  iGDDS
//
//  Created by Roberto Abraham on Sat Aug 24 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "MyDocument.h"
#import "ExtractionWindowController.h"
#include "fitsio.h"

static void reportFITSError(int status, char file[], int line);
static void getBaseName(char pathname[], char base[]);

@implementation MyDocument

+(void) initialize
{
    if (self==[MyDocument class]){
        [self setVersion:3];
    }
}

//Action methods

- (IBAction)display:(id)sender
{
    int row = [tableView selectedRow];
    NSMutableString *extendedFilename = [NSMutableString stringWithString:[twoDSpectraField stringValue]];
    Slit *theSlit;
    NSString *boxSuffix;
    int i;
    int ylo,yhi;
    int xCCD, yCCD, specPosY, specPosX;

    //Make sure only one mask is receiving messages with regard to mouse clicks. This is
    //here as a backup in case the user has opened up a new window without closing the old window.
    start = [NSDate date];
    for(i=0;i<[mask count];i++)
        [[NSNotificationCenter defaultCenter] removeObserver:[[mask objectAtIndex:i] aperture]
                                                        name:@"FITSImageViewMouseDownNotification"
                                                      object:nil];
    NSLog(@"Initializtion time:%g seconds", -[start timeIntervalSinceNow]);


    // Display the chosen slit.
    if (row != -1){

        NSLog(@"xBin is %f",xBin);
        NSLog(@"yBin is %f",yBin);
        
        theSlit = [mask objectAtIndex:row];
        //theSlit = [[mask objectAtIndex:row] copyWithZone:NULL];
        
        //account for binning and offset
        xCCD = xBin*[theSlit xCCD] + xOffset;
        yCCD = yBin*[theSlit yCCD] + yOffset;
        specPosX = xBin*[theSlit specPosX];
        specPosY = yBin*[theSlit specPosY];
        
        //default display box
        ylo = yCCD + specPosY - len/2;
        yhi = yCCD + specPosY + len/2;

        //object image. note we reverse X-axis here so blue is at left as god intended
        boxSuffix = [NSString stringWithFormat:@"[1][-*,%d:%d]",ylo,yhi];
        [extendedFilename appendString:boxSuffix];
        [imageOf2DSpectrum release];
        imageOf2DSpectrum = [[Image alloc] initWithFITS:extendedFilename];

        //sky image. note we reverse X-axis here so blue is at left as god intended
        [extendedFilename release];
        extendedFilename = [NSMutableString stringWithString:[skySpectraField stringValue]];
        [extendedFilename appendString:boxSuffix];
        [imageOfSkySpectrum release];
        imageOfSkySpectrum = [[Image alloc] initWithFITS:extendedFilename];

        //set up the information in the window controller
        if (!extractionWindowController){
            NSLog(@" ###### Allocating extractionWindowController and calling awake from nib automatically (later):");
            extractionWindowController = [[ExtractionWindowController alloc] init];
            [self setExtractionWindowControllerHasBeenDisplayedBefore:NO];
        }
        [extractionWindowController setFits:imageOf2DSpectrum];
        [extractionWindowController setSkyFits:imageOfSkySpectrum];
        [extractionWindowController setYOffsetCCD:ylo];
        [extractionWindowController setnaxis1:naxis1];
        [extractionWindowController setXCCD:xCCD];
        [extractionWindowController setDocument:self];
        [extractionWindowController setTheSlit:theSlit];

        // We change stuff in the controller, so want to call awakeFromNib every time it's shown. This
        // does good stuff like register the slit's aperture so it recieves
        // FITSImageViewMouseDownNotification notifications.
        if(extractionWindowControllerHasBeenDisplayedBefore){
            NSLog(@" ###### Calling awakeFromNib manually:");
            [extractionWindowController awakeFromNib];
        }
            
        //display the window
        [extractionWindowController showWindow:self];
        [self setExtractionWindowControllerHasBeenDisplayedBefore:YES];
        [[extractionWindowController window] setTitle:[NSString stringWithFormat:@"Object Number %d",[theSlit objectNumber]]];
    }
    
    //refresh
    NSLog(@" ###### Telling extractionWindowController to refresh itself");
    [extractionWindowController refresh:self];

}


- (IBAction)importMDF:(id)sender
{
    int          result;
    NSArray     *fileTypes = [NSArray arrayWithObject:@"fits"];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    int          status = 0;
    int          f_res;
    fitsfile    *fptr;
    char         fbasename[100];
    char         tablename[100];
    int          hdutype;
    long         nrows;
    long         row;
    int          ncols;
    int          col;
    int          typecode;
    long         repeat;
    long         width;
    char         templt[100];
    char         colname[100];
    int          colnum;
    char         tbl_prepend[32];
    char         tbl_append[32];
    char        *ffilename;
    char         nulval[200];
    int          myInt;
    float        myFloat;

    NSLog(@"Importing MDF file");

    //If the file has been modified make sure the user really wants to do this.
    if ( [mask count] != 0 ){
        NSBeep();
        status = NSRunAlertPanel(@"Warning!",
                                 @"Importing a new MDF will overwrite all the stored results in this file. Are you sure?", @"Yes", @"Cancel", nil);
        if ( status != NSAlertDefaultReturn ) {
            return;
        }
    }
    
    //Put up a file browser and let the user select some file(s)
    [oPanel setAllowsMultipleSelection:NO];
    result = [oPanel runModalForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:RGAInputFileLocationKey] file:nil  types:fileTypes];
    if (result == NSOKButton) {
        NSArray *filesToOpen = [oPanel filenames];
        NSString *aFile = [filesToOpen objectAtIndex:0];
        
        //Process the FITS MDF file here
        ffilename = (char *)[aFile UTF8String];
        NSLog(@"Trying to open %s",ffilename);
        status = 0;
        f_res = fits_open_file(&fptr,ffilename, READONLY, &status);
        if(f_res) {
            reportFITSError(status, __FILE__, __LINE__);
            status = NSRunAlertPanel(@"Error", @"Unable to open file.", @"OK", nil, nil);
            return;
        }
        getBaseName(ffilename, fbasename);
        snprintf(tablename, sizeof(tablename),
                 "%s%s%s", tbl_prepend, fbasename, tbl_append);

        /* Find out if this is a table.   hdutype will be set to either     */
        /* IMAGE_HDU, ASCII_TBL or BINARY_TBL                               */
        status = 0;
        f_res = fits_get_hdu_type(fptr, &hdutype, &status);
        if(f_res) {
            reportFITSError(status, __FILE__, __LINE__);
            return;
        }
        NSLog(@"hdutype: %d (IAB %d %d %d)\n",
                  hdutype, IMAGE_HDU, ASCII_TBL, BINARY_TBL);

        // Look for a _TBL kind of HDU 
        while ( !((hdutype == ASCII_TBL) || (hdutype == BINARY_TBL)) ) 	{
            status = 0;
            f_res = fits_movrel_hdu(fptr, 1, &hdutype, &status);
            if(f_res) {
                reportFITSError(status, __FILE__, __LINE__);
                NSBeep();
                status = NSRunAlertPanel(@"Error", @"This file does not contain a FITS table.", @"OK", nil, nil);
                return;
            }
            NSLog(@"hdutype: %d\n", hdutype);
        }

        // Count the number of slits in the MDF */
        status = 0;
        f_res = fits_get_num_rows(fptr, &nrows, &status);
        if(f_res)
        {
            reportFITSError(status, __FILE__, __LINE__);
            NSBeep();
            status = NSRunAlertPanel(@"Error", @"Unable to access table rows.", @"OK", nil, nil);
            return;
        }
        NSLog(@"MDF contains %d slits\n",nrows);

        // Count the number of columns and make sure there are 23 of them (the standard number for an MDF)
        status = 0;
        f_res = fits_get_num_cols(fptr, &ncols, &status);
        if(f_res)
        {
            reportFITSError(status, __FILE__, __LINE__);
            NSBeep();
            status = NSRunAlertPanel(@"Error", @"Unable to access table columns.", @"OK", nil, nil);
            return;            
        }
        if(ncols!=23){
            NSBeep();
            status = NSRunAlertPanel(@"Error", @"This FITS file does not appear to be a standard MDF file", @"OK", nil, nil);
            return;            
        }

        // Get column names and types just to make sure they're what we think they are
        for(col=1; col<=ncols; col++)
        {
            snprintf(templt, sizeof(templt), "%d", col);
            status = 0;
            f_res = fits_get_colname(fptr, CASEINSEN, templt,
                                     colname, &colnum, &status);
            if(f_res){
                reportFITSError(status, __FILE__, __LINE__);
                return;
            }
            
            status = 0;
            f_res = fits_get_coltype(fptr, col,
                                     &typecode, &repeat, &width, &status);
            if(f_res){
                reportFITSError(status, __FILE__, __LINE__);
                return;
            }
            //NSLog(@"Column %d name: %s of type %d \n",col,colname,typecode);
        }

        // Looks like everything is OK so let's really do this.
        [mask release];
        mask = [[NSMutableArray alloc] init];
        
        // Read data values. We'll read everything as a string and convert later.
        for(row=1; row<=nrows; row++){
            Slit *aSlit;
            int firstelem = 1;
            int nelements = 1;
            int dummy;
            strcpy(nulval, " ");
            status = 0;

            aSlit = [[Slit alloc] init];
            
            f_res = fits_read_col(fptr,  TLONG, 1, row, firstelem, nelements, nulval, &myInt, &dummy, &status);
            [aSlit setObjectNumber:myInt];
            f_res = fits_read_col(fptr, TFLOAT, 2, row, firstelem, nelements, nulval, &myFloat, &dummy, &status);
            [aSlit setRa:myFloat];
            f_res = fits_read_col(fptr, TFLOAT, 3, row, firstelem, nelements, nulval, &myFloat, &dummy, &status);
            [aSlit setDec:myFloat];
            f_res = fits_read_col(fptr, TFLOAT, 4, row, firstelem, nelements, nulval, &myFloat, &dummy, &status);
            [aSlit setXCCD:myFloat];
            f_res = fits_read_col(fptr, TFLOAT, 5, row, firstelem, nelements, nulval, &myFloat, &dummy, &status);
            [aSlit setYCCD:myFloat];
            f_res = fits_read_col(fptr, TFLOAT, 6, row, firstelem, nelements, nulval, &myFloat, &dummy, &status);
            [aSlit setSpecPosX:myFloat];
            f_res = fits_read_col(fptr, TFLOAT, 7, row, firstelem, nelements, nulval, &myFloat, &dummy, &status);
            [aSlit setSpecPosY:myFloat];
            f_res = fits_read_col(fptr, TFLOAT, 8, row, firstelem, nelements, nulval, &myFloat, &dummy, &status);
            [aSlit setSlitPosX:myFloat];
            f_res = fits_read_col(fptr, TFLOAT, 9, row, firstelem, nelements, nulval, &myFloat, &dummy, &status);
            [aSlit setSlitPosY:myFloat];
            f_res = fits_read_col(fptr, TFLOAT,10, row, firstelem, nelements, nulval, &myFloat, &dummy, &status);
            [aSlit setSlitSizeX:myFloat];
            f_res = fits_read_col(fptr, TFLOAT,11, row, firstelem, nelements, nulval, &myFloat, &dummy, &status);
            [aSlit setSlitSizeY:myFloat];
            f_res = fits_read_col(fptr, TFLOAT,12, row, firstelem, nelements, nulval, &myFloat, &dummy, &status);
            [aSlit setSlitTilt:myFloat];
            f_res = fits_read_col(fptr, TFLOAT,13, row, firstelem, nelements, nulval, &myFloat, &dummy, &status);
            [aSlit setMag:myFloat];
            if(f_res){
                reportFITSError(status, __FILE__, __LINE__);
                return;
            }

            //Store the calibration info in the slit
            [aSlit setNumberOfCombinedFrames:numberOfCombinedFrames];
            [aSlit setNormalizedFrameExposureTime:normalizedFrameExposureTime];
            [aSlit setReadNoise:readNoise];

            //Append the the new slit to the mask array
            [mask addObject:aSlit];
        }
        // [mdfField setStringValue:aFile];
        status = 0;
        f_res = fits_close_file(fptr, &status);
        
    }

    //Alert document object that it's been changed
    [self updateChangeCount:NSChangeDone];
    [self updateUI];
    
}


- (IBAction)browseForPreimagingFile:(id)sender
{
    int          result;
    NSArray     *fileTypes = [NSArray arrayWithObject:@"fits"];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];

    //Put up a file browser and let the user select some file(s)
    [oPanel setAllowsMultipleSelection:NO];
    result = [oPanel runModalForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:RGAInputFileLocationKey] file:nil  types:fileTypes];
    if (result == NSOKButton) {
        NSArray *filesToOpen = [oPanel filenames];
        NSString *aFile = [filesToOpen objectAtIndex:0];
        [preimagingField setStringValue:aFile];
    }
    [self updateChangeCount:NSChangeDone];
    [self updateUI];
}


- (IBAction)browseForTwoDSpectraFile:(id)sender
{
    int          result;
    NSArray     *fileTypes = [NSArray arrayWithObject:@"fits"];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];

    //Put up a file browser and let the user select some file(s)
    [oPanel setAllowsMultipleSelection:NO];
    result = [oPanel runModalForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:RGAInputFileLocationKey] file:nil  types:fileTypes];
    if (result == NSOKButton) {
        NSArray *filesToOpen = [oPanel filenames];
        NSString *aFile = [filesToOpen objectAtIndex:0];
        [twoDSpectraField setStringValue:aFile];
    }
    [self updateChangeCount:NSChangeDone];
    [self updateUI];
}


- (IBAction)browseForSkySpectraFile:(id)sender
{
    int          result;
    NSArray     *fileTypes = [NSArray arrayWithObject:@"fits"];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];

    //Put up a file browser and let the user select some file(s)
    [oPanel setAllowsMultipleSelection:NO];
    result = [oPanel runModalForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:RGAInputFileLocationKey] file:nil  types:fileTypes];
    if (result == NSOKButton) {
        NSArray *filesToOpen = [oPanel filenames];
        NSString *aFile = [filesToOpen objectAtIndex:0];
        [skySpectraField setStringValue:aFile];
    }
    [self updateChangeCount:NSChangeDone];
    [self updateUI];
}


- (IBAction)storeCalibrationInfo:(id)sender
{
    int i;
    
    NSLog(@"Storing calibration info");
    numberOfCombinedFrames = [numberOfCombinedFramesField floatValue];
    normalizedFrameExposureTime = [normalizedFrameExposureTimeField floatValue];
    readNoise = [readNoiseField floatValue];
    for(i=0;i<[mask count];i++){
        Slit *theSlit = [mask objectAtIndex:i];
        [theSlit setNumberOfCombinedFrames:numberOfCombinedFrames];
        [theSlit setNormalizedFrameExposureTime:normalizedFrameExposureTime];
        [theSlit setReadNoise:readNoise];
    }
    
}


- (IBAction)exportExtractionsToASCIIFiles:(id)sender
{
    int i;

    [progressIndicator setDisplayedWhenStopped:NO];
    [progressIndicator setControlTint:NSDefaultControlTint];
    [progressIndicator setIndeterminate:NO];
    [progressIndicator setMinValue:0.0];
    [progressIndicator setMaxValue:(double)[mask count]];
    [progressIndicator setDoubleValue:0.0];

    for(i=0;i<[mask count];i++){
        
        [progressIndicator incrementBy:1.0];
        [progressIndicator setNeedsDisplay:YES];
        [progressIndicator displayIfNeeded];
        
        Slit *theSlit = [mask objectAtIndex:i];
        if([theSlit calibratedExtractionExists]){
            NSString *shortfilename = [NSString stringWithFormat:@"%d_final.txt",[theSlit objectNumber]];
            NSString *dir = [[NSUserDefaults standardUserDefaults] objectForKey:RGAOutputFileLocationKey];
            NSString *filename = [[dir stringByAppendingString:@"/"]
                          stringByAppendingString:[[[NSUserDefaults standardUserDefaults] objectForKey:RGAOutputFilePrefixKey]
                          stringByAppendingString:shortfilename]];
            NSLog(@"Exporing object %d to file %@",[theSlit objectNumber],filename);
            if (![theSlit useCompanionSpectrum])
            {
                [theSlit exportToFile:filename
                      fluxCalibration:fluxCalibrationWave
                               redFix:redEndCorrectionWave
                atmosphericAbsorption:atmosphericTransmissionWave];
            }
            else
            {
                [theSlit exportCompanionToFile:filename
                      fluxCalibration:fluxCalibrationWave
                               redFix:redEndCorrectionWave
                atmosphericAbsorption:atmosphericTransmissionWave];
            }
        }
        else{
            NSLog(@"Ignoring object %d",[theSlit objectNumber]);
        }
    }

    [progressIndicator setDoubleValue:0.0];
    [progressIndicator setControlTint:NSClearControlTint];
    [progressIndicator setNeedsDisplay:YES];
}


- (IBAction)exportExtractionsToFITSFiles:(id)sender
{
    int i;

    [progressIndicator setDisplayedWhenStopped:NO];
    [progressIndicator setControlTint:NSDefaultControlTint];
    [progressIndicator setIndeterminate:NO];
    [progressIndicator setMinValue:0.0];
    [progressIndicator setMaxValue:(double)[mask count]];
    [progressIndicator setDoubleValue:0.0];

    for(i=0;i<[mask count];i++){

        [progressIndicator incrementBy:1.0];
        [progressIndicator setNeedsDisplay:YES];
        [progressIndicator displayIfNeeded];

        Slit *theSlit = [mask objectAtIndex:i];
        if([theSlit calibratedExtractionExists]){
            NSString *shortfilename = [NSString stringWithFormat:@"%d_final.fits",[theSlit objectNumber]];
            NSString *dir = [[NSUserDefaults standardUserDefaults] objectForKey:RGAOutputFileLocationKey];
            NSString *filename = [[dir stringByAppendingString:@"/"]
                          stringByAppendingString:[[[NSUserDefaults standardUserDefaults] objectForKey:RGAOutputFilePrefixKey]
                          stringByAppendingString:shortfilename]];
            NSLog(@"Exporing object %d to file %@",[theSlit objectNumber],filename);
            [theSlit exportToFITS:filename
                  fluxCalibration:fluxCalibrationWave
                           redFix:redEndCorrectionWave
            atmosphericAbsorption:atmosphericTransmissionWave];
        }
        else{
            NSLog(@"Ignoring object %d",[theSlit objectNumber]);
        }
    }

    [progressIndicator setDoubleValue:0.0];
    [progressIndicator setControlTint:NSClearControlTint];
    [progressIndicator setNeedsDisplay:YES];
}



//Datasource methods
-(int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [mask count];
}


- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex
{
    NSString *identifier = [aTableColumn identifier];
    Slit *s = [mask objectAtIndex:rowIndex];
    return [s valueForKey:identifier];
}


- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(int)rowIndex
{
    NSString *identifier= [aTableColumn identifier];
    Slit *s = [mask objectAtIndex:rowIndex];
    [s takeValue:anObject forKey:identifier];
}


// Delegate methods
- (void) tableView:(NSTableView*)theTableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    NSMutableArray  *temporaryMask;
    NSString *selectorStringRoot = @"compare";
    NSString *selectorString;
    SEL *aSelector;

    // check to see if this column was already the selected one and if so invert the sort function.
    if ([currentSortedColumn isEqualToString:[tableColumn identifier]] == YES)
    {
        if(upSort)
            upSort = FALSE;
        else
            upSort = TRUE;
    }
    else
    {   // if there already was a sorted column, remove the indicator image from it.
        [theTableView setIndicatorImage:nil inTableColumn:[tableView tableColumnWithIdentifier:currentSortedColumn]];
        upSort = TRUE;
    }

    // set the highlight+indicator image in the newly selected column
    [theTableView setHighlightedTableColumn:tableColumn];
    if(upSort)
        [theTableView setIndicatorImage:upSortImage inTableColumn:tableColumn];
    else
        [theTableView setIndicatorImage:downSortImage inTableColumn:tableColumn];

    [currentSortedColumn release];
    currentSortedColumn = [[NSString alloc] initWithString:[tableColumn identifier]];

    selectorString = [[NSString alloc] initWithString:[[selectorStringRoot stringByAppendingString:[currentSortedColumn capitalize]] stringByAppendingString:@":"]];
    aSelector= NSSelectorFromString(selectorString);
    
    // The following does not create new objects, it merely re-orders existing pointers to objects!
    temporaryMask = [mask sortedArrayUsingSelector:aSelector];
    if (upSort){
        [temporaryMask retain];
        [mask release];
        mask = temporaryMask;
    }
    else{
        int i;
        [mask release];
        mask=[[NSMutableArray alloc] init];
        for(i=[temporaryMask count]-1;i>=0;i--){
            [mask addObject:[temporaryMask objectAtIndex:i]];
        }
    }

    [self updateUI];

}


//Private methods
- (void)updateUI
{
    NSString *statusText;
    statusText = [NSString stringWithFormat:@"%d slits",[mask count]];
    NSLog(@"%@",statusText);
    [statusField setStringValue:statusText];
    [numberOfCombinedFramesField setFloatValue:numberOfCombinedFrames];
    [normalizedFrameExposureTimeField setFloatValue:normalizedFrameExposureTime];
    [readNoiseField setFloatValue:readNoise];    
    [tableView reloadData];
    [redfixCalibrationMatrix deselectAllCells];
    [atmosphericCalibrationMatrix deselectAllCells];
    [fluxCalibrationMatrix deselectAllCells];

    if(useDefaultRedfixCalibration)
        [redfixCalibrationMatrix selectCellAtRow:0 column:0];
    else
        [redfixCalibrationMatrix selectCellAtRow:0 column:1];

    if(useDefaultAtmosphericCalibration)
        [atmosphericCalibrationMatrix selectCellAtRow:0 column:0];
    else
        [atmosphericCalibrationMatrix selectCellAtRow:0 column:1];
    
    if(useDefaultFluxCalibration)
        [fluxCalibrationMatrix selectCellAtRow:0 column:0];
    else
        [fluxCalibrationMatrix selectCellAtRow:0 column:1];
    
}


//Reset calibration files
- (IBAction) loadCalibrationFiles:(id)sender
{

    int           result;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray       *fileTypes = [NSArray arrayWithObject:@"fits"];
    NSOpenPanel   *oPanel = [NSOpenPanel openPanel];

    //Simple case where user is browsing to find an external file
    if ([sender class] == [NSButton class]){
        [oPanel setAllowsMultipleSelection:NO];
        [oPanel setTitle:@"Select FITS calibration file"];
        result = [oPanel runModalForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:RGAInputFileLocationKey] file:nil  types:fileTypes];
        if (result == NSOKButton) {
             NSArray *filesToOpen = [oPanel filenames];
             NSString *aFile = [filesToOpen objectAtIndex:0];
             if (sender == loadRedfixCalibrationFileButton){
                 [redfixCalibrationField setStringValue:aFile];
             }
             if (sender == loadFluxCalibrationFileButton){
                 [fluxCalibrationField setStringValue:aFile];
             }
             if (sender == loadAtmosphericCalibrationFileButton){
                 [atmosphericCalibrationField setStringValue:aFile];
             }
        }
        else{
            //User has cancelled so make sure we go with default
            if (sender == loadRedfixCalibrationFileButton){
                useDefaultRedfixCalibration = YES;
                [redfixCalibrationMatrix selectCellAtRow:0 column:0];
            }
            if (sender == loadFluxCalibrationFileButton){
                useDefaultFluxCalibration = YES;
                [fluxCalibrationMatrix selectCellAtRow:0 column:0];
            }
            if (sender == loadAtmosphericCalibrationFileButton){
                useDefaultAtmosphericCalibration = YES;
                [atmosphericCalibrationMatrix selectCellAtRow:0 column:0];
            }
            return;
        }
        [self updateChangeCount:NSChangeDone];
        [self updateUI];
    }

    //Case where the user has clicked a radio button
    if ([sender class] == [NSMatrix class]){
        if ([[[sender selectedCell] title] compare:@"FITS file:"]==NSOrderedSame){

            //User has gone from default to wanting to use an external FITS file
            if (sender == redfixCalibrationMatrix)
                useDefaultRedfixCalibration = NO;
            if (sender == fluxCalibrationMatrix)
                useDefaultFluxCalibration = NO;
            if (sender == atmosphericCalibrationMatrix)
                useDefaultAtmosphericCalibration = NO;

            //Check if a valid FITS file is already defined in the corresponding field. If not browse to find it.
            if ((sender == redfixCalibrationMatrix && ![fileManager fileExistsAtPath:[redfixCalibrationField stringValue]]) ||
                (sender == fluxCalibrationMatrix && ![fileManager fileExistsAtPath:[fluxCalibrationField stringValue]]) ||
                (sender == atmosphericCalibrationMatrix && ![fileManager fileExistsAtPath:[atmosphericCalibrationField stringValue]])) {
                
                //user wants to use a FITS file but it doesn't exist. Put up a file browser and let the user select a file
                [oPanel setAllowsMultipleSelection:NO];
                [oPanel setTitle:@"Select FITS calibration file"];
                result = [oPanel runModalForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:RGAInputFileLocationKey] file:nil types:fileTypes];
                if (result == NSOKButton) {
                    NSArray *filesToOpen = [oPanel filenames];
                    NSString *aFile = [filesToOpen objectAtIndex:0];
                    [sender deselectSelectedCell];
                    [sender selectCellAtRow:0 column:1];
                    if (sender == redfixCalibrationMatrix){
                        [redfixCalibrationField setStringValue:aFile];
                    }
                    if (sender == fluxCalibrationMatrix){
                        [fluxCalibrationField setStringValue:aFile];
                    }
                    if (sender == atmosphericCalibrationMatrix){
                        [atmosphericCalibrationField setStringValue:aFile];
                    }
                }
                else{
                    //User has cancelled so we go back to using the default.
                    [sender deselectSelectedCell];
                    [sender selectCellAtRow:0 column:0];
                    if (sender == redfixCalibrationMatrix)
                        useDefaultRedfixCalibration = YES;
                    if (sender == fluxCalibrationMatrix)
                        useDefaultFluxCalibration = YES;
                    if (sender == atmosphericCalibrationMatrix)
                        useDefaultAtmosphericCalibration = YES;
                    [self updateUI];
                    return;
                }
                [self updateChangeCount:NSChangeDone];
                [self updateUI];
            }
        }
        else{
            //User has gone from using an external FITS file to using the default calibration file
            if (sender == redfixCalibrationMatrix)
                useDefaultRedfixCalibration = YES;
            if (sender == fluxCalibrationMatrix)
                useDefaultFluxCalibration = YES;
            if (sender == atmosphericCalibrationMatrix)
                useDefaultAtmosphericCalibration = YES;
        }
        [self updateChangeCount:NSChangeDone];
        [self updateUI];

    }
    
    
    //Load external file names
    [externalRedfixCalibrationFile setString:[redfixCalibrationField stringValue]];
    [externalFluxCalibrationFile setString:[fluxCalibrationField stringValue]];
    [externalAtmosphericCalibrationFile setString:[atmosphericCalibrationField stringValue]];
    
    //Load the redfix wave
    if(redEndCorrectionWave) {
        [redEndCorrectionWave release];
        redEndCorrectionWave = nil;
    }
    if([[[redfixCalibrationMatrix selectedCell] title] compare:@"Default"]==NSOrderedSame) {
        useDefaultRedfixCalibration = YES;
        redEndCorrectionWave = [[Wave alloc] initWithFITS:defaultRedfixCalibrationFile];
    }
    else{
        if (checkForSimpleSpectrum((char *)[externalRedfixCalibrationFile UTF8String])==0){
            useDefaultRedfixCalibration = NO;
            redEndCorrectionWave = [[Wave alloc] initWithFITS:externalRedfixCalibrationFile];
        }
        else{
            NSRunAlertPanel(@"Error in calibration file!",
                            @"The external red-end correction file is not a simple FITS spectrum. The default calibration curve will be used instead.",
                            @"OK", nil, nil);
            useDefaultRedfixCalibration = YES;
            [externalRedfixCalibrationFile setString:@" "];
            [redfixCalibrationField setStringValue:externalRedfixCalibrationFile];
            redEndCorrectionWave = [[Wave alloc] initWithFITS:defaultRedfixCalibrationFile];
        }  
    }

    //Load the flux calibration wave
    if(fluxCalibrationWave) {
        [fluxCalibrationWave release];
        fluxCalibrationWave = nil;
    }
    if([[[fluxCalibrationMatrix selectedCell] title] compare:@"Default"]==NSOrderedSame) {
        useDefaultFluxCalibration = YES;
        fluxCalibrationWave = [[Wave alloc] initWithFITS:defaultFluxCalibrationFile];
    }
    else{
        if (checkForSimpleSpectrum((char *)[externalFluxCalibrationFile UTF8String])==0){
            useDefaultFluxCalibration = NO;
            fluxCalibrationWave = [[Wave alloc] initWithFITS:externalFluxCalibrationFile];
        }
        else{
            NSRunAlertPanel(@"Error in calibration file!",
                            @"The external flux calibration file is not a simple FITS spectrum. The default calibration curve will be used instead.",
                            @"OK", nil, nil);
            useDefaultFluxCalibration = YES;
            [externalFluxCalibrationFile setString:@" "];
            [fluxCalibrationField setStringValue:externalFluxCalibrationFile];
            fluxCalibrationWave = [[Wave alloc] initWithFITS:defaultFluxCalibrationFile];
        }
    }

    //Load the atmospheric calibration wave
    if(atmosphericTransmissionWave) {
        [atmosphericTransmissionWave release];
        atmosphericTransmissionWave = nil;
    }
    if([[[atmosphericCalibrationMatrix selectedCell] title] compare:@"Default"]==NSOrderedSame) {
        useDefaultAtmosphericCalibration = YES;
        atmosphericTransmissionWave = [[Wave alloc] initWithFITS:defaultAtmosphericCalibrationFile];
    }
    else{
        if (checkForSimpleSpectrum((char *)[externalAtmosphericCalibrationFile UTF8String])==0){
            useDefaultAtmosphericCalibration = NO;
            atmosphericTransmissionWave = [[Wave alloc] initWithFITS:externalAtmosphericCalibrationFile];
        }
        else{
            NSRunAlertPanel(@"Error in calibration file!",
                            @"The external atmospheric transmission file is not a simple FITS spectrum. The default transmission curve will be used instead.",
                            @"OK", nil, nil);
            useDefaultAtmosphericCalibration = YES;
            [externalAtmosphericCalibrationFile setString:@" "];
            [atmosphericCalibrationField setStringValue:externalAtmosphericCalibrationFile];
            atmosphericTransmissionWave = [[Wave alloc] initWithFITS:defaultAtmosphericCalibrationFile];
        }
    }

    [self updateUI];
 
}     

//Overriding methods
- (id)init
{
    NSBundle *myBundle = [NSBundle mainBundle];
    NSArray *spectralTemplatesXML;
    NSEnumerator *e;
    NSDictionary *dict;
    
    if (self=[super init]){
        [self setExtractionWindowControllerHasBeenDisplayedBefore:NO];

        //Set some defaults
        numberOfCombinedFrames = 51;
        normalizedFrameExposureTime = 1800;
        readNoise = 0.95;
        len = 34;
        slit = 28;
        xBin = 1;
        yBin = 2;
        xOffset = 0;
        yOffset = 35;
        naxis1 = 3175; // This only gets used to decide where the default NodAndShuffle aperture get sdisplayed
        naxis2 = 4608; // This really does nothing in iGDDS
        
        defaultFluxCalibrationFile =
            [[NSString stringWithString:[myBundle pathForResource:@"FLUXCAL_KARL" ofType:@"fits"]] retain];
        defaultRedfixCalibrationFile =
            [[NSString stringWithString:[myBundle pathForResource:@"REDFIX_DAVID" ofType:@"fits"]] retain];
        defaultAtmosphericCalibrationFile =
            [[NSString stringWithString:[myBundle pathForResource:@"ATMOSPHERE_DAVID" ofType:@"fits"]] retain];
        
        externalFluxCalibrationFile = [[NSMutableString stringWithString:@" "] retain];
        externalRedfixCalibrationFile = [[NSMutableString stringWithString:@" "] retain];
        externalAtmosphericCalibrationFile = [[NSMutableString stringWithString:@" "] retain];
        useDefaultFluxCalibration = YES;
        useDefaultRedfixCalibration = YES;
        useDefaultAtmosphericCalibration = YES;

        // Load wavelengths of good sky lines
        goodSkyLines = [NSMutableArray arrayWithContentsOfFile:[myBundle pathForResource:@"skyLines" ofType:@"xml"]];
        [goodSkyLines retain];

        // Load spectral templates
        spectralTemplates = [[NSMutableDictionary alloc] init];
        spectralTemplateLabels = [[NSMutableArray alloc] init];
        spectralTemplatesXML = [NSArray arrayWithContentsOfFile:[myBundle pathForResource:@"templates" ofType:@"xml"]];
        e = [spectralTemplatesXML objectEnumerator];
        while (dict = [e nextObject])
        {
            NSString *file = [dict valueForKey:@"File"];
            NSString *type = [dict valueForKey:@"Type"];
            NSString *key = [dict valueForKey:@"Label"];
            [spectralTemplates setObject:[[Wave alloc] initWithFITS:[myBundle pathForResource:file ofType:type]] forKey:key];
            [spectralTemplateLabels addObject:key];
        }
        
    }
    return self;
}


- (void)dealloc
{
    [extractionWindowController release];
    [mask release];
    [super dealloc];
}



- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}



// Add any code here that need to be executed once the windowController has loaded the document's window.
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{

    NSTableColumn *tColumn;
    YesNoFormatter *boolFormatter;
    
    [super windowControllerDidLoadNib:aController];

    // Ensure each text field has *something* in it so start off by putting a single space in each. This
    // is so I can easily save the document without having to worry about looking for nil values
    // [mdfField setStringValue:@" "];
    [preimagingField setStringValue:@" "];
    [twoDSpectraField setStringValue:@" "];

    // Now restore saved values into GUI elements. All elements have picked up 
    // default values with the init method so we need to override these.
    //
    // Note that objects in the objectToSave array with indices greater than 11 
    // are initialized already, as they are set within the loadDataRepresentation:ofType:
    // method. This is because the NSController object wasn't available when iGDDS was 
    // first being developed, so the GUI elements defined early in the life of iGDDS use the 
    // outlets + target pattern of NSController. Someday I will find the time
    // to rewrite this class so everything uses NSController.
    
    if ([objectsToSave count] == 3 ){
        [preimagingField setStringValue:[objectsToSave objectAtIndex:1]];
        [twoDSpectraField setStringValue:[objectsToSave objectAtIndex:2]];
    }

    if ([objectsToSave count] == 6 ){
        [preimagingField setStringValue:[objectsToSave objectAtIndex:1]];
        [twoDSpectraField setStringValue:[objectsToSave objectAtIndex:2]];
        numberOfCombinedFrames = [[objectsToSave objectAtIndex:3] floatValue];
        normalizedFrameExposureTime = [[objectsToSave objectAtIndex:4] floatValue];
        readNoise = [[objectsToSave objectAtIndex:5] floatValue];
    }

    if ([objectsToSave count] == 12 || [objectsToSave count] == 20) {
        
        [preimagingField setStringValue:[objectsToSave objectAtIndex:1]];
        [twoDSpectraField setStringValue:[objectsToSave objectAtIndex:2]];
        numberOfCombinedFrames = [[objectsToSave objectAtIndex:3] floatValue];
        normalizedFrameExposureTime = [[objectsToSave objectAtIndex:4] floatValue];
        readNoise = [[objectsToSave objectAtIndex:5] floatValue];
        useDefaultFluxCalibration = [[objectsToSave objectAtIndex:6] intValue];
        useDefaultRedfixCalibration = [[objectsToSave objectAtIndex:7] intValue];
        useDefaultAtmosphericCalibration = [[objectsToSave objectAtIndex:8] intValue];
        NSLog(@"Read in flux cal: %d",useDefaultFluxCalibration);
        
        [externalFluxCalibrationFile setString:[objectsToSave objectAtIndex:9]];
        [fluxCalibrationField setStringValue:externalFluxCalibrationFile];

        [externalRedfixCalibrationFile setString:[objectsToSave objectAtIndex:10]];
        [redfixCalibrationField setStringValue:externalRedfixCalibrationFile];

        [externalAtmosphericCalibrationFile setString:[objectsToSave objectAtIndex:11]];
        [atmosphericCalibrationField setStringValue:externalAtmosphericCalibrationFile];
        
    }

    
    
    //Update GUI elements
    [numberOfCombinedFramesField setFloatValue:numberOfCombinedFrames];
    [normalizedFrameExposureTimeField setFloatValue:normalizedFrameExposureTime];
    [readNoiseField setFloatValue:readNoise];

    //Now do the table elements
    boolFormatter = [[YesNoFormatter alloc] init];    
    tColumn=[tableView tableColumnWithIdentifier:@"isCalibrated"];
    [[tColumn dataCell] setFormatter:boolFormatter];
    upSortImage = [[[NSTableView class] performSelector:@selector(_defaultTableHeaderSortImage)] retain];
    downSortImage = [[[NSTableView class] performSelector:@selector(_defaultTableHeaderReverseSortImage)] retain];    
    
    // Set things up so a double click on a row sends the display message on the highligted slit
    [tableView setDoubleAction:@selector(display:)];
    [self updateUI];

    //Load calibration files last because what we do depends on the GUI settings
    [self loadCalibrationFiles:nil];

}


- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    // Insert code here to write your document from the given data.
    
    [extractionWindowController storeNote]; // in case user is in the middle of editing a note in the window controller

    if (objectsToSave)
        [objectsToSave release];
    objectsToSave = [[NSMutableArray alloc] init];
    
    if (mask!=nil){
        [objectsToSave addObject:mask];                                                       //Index 0
        [objectsToSave addObject:[preimagingField stringValue]];                              //Index 1
        [objectsToSave addObject:[twoDSpectraField stringValue]];                             //Index 2
        [objectsToSave addObject:[NSNumber numberWithFloat:numberOfCombinedFrames]];          //Index 3 - v1
        [objectsToSave addObject:[NSNumber numberWithFloat:normalizedFrameExposureTime]];     //Index 4 - v1
        [objectsToSave addObject:[NSNumber numberWithFloat:readNoise]];                       //Index 5 - v1
        [objectsToSave addObject:[NSNumber numberWithInt:useDefaultFluxCalibration]];         //Index 6 - v2
        [objectsToSave addObject:[NSNumber numberWithInt:useDefaultRedfixCalibration]];       //Index 7 - v2
        [objectsToSave addObject:[NSNumber numberWithInt:useDefaultAtmosphericCalibration]];  //Index 8 - v2
        [objectsToSave addObject:externalFluxCalibrationFile];                                //Index 9 - v2
        [objectsToSave addObject:externalRedfixCalibrationFile];                              //Index 10 - v2
        [objectsToSave addObject:externalAtmosphericCalibrationFile];                         //Index 11 - v2
        [objectsToSave addObject:[NSNumber numberWithInt:len]];                               //Index 12 - v3
        [objectsToSave addObject:[NSNumber numberWithInt:slit]];                              //Index 13 - v3
        [objectsToSave addObject:[NSNumber numberWithFloat:xBin]];                            //Index 14 - v3
        [objectsToSave addObject:[NSNumber numberWithFloat:yBin]];                            //Index 15 - v3
        [objectsToSave addObject:[NSNumber numberWithInt:xOffset]];                           //Index 16 - v3
        [objectsToSave addObject:[NSNumber numberWithInt:yOffset]];                           //Index 17 - v3
        [objectsToSave addObject:[NSNumber numberWithInt:naxis1]];                            //Index 18 - v3
        [objectsToSave addObject:[NSNumber numberWithInt:naxis2]];                            //Index 19 - v3        
    }
    return [NSArchiver archivedDataWithRootObject:objectsToSave];
}


- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
    // Insert code here to read your document from the given data.
    // You can also choose to override -loadFileWrapperRepresentation:ofType: or -readFromFile:ofType: instead.
    [objectsToSave release];
    [mask release];
    objectsToSave = [[NSUnarchiver unarchiveObjectWithData:data] retain];
    NSLog(@"Unarchiving %d objects",[objectsToSave count]);
    if ([objectsToSave count] > 0)
        mask = [[objectsToSave objectAtIndex:0] retain];
    // Other objects will be extracted from the objectsToSave array in the
    // windowControllerDidLoadNib method since they rely on UI elements being
    // loaded up first.
    
    if ([objectsToSave count] == 20 ){
        
        // Note that objects in the objectToSave array with indices less than 12 
        // get initialized in the windowControllerDidLoadNib method. This is
        // because the NSController object wasn't available when iGDDS was first being
        // developed, so the GUI elements defined early in the life of iGDDS use the 
        // outlets + target pattern. Someday I will find the time to rewrite 
        // this class so everything uses NSController.
        
        len = [[objectsToSave objectAtIndex:12] intValue];
        slit = [[objectsToSave objectAtIndex:13] intValue];
        xBin = [[objectsToSave objectAtIndex:14] floatValue];
        yBin = [[objectsToSave objectAtIndex:15] floatValue];
        xOffset = [[objectsToSave objectAtIndex:16] intValue];
        yOffset = [[objectsToSave objectAtIndex:17] intValue];
        naxis1 = [[objectsToSave objectAtIndex:18] intValue];
        naxis2 = [[objectsToSave objectAtIndex:19] intValue];
        
    }
    
    [self updateUI];
    return YES;
}


//FITS access convenience methods
static void reportFITSError(int status, char file[], int line)
{
    char    err_text[256];
    int     more;
    if(status) {
        fits_get_errstatus(status, err_text);
        NSLog(@"ERROR: %d -- %s\n", status, err_text);

        more = fits_read_errmsg(err_text);
        while(more) {
            NSLog(@"       %s\n", err_text);
            more = fits_read_errmsg(err_text);
        }
        NSLog(@"       detected in %s:%d\n", file, line);
    }
    return;
}


static void getBaseName(char pathname[], char base[])
{
    char  *openbracket_ptr;
    char  *start_ptr;
    char  *dot_ptr;
    char  *slash_ptr;

    /* Filter criteria follow the URL and are contained in  */
    /* pairs of square brackets "[]".  Chop the string at   */
    /* the left most open bracket if one is found.          */
    openbracket_ptr = index(pathname, '[');
    if (openbracket_ptr) {
        /* Replace "[" with terminator */
        openbracket_ptr[0] = '\0';
    }

    slash_ptr = rindex(pathname, '/');
    if (slash_ptr) {
        /* The start of the "good part" follows the the     */
        /* rightmost "/"                                    */
        start_ptr = &slash_ptr[1];
    }
    else {
        start_ptr = pathname;
    }

    strcpy(base, start_ptr);
    dot_ptr   =  index(base, '.');
    if (dot_ptr) {
        /* Replace "." with terminator */
        dot_ptr[0] = '\0';
    }
}



//Accessor methods
idAccessor(mask, setMask)
boolAccessor(extractionWindowControllerHasBeenDisplayedBefore,setExtractionWindowControllerHasBeenDisplayedBefore);
idAccessor(fluxCalibrationWave,setFluxCalibrationWave)
idAccessor(redEndCorrectionWave,setRedEndCorrectionWave)
idAccessor(atmosphericTransmissionWave,setAtmosphericTransmissionWave)
idAccessor(goodSkyLines, setGoodSkyLines)
idAccessor(spectralTemplates, setSpectralTemplates)
idAccessor(spectralTemplateLabels, setSpectralTemplateLabels)

//Added in version 1
floatAccessor(numberOfCombinedFrames,setNumberOfCombinedFrames)
floatAccessor(normalizedFrameExposureTime,setNormalizedFrameExposureTime)
floatAccessor(readNoise,setReadNoise)

//Added in version 2
boolAccessor(useDefaultFluxCalibration,setUseDefaultFluxCalibration);
boolAccessor(useDefaultRedfixCalibration,setUseDefaultRedfixCalibration);
boolAccessor(useDefaultAtmosphericCalibration,setUseDefaultAtmosphericCalibration);
idAccessor(externalFluxCalibrationFile,setExternalFluxCalibrationFile);
idAccessor(externalRedfixCalibrationFile,setExternalRedfixCalibrationFile);
idAccessor(externalAtmosphericCalibrationFile,setExternalAtmosphericCalibrationFile);


@end
