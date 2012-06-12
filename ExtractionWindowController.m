#import "ExtractionWindowController.h"
#import "MyDocument.h"

#define FRAMESCALE 4.40
#define REDSHIFTTABFRAMESCALE 3.29

@implementation ExtractionWindowController


#pragma mark
#pragma mark DOCUMENT INPUT/OUTPUT

-(IBAction) saveDocument:(id)sender
{
    [[self document] saveDocument:nil];
}


-(IBAction) saveDocumentAs:(id)sender
{
    [[self document] saveDocumentAs:nil];
}


#pragma mark
#pragma mark FITS INPUT/OUTPUT METHODS

- (IBAction)importFITSCalibration:(id)sender
{
    NSArray *fileTypes = [NSArray arrayWithObject:@"fits"];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    WavelengthCalibrator *wc = [[self theSlit] wavelengthCalibrator];
    Wave *wavelengthCalibrationWave;
    NSMutableArray *sl = (NSMutableArray *)[[self document] goodSkyLines];
    int result, i;

    //Put up a file browser and let the user select a file
    [oPanel setAllowsMultipleSelection:NO];
    result = [oPanel runModalForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:RGAInputFileLocationKey]
                                     file:nil
                                    types:fileTypes];
    if (result == NSOKButton) {
        WavelengthCalibrator *cal = [[self theSlit] wavelengthCalibrator];

        NSArray *filesToOpen = [oPanel filenames];
        NSString *aFile = [filesToOpen objectAtIndex:0];
        wavelengthCalibrationWave = [[Wave alloc] initWithFITS:aFile];
        NSLog(@"Wavelength calibration wave: %@",wavelengthCalibrationWave);

        for(i=0;i<[sl count];i++){
            [wc addReferencePointAtCCDPosition:(float)[wavelengthCalibrationWave dindexAtX:[[sl objectAtIndex:i] floatValue] outOfRangeValue:-1000.0]-1.0
                                withWavelength:(float)[[sl objectAtIndex:i] floatValue]];
        }
        [wavelengthCalibrationTableView reloadData];
        [cal setNCoeff:5];
        [orderField setIntValue:[cal nCoeff]];
        if([[[self theSlit] wavelengthCalibrator] numberOfReferencePoints]>=2){
            [self updateWavelengthCalibrationSolution:nil];
            [self plotWavelengthSolution:nil];
        }
        [self refreshPlots:nil];
        [[self document] updateChangeCount:NSChangeDone];
        [wavelengthCalibrationWave release];
    }

}



- (IBAction)saveSpectrumAsFITS:(id)sender
{
    int npts;
    int ncalpts;
    RGAPoint *pointBytes;
    NSString *shortfilename;
    NSString *dir;
    NSString *filename;
    float *x,*y,*yopt,*ysky,*lambda;
    float crpix=0.0,crval=0.0,cdelt=0.0;
    int i;
    int status;

    //Make sure we've got the latest extraction
    [self extract:nil];
    
    //Preliminary setup
    npts = [[[self theSlit] spec] nPoints];
    ncalpts = [[[self theSlit] wavelengthCalibrator] numberOfReferencePoints];
    shortfilename = [NSString stringWithFormat:@"%d.fits",[[self theSlit] objectNumber]];
    dir = [[NSUserDefaults standardUserDefaults] objectForKey:RGAOutputFileLocationKey];
    filename = [[dir stringByAppendingString:@"/"]
                stringByAppendingString:[[[NSUserDefaults standardUserDefaults] objectForKey:RGAOutputFilePrefixKey]
                stringByAppendingString:shortfilename]];
    //NSLog(@"How's this filename?: %@\n",filename);
    //NSLog(@"Attempting to save %d data points in a FITS file\n",npts);
    
    pointBytes = (RGAPoint *)[[[[self theSlit] spec] data] bytes];
    y = (float *) malloc(npts*sizeof(float));
    for(i=0;i<npts;i++){
        *(y+i) = pointBytes[i].y;
    }

    pointBytes = (RGAPoint *)[[[[self theSlit] optimallyExtractedSpectrum] data] bytes];
    yopt = (float *) malloc(npts*sizeof(float));
    for(i=0;i<npts;i++){
        *(yopt+i) = pointBytes[i].y;
    }

    pointBytes = (RGAPoint *)[[[[self theSlit] skySpec] data] bytes];
    ysky = (float *) malloc(npts*sizeof(float));
    for(i=0;i<npts;i++){
        *(ysky+i) = pointBytes[i].y;
    }

    pointBytes = (RGAPoint *)[[[[self theSlit] spec] data] bytes];
    x = (float *) malloc(npts*sizeof(float));
    for(i=0;i<npts;i++){
        *(x+i) = pointBytes[i].x;
    }

    pointBytes = (RGAPoint *)[[[[self theSlit] spec] data] bytes];
    lambda = (float *) malloc(npts*sizeof(float));
    if ([[[self theSlit] wavelengthCalibrator] numberOfReferencePoints]>=2){
        [self updateWavelengthCalibrationSolution:nil];
        for(i=0;i<npts;i++){
            *(lambda+i) = [[[self theSlit] wavelengthCalibrator] wavelengthAtCCDPosition:pointBytes[i].x];
        }
    }
    else{
        for(i=0;i<npts;i++){
            *(lambda+i) = 0.0;
        }

    }

    //work out el-crude-o linear wavelength cal if that is possible
    if(ncalpts>=2){
        crpix = [[[self theSlit] wavelengthCalibrator] ccdPosition:0]-*x; //the crpix keyword is in logical, not physical coords
        crval = [[[self theSlit] wavelengthCalibrator] wavelength:0];
        cdelt = fabs([[[self theSlit] wavelengthCalibrator] wavelength:1] - [[[self theSlit] wavelengthCalibrator] wavelength:0]);
        cdelt /= abs([[[self theSlit] wavelengthCalibrator] ccdPosition:1]-[[[self theSlit] wavelengthCalibrator] ccdPosition:0]);
    }

    // Use this to write out a multi-extension FITS file with WCS information stored as an explicit look-up table:
    //
    writefloatspec((char *) [filename UTF8String], x, y, yopt, ysky, lambda,
                   (float *)[[self fits] pixelData],
                   (float *)[[self segWithMasks] pixelData],(float *)[[self weights] pixelData],
                   (long)npts, (long)[[self fits] nx],(long)[[self fits] ny],crval,crpix,cdelt,&status);

    // Use this to write out a simple FITS spectrum with WCS information encoded as a Legendre polynomial:
    //savespectrum((char *) [filename cString], npts, y, -32,
    //             1-[(WavelengthCalibrator *)[[self theSlit] wavelengthCalibrator] pMin],
    //             [(WavelengthCalibrator *)[[self theSlit] wavelengthCalibrator] pMin],
    //             [(WavelengthCalibrator *)[[self theSlit] wavelengthCalibrator] pMax],
    //             [(WavelengthCalibrator *)[[self theSlit] wavelengthCalibrator] coefficients],
    //             [(WavelengthCalibrator *)[[self theSlit] wavelengthCalibrator] nCoeff]);

    free(x);
    free(y);
    free(yopt);
    free(ysky);
    free(lambda);

}


- (IBAction) exportTheRedshiftTabSpectrumToAFITSFile:(id)sender
{

    NSSavePanel *sPanel = [NSSavePanel savePanel];
    NSString *shortfilename = [NSString stringWithFormat:@"%d_final.fits",[[self theSlit] objectNumber]];
    [sPanel beginSheetForDirectory:@""
                              file:shortfilename
                    modalForWindow:[self window]
                     modalDelegate:self
                    didEndSelector:@selector(didEndSaveFITSSaveSheet:returnCode:contextInfo:)
                       contextInfo:(void *)[self theSlit]];
}


#pragma mark
#pragma mark ASCII IMPORT/EXPORT

- (IBAction) exportTheRedshiftTabSpectrumToAnASCIIFile:(id)sender
{

    NSSavePanel *sPanel = [NSSavePanel savePanel];
    NSString *shortfilename = [NSString stringWithFormat:@"%d_final.txt",[[self theSlit] objectNumber]];
    [sPanel beginSheetForDirectory:@""
                              file:shortfilename
                    modalForWindow:[self window]
                     modalDelegate:self
                    didEndSelector:@selector(didEndSaveASCIISaveSheet:returnCode:contextInfo:)
                       contextInfo:(void *)[self theSlit]];
}


#pragma mark
#pragma mark MANIPULATION OF GUI ELEMENTS


- (IBAction) toggleExternalSpectrum:(id)sender{

    if([sender state]==NSOnState){
        [[self theSlit] setUseCompanionSpectrum:YES];
        [redshiftTabUseOptimalExtractionButton setState:NSOffState];
        [redshiftTabShowSkyButton setState:NSOffState];
        [redshiftTabUseOptimalExtractionButton setEnabled:NO];
        [redshiftTabShowSkyButton setEnabled:NO];
    }
    else{
        [[self theSlit] setUseCompanionSpectrum:NO];
        [redshiftTabUseOptimalExtractionButton setState:NSOffState];
        [redshiftTabShowSkyButton setState:NSOffState];
        [redshiftTabUseOptimalExtractionButton setEnabled:YES];
        [redshiftTabShowSkyButton setEnabled:YES];
    }

    [self plotTheRedshiftTabSpectrum:nil];
}


- (IBAction)apertureChanged:(id)sender
{
    [[self theSlit] setNeedsExtraction:YES];
    [doItButton setKeyEquivalent:@"\r"];
    [self refreshImagesQuickly:nil];
}



//Logic for what buttons are allowed to be on goes here
- (void) validateButtons{

    //Should the Do It! button throb?
    if ([[self theSlit] needsExtraction]==YES){
        [doItButton setKeyEquivalent:@"\r"];
    }
    else{
        [doItButton setKeyEquivalent:@""];
    }

    //If wavelength calibration doesn't exist we can't select it and flux calibration is not possible
    if ([[[self theSlit] wavelengthCalibrator] numberOfReferencePoints]>=2){
        [useWavelengthsButton setEnabled:YES];
        [useFluxCalibrationButton setEnabled:YES];
        [useRedEndCorrectionButton setEnabled:YES];

    }
    else{
        [useWavelengthsButton setEnabled:NO];
        [useFluxCalibrationButton setEnabled:NO];
        [useRedEndCorrectionButton setEnabled:NO];
    }

    //If wavelength calibration is not selected we can't select flux calibration
    if ([useWavelengthsButton state]==NSOnState){
        [useFluxCalibrationButton setEnabled:YES];
        [useRedEndCorrectionButton setEnabled:YES];
    }
    else{
        [useFluxCalibrationButton setEnabled:NO];
        [useRedEndCorrectionButton setEnabled:NO];
    }

}


- (IBAction)autoScale:(id)sender
{
    [minField setFloatValue:[fits min]];
    [maxField setFloatValue:[fits max]];
    [self refreshImages:nil];
}

- (IBAction)highContrastObject:(id)sender
{
    [maxField setFloatValue:2.0];
    [minField setFloatValue:-2.0];
    [imageTypeMatrix selectCellWithTag:0];
    [self refreshImages:nil];
}


- (IBAction)mediumContrastObject:(id)sender
{
    [maxField setFloatValue:5.0];
    [minField setFloatValue:-5.0];
    [imageTypeMatrix selectCellWithTag:0];
    [self refreshImages:nil];
}


- (IBAction)lowContrastObject:(id)sender
{
    [maxField setFloatValue:50.0];
    [minField setFloatValue:-50.0];
    [imageTypeMatrix selectCellWithTag:0];
    [self refreshImages:nil];
}


- (IBAction)highContrastSky:(id)sender
{
    [maxField setFloatValue:2.0];
    [minField setFloatValue:-2.0];
    [imageTypeMatrix selectCellWithTag:1];
    [self refreshImages:nil];
}


- (IBAction)mediumContrastSky:(id)sender
{
    [maxField setFloatValue:5.0];
    [minField setFloatValue:-5.0];
    [imageTypeMatrix selectCellWithTag:1];
    [self refreshImages:nil];
}


- (IBAction)lowContrastSky:(id)sender
{
    [maxField setFloatValue:100.0];
    [minField setFloatValue:-100.0];
    [imageTypeMatrix selectCellWithTag:1];
    [self refreshImages:nil];
}

- (IBAction) zapAperture:(id)sender
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    //NSLog(@"Zapping aperture and replacing it with a default one...");
    [nc removeObserver:[theImageView aperture]];
    [[[self theSlit] aperture] release];
    [[self theSlit] setAperture:[[NodAndShuffleAperture alloc] init]];
    [self loadAperture];
    [theImageView setNeedsDisplay:YES];
    [theScrollingImageView setNeedsDisplay:YES];
    [[self theSlit] setNeedsExtraction:YES];
    [doItButton setKeyEquivalent:@"\r"];
    [self refreshImages:nil];
}

- (IBAction) updateMarkers:(id)sender
{
    [[self theSlit] setStartMarkerWavelength:[statisticsTabStartMarkerWavelengthField floatValue]];
    [[self theSlit] setEndMarkerWavelength:[statisticsTabEndMarkerWavelengthField floatValue]];
}


- (IBAction)setTrialRedshift:(id)sender
{
    float redshift;
    redshift = [redshiftTabTrialRedshiftField floatValue];
    [[[thePlotView mainLayerData] objectAtIndex:2] setRedshift:redshift];
    //[[self theSlit] setRedshift:redshift];
    [self refreshPlots:nil];
}


- (void)updateLastMouseClickInformation:(NSNotification *)instruction
{
    int x,y;
    //int xCCD, yCCD;
    int yCCD;
    float val;

    //NSLog(@"Attempting to update mouse click information\n");

    //Only update clicks in the scrolling window so simply return if
    //some other view has posted the notification.
    if ([instruction object] != theScrollingImageView)
        return;

    x = ([(FITSImageView *)[instruction object] x]/[(FITSImageView *)[instruction object] scaling]);
    y = ([(FITSImageView *)[instruction object] y]/[(FITSImageView *)[instruction object] scaling]);

    // Stuff to be aware of if you want to use CCD units:
    // Note X is reversed because we decided we wanted blue to be on the left for
    // the displayed 2D spectral image. And we must add an offset to y because we
    // are only displaying a strip across the spectral direction. So we need
    // to change to the physical coordinates. Final, note we will report X,Y
    // coordinates in the standard IRAF/ds9 unit-offset system so we'll need
    // to subtract 1 from the X and Y positions from the reported values when
    // accessing the pixels in the stored array.
    xCCD = [fits nx]-x;
    yCCD = [self yOffsetCCD]+y;

    val = [fits value:x :y];
    //[xField setFloatValue:xCCD];
    //[yField setFloatValue:yCCD];
    [xField setFloatValue:x];
    [yField setFloatValue:y];
    [valField setFloatValue:val];
}



- (void)drawScrollingViewBoundsInStickyView:(NSNotification *)instruction{
    NSScrollView *sv = (NSScrollView *) [[theScrollingImageView superview] superview];
    NSRect b = [[sv contentView] bounds];
    float ppxu = [theScrollingImageView pPXUnit];
    float ppyu = [theScrollingImageView pPYUnit];
    Guide *g;
    if (![theImageView objectsToDraw]){
        [theImageView setObjectsToDraw:[[[NSMutableArray alloc] init] autorelease]];
        [[theImageView objectsToDraw] addObject:[[[Guide alloc] initWithView:theImageView] autorelease]];
    }
    g = [[theImageView objectsToDraw] objectAtIndex:0];
    [g setLeft:b.origin.x/ppxu];
    [g setRight:(b.origin.x/ppxu+b.size.width/ppxu)];
    [g setBottom:b.origin.y/ppyu];
    [g setTop:(b.origin.y/ppyu+b.size.height/ppyu)];
    [theImageView setNeedsDisplay:YES];
}


- (IBAction) toggleTheRedshiftPlotHoldState:(id)sender{
    if([theRedshiftPlotView hold]){
        [theRedshiftPlotView setHold:NO];
        [sender setTitle:@"Hold Plot Range"];
    }
    else{
        [theRedshiftPlotView setHold:YES];
        [sender setTitle:@"Free Plot Range"];
    }
}


- (IBAction) storeRedshiftAndGrade:(id)sender
{
    [[self theSlit] setRedshift:[notesTabFinalAssignedRedshiftField floatValue]];
    [[self theSlit] setGrade:[notesTabConfidenceGradeField intValue]];
}

- (IBAction) storeCompanionWaveInformation:(id)sender
{
    [[self theSlit] setNumberOfCombinedFramesInCompanionSpectrum:[redshiftTabExternalSpectrumNumberOfCombinedFramesField intValue]];
}

//Explicitly parks the text in the notes textTextView into the slit object
- (void)storeNote{
    NSRange range = NSMakeRange(0, [[notesTextView textStorage] length]);
    [self storeRedshiftAndGrade:nil];
    [[self theSlit] setNotes:[NSArchiver archivedDataWithRootObject:[notesTextView RTFDFromRange:range]]];
}


//Delegate methods for the notesTextView NSTextView

//This is basically unreliable, as what constitutes the end of editing does not include a
//bunch of things like clicking on a tab (basically what constitutes editing would seem
//to be changing the firstResponder for the window). So I have to take some extra steps
//to make sure the note is stored, by triggering [self storeNote] upon saving the document
//and upon closing the window.
- (void)textDidEndEditing:(NSNotification *)aNotification
{
    [self storeNote];
}

- (void)textDidChange:(NSNotification *)aNotification
{
    [[self document] updateChangeCount:NSChangeDone];
}




//Delegate methods for the main NSTableView
- (void)tabView:(NSTabView*)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem;
{
    int i;

    //Redshift Tab
    if([[tabViewItem label] isEqualToString:@"Redshift"]){

        if ([[[self theSlit] wavelengthCalibrator] numberOfReferencePoints]>=2){
            [self plotTheRedshiftTabSpectrum:nil];
        }
        else{
            //No wavelength calibration exists. Clear plots
            [[self theRedshiftPlotView] setShouldDrawFrameBox:NO];
            [[self theRedshiftPlotView] setShouldDrawAxes:NO];
            [[self theRedshiftPlotView] setShouldDrawMajorTicks:NO];
            [[self theRedshiftPlotView] setShouldDrawMinorTicks:NO];
            [[self theRedshiftPlotView] setShouldDrawGrid:NO];
            for(i=0;i<[[[self theRedshiftPlotView] mainLayerData] count];i++)
                [[[[self  theRedshiftPlotView] mainLayerData] objectAtIndex:i] setShowMe:NO];
            for(i=0;i<[[[self theRedshiftPlotView] secondaryLayerData] count];i++)
                [[[[self  theRedshiftPlotView] secondaryLayerData] objectAtIndex:i] setShowMe:NO];
            [[self  theRedshiftPlotView] refresh];
        }
    }

    //Extraction Tab
    if([[tabViewItem label] isEqualToString:@"Extraction"]){

        if ([[[self theSlit] wavelengthCalibrator] numberOfReferencePoints]>=2){
			[[self  theWavelengthSolutionPlotView] refresh];
        }
        else{
            //No wavelength calibration exists. Clear plots
            [[self theWavelengthSolutionPlotView] setShouldDrawFrameBox:NO];
            [[self theWavelengthSolutionPlotView] setShouldDrawAxes:NO];
            [[self theWavelengthSolutionPlotView] setShouldDrawMajorTicks:NO];
            [[self theWavelengthSolutionPlotView] setShouldDrawMinorTicks:NO];
            [[self theWavelengthSolutionPlotView] setShouldDrawGrid:NO];
            for(i=0;i<[[[self theWavelengthSolutionPlotView] mainLayerData] count];i++)
                [[[[self  theWavelengthSolutionPlotView] mainLayerData] objectAtIndex:i] setShowMe:NO];
            for(i=0;i<[[[self theWavelengthSolutionPlotView] secondaryLayerData] count];i++)
                [[[[self  theWavelengthSolutionPlotView] secondaryLayerData] objectAtIndex:i] setShowMe:NO];
            [[self  theWavelengthSolutionPlotView] refresh];
        }
    }
}


#pragma mark
#pragma mark EXTERNAL SPECTRA

- (IBAction)importExternalSpectrumWave:(id)sender
{
    int          result;
    NSMutableArray  *fileTypes;
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    NSString *message0,*message1,*message2;
    
    // User has requested a file browser
    fileTypes = [[[NSMutableArray alloc] init] autorelease];
    [fileTypes addObject:@"txt"];
    [fileTypes addObject:@"fits"];
    [oPanel setAllowsMultipleSelection:NO];
    result = [oPanel runModalForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:RGAInputFileLocationKey] file:nil types:fileTypes];
    if (result == NSOKButton) {
        NSArray *filesToOpen = [oPanel filenames];
        NSString *aFile = [filesToOpen objectAtIndex:0];
        message0 = [NSString stringWithString:@"An external spectrum has been stored and associated with this slit.\n"];
        message1 = [NSString stringWithFormat:@"It was stored on %@ and its filename was %@",[[NSDate date] description],aFile];
        message2 = [message0 stringByAppendingString:message1];
        [[[self theSlit] companionSpectrumDictionary] takeValue:message2 forKey:@"Message"];
        if([[aFile pathExtension] isEqualTo:@"fits"])
            [[self theSlit] setCompanionSpectrumWave:[[Wave alloc] initWithFITS:aFile]];
        else
            [[self theSlit] setCompanionSpectrumWave:[[Wave alloc] initWithTextFile:aFile xColumn:0 yColumn:10]];
        NSLog(@"%@",[[self theSlit] companionSpectrumWave]);
        [redshiftTabExternalSpectrumField setStringValue:[[[self theSlit] companionSpectrumDictionary] valueForKey:@"Message"]];
        [redshiftTabUseExternalSpectrumButton setEnabled:YES];
    }

}


#pragma mark
#pragma mark UPDATE VIEWS

- (void)updateRedshiftTabSpectrumOnNotification:(NSNotification *)aNotification
{
    [self plotTheRedshiftTabSpectrum:nil];
}    


- (IBAction) updateWavelengthCalibrationSolution:(id)sender
{
    WavelengthCalibrator *cal = [[self theSlit] wavelengthCalibrator];
    NSMutableData *coeffData;
    double *coeffs;
    int i;

    [cal setNCoeff:[orderField intValue]];
    [cal setPMin:(int)[[theImageView aperture] getWCSPoint:0].x];
    [cal setPMax:(int)[[theImageView aperture] getWCSPoint:3].x];
    if ([cal numberOfReferencePoints]>=2){
        [cal solve];
        if([cal solutionExists]){
            [[self theSlit] setIsCalibrated:YES];
        }
        else{
            [[self theSlit] setIsCalibrated:NO];
        };
        [rmsField setStringValue:[NSString stringWithFormat:@"RMS: %.2f Angstrom",[cal rms]]];

        //Calibrate the stored Waves.
        coeffs = (double *)malloc([cal nCoeff]*sizeof(double));
        for(i=0;i<[cal nCoeff];i++)
            *(coeffs + i) = [cal coefficient:i];
        coeffData = [[NSMutableData alloc] init];
        [coeffData appendBytes:coeffs length:([cal nCoeff]*sizeof(double))];
        [[[self theSlit] spectrumWave] setScaleWithCoefficients:coeffData
                                                          order:([cal nCoeff]-1)
                                                             p0:0
                                                           pMin:0.0
                                                           pMax:([[[self theSlit] spectrumWave] n]-1)];
        [coeffData release];
        [self plotWavelengthSolution:nil];
        free(coeffs);
    }
}


// Refreshes all plots
- (IBAction)refreshPlots:(id)sender{

    //Make sure button state is consistent
    [self validateButtons];

    //Should we display a sky spectrum on the plot view?
    if([showSkyButton state]==NSOnState){
        [[[thePlotView mainLayerData] objectAtIndex:1] setShowMe:YES];
    }
    else{
        [[[thePlotView mainLayerData] objectAtIndex:1] setShowMe:NO];
    }

    //The plot view
    [thePlotView setNeedsDisplay:YES];

    //The profile plot view
    [theProfilePlotView setNeedsDisplay:YES];

    //The sky calibration plot view
    [theSkyCalibrationPlotView setNeedsDisplay:YES];

}


// Refresh image without regenerating theNSImage
- (IBAction) refreshImagesQuickly:(id)sender;
{
    //The stretchy image
    [theImageView setImage:theNSImage];
    [[theImageView aperture] setGap:[gapSlider floatValue]];
    [[theImageView aperture] setDYUpper:[dYUpperSlider floatValue]];
    [[theImageView aperture] setDYLower:[dYLowerSlider floatValue]];
	
	
	//The scrolling image
	//Changes made for KGB and the GLARE project --- the scrolling image view gets a copy of the aperture
    [theScrollingImageView setImage:theNSImage];
    [theScrollingImageView setAnnotationPaths:annotationPaths];
	if ([theScrollingImageView aperture])
		[[theScrollingImageView aperture] release];
	[theScrollingImageView setAperture:[[theImageView aperture] copyWithZone:NULL]]; // this is new!
	[[theScrollingImageView aperture] setShowControlPoints:NO];
	[theScrollingImageView scaleFrameBy:FRAMESCALE];
    [[theScrollingImageView aperture] setView:theScrollingImageView];
	[[theScrollingImageView aperture] setDelegate:nil];
	[[theImageView aperture] setDelegate:[theScrollingImageView aperture]];

	//Do we draw the apertures?
    if([apertureButton state]==NSOnState){
        [theImageView setShouldDrawNodAndShuffleExtractionBox:YES];
		[theScrollingImageView setShouldDrawNodAndShuffleExtractionBox:YES];
    }
    else{
        [theImageView setShouldDrawNodAndShuffleExtractionBox:NO];
		[theScrollingImageView setShouldDrawNodAndShuffleExtractionBox:NO];
    }
    [theImageView setNeedsDisplay:YES];
    [theScrollingImageView setNeedsDisplay:YES];
	
	
    //The redshift tab scrolling image
    [theRedshiftTabImageView setImage:theNSImage];
    [theRedshiftTabImageView scaleFrameBy:REDSHIFTTABFRAMESCALE];
    [theRedshiftTabImageView setShouldDrawNodAndShuffleExtractionBox:NO];
    [theRedshiftTabImageView setNeedsDisplay:YES];

	
	
}


// Refreshes all images
- (IBAction)refreshImages:(id)sender
{
    Image *tempObjectImage;
    Image *tempSkyImage;
    Image *smoothedObjectImage;

    [theNSImage release];
    imageSize.width = [fits nx];
    imageSize.height = [fits ny];
    theNSImage = [[NSImage alloc] initWithSize: imageSize];

    tempObjectImage = [fits copy];
    tempSkyImage = [skyFits copy];

    //Should we smooth the images?
    if([smoothButton state]==NSOnState){
        smoothedObjectImage =[tempObjectImage boxcar:1]; // Note that in this case smoothedObjectImage is autoreleased!
    }
    else{
        smoothedObjectImage  = tempObjectImage;
    }


    //Determine whether to display the sky image or the object image.
    if([[[imageTypeMatrix selectedCell] title] compare:@"Sky"]) {
        [theNSImage addRepresentation:[smoothedObjectImage createRepresentationWithMin:[minField floatValue]
                                                                                andMax:[maxField floatValue]]];
    }
    else{
        [theNSImage addRepresentation:[tempSkyImage createRepresentationWithMin:[minField floatValue]
                                                                         andMax:[maxField floatValue]]];
    }

    [self refreshImagesQuickly:nil];

    //Clean up
    [tempObjectImage release];
    [tempSkyImage release];

}


// Refreshes all plots and images
- (IBAction)refresh:(id)sender
{
    [self refreshPlots:nil];
    [self refreshImages:nil];
    [theRedshiftTabTemplatesTabTableViewController updateUI];
}



#pragma mark
#pragma mark INITIALIZATION

- (void)awakeFromNib
{

    NSBundle *bundle = [NSBundle mainBundle];
    NSString *pathToCribImage = [bundle pathForImageResource:@"SkyLines"];
    NSImage *cribImage;
    WavelengthCalibrator *cal = [[self theSlit] wavelengthCalibrator];

    [self loadAperture];
    [self setMasks];
    [self refreshImages:nil];
    [self setupWavelengthCalibration];
    [[self useWavelengthsButton] setState:NSOffState];

    //Restore the notes tab. We'll first clear the window in case some notes from the last object are still there.
    [notesTabFinalAssignedRedshiftField setFloatValue:[theSlit redshift]];
    [notesTabConfidenceGradeField setIntValue:[theSlit grade]];
    [[self notesTextView] replaceCharactersInRange:NSMakeRange(0, [[[self notesTextView] string] length]) withString:@""];
    if ([(NSData *)[theSlit notes] length]>0){
        //NSLog(@"Loading %d bytes",[(NSData *)[theSlit notes] length]);
        [[self notesTextView] replaceCharactersInRange:NSMakeRange(0, 0) withRTFD:[NSUnarchiver unarchiveObjectWithData:[theSlit notes]]];
    }

    //Clear the statistics tab's text view
    [[self statisticsTextView] replaceCharactersInRange:NSMakeRange(0, [[[self statisticsTextView] string] length]) withString:@""];

    //If the wavelength calibration is known, set its fields and make sure it's updated
    if ([cal nCoeff] < 0)
        [cal setNCoeff:5];
    [orderField setIntValue:[cal nCoeff]];
    if ([cal numberOfReferencePoints]>=2){
        [self updateWavelengthCalibrationSolution:nil]; 
        [rmsField setStringValue:[NSString stringWithFormat:@"RMS: %.2f Angstrom",[cal rms]]];
    }
    else{
        [rmsField setStringValue:@"RMS: Not Defined"];
    }

    //set some other stored field information
    [[self redshiftTabTrialRedshiftField] setFloatValue:[theSlit redshift]];
    [self setTrialRedshift:nil];

    //Display the crib image
    [[theCribImageView image] release];
    cribImage = [[NSImage alloc] initWithContentsOfFile:pathToCribImage];
    [theCribImageView setImage:cribImage];
    [theCribImageView setImageFrameStyle:NSImageFramePhoto];
    [theCribImageView setImageScaling:NSScaleToFit];
    [theCribImageView setNeedsDisplay:YES];

    //Spectral template
    if (!theTemplate)
        theTemplate = [[LineLabelData alloc] initWithView:thePlotView];

    //Set the guide
    if (![theImageView objectsToDraw]){
        [theImageView setObjectsToDraw:[[[NSMutableArray alloc] init] autorelease]];
        [[theImageView objectsToDraw] addObject:[[[Guide alloc] initWithView:theImageView] autorelease]];
    }

    //Make sure some critical fields are set
    if ([[self nBinField] intValue]<=0){
        [nBinField setIntValue:1];
    }

    // Set things up so a double click on a row of the sky line table sends the plotSkyLine message
    [wavelengthCalibrationTableView setAction:@selector(plotSkyLine:)];

    //Make sure we're on the extraction tab
    [theGlobalTagView selectFirstTabViewItem:(nil)];

    //Make sure the progress indicator is a wheel
    [progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
    [progressIndicator setDisplayedWhenStopped:NO];

    //External spectrum information
    [redshiftTabShowSkyButton setEnabled:YES];
    [redshiftTabExternalSpectrumField setStringValue:[[[self theSlit] companionSpectrumDictionary] valueForKey:@"Message"]];
    [redshiftTabExternalSpectrumNumberOfCombinedFramesField setIntValue:[[self theSlit] numberOfCombinedFramesInCompanionSpectrum]];

    if ([(NSString *)[[[self theSlit] companionSpectrumDictionary] valueForKey:@"Message"] isEqualTo:@"No external spectrum stored."]){
        //No companion spectrum exists so make it impossible for user to show it.
        [redshiftTabUseExternalSpectrumButton setEnabled:NO];
    }
    else{
        [redshiftTabUseExternalSpectrumButton setEnabled:YES];
        //Companion spectrum exists but may or may not be shown
        if([[self theSlit] useCompanionSpectrum]){
            [redshiftTabUseExternalSpectrumButton setState:NSOnState];
            [redshiftTabUseOptimalExtractionButton setState:NSOffState];
            [redshiftTabShowSkyButton setState:NSOffState];
            [redshiftTabUseOptimalExtractionButton setEnabled:NO];
            [redshiftTabShowSkyButton setEnabled:NO];
        }
        else{
            [redshiftTabUseExternalSpectrumButton setState:NSOffState];
        }
    }

    // Restore plots. If no plots exist then clear plot views if necessary
    if([[theSlit spec] nPoints] == 0){
        //NSLog(@"No stored plot found. Clearing the view");
        [self clearThePlotViews];
    }
    else{
        //NSLog(@"<<<< Restoring stored plots >>>>");
        [self restoreSavedPlots];
    }
    


    //NSLog(@"Leaving awakeFromNib");
}



//Put initializers here that rely on UI elements being in place. This is the place to
//send initialization messages to the window's subviews.
- (void)windowDidLoad {

    //NSLog(@"Nib file is loaded");

    [theImageView setImageScaling:NSScaleToFit];
    [theImageView setImageAlignment:NSImageAlignCenter];
    [theImageView setNeedsDisplay:YES];

    [theScrollingImageView setImageScaling:NSScaleToFit];
    [theScrollingImageView setImageAlignment:NSImageAlignCenter];
    [theScrollingImageView setPostsBoundsChangedNotifications:YES];
    [theScrollingImageView setShouldDrawMasks:YES];
    [theScrollingImageView setShouldCreateMasks:YES];
    [theScrollingImageView setNeedsDisplay:YES];

    [theRedshiftTabImageView setImageScaling:NSScaleToFit];
    [theRedshiftTabImageView setImageAlignment:NSImageAlignCenter];
    [theRedshiftTabImageView setPostsBoundsChangedNotifications:NO];
    [theRedshiftTabImageView setShouldDrawMasks:YES];
    [theRedshiftTabImageView setShouldCreateMasks:NO];
    [theRedshiftTabImageView setNeedsDisplay:YES];

}


-(void) clearThePlotViews{
    int i;
    [[self thePlotView] setShouldDrawFrameBox:NO];
    [[self thePlotView] setShouldDrawAxes:NO];
    [[self thePlotView] setShouldDrawMajorTicks:NO];
    [[self thePlotView] setShouldDrawMinorTicks:NO];
    [[self thePlotView] setShouldDrawGrid:NO];

    [[self theProfilePlotView] setShouldDrawFrameBox:NO];
    [[self theProfilePlotView] setShouldDrawAxes:NO];
    [[self theProfilePlotView] setShouldDrawMajorTicks:NO];
    [[self theProfilePlotView] setShouldDrawMinorTicks:NO];
    [[self theProfilePlotView] setShouldDrawGrid:NO];

    [[self theWavelengthSolutionPlotView] setShouldDrawFrameBox:NO];
    [[self theWavelengthSolutionPlotView] setShouldDrawAxes:NO];
    [[self theWavelengthSolutionPlotView] setShouldDrawMajorTicks:NO];
    [[self theWavelengthSolutionPlotView] setShouldDrawMinorTicks:NO];
    [[self theWavelengthSolutionPlotView] setShouldDrawGrid:NO];

    [[self theSkyLinePlotView] setShouldDrawFrameBox:NO];
    [[self theSkyLinePlotView] setShouldDrawAxes:NO];
    [[self theSkyLinePlotView] setShouldDrawMajorTicks:NO];
    [[self theSkyLinePlotView] setShouldDrawMinorTicks:NO];
    [[self theSkyLinePlotView] setShouldDrawGrid:NO];

    [[self theSkyCalibrationPlotView] setShouldDrawFrameBox:NO];
    [[self theSkyCalibrationPlotView] setShouldDrawAxes:NO];
    [[self theSkyCalibrationPlotView] setShouldDrawMajorTicks:NO];
    [[self theSkyCalibrationPlotView] setShouldDrawMinorTicks:NO];
    [[self theSkyCalibrationPlotView] setShouldDrawGrid:NO];

    [[self theRedshiftPlotView] setShouldDrawFrameBox:NO];
    [[self theRedshiftPlotView] setShouldDrawAxes:NO];
    [[self theRedshiftPlotView] setShouldDrawMajorTicks:NO];
    [[self theRedshiftPlotView] setShouldDrawMinorTicks:NO];
    [[self theRedshiftPlotView] setShouldDrawGrid:NO];

    for(i=0;i<[[[self thePlotView] mainLayerData] count];i++)
        [[[[self thePlotView] mainLayerData] objectAtIndex:i] setShowMe:NO];
    for(i=0;i<[[[self thePlotView] secondaryLayerData] count];i++)
        [[[[self thePlotView] secondaryLayerData] objectAtIndex:i] setShowMe:NO];
    [[self thePlotView] refresh];

    for(i=0;i<[[[self theProfilePlotView] mainLayerData] count];i++)
        [[[[self theProfilePlotView] mainLayerData] objectAtIndex:i] setShowMe:NO];
    for(i=0;i<[[[self theProfilePlotView] secondaryLayerData] count];i++)
        [[[[self theProfilePlotView] secondaryLayerData] objectAtIndex:i] setShowMe:NO];
    [[self theProfilePlotView] refresh];

    for(i=0;i<[[[self theWavelengthSolutionPlotView] mainLayerData] count];i++)
        [[[[self theWavelengthSolutionPlotView] mainLayerData] objectAtIndex:i] setShowMe:NO];
    for(i=0;i<[[[self theWavelengthSolutionPlotView] secondaryLayerData] count];i++)
        [[[[self theWavelengthSolutionPlotView] secondaryLayerData] objectAtIndex:i] setShowMe:NO];
    [[self theWavelengthSolutionPlotView] refresh];

    for(i=0;i<[[[self theSkyLinePlotView] mainLayerData] count];i++)
        [[[[self theSkyLinePlotView] mainLayerData] objectAtIndex:i] setShowMe:NO];
    for(i=0;i<[[[self theSkyLinePlotView] secondaryLayerData] count];i++)
        [[[[self theSkyLinePlotView] secondaryLayerData] objectAtIndex:i] setShowMe:NO];
    [[self theSkyLinePlotView] refresh];

    for(i=0;i<[[[self theRedshiftPlotView] mainLayerData] count];i++)
        [[[[self theRedshiftPlotView] mainLayerData] objectAtIndex:i] setShowMe:NO];
    for(i=0;i<[[[self theRedshiftPlotView] secondaryLayerData] count];i++)
        [[[[self theRedshiftPlotView] secondaryLayerData] objectAtIndex:i] setShowMe:NO];
    [[self theRedshiftPlotView] refresh];

}


-(void) restoreSavedPlots
{
	
    NSLog(@" ++++++ Entering restoreSavedPlots:");
    
    //Try to plot up the object and spectra. If either of these fail, clear the
	//PlotView display and don't try to restore anything.

    NSLog(@"Restoring binned spectrum plot");
	[self plotTheBinnedSpectrum:nil]; 	
	if ([[self theSlit] errorStatus])
		[self clearThePlotViews];
	else {
		
		//Editable sky spectrum
		NSLog(@"Restoring sky calibration plot");
		[self plotSkyCalibration:nil];
		
		//Profile
		NSLog(@"Restoring profile plot");
		if(!profilePlotArray)
			profilePlotArray = [[NSMutableArray alloc] init];
		[profilePlotArray removeAllObjects];
		[[[self theSlit] profile] setColor:[NSColor redColor]];
		[[[self theSlit] profile] setHistogram:YES];
		[[[self theSlit] profile] setShowMe:YES];
		[profilePlotArray addObject:[[self theSlit] profile]];
		[theProfilePlotView setMainLayerData:profilePlotArray];
		[theProfilePlotView setTopOffset:10.0];
		[theProfilePlotView setBottomOffset:20.0];
		[theProfilePlotView setShouldDrawFrameBox:YES];
		[theProfilePlotView setShouldDrawAxes:YES];
		[theProfilePlotView setShouldDrawMajorTicks:YES];
		[theProfilePlotView setShouldDrawMinorTicks:YES];
		[theProfilePlotView setShouldDrawGrid:NO];
		[theProfilePlotView setXMin:0];
		[theProfilePlotView setXMax:[fits ny]-1];
		[theProfilePlotView setXMajorIncrement:10];
		[theProfilePlotView setYMin:0.0];
		[theProfilePlotView setYMax:1.0];
		[theProfilePlotView setYMajorIncrement:0.5];
		[theProfilePlotView setTickMarkLength:-2.0];
		[theProfilePlotView setTickMarkLocation:2];
		[theProfilePlotView refresh];

		//Wavelength solution
		if([[theSlit wavelengthCalibrationReferencePoints] nPoints] < 2){
			[[self theWavelengthSolutionPlotView] setShouldDrawFrameBox:NO];
			[[self theWavelengthSolutionPlotView] setShouldDrawAxes:NO];
			[[self theWavelengthSolutionPlotView] setShouldDrawMajorTicks:NO];
			[[self theWavelengthSolutionPlotView] setShouldDrawMinorTicks:NO];
			[[self theWavelengthSolutionPlotView] setShouldDrawGrid:NO];
			[[self useWavelengthsButton] setState:NSOffState];
			
			//check for pathological case where a single line exists but no full solution
			//exists. In this case we should at least show the line profile
			if ([[theSlit wavelengthCalibrationReferencePoints] nPoints] == 1)
				[self plotSkyLine:nil];
		}
		else{
			NSLog(@"Restoring sky line plot");
			[self plotSkyLine:nil];
			NSLog(@"Restoring wavelength solution plot");
			[self plotWavelengthSolution:nil];
			[[self theWavelengthSolutionPlotView] setNeedsDisplay:YES];
		}
		NSLog(@"+++++ Leaving restoreSavedPlots:. Any plotting that comes after here is redundant");
	}
	
	[self refresh:nil];

}


- (void)loadAperture{

    //If the aperture has not been set manually, try to set it somewhere
    //sensible
    if(([[theSlit aperture] dYUpper] < 1) && ([[theSlit aperture] dYLower] < 1)){
        [[theSlit aperture] setWCSPoint:0 x:(naxis1-xCCD-700) y:25];
        [[theSlit aperture] setWCSPoint:1 x:(naxis1-xCCD-250) y:25];
        [[theSlit aperture] setWCSPoint:2 x:(naxis1-xCCD+250) y:25];
        [[theSlit aperture] setWCSPoint:3 x:(naxis1-xCCD+800) y:25];
    }
    //Tell the aperture what FITSImageView it's going to live in and embed it in the view
    [[theSlit aperture] setView:[self theImageView]];
	
    //Instruct the application's notification center to notify the aperture when a
    //specific FITSImageView sends a mouse click notification. We need to unregister this
    //later when the window gets closed or the aperture object will continue to receive
    //(and willl attempt to process) mouse clicks forever. This unregistering is taken care
    //of by the WindowController.
    [[NSNotificationCenter defaultCenter] addObserver: [theSlit aperture]
                                             selector: @selector(processMouseClick:)
                                                 name: @"FITSImageViewMouseDownNotification"
                                               object:[self theImageView]];
	
    //Embed the aperture in the view(s)
    [[self theImageView] setAperture:[theSlit aperture]];
	
	//Changes made for KGB for the GLARE project
	if ([theScrollingImageView aperture])
		[[theScrollingImageView aperture] release];
    [theScrollingImageView setAperture:[[theImageView aperture] copyWithZone:NULL]];
	[[theScrollingImageView aperture] setShowControlPoints:NO];
	[theScrollingImageView setShouldDrawNodAndShuffleExtractionBox:YES];
	[[theScrollingImageView aperture] setDelegate:nil];
	[[theImageView aperture] setDelegate:[theScrollingImageView aperture]];
	
    //Set the sliders if they've already been set, otherwise leave them alone.
    //NSLog(@"Recalling stored aperture slider positions");
    if ([[theSlit aperture] dYUpper] > 0.001 || [[theSlit aperture] dYLower] > 0.001 || [[theSlit aperture] gap] > 0.001){
        [[self dYUpperSlider] setFloatValue:[[theSlit aperture] dYUpper]];
        [[self dYLowerSlider] setFloatValue:[[theSlit aperture] dYLower]];
        [[self gapSlider] setFloatValue:[[theSlit aperture] gap]];
    }

}


-(void)setMasks{
    int i;
    for(i=0;i<[[theSlit masks] count];i++){
        [[[theSlit masks] objectAtIndex:i] setView:theScrollingImageView];
        [[NSNotificationCenter defaultCenter] addObserver: [[theSlit masks] objectAtIndex:i]
                                                 selector: @selector(processMouseClick:)
                                                     name: @"FITSImageViewMouseDownNotification"
                                                   object: theScrollingImageView];
    }
    [theScrollingImageView setMasks:[theSlit masks]];
}


-(void) setupWavelengthCalibration{
    //Set the delegate for the wavelength calibration tableview
    [[self wavelengthCalibrationTableView] setDataSource:[theSlit wavelengthCalibrator]];

    //Make sure the number of calibration points is listed correctly
    [[self calibrationInfoField] setStringValue:[NSString stringWithFormat:@"%d points stored",[[theSlit wavelengthCalibrator] numberOfReferencePoints]]];
}


#pragma mark
#pragma mark ANALYSIS

- (IBAction)extract:(id)sender{

    int nx = [fits nx];
    int ny = [fits ny];
    NSRect frame = NSMakeRect(0,0,nx,ny);
    NSData *pdfWithoutMasks,*pdfWithMasks;
    NSData *tiffWithoutMasks,*tiffWithMasks;
    NSBitmapImageRep *bitmapWithoutMasks,*bitmapWithMasks;
    int xstart,xend;
    int i,j;
	int count,status;
    float *xg, *yg, *xog, *yog, *xs, *ys, *frac, *yv, *yov;
    double *dyg, *dyog, *dyv, *dyov, *dfrac; 
    float flux,norm,variance,coefficient,ymin,ymax;
    int npts;
    float profileY[1000]={0.};
    float profileX[1000]={0.};
    int columnYStart,globalYStart;
    int nyInAperturesGlobal=0;
    int nyInApertures=0;
    float opacity;
    float readnoise = [[self theSlit] readNoise];
    int ncombine = [[self theSlit] numberOfCombinedFrames];
	NSUInteger p[4]={0,0,0,0};
	NSUInteger r,g,b,a;

    
    //start spinning progress indicator
    [progressIndicator startAnimation:nil];

    ///////////////////////////////////////////////////////////////////////////////////////
    //        CREATE TWO APERTURE SEGMENTATION IMAGES, WITH AND WITHOUT MASKS
    ///////////////////////////////////////////////////////////////////////////////////////

    //We will composite an image with the apertures to a PDF file. We need to ensure the PDF
    //has *exactly* the same dimensions as the FITS image. We will work using the scrolling
    //view since that preserves the dimensions of the original image. This means we
    //need to add the aperture to the view though, since the scrolling view does not
    //include the view by default.
    
    [theScrollingImageView scaleFrameBy:1.0];
	if ([theScrollingImageView aperture])
		[[theScrollingImageView aperture] release];
    [theScrollingImageView setAperture:[[theImageView aperture] copyWithZone:NULL]]; 
	[[theScrollingImageView aperture] setShowControlPoints:NO];
    [[theScrollingImageView aperture] setView:theScrollingImageView];
    [theScrollingImageView setShouldDrawNodAndShuffleExtractionBox:YES];

    //Set opacity of aperture and masks to 1.0 (fully opaque), so we can use simple R,G,B to do segmentation
    opacity = [[theScrollingImageView aperture] opacity];
    [[theScrollingImageView aperture] setOpacity:1.0]; 
    [theScrollingImageView setMaskOpacity:1.0];   
	
    //Segmentation image with masks
    [theScrollingImageView setShouldDrawMasks:YES];    
    pdfWithMasks = [theScrollingImageView dataWithPDFInsideRect:frame];      //Store the view as PDF data
    // [pdfWithMasks writeToFile:@"/var/tmp/bob0.pdf" atomically:YES];       //Write the PDF data to a PDF file as an aid to debugging
	tiffWithMasks=[[[NSImage alloc] initWithData:pdfWithMasks] TIFFRepresentation]; // Now the view is stored as TIFF data
	[tiffWithMasks writeToFile:@"/var/tmp/withMasks.tiff" atomically:YES];        //Write the TIFF data to a TIFF file as an aid to debugging
	bitmapWithMasks = [NSBitmapImageRep imageRepWithData:tiffWithMasks];     //Turn this into a bitmap
	if (bitmapWithMasks==nil) NSLog(@"FAILED TO CREATE MASKED IMAGE!");
		
	// SANITY CHECKS: verify basic access the data
	NSLog(@"Image is %u pixels high",[bitmapWithMasks pixelsHigh]);
    NSLog(@"Image is %u pixels wide",[bitmapWithMasks pixelsWide]);
	[bitmapWithMasks getPixel:p atX:10 y:10];
	r=p[0]; g=p[1]; b=p[2]; a=p[3];
	NSLog(@"At (10,10) the r,g,b,a value is: %u %u %u %u",r,g,b,a);

    //Segmentation image without masks
    [theScrollingImageView setShouldDrawMasks:NO];
    pdfWithoutMasks = [theScrollingImageView dataWithPDFInsideRect:frame];        //Store the view as PDF data
    // [pdfWithoutMasks writeToFile:@"/var/tmp/bob1.pdf" atomically:YES];         //Write the PDF data to a file as an aid to debugging
	tiffWithoutMasks=[[[NSImage alloc] initWithData:pdfWithoutMasks] TIFFRepresentation]; // Now the view is stored as TIFF data
	[tiffWithoutMasks writeToFile:@"/var/tmp/withoutMasks.tiff" atomically:YES];        //Write the TIFF data to a TIFF file as an aid to debugging
    bitmapWithoutMasks = [NSBitmapImageRep imageRepWithData:tiffWithoutMasks];    //Turn this into a bitmap
	if (bitmapWithoutMasks==nil) NSLog(@"FAILED TO CREATE NON-MASKED IMAGE!");

    //Reset opacity to previous value
    [[theScrollingImageView aperture] setOpacity:opacity];
    [theScrollingImageView setMaskOpacity:0.2]; 
    
    //Create the segmen�tation images here. This object (segWithMasks) has values of -1, 0, 1.
    if(!segWithMasks){
        segWithMasks = [[Image alloc] initWithValue:0.0 nx:[fits nx] ny:[fits ny]];
    }
    else{
        [segWithMasks clear];
    }

    if(!segWithoutMasks){
        segWithoutMasks = [[Image alloc] initWithValue:0.0 nx:[fits nx] ny:[fits ny]];
    }
    else{
        [segWithoutMasks clear];
    }
    xstart = [[theImageView aperture] getWCSPoint:0].x;
    xend = [[theImageView aperture] getWCSPoint:3].x;
    if (xstart<0)
        xstart = 0;
    if (xend > nx-1)
        xend = nx-1;
    for(i=xstart;i<xend;i++){
        for(j=0;j<ny;j++){

			[bitmapWithMasks getPixel:p atX:i y:j];
			r=p[0]; g=p[1]; b=p[2]; a=p[3];

            if (r==253 && g==255 && b == 0)                 // Not sure why it's 253 instead of 255...
                [segWithMasks setValue:-1 x:i y:(ny-j-1)];  // note y-axis flip
            if (r==255 && g==0   && b == 255)
                [segWithMasks setValue:1 x:i y:(ny-j-1)];   // note y-axis flip
            
            //without masks
			[bitmapWithoutMasks getPixel:p atX:i y:j];
			r=p[0]; g=p[1]; b=p[2]; a=p[3];
            if (r==253 && g==255 && b == 0)                    // Not sure why it's 253 instead of 255...
                [segWithoutMasks setValue:-1 x:i y:(ny-j-1)];  // note y-axis flip
            if (r==255 && g==0   && b == 255)
                [segWithoutMasks setValue:1 x:i y:(ny-j-1)];   // note y-axis flip
        }
    }
	    
    //Restore the status quo ante. Remember the aperture is now being shared by two views
    //so make sure it is picking up mouse events from the right view.
    [[theImageView aperture] setView:theImageView];
    [theScrollingImageView setShouldDrawMasks:YES];    
    [theScrollingImageView scaleFrameBy:FRAMESCALE];
	if ([theScrollingImageView aperture])
		[[theScrollingImageView aperture] release];
    [theScrollingImageView setAperture:[[theImageView aperture] copyWithZone:NULL]]; // New for KGB and GLARE. This used to be set to nil so nothing was drawn.
	[[theScrollingImageView aperture] setShowControlPoints:NO];
    [[theScrollingImageView aperture] setView:theScrollingImageView];
    [theScrollingImageView setShouldDrawNodAndShuffleExtractionBox:YES]; // New for KGB and GLARE. This used to be set to nil so nothing was drawn.
	[[theScrollingImageView aperture] setDelegate:nil];
	[[theImageView aperture] setDelegate:[theScrollingImageView aperture]];
	
    //Refresh the views.
    [theScrollingImageView setNeedsDisplay:YES];
    [theImageView setNeedsDisplay:YES];


    ///////////////////////////////////////////////////////////////////////////////////////
    //        CREATE AND PLOT THE OPTIMAL EXTRACTION PROFILE WEIGHTING ARRAY
    ///////////////////////////////////////////////////////////////////////////////////////

    // We create profileY here. This is always positive.
    globalYStart = 0;
    for(i=0;i<ny;i++) profileX[i]=i;
    for(i=xstart;i<xend;i++){
        columnYStart = 0;
        for(j=0;j<ny;j++){
            if([segWithoutMasks value:i :j] != 0){
                //determine Y offset of first point in a mask... all indices are relative to this
                if (globalYStart == 0){
                    globalYStart = j;
                }
                //determine Y offset of first point in this particular column
                if (columnYStart == 0){
                    columnYStart = j;
                }
                profileY[j + (globalYStart - columnYStart)]+=[fits value:i :j]*abs([segWithMasks value:i :j]);
            }
        }
    }

    // normalize the profile to lie within the range (0,+1)
    ymin =  1.e30;
    ymax = -1.e30;
    for(i=0;i<ny;i++){
        if (profileY[i]>ymax) ymax=profileY[i];
        if (profileY[i]<ymin) ymin=profileY[i];
    }
    for(i=0;i<ny;i++){
        if (profileY[i]>0.0) profileY[i]=profileY[i]/ymax;
        if (profileY[i]<0.0) profileY[i]=profileY[i]/ymin;
    }
        
    // work out how much of the spectral direction is actually occupied by an aperture. This is
    // only approximate for a given column due to pixellation of the bezier curves.
    nyInAperturesGlobal = 0;
    for(i=0;i<ny;i++){
        if(fabs(profileY[i])>1e-10){
            nyInAperturesGlobal++;
        }
    }

    //load profile data into the Line objects
    [[[self theSlit] profile] loadDataPoints:ny withXValues:profileX andYValues:profileY];
    [[[self theSlit] profile] setColor:[NSColor redColor]];
    [[[self theSlit] profile] setHistogram:YES];
    [[[self theSlit] profile] setShowMe:YES];

    //store the Line objects in an array and store this array in the Plot object
    [profilePlotArray removeAllObjects];
    [profilePlotArray addObject:[[self theSlit] profile]];
    [theProfilePlotView setMainLayerData:profilePlotArray];

    //draw the profile
    [theProfilePlotView setTopOffset:10.0];
    [theProfilePlotView setBottomOffset:20.0];
    [theProfilePlotView setShouldDrawFrameBox:YES];
    [theProfilePlotView setShouldDrawAxes:YES];
    [theProfilePlotView setShouldDrawMajorTicks:YES];
    [theProfilePlotView setShouldDrawMinorTicks:YES];
    [theProfilePlotView setShouldDrawGrid:NO];
    [theProfilePlotView setXMin:0];
    [theProfilePlotView setXMax:ny-1];
    [theProfilePlotView setXMajorIncrement:10];
    [theProfilePlotView setYMin:0.0];
    [theProfilePlotView setYMax:1.0];
    [theProfilePlotView setYMajorIncrement:0.5];
    [theProfilePlotView setTickMarkLength:-2.0];
    [theProfilePlotView setTickMarkLocation:2];

    //refresh the view
    [theProfilePlotView refresh]; //so cache is drawn
    [theProfilePlotView setNeedsDisplay:YES];


    ///////////////////////////////////////////////////////////////////////////////////////
    //                      CREATE THE WEIGHTS IMAGE
    ///////////////////////////////////////////////////////////////////////////////////////
    
    // Note that the weights image (weights) has values between 0 and 1.
    if (!weights)
        weights = [[Image alloc] initWithValue:0.0 nx:[fits nx] ny:[fits ny]];
    globalYStart = 0;
    for(i=xstart;i<xend;i++){
        columnYStart = 0;
        for(j=0;j<ny;j++){
            if([segWithoutMasks value:i :j] != 0){
                //determine Y offset of first point in a mask... all indices are relative to this
                if (globalYStart == 0){
                    globalYStart = j;
                }
                //determine Y offset of first point in this particular column
                if (columnYStart == 0){
                    columnYStart = j;
                }
				if (abs([segWithMasks value:i :j]) > 0.000001)
					[weights setValue:profileY[j + (globalYStart - columnYStart)] x:i y:j];
            }
        }
    }    
   
    ///////////////////////////////////////////////////////////////////////////////////////
    //                   CREATE A BUNCH OF IMAGES USEFUL FOR DEBUGGING
    ///////////////////////////////////////////////////////////////////////////////////////
	[segWithMasks saveFITS:@"!/var/tmp/withMasks.fits"];
	[segWithoutMasks saveFITS:@"!/var/tmp/withoutMasks.fits"];
	[fits saveFITS:@"!/var/tmp/data.fits"];
	[weights saveFITS:@"!/var/tmp/weights.fits"];
	

    ///////////////////////////////////////////////////////////////////////////////////////
    //                   CREATE THE LINEARLY-EXTRACTED OBJECT SPECTRUM
    ///////////////////////////////////////////////////////////////////////////////////////
    
    npts=(xend-xstart);
    count = 0;
    xg = (float *) malloc(npts*sizeof(float));
    yg = (float *) malloc(npts*sizeof(float));
    yv = (float *) malloc(npts*sizeof(float));
    frac = (float *) malloc(npts*sizeof(float));
    ymin =  1.e30;
    ymax = -1.e30;
    for(i=xstart;i<xend;i++){
        *(xg + count) = i;
        flux = 0.;
        norm = 0.;
        variance = 0.;
        nyInApertures = 0;
        for(j=0;j<ny;j++){
            //sum over column using Karl's algorithm for weighting
            flux += [fits value:i :j]*[segWithMasks value:i :j];
            variance += (2.0*[skyFits value:i :j]/ncombine + pow(readnoise,2.0))*abs([segWithMasks value:i :j]);
            nyInApertures += abs([segWithoutMasks value:i :j]);
            norm += abs([segWithMasks value:i :j]);
        }
        if (norm>1e-20){ // effectively zero... just some tiny number to avoid floating point funnies
            flux /= norm; //flux is now the average of non-rejected pixels
            flux *= nyInApertures;   //flux is now normalised to what the sum would be if all pixels were perfect
        }
        else{
            variance = 1.e30; // zero flux so give it an enormous variance so weight is small
        }
        
        *(yg + count) = flux;
        *(yv + count) = variance;
        *(frac + count) = norm/nyInApertures;
        
        if (flux < ymin)
            ymin = flux;
        if (flux > ymax)
            ymax = flux;
        count++;
    }
    //NSLog(@"Linearly extracted spectrum max: %f",ymax);
    

    ///////////////////////////////////////////////////////////////////////////////////////
    //                   CREATE THE OPTIMALLY-EXTRACTED OBJECT SPECTRUM
    ///////////////////////////////////////////////////////////////////////////////////////

    count = 0;
    xog = (float *) malloc(npts*sizeof(float));
    yog = (float *) malloc(npts*sizeof(float));
    yov = (float *) malloc(npts*sizeof(float));
    ymin =  1.e30;
    ymax = -1.e30;
    for(i=xstart;i<xend;i++){
        float fudge = 1.0; // not used... in fact it cancels out.
        coefficient = 0.;
        *(xog + count) = i;
        flux = 0.;
        norm = 0.;
        variance = 0.;
        for(j=0;j<ny;j++){
            //sum over column using Karl's algorithm for weighting
            //assume readnoise is manually entered and reflects the readnoise per 
            //pixel for the actual frame (including N&S factor of 2)
            flux += [fits value:i :j]*[segWithMasks value:i :j]*fudge*[weights value:i :j];
            norm += abs([segWithMasks value:i :j])*pow(fudge*[weights value:i :j],2.0);  // Note change
            variance += (2.0*[skyFits value:i :j]/ncombine +
                         pow(readnoise,2.0))*abs([segWithMasks value:i :j])*pow(fudge*[weights value:i :j],2.0);
            // Note the 2.0 on the sky reflects N&S difference, readnoise already
            // includes it we assume
            coefficient += fudge*[weights value:i :j];
        }
        
        if (norm>1e-20){ // effectively zero... just some tiny number to avoid floating point funnies
            flux /= norm; //flux is now the average of non-rejected pixels
            flux *= coefficient;
            variance /= pow(norm,2.0);
            variance *= pow(coefficient,2.0);
        }
        else{
            variance = 1.e30; // zero flux so give it an enormous variance so weight is small
        }

        *(yog + count) = flux; // assign value to flux spectrum
        *(yov + count) = variance; // assign value to variance spectrum

        //keep track of min and max vals
        if (flux < ymin)
            ymin = flux;
        if (flux > ymax)
            ymax = flux;

        count++;
    }
    //NSLog(@"Optimally extracted spectrum max: %f",ymax);
    
    
    
    ///////////////////////////////////////////////////////////////////////////////////////
    //                      CREATE THE SKY SPECTRUM
    ///////////////////////////////////////////////////////////////////////////////////////
    
    xs = (float *) malloc(npts*sizeof(float));
    ys = (float *) malloc(npts*sizeof(float));
    count = 0;
    ymin =  1.e30;
    ymax = -1.e30;
    for(i=xstart;i<xend;i++){
        *(xs + count) = i;
        flux = 0.;
        norm = 0.;
        for(j=0;j<ny;j++){
            //sum over column using Karl's algorithm for weighting
            flux += [skyFits value:i :j]*abs([segWithMasks value:i :j]);
            norm += abs([segWithMasks value:i :j]);
        }
        if (norm>0){
            flux /= norm; //flux is now the average of non-rejected pixels
            flux *= nyInApertures;   //flux is now normalised to what the sum would be if all pixels were perfect
        }

        *(ys + count) = flux;
        if (flux < ymin)
            ymin = flux;
        if (flux > ymax)
            ymax = flux;
        count++;
    }    
    

    ///////////////////////////////////////////////////////////////////////////////////////
    //                      PLOT THE SPECTRA UP
    ///////////////////////////////////////////////////////////////////////////////////////
    
    [[[self theSlit] spec] loadDataPoints:npts withXValues:xg andYValues:yg];
    [[[self theSlit] optimallyExtractedSpectrum] loadDataPoints:npts withXValues:xog andYValues:yog];
    [[[self theSlit] skySpec] loadDataPoints:npts withXValues:xs andYValues:ys];
    [[[self theSlit] varianceSpectrum] loadDataPoints:npts withXValues:xg andYValues:yv];
    [[[self theSlit] optimallyExtractedVarianceSpectrum] loadDataPoints:npts withXValues:xog andYValues:yov];

    // call a separate method so user can mess with binning etc without re-extracting
    //NSLog(@"Number of points in optimally extracted spectrum: %d \n",[[[self theSlit] optimallyExtractedSpectrum] nPoints]);
    [self plotSkyCalibration:nil]; 
    [self plotTheBinnedSpectrum:nil]; 


    
    ///////////////////////////////////////////////////////////////////////////////////////
    //                      STORE SPECTRA AS WAVES
    ///////////////////////////////////////////////////////////////////////////////////////

    //stupidly, I need to convert every single thing from float to double. ugh.
    dyg = (double *) malloc(npts*sizeof(double));
    dyog = (double *) malloc(npts*sizeof(double));
    dyv = (double *) malloc(npts*sizeof(double));
    dyov = (double *) malloc(npts*sizeof(double));
    dfrac = (double *) malloc(npts*sizeof(double));

    for(i=0;i<npts;i++){
        *(dyg+i)=(double) *(yg+i);
        *(dyog+i)=(double) *(yog+i);
        *(dyv+i)=(double) *(yv+i);
        *(dyov+i)=(double) *(yov+i);
        *(dfrac+i)=(double) *(frac+i);
    }

    //Make sure the output waves exist
    if (![[self theSlit] spectrumWave])
        [[self theSlit] setSpectrumWave:[[Wave alloc] init]];
    if (![[self theSlit] optimallyExtractedSpectrumWave])
        [[self theSlit] setOptimallyExtractedSpectrumWave:[[Wave alloc] init]];
    if (![[self theSlit] varianceSpectrumWave])
        [[self theSlit] setVarianceSpectrumWave:[[Wave alloc] init]];
    if (![[self theSlit] optimallyExtractedVarianceSpectrumWave])
        [[self theSlit] setOptimallyExtractedVarianceSpectrumWave: [[Wave alloc] init]];

    //Set the Waves
    [[[self theSlit] spectrumWave] initWithLinearScale:dyg nData:npts startX:0.0 dX:1.0 offset:0];
    [[[self theSlit] optimallyExtractedSpectrumWave] initWithLinearScale:dyog nData:npts startX:0.0 dX:1.0 offset:0];
    [[[self theSlit] varianceSpectrumWave] initWithLinearScale:dyv nData:npts startX:xstart dX:1.0 offset:0]; // note start position!
    [[[self theSlit] optimallyExtractedVarianceSpectrumWave] initWithLinearScale:dyov nData:npts startX:0.0 dX:1.0 offset:0];
    [[[self theSlit] fractionOfApertureUnmaskedWave] initWithLinearScale:dfrac nData:npts startX:0.0 dX:1.0 offset:0];

    
    ///////////////////////////////////////////////////////////////////////////////////////
    //                      PLOT WAVES
    ///////////////////////////////////////////////////////////////////////////////////////
    [self plotSkyCalibration:nil];    

    ///////////////////////////////////////////////////////////////////////////////////////
    //                           CLEAN UP
    ///////////////////////////////////////////////////////////////////////////////////////

    free(yg);free(yog);free(yv);free(yov);free(frac);
    free(dyg);free(dyog);free(dyv);free(dyov);free(dfrac);

    //Indicate that extraction is not needed
    [[self theSlit] setNeedsExtraction:NO];
    [doItButton setKeyEquivalent:@""];

    //inform document it's been changed
    [[self document] updateChangeCount:NSChangeDone];

    //stop spinning progress indicator
    [progressIndicator stopAnimation:nil];

}


- (IBAction) calculateStatistics:(id)sender
{
    NSRange wholeRange;
    NSRange endRange;
    double left;
    double right;
    Wave *sw = [[self theSlit] spectrumWave];
    //Wave *osw = [[self theSlit] optimallyExtractedSpectrumWave];

    [self updateMarkers:nil];
    left =  (double)[[self theSlit] startMarkerWavelength];
    right = (double)[[self theSlit] endMarkerWavelength];
    [statisticsTextView selectAll:nil];
    wholeRange = [statisticsTextView selectedRange];
    endRange = NSMakeRange(wholeRange.length, 0);
    [statisticsTextView setSelectedRange:endRange];
    [statisticsTextView insertText:[NSString stringWithFormat:@"SNR in range %8.1f√Ö - %8.1f√Ö is %6.2f\n",
        left,
        right,
        [sw signalToNoiseInRangeFromX:left toX:right]]];
}



#pragma mark
#pragma mark PLOTTING


//This takes a bunch of data points and creates a calibrated spectrum with optional smoothing. If the wavelength calibrator
//is nil then no wavelength calibration is done.
//(Wave *) processSpectrum:(float *)y x:(float *)x cal:(WavelengthCalibrator *)wc
//{
//}


- (IBAction)plotTheBinnedSpectrum:(id)sender
{
    int nbin = [nBinField intValue];
    int npts = [[[self theSlit] spec] nPoints];
    RGAPoint *specBytes = (RGAPoint *)[[[[self theSlit] spec] data] bytes];
    RGAPoint *optimallyExtractedSpectrumBytes = (RGAPoint *)[[[[self theSlit] optimallyExtractedSpectrum] data] bytes];
    RGAPoint *skySpecBytes = (RGAPoint *)[[[[self theSlit] skySpec] data] bytes];
    RGAPoint *spectrumBytesToUse;
    float *x,*y,*ysky;
    float localPixscale;
    int i,j,count;
    LinePlotData *specLine, *skySpecLine;
    float skynorm;
    NSData *specColorAsData, *skyColorAsData;
    float exptime = [[self theSlit] normalizedFrameExposureTime];

    //Make sure button state is consistent
    [self validateButtons];
    
    //Retrieve colors from defaults database
    specColorAsData = [[NSUserDefaults standardUserDefaults] objectForKey:RGASpecColorWellKey];
    skyColorAsData = [[NSUserDefaults standardUserDefaults] objectForKey:RGASkyColorWellKey];

    
    if (nbin <= 0){
        NSLog(@"Error: nbin is %d\n",nbin);
        nbin=1;
    }

    y = (float *) malloc(npts*sizeof(float));
    x = (float *) malloc(npts*sizeof(float));
    ysky = (float *) malloc(npts*sizeof(float));
    
    //Decide whether or not to plot the optimally extracted spectrum, and normalize the sky spectrum 
    //so its maximum corresponds to the maximum value of the object spectrum.
    if([useOptimalExtractionButton state]==NSOnState){
        spectrumBytesToUse = optimallyExtractedSpectrumBytes;
        skynorm = [(LinePlotData *)[[self theSlit] optimallyExtractedSpectrum] yMax]/[(LinePlotData *)[[self theSlit] skySpec] yMax];
    }
    else{
        spectrumBytesToUse = specBytes;
        skynorm = [(LinePlotData *)[[self theSlit] spec] yMax]/[(LinePlotData *)[[self theSlit] skySpec] yMax]; // hmm
    }
    
    count = 0;
    for(i=0;i<npts;i+=nbin){
        *(y+count) = 0.;
        for(j=0;j<nbin;j++){
            *(y+count) = spectrumBytesToUse[i+j].y;
        }
        *(x+count) = spectrumBytesToUse[i].x;  // x-values get assigned here
        count++;
    }

    count = 0;
    for(i=0;i<npts;i+=nbin){
        *(ysky+count) = 0.;
        for(j=0;j<nbin;j++){
            *(ysky+count) = skynorm*skySpecBytes[i+j].y;
        }
        count++;
    }    

    //Determine whether to plot X-coordinate as wavelength or as CCD coordinate. Note that
    //the x-axis has already been subsampled to account for binning.
    if([useWavelengthsButton state]==NSOnState){
        [self updateWavelengthCalibrationSolution:nil];
        for(i=0;i<count;i++){
            x[i]=[[[self theSlit] wavelengthCalibrator] wavelengthAtCCDPosition:x[i]];
        }
    }    

    //Optionally apply a red-end correction
    if([useWavelengthsButton state]==NSOnState && [useRedEndCorrectionButton state]==NSOnState){
        for(i=0;i<count;i++){
            y[i] += [(Wave *)[[self document] redEndCorrectionWave] yAtX:x[i] outOfRangeValue:0.0];
            ysky[i] += [(Wave *)[[self document] redEndCorrectionWave] yAtX:x[i] outOfRangeValue:0.0];
        }
    }

    //Optionally flux calibrate the spectra
    if([useWavelengthsButton state]==NSOnState && [useFluxCalibrationButton state]==NSOnState){
        for(i=0;i<count;i++){
            y[i] /= pow(10.,[(Wave *)[[self document] fluxCalibrationWave] yAtX:x[i] outOfRangeValue:1.0]/2.5);
            ysky[i] /= pow(10.,[(Wave *)[[self document] fluxCalibrationWave] yAtX:x[i] outOfRangeValue:1.0]/2.5);

            //Divide by the exposure time
            y[i] /=  exptime;
            ysky[i] /= exptime;
            
            //Divide by the local pixel scale
            if (i==0) {
                localPixscale = x[i+1]-x[i]; // treat lower endpoint of spectrum as a special case
            }
            else{
                localPixscale = x[i]-x[i-1]; 
            }
            y[i] /= localPixscale;
            ysky[i] /= localPixscale;
            
        }
    }
	
	NSLog(@">>>>>> Doing a sanity check then trying to draw stuff... <<<<<<<<");
	NSLog(@">>>>> %f %f <<<<<<",x[0],x[npts-1]);
	
	if (x[0] < 1 || x[npts-1]>1000000) {
		// Houston, we have a problem. Set the error status flag and bail out.
		[[self theSlit] setErrorStatus:YES];
	}
	else {
		// Looks good... proceed with drawing.
		specLine = [[LinePlotData alloc] init];
		skySpecLine = [[LinePlotData alloc] init];
		
		[specLine loadDataPoints:count withXValues:x andYValues:y];
		[specLine setWidth:1.0];
		[specLine setColor:[NSUnarchiver unarchiveObjectWithData:specColorAsData]];
		[specLine setHistogram:YES];

		[skySpecLine loadDataPoints:count withXValues:x andYValues:ysky];
		[skySpecLine setWidth:1.0];
		[skySpecLine setColor:[NSUnarchiver unarchiveObjectWithData:skyColorAsData]];
		[skySpecLine setHistogram:YES];

		//Draw the plot
		[thePlotView setShouldDrawFrameBox:YES];
		[thePlotView setShouldDrawAxes:YES];
		[thePlotView setShouldDrawMajorTicks:YES];
		[thePlotView setShouldDrawMinorTicks:YES];
		[thePlotView setShouldDrawGrid:NO];
		[thePlotView setXMin:(100.0*(int)([specLine xMin])/100)];
		[thePlotView setXMax:(100.0*(1+(int)([specLine xMax])/100))];
		[thePlotView setYMin:[specLine yMin]];
		[thePlotView setYMax:1.1*[specLine yMax]];
		[thePlotView setTickMarkLength:-2.0];
		[thePlotView setTickMarkLocation:2];
		[thePlotView setNiceTicks];
	
		//create an array of lines, x-y points, templates, etc and store for plotting
		[thePlotView setMainLayerData:plotarr];

		[plotarr removeAllObjects];
	
		[plotarr addObject:specLine];
		[plotarr addObject:skySpecLine];
		[plotarr addObject:theTemplate];
    
		//decrease the retain count so these objects are deallocated properly later
		[specLine release];
		[skySpecLine release];

		//store the array of things I want plotted in the plot object and add this to the view
		[thePlotView setMainLayerData:plotarr];
		[[NSColor blackColor] set];

		//Should we display a sky spectrum on the plot view?
		if([showSkyButton state]==NSOnState){
			//NSLog(@"Showing sky spectrum");
			[[[thePlotView mainLayerData] objectAtIndex:1] setShowMe:YES];
		}
		else{
			//NSLog(@"Hiding sky spectrum");
			[[[thePlotView mainLayerData] objectAtIndex:1] setShowMe:NO];
		}

		[[[thePlotView mainLayerData] objectAtIndex:2] setShowMe:NO];

		//Update view
		[thePlotView refresh]; // rebuilds the cache image with the new spectra
		[thePlotView setNeedsDisplay:YES];
		
		//All went well so clear any error flags
		[[self theSlit] setErrorStatus:NO];

	}
	
    //tidy
    free(x);
    free(y);
    free(ysky);
    
}

- (void)setTheRedshiftTabSpectrumAttributes:(NSDictionary *)d
{
    [theRedshiftPlotView setShouldDrawFrameBox:YES];
    [theRedshiftPlotView setShouldDrawAxes:YES];
    [theRedshiftPlotView setShouldDrawMajorTicks:YES];
    [theRedshiftPlotView setShouldDrawMinorTicks:YES];
    [theRedshiftPlotView setShouldDrawGrid:NO];
    
    /*
    [theRedshiftPlotView setXMin:[d valueForKey:@"XMin"]];
    [theRedshiftPlotView setXMax:[d valueForKey:@"XMax"]];
    [theRedshiftPlotView setYMin:[d valueForKey:@"YMin"]];
    [theRedshiftPlotView setYMax:[d valueForKey:@"YMax"]];
     */
}

- (IBAction)plotTheRedshiftTabSpectrum:(id)sender
{
    
    NSMutableDictionary *dict=nil;
    Wave *skyWaveToPlot;
    Wave *objectWaveToPlot;
    Wave *tempWave1,*tempWave2,*tempWave3;
    int nbin = [redshiftTabBinWidth intValue];
    NSData *specColorAsData, *skyColorAsData;
    NSMutableArray *templateArray;
    NSEnumerator *e;
    Template *thisTemplate;
    LinePlotData *tempLine;
    float exposureTime;
    float lambda0,z0;
    
    NSLog(@"This slit has %d plot attributes stored",[[[self theSlit] plotAttributesDictionary] count]);
    
    if([redshiftTabUseExternalSpectrumButton state]==NSOnState)
    {
        // WORK WITH EXTERNAL SPECTRUM
        
        // Do we co-add or substitute?
        if([redshiftTabExternalSpectrumMatrix selectedRow]==1) {
            //substitute
            objectWaveToPlot = [[[self theSlit] companionSpectrumWave] copyWithZone:NULL];
        }
        else{
            //co-add
            int E = [redshiftTabExternalSpectrumNumberOfCombinedFramesField intValue]; //!!!!
            int M = [[self theSlit] numberOfCombinedFrames];
            tempWave1 = [[[self theSlit] companionSpectrumWave] copyWithZone:NULL];
            [tempWave1 multiplyByScalar:(float)E];
            dict = [[self theSlit] calibratedWaves:NULL redFix:NULL atmosphericAbsorption:NULL];
            [dict retain];
            tempWave2 = [dict objectForKey:@"Electrons"];
            [tempWave2 multiplyByScalar:(float)M];
            [tempWave2 addWave:tempWave1 outOfRangeValue:0.0];
            [tempWave2 multiplyByScalar:(float)1.0/(float)(E+M)];
            objectWaveToPlot = tempWave2;
            [tempWave1 release]; tempWave1 = nil;
        }

        skyWaveToPlot = [[Wave alloc] initWithZerosUsingN:128 startX:2000 dX:1.0 offset:0];
                
        if ([redshiftTabUseRedEndCorrectionButton state]==NSOnState)
            [objectWaveToPlot addWave:[[self document] redEndCorrectionWave] outOfRangeValue:0.0];

        if([redshiftTabUseAtmosphericCorrectionButton state]==NSOnState){
            tempWave1 = [[[self document] atmosphericTransmissionWave] copyWithZone:NULL];
            [tempWave1 invert];
            [objectWaveToPlot multiplyByWave:tempWave1 outOfRangeValue:1.0];
            [tempWave1 release];
        }

        if([redshiftTabUseFluxCalibrationButton state]==NSOnState){
            exposureTime = [[self theSlit] normalizedFrameExposureTime];
            tempWave1 = [[[self document] fluxCalibrationWave] copyWithZone:NULL];
            tempWave2 = [objectWaveToPlot copyWithZone:NULL];
            [tempWave2 localGridInPlace];
            [tempWave2 invert];
            [tempWave1 multiplyByScalar:(1.0/2.5)];
            [tempWave1 tenToThePower];
            [tempWave1 invert];
            [objectWaveToPlot multiplyByWave:tempWave1 outOfRangeValue:0.0];
            [objectWaveToPlot multiplyByScalar:(1.0/exposureTime)];
            [objectWaveToPlot multiplyByWave:tempWave2 outOfRangeValue:0.0];
            [tempWave1 release]; tempWave1 = nil;
            [tempWave2 release]; tempWave2 = nil;
        }

        specColorAsData = [[NSUserDefaults standardUserDefaults] objectForKey:RGASpecColorWellKey];
        [[objectWaveToPlot attributes] takeValue:[NSUnarchiver unarchiveObjectWithData:specColorAsData] forKey:@"Color"];

        skyColorAsData = [[NSUserDefaults standardUserDefaults] objectForKey:RGASkyColorWellKey];
        [[skyWaveToPlot attributes] takeValue:[NSUnarchiver unarchiveObjectWithData:skyColorAsData] forKey:@"Color"];
        
    }
    else
    {
        //WORK WITH INTERNAL SPECTRUM
        
        if ([redshiftTabUseRedEndCorrectionButton state]==NSOnState)
            tempWave1 = [[self document] redEndCorrectionWave];
        else
            tempWave1 = nil;

        if ([redshiftTabUseAtmosphericCorrectionButton state]==NSOnState)
            tempWave2 = [[self document] atmosphericTransmissionWave];
        else
            tempWave2 = nil;

        if ([redshiftTabUseFluxCalibrationButton state]==NSOnState)
            tempWave3 = [[self document] fluxCalibrationWave];
        else
            tempWave3 = nil;  

        dict = [[self theSlit] calibratedWaves:tempWave3 redFix:tempWave1 atmosphericAbsorption:tempWave2];
        [dict retain];
        if ([redshiftTabUseOptimalExtractionButton state]==NSOffState)
            objectWaveToPlot = [dict objectForKey:@"Flux"];
        else
            objectWaveToPlot = [dict objectForKey:@"OptFlux"];
        
        specColorAsData = [[NSUserDefaults standardUserDefaults] objectForKey:RGASpecColorWellKey];
        [[objectWaveToPlot attributes] takeValue:[NSUnarchiver unarchiveObjectWithData:specColorAsData] forKey:@"Color"];

        
        skyWaveToPlot = [dict objectForKey:@"SkyFlux"];
        skyColorAsData = [[NSUserDefaults standardUserDefaults] objectForKey:RGASkyColorWellKey];
        [[skyWaveToPlot attributes] takeValue:[NSUnarchiver unarchiveObjectWithData:skyColorAsData] forKey:@"Color"];
        [skyWaveToPlot multiplyByScalar:([objectWaveToPlot yMax]/[skyWaveToPlot yMax])];

    }

    // OPTIONAL SMOOTHING
    [objectWaveToPlot boxcar:nbin];
    
    // SET TRIAL REDSHIFT
    [theTemplate setRedshift:[redshiftTabTrialRedshiftField floatValue]];
    
    // DISPLAY EXTRACTED SPECTRA
    [theRedshiftPlotView setShouldDrawFrameBox:YES];
    [theRedshiftPlotView setShouldDrawAxes:YES];
    [theRedshiftPlotView setShouldDrawMajorTicks:YES];
    [theRedshiftPlotView setShouldDrawMinorTicks:YES];
    [theRedshiftPlotView setShouldDrawGrid:NO];

    if(![theRedshiftPlotView hold]){
        [theRedshiftPlotView setXMin:(100.0*(int)([objectWaveToPlot xMin])/100)];
        [theRedshiftPlotView setXMax:(100.0*(1+(int)([objectWaveToPlot xMax])/100))];
        [theRedshiftPlotView setYMin:[objectWaveToPlot yMin]];
        [theRedshiftPlotView setYMax:1.1*[objectWaveToPlot yMax]];
    }
    
    [theRedshiftPlotView setTickMarkLength:-2.0];
    [theRedshiftPlotView setTickMarkLocation:2];
    [theRedshiftPlotView setNiceTicks];

    if(![theRedshiftPlotView mainLayerData])
        [theRedshiftPlotView setMainLayerData:[[NSMutableArray alloc] init]];
    [[theRedshiftPlotView mainLayerData] removeAllObjects];
    [[theRedshiftPlotView mainLayerData] addObject:objectWaveToPlot];
    [[theRedshiftPlotView mainLayerData] addObject:skyWaveToPlot];
    [[theRedshiftPlotView mainLayerData] addObject:theTemplate];
    
    // Send release message to free up the intermediate waves. The objectWaveToPlot and skyWaveToPlot waves are
    // retained because their retain count was incremented when they were added to the mainLayerData NSArray.
    if(dict)
        [dict release];

    //only show sky if button requesting this is on
    if([redshiftTabShowSkyButton state]==NSOnState){
        [[(Wave *)[[theRedshiftPlotView mainLayerData] objectAtIndex:1] attributes] takeValue:[NSNumber numberWithBool:YES] forKey:@"Visible"];
    }
    else{
        [[(Wave *)[[theRedshiftPlotView mainLayerData] objectAtIndex:1] attributes] takeValue:[NSNumber numberWithBool:NO] forKey:@"Visible"];
    }

    
    // DISPLAY LABELS
    if([redshiftTabShowLabelsButton state]==NSOnState){
        [[[theRedshiftPlotView mainLayerData] objectAtIndex:2] setShowMe:YES];
    }
    else{
        [[[theRedshiftPlotView mainLayerData] objectAtIndex:2] setShowMe:NO];
    }


    // DISPLAY SPECTRAL TEMPLATES
    
    if(![theRedshiftPlotView secondaryLayerData])
        [theRedshiftPlotView setSecondaryLayerData:[[NSMutableArray alloc] init]];
    [[theRedshiftPlotView secondaryLayerData] removeAllObjects];
    lambda0 = [redshiftTabTemplateWavelengthField floatValue];
    z0 = [redshiftTabTrialRedshiftField floatValue];

    templateArray = [theRedshiftTabTemplatesTabTableViewController templates];
    e = [templateArray objectEnumerator];
    while (thisTemplate = [e nextObject])
    {
        if([thisTemplate isDisplayed]==YES){
            NSColor *color = [thisTemplate color];
            tempWave1 = [[thisTemplate wave] duplicate];
            tempLine = [[[LinePlotData alloc] init] autorelease];
            [tempWave1 multiplyByScalar:([theRedshiftPlotView yMax]/[tempWave1 yAtX:lambda0/(1.0+z0) outOfRangeValue:1.0])];
            [tempWave1 multiplyByScalar:[redshiftTabNormalizationField floatValue]];
            [tempLine loadWave:tempWave1 withRedshift:[redshiftTabTrialRedshiftField floatValue]];
            [tempLine setShowMe:YES];
            [tempLine setColor:color];
            [[theRedshiftPlotView secondaryLayerData] addObject:tempLine];
            [tempWave1 release];
        }
    }  
     
    //Update view
    [[self theRedshiftPlotView] refresh]; // rebuilds the cache image with the new spectra
    [[self theRedshiftPlotView] setNeedsDisplay:YES];

    // Store all attributes
    [[[self theSlit] plotAttributesDictionary] removeAllObjects];
    [[[self theSlit] plotAttributesDictionary] takeValue:[NSNumber numberWithBool:([redshiftTabExternalSpectrumMatrix selectedRow] ? YES : NO)]
                                                  forKey:@"UseExternalSpectrum?"];
    [[[self theSlit] plotAttributesDictionary] takeValue:[NSNumber numberWithBool:([redshiftTabUseRedEndCorrectionButton state]==NSOnState ? YES : NO)]
                                                  forKey:@"UseRedEndCorrection?"];
    [[[self theSlit] plotAttributesDictionary] takeValue:[NSNumber numberWithBool:([redshiftTabUseAtmosphericCorrectionButton state]==NSOnState ? YES : NO)]
                                                  forKey:@"UseAtmosphericCorrection?"];
    [[[self theSlit] plotAttributesDictionary] takeValue:[NSNumber numberWithBool:([redshiftTabUseFluxCalibrationButton state]==NSOnState ? YES : NO)]
                                                  forKey:@"UseFluxCalibration?"];
    [[[self theSlit] plotAttributesDictionary] takeValue:[NSNumber numberWithBool:([redshiftTabUseOptimalExtractionButton state]==NSOnState ? YES : NO)]
                                                  forKey:@"UseOptimalExtraction?"];
    [[[self theSlit] plotAttributesDictionary] takeValue:[NSNumber numberWithBool:([redshiftTabShowSkyButton state]==NSOnState ? YES : NO)]
                                                  forKey:@"ShowSkySpectrum?"];
    [[[self theSlit] plotAttributesDictionary] takeValue:[specColorAsData copyWithZone:NULL]
                                                  forKey:@"ObjectSpectrumColor"];
    [[[self theSlit] plotAttributesDictionary] takeValue:[skyColorAsData copyWithZone:NULL]
                                                  forKey:@"SkySpectrumColor"];
    [[[self theSlit] plotAttributesDictionary] takeValue:[NSNumber numberWithInt:nbin]
                                                  forKey:@"SmoothingBoxHalfWidth"];
    [[[self theSlit] plotAttributesDictionary] takeValue:[NSNumber numberWithFloat:[redshiftTabTrialRedshiftField floatValue]]
                                                  forKey:@"TrialRedshift"];
    [[[self theSlit] plotAttributesDictionary] takeValue:[NSNumber numberWithFloat:[theRedshiftPlotView xMin]]
                                                  forKey:@"XMin"];
    [[[self theSlit] plotAttributesDictionary] takeValue:[NSNumber numberWithFloat:[theRedshiftPlotView xMax]]
                                                  forKey:@"XMax"];
    [[[self theSlit] plotAttributesDictionary] takeValue:[NSNumber numberWithFloat:[theRedshiftPlotView yMin]]
                                                  forKey:@"YMin"];
    [[[self theSlit] plotAttributesDictionary] takeValue:[NSNumber numberWithFloat:[theRedshiftPlotView yMax]]
                                                  forKey:@"YMax"];
    [[[self theSlit] plotAttributesDictionary] takeValue:[NSNumber numberWithFloat:lambda0]
                                                  forKey:@"TemplatesCrossingWavelength"];
    [[[self theSlit] plotAttributesDictionary] takeValue:[NSNumber numberWithFloat:[redshiftTabNormalizationField floatValue]]
                                                  forKey:@"TemplatesNormalization"];
    //[[[self theSlit] plotAttributesDictionary] takeValue:templatesShownArray
    //                                              forKey:@"TemplatesShownArray"];

  
     
}


- (IBAction)plotSkyLine:(id)sender
{

    int row = [wavelengthCalibrationTableView selectedRow];
    float x = [[[self theSlit] wavelengthCalibrator] ccdPosition:row];
    LinePlotData *mark;

    mark = [[LinePlotData alloc] init];
    float *xmark = (float *)malloc(2*sizeof(float));
    float *ymark = (float *)malloc(2*sizeof(float));

    xmark[0] = x;
    xmark[1] = x;
    ymark[0] = [(LinePlotData *)[[self theSlit] skySpec] yMin];
    ymark[1] = [(LinePlotData *)[[self theSlit] skySpec] yMax];
    [mark loadDataPoints:2 withXValues:xmark andYValues:ymark];
    [mark setColor:[NSColor blueColor]];
    [mark setStyle:0];

    if(![theSkyLinePlotView mainLayerData])
        [theSkyLinePlotView setMainLayerData:[[NSMutableArray alloc] init]];
    if(![theSkyLinePlotView secondaryLayerData])
        [theSkyLinePlotView setSecondaryLayerData:[[NSMutableArray alloc] init]];

    [[theSkyLinePlotView mainLayerData] removeAllObjects];
    [[theSkyLinePlotView mainLayerData] addObject:[[self theSlit] skySpec]];
    [[[self theSlit] skySpec] setShowMe:YES];

    [[theSkyLinePlotView secondaryLayerData] removeAllObjects];
    [[theSkyLinePlotView secondaryLayerData] addObject:mark];
    [mark setShowMe:YES];


    [theSkyLinePlotView setShouldDrawFrameBox:YES];
    [theSkyLinePlotView setShouldDrawAxes:NO];
    [theSkyLinePlotView setShouldDrawMajorTicks:YES];
    [theSkyLinePlotView setShouldDrawMinorTicks:YES];
    [theSkyLinePlotView setShouldDrawGrid:NO];
    [theSkyLinePlotView setXMin:x-30.0];
    [theSkyLinePlotView setXMax:x+30.0];
    [theSkyLinePlotView setYMin:[(LinePlotData *)[[self theSlit] skySpec] yMin]];
    [theSkyLinePlotView setYMax:[(LinePlotData *)[[self theSlit] skySpec] yMax]];
    [theSkyLinePlotView setTickMarkLength:-2.0];
    [theSkyLinePlotView setTickMarkLocation:2];
    [theSkyLinePlotView setDefaultFontSize:10];
    [theSkyLinePlotView setNiceTicks];



    //Update view
    [[self theSkyLinePlotView] refresh]; // rebuilds the cache image with the new spectra
    [[self theSkyLinePlotView] setNeedsDisplay:YES];

}


- (IBAction) plotSkyCalibration:(id)sender {
    float xmin, xmax;
    RGAPoint *skySpecBytes = (RGAPoint *)[[[[self theSlit] skySpec] data] bytes];
	
	
    //Bail out if no extraction exists... we need an extraction in order that the range
    //of plotting can be determined.
    if (!skySpecBytes){
        NSLog(@"Please extract the spectrum before trying to wavelength calibrate it");
        return;
    }
	
    xmin = (float)[(Wave *)[[self theSlit] varianceSpectrumWave] xMin];
    xmax = (float)[(Wave *)[[self theSlit] varianceSpectrumWave] xMax];
	
    // This check catches an occasional initialization problem and resets things
    // so the variance spectrum is not drawn but next time the slit is initialized
    // properly.
    if (xmax>1.0e9 || (xmax < xmin) || (xmin < 1 && xmax < 1)){
        xmin = 0.0;
        xmax = 0.0;
		return;
	}
	else{
		
		//Draw the plot
		[theSkyCalibrationPlotView setShouldDrawFrameBox:YES];
		[theSkyCalibrationPlotView setShouldDrawAxes:YES];
		[theSkyCalibrationPlotView setShouldDrawMajorTicks:YES];
		[theSkyCalibrationPlotView setShouldDrawMinorTicks:YES];
		[theSkyCalibrationPlotView setShouldDrawGrid:NO];
		[theSkyCalibrationPlotView setXMin:xmin];
		[theSkyCalibrationPlotView setXMax:xmax];
		[theSkyCalibrationPlotView setYMin:0.0];
		[theSkyCalibrationPlotView setYMax:400.0];
		[theSkyCalibrationPlotView setNiceTicks];
		[theSkyCalibrationPlotView setTickMarkLength:-2.0];
		[theSkyCalibrationPlotView setTickMarkLocation:2];
		[theSkyCalibrationPlotView setTopOffset:10.0];
		[theSkyCalibrationPlotView setBottomOffset:18.0];
		[theSkyCalibrationPlotView setRightOffset:8.0];
		
		//store the array of things I want plotted in the plot object and add this to the view
		[skyCalibrationPlotArray removeAllObjects];
		[skyCalibrationPlotArray addObject:[[self theSlit] varianceSpectrumWave]];
		
		[theSkyCalibrationPlotView setMainLayerData:skyCalibrationPlotArray];
		[[NSColor blackColor] set];
		
		[theSkyCalibrationPlotView refresh]; //rebuild image cache
		[theSkyCalibrationPlotView setNeedsDisplay:YES];
	}
	
}


- (IBAction) plotWavelengthSolution:(id)sender {
    float x[100]={0.0};
    float y[100]={0.0};
    float xs[100]={0.0};
    float ys[100]={0.0};
    float xmin,xmax,dx;
    int i,npts;
    int status;
    LinePlotData *solution;
    SymbolPlotData *scatter;
    RGAPoint *specBytes = (RGAPoint *)[[[[self theSlit] spec] data] bytes];

    //Bail out if no extraction exists... we need an extraction in order that the range
    //of plotting can be determined.
    if (!specBytes){
        status = NSRunAlertPanel(@"Warning!", @"Spectrum has not yet been extracted, so there's nothing to calibrate. Please extract the spectrum before trying to wavelength calibrate it", @"OK", nil, nil);
        return;
    }

    scatter = [[SymbolPlotData alloc] init];
    solution = [[LinePlotData alloc] init];

    //Make sure we're using the latest solution
    [[[self theSlit] wavelengthCalibrator] solve];
    if([[[self theSlit] wavelengthCalibrator] solutionExists])
        [[self theSlit] setIsCalibrated:YES];

    //populate the scatter object
    npts = [[[self theSlit] wavelengthCalibrator] numberOfReferencePoints];
    for(i=0; i<npts; i++){
        x[i] = [[[self theSlit] wavelengthCalibrator] ccdPosition:i];
        y[i] = [[[self theSlit] wavelengthCalibrator] wavelength:i];
    }
    [scatter loadDataPoints:npts withXValues:x andYValues:y];

    xmin = specBytes[0].x;
    xmax = specBytes[[[[self theSlit] spec] nPoints]-1].x;
    dx = (xmax-xmin)/100;

    for(i=0; i<100; i++){
        xs[i]=xmin+i*dx;
        ys[i]=[[[self theSlit] wavelengthCalibrator] wavelengthAtCCDPosition:xs[i]];
    }
    [solution loadDataPoints:100 withXValues:xs andYValues:ys];
    [solution setWidth:0];
    [solution setColor:[NSColor redColor]];
    //NSLog(@"Fit curve line has %d points",[solution nPoints]);

    //Draw the plot
    [theWavelengthSolutionPlotView setShouldDrawFrameBox:YES];
    [theWavelengthSolutionPlotView setShouldDrawAxes:YES];
    [theWavelengthSolutionPlotView setShouldDrawMajorTicks:YES];
    [theWavelengthSolutionPlotView setShouldDrawMinorTicks:YES];
    [theWavelengthSolutionPlotView setShouldDrawGrid:NO];
    [theWavelengthSolutionPlotView setXMin:0.98*[solution xMin]];
    [theWavelengthSolutionPlotView setXMax:1.02*[solution xMax]];
    [theWavelengthSolutionPlotView setYMin:0.98*[solution yMin]];
    [theWavelengthSolutionPlotView setYMax:1.02*[solution yMax]];
    [theWavelengthSolutionPlotView setNiceTicks];
    [theWavelengthSolutionPlotView setTickMarkLength:-2.0];
    [theWavelengthSolutionPlotView setTickMarkLocation:2];

    //create an array of x-y points, lines, etc and store for plotting
    [wavelengthSolutionPlotArray removeAllObjects];
    [wavelengthSolutionPlotArray addObject:scatter];
    [wavelengthSolutionPlotArray addObject:solution];
    
    //Send objects a release so they are properly de-allocated when the array is sent a removeAllObjects message
    [scatter release];
    [solution release];

    //store the array of things I want plotted in the plot object and add this to the view
    [theWavelengthSolutionPlotView setMainLayerData:wavelengthSolutionPlotArray];
    [[NSColor blackColor] set]; 
    [theWavelengthSolutionPlotView refresh]; //rebuild image cache
    [theWavelengthSolutionPlotView setNeedsDisplay:YES];

    //store the plotted objects in the slit object so they're saved with the document
    [[self theSlit] setWavelengthCalibrationReferencePoints:scatter];
    [[self theSlit] setWavelengthCalibrationFit:solution];

}


#pragma mark
#pragma mark PLOT DELEGATES

//Delegate methods for the PlotView
- (void) processPlotViewMouseDownAtWCSPoint:(NSPoint)pt
{
    NSPoint pt1=pt;
    NSPoint pt2=pt;

    //The extraction scrolling image view might need wavelength to ccd unit conversion (or might not)
    if ([useWavelengthsButton isEnabled]==YES && [useWavelengthsButton state]==NSOnState){
        pt1.x = [[theSlit wavelengthCalibrator] ccdPositionAtWavelength:pt.x];
    }
    [theScrollingImageView zoomInOn:pt1];

    //The redshift tab image definitely needs conversion from wavelength units to CCD units
    pt2.x = [[theSlit wavelengthCalibrator] ccdPositionAtWavelength:pt.x];
    [theRedshiftTabImageView zoomInOn:pt2];

}


- (void) processPlotViewLayerDragFrom:(NSPoint)worldPoint0 to:(NSPoint)worldDragPoint
{
    float restWavelengthOfFeature = worldPoint0.x/(1.0+[redshiftTabTrialRedshiftField floatValue]);
    float redshift = (worldDragPoint.x - restWavelengthOfFeature)/restWavelengthOfFeature;
    float yFracChange = (worldDragPoint.y/worldPoint0.y);

    [redshiftTabNormalizationField setFloatValue:yFracChange*[redshiftTabNormalizationField floatValue]];
    [redshiftTabTrialRedshiftField setFloatValue:redshift];
    [[[thePlotView mainLayerData] objectAtIndex:2] setRedshift:redshift];
    [self plotTheRedshiftTabSpectrum:nil];
    [self refreshPlots:nil];
}


#pragma mark
#pragma mark WAVELENGTH CALIBRATION

- (IBAction)addCalPoint:(id)sender
{
    NSString *label = [NSString stringWithFormat:@"%d points stored",[[[self theSlit] wavelengthCalibrator] numberOfReferencePoints]+1];

    [[[self theSlit] wavelengthCalibrator] addReferencePointAtCCDPosition:[xField floatValue] withWavelength:[lambdaField floatValue]];
    [calibrationInfoField setStringValue:label];
    [wavelengthCalibrationTableView reloadData];
    if([[[self theSlit] wavelengthCalibrator] numberOfReferencePoints]>=2){
        [self updateWavelengthCalibrationSolution:nil];
        [self plotWavelengthSolution:nil];
    }
    [self refreshPlots:nil];
    [[self document] updateChangeCount:NSChangeDone];

}


-(IBAction) deleteCalPoint:(id)sender
{
    int status;
    NSEnumerator *enumerator;
    NSNumber *index;
    NSMutableArray *tempArray = [NSMutableArray array];
    NSString *label;
    id tempObject;
    if ( [wavelengthCalibrationTableView numberOfSelectedRows] == 0 )
        return;
    NSBeep();
    status = NSRunAlertPanel(@"Warning!", @"Are you sure you want to delete the selected calibration point(s)?", @"OK", @"Cancel", nil);
    if ( status == NSAlertDefaultReturn ) {
        enumerator = [wavelengthCalibrationTableView selectedRowEnumerator];
        while ( (index = [enumerator nextObject]) ) {
            tempObject = [[[[self theSlit] wavelengthCalibrator] referencePoints] objectAtIndex:[index intValue]];
            [tempArray addObject:tempObject];
        }
        [[[[self theSlit] wavelengthCalibrator] referencePoints] removeObjectsInArray:tempArray];
        [wavelengthCalibrationTableView reloadData];
    }
    label = [NSString stringWithFormat:@"%d points stored",[[[self theSlit] wavelengthCalibrator] numberOfReferencePoints]];
    [calibrationInfoField setStringValue:label];
    [self plotWavelengthSolution:nil];
    [self refreshPlots:nil];
    [[self document] updateChangeCount:NSChangeDone];
}


- (IBAction)shiftSkyLineLeft:(id)sender
{
    WavelengthCalibrator *cal = [[self theSlit] wavelengthCalibrator];
    int row = [wavelengthCalibrationTableView selectedRow];
    float x;
    if (row < 0)
        return;
    x = [cal ccdPosition:row];
    [[[cal referencePoints] objectAtIndex:row] setObject:[NSNumber numberWithFloat:(x+1)] forKey:@"ccdPosition"];
    [self plotSkyLine:nil];
    [self updateWavelengthCalibrationSolution:nil];
}


- (IBAction)shiftSkyLineRight:(id)sender
{
    WavelengthCalibrator *cal = [[self theSlit] wavelengthCalibrator];
    int row = [wavelengthCalibrationTableView selectedRow];
    float x;
    if (row < 0)
        return;
    x = [cal ccdPosition:row];
    [[[cal referencePoints] objectAtIndex:row] setObject:[NSNumber numberWithFloat:(x-1)] forKey:@"ccdPosition"];
    [self plotSkyLine:nil];
    [self updateWavelengthCalibrationSolution:nil];
}


- (IBAction)shiftAllSkyLinesLeft:(id)sender
{
    WavelengthCalibrator *cal = [[self theSlit] wavelengthCalibrator];
    int i;
    float x;
    for(i=0;i<[cal numberOfReferencePoints];i++){
        x = [cal ccdPosition:i];
        [[[cal referencePoints] objectAtIndex:i] setObject:[NSNumber numberWithFloat:(x+1)] forKey:@"ccdPosition"];
    }
    [self plotSkyLine:nil];
    [self updateWavelengthCalibrationSolution:nil];
}


- (IBAction)shiftAllSkyLinesRight:(id)sender
{
    WavelengthCalibrator *cal = [[self theSlit] wavelengthCalibrator];
    int i;
    float x;
    for(i=0;i<[cal numberOfReferencePoints];i++){
        x = [cal ccdPosition:i];
        [[[cal referencePoints] objectAtIndex:i] setObject:[NSNumber numberWithFloat:(x-1)] forKey:@"ccdPosition"];
    }
    [self plotSkyLine:nil];
    [self updateWavelengthCalibrationSolution:nil];
}



#pragma mark
#pragma mark SAVE SHEETS

/* Called when save panels are dismissed. */
- (void)didEndSaveASCIISaveSheet:(NSSavePanel *)savePanel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    theSlit = (Slit *)contextInfo;
    [savePanel orderOut:nil];
    if (returnCode == NSOKButton) {
        if (![theSlit useCompanionSpectrum]){
            [theSlit exportToFile:[savePanel filename]
                  fluxCalibration:[[self document] fluxCalibrationWave]
                           redFix:[[self document] redEndCorrectionWave]
            atmosphericAbsorption:[[self document] atmosphericTransmissionWave]];
        }
        else {
            [theSlit exportCompanionToFile:[savePanel filename]
                  fluxCalibration:[[self document] fluxCalibrationWave]
                           redFix:[[self document] redEndCorrectionWave]
            atmosphericAbsorption:[[self document] atmosphericTransmissionWave]];
        }
    }
}


- (void)didEndSaveFITSSaveSheet:(NSSavePanel *)savePanel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    theSlit = (Slit *)contextInfo;
    [savePanel orderOut:nil];
    if (returnCode == NSOKButton) {
        [theSlit exportToFITS:[savePanel filename]
              fluxCalibration:[[self document] fluxCalibrationWave]
                       redFix:[[self document] redEndCorrectionWave]
        atmosphericAbsorption:[[self document] atmosphericTransmissionWave]];
    }
}




#pragma mark
#pragma mark ACCESSORS


-(id)theImageView{
    return theImageView;
}

-(id)theScrollingImageView{
    return theScrollingImageView;
}

#pragma mark
#pragma mark BASIC

-(void)dealloc{
    [segWithMasks release];
    [segWithoutMasks release];
    [weights release];
    [super dealloc];
}

- (NSString *) description
{
    return [fits description];
}


//Delegate method for the window.
//If the extraction window is about to close we need to unregister the existing
//slit aperture from the notification center or it will attempt to process mouse
//clicks forever. We also make sure the descriptive note text is stored in the
//slit. We'll also do a basic clean up.
- (void)windowWillClose:(NSNotification *)aNotification
{
    int i;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    //NSLog(@"<<<<<< Removing aperture from list of observers >>>>>>>>");
    [nc removeObserver: [theImageView aperture]];
    //NSLog(@"<<<<<< Removing masks from list of observers >>>>>>>>");
    for(i=0;i<[[theSlit masks] count];i++)
        [nc removeObserver:[[theSlit masks] objectAtIndex:i]];
    [self storeNote];

}


- (id)init {

    self = [super initWithWindowNibName:@"TestExtractionWindow"];

    //Set some sensible defaults
    scale = 1.0;
    currentAbsoluteAnnotationScale = 1.0;

    //Listen for some pertinent notifications.
    [self setNote:[NSNotificationCenter defaultCenter]];

    //User has clicked mouse in a FITSImageView
    [[self note] addObserver: self
                    selector: @selector(updateLastMouseClickInformation:)
                        name: @"FITSImageViewMouseDownNotification"
                      object: nil];

    //User has has scrolled the window (or otherwise changed the bounds)
    [[self note] addObserver: self
                    selector: @selector(drawScrollingViewBoundsInStickyView:)
                        name: @"NSViewBoundsDidChangeNotification"
                      object: nil];

    //User has has scrolled the window (or otherwise changed the bounds)
    [[self note] addObserver: self
                    selector: @selector(updateRedshiftTabSpectrumOnNotification:)
                        name: @"RGATemplateColorDidChangeNotification"
                      object: nil];


    //Components of the 1D spectrum plot
    plotarr = [[NSMutableArray alloc] init];
    [[self thePlotView] setMainLayerData:plotarr];

    //Components of the profile plot
    profilePlotArray = [[NSMutableArray alloc] init];
    [theProfilePlotView setMainLayerData:profilePlotArray];

    //Components of the profile plot
    skyCalibrationPlotArray = [[NSMutableArray alloc] init];
    [theSkyCalibrationPlotView setMainLayerData:skyCalibrationPlotArray];

    //Components of the wavelength solution plot
    wavelengthSolutionPlotArray = [[NSMutableArray alloc] init];
    [theWavelengthSolutionPlotView setMainLayerData:wavelengthSolutionPlotArray];

    //Note that further initialization that involves GUI elements will have to be done in
    //the awakeFromNib method as the outlets are not initialized when init is called.

    return self;
}



#pragma mark
#pragma mark OBSOLETE

float fluxCal(float lambda, float flux){
    double L,fac;
    L=(double) lambda;
    fac = 54.865742 -0.046797075*L + 1.4610425e-5*pow(L,2) -2.124026e-9*pow(L,3) +
        1.4636271e-13*pow(L,4) -3.8740422e-18*pow(L,5);
    return(flux/(float)fac);
}

#pragma mark
#pragma mark OTHER ACCESSORS
//Accessor methods
idAccessor(note,setNote)
idAccessor(fits, setFits)
idAccessor(skyFits, setSkyFits)
idAccessor(segWithMasks, setSegWithMasks)
idAccessor(weights, setWeights)
idAccessor(annotationPaths, setAnnotationPaths)
floatAccessor(scale, setScale)
floatAccessor(currentAbsoluteAnnotationScale, setCurrentAbsoluteAnnotationScale)
intAccessor(yOffsetCCD,setYOffsetCCD)
idAccessor(thePlotView,setThePlotView)
idAccessor(theRedshiftPlotView,setTheRedshiftPlotView)
idAccessor(theProfilePlotView,setTheProfilePlotView)
idAccessor(theWavelengthSolutionPlotView,setTheWavelengthSolutionPlotView)
idAccessor(theSkyLinePlotView,setTheSkyLinePlotView)
idAccessor(theSkyCalibrationPlotView,setTheSkyCalibrationPlotView)
idAccessor(notesTextView,setNotesTextView)
idAccessor(plotarr,setPlotarr)
idAccessor(theSlit,setTheSlit)
idAccessor(wavelengthCalibrationTableView,setWavelengthCalibrationTableView)
idAccessor(calibrationInfoField,setCalibrationInfoField)
idAccessor(nBinField,setNBinField)
idAccessor(dYUpperSlider,setDYUpperSlider)
idAccessor(dYLowerSlider,setDYLowerSlider)
idAccessor(gapSlider,setGapSlider)
idAccessor(useWavelengthsButton,setUseWavelengthsButton)
idAccessor(redshiftTabTrialRedshiftField,setRedshiftTabTrialRedshiftField)
intAccessor(naxis1,setnaxis1)
intAccessor(xCCD,setXCCD)
idAccessor(statisticsTextView,setStatisticsTextView)


@end
