#import <Cocoa/Cocoa.h>
#import "FITSImageView.h"
#import "Slit.h"
#import "Wave.h"
#import "PlotView.h"
#import "PlotData.h"
#import "Plot.h"
#import "RedshiftPlotView.h"
#import "CalibrationPlotView.h"
#import "LinePlotData.h"
#import "CribImageView.h"
#import "LineLabelData.h"
#import "TemplateTableController.h"
#import "Guide.h"
#import "Template.h"

@class MyDocument;
@class Image;

//External function
float fluxCal(float lambda, float flux);

@interface ExtractionWindowController : NSWindowController {
    NSNotificationCenter *note;
    Image *fits;
    Image *skyFits;
    Image *segWithMasks;
    Image *segWithoutMasks;
    Image *weights;
    Image *temp;
    Wave  *externalSpectrumWave;
    NSImage *theNSImage;
    NSMutableArray *annotationPaths;

    //Outlets in the Extraction tab
    IBOutlet FITSImageView *theScrollingImageView;
    IBOutlet FITSImageView *theImageView;
    IBOutlet PlotView *thePlotView;
    IBOutlet PlotView *theProfilePlotView;
    IBOutlet PlotView *theWavelengthSolutionPlotView;
    IBOutlet CalibrationPlotView *theSkyCalibrationPlotView;

    IBOutlet NSTextField *minField;
    IBOutlet NSTextField *maxField;
    IBOutlet NSTextField *xField;
    IBOutlet NSTextField *yField;
    IBOutlet NSTextField *valField;
    IBOutlet NSTextField *lambdaField;
    IBOutlet NSTextField *calibrationInfoField;
    IBOutlet NSButton *smoothButton;
    IBOutlet NSButton *apertureButton;
    IBOutlet NSButton *showSkyButton;
    IBOutlet NSMatrix *imageTypeMatrix;
    IBOutlet NSSlider *gapSlider;
    IBOutlet NSSlider *dYUpperSlider;
    IBOutlet NSSlider *dYLowerSlider;
    IBOutlet NSButton *useOptimalExtractionButton;
    IBOutlet NSButton *useWavelengthsButton;
    IBOutlet NSButton *useFluxCalibrationButton;
    IBOutlet NSButton *useRedEndCorrectionButton;
    IBOutlet NSTextField *nBinField;
    IBOutlet NSTableView *wavelengthCalibrationTableView;
    IBOutlet CribImageView *theCribImageView;
    IBOutlet NSTextView *notesTextView;
    IBOutlet PlotView *theSkyLinePlotView;
    IBOutlet NSTextField *orderField;
    IBOutlet NSTextField *rmsField;
    IBOutlet NSTabView *theGlobalTagView;
//    IBOutlet NSSlider *positiveGaussianPositionSlider;
//    IBOutlet NSSlider *positiveGaussianSigmaSlider;
//    IBOutlet NSSlider *negativeGaussianPositionSlider;
//    IBOutlet NSSlider *negativeGaussianSigmaSlider;
//    IBOutlet NSButton *useGaussianButton;
    IBOutlet NSButton *doItButton;
//    IBOutlet NSTextField *positiveGaussianTextField;    
//    IBOutlet NSTextField *positiveGaussianPositionTextField;
//    IBOutlet NSTextField *positiveGaussianSigmaTextField;
//    IBOutlet NSTextField *negativeGaussianTextField;    
//    IBOutlet NSTextField *negativeGaussianPositionTextField;
//    IBOutlet NSTextField *negativeGaussianSigmaTextField;
    IBOutlet NSProgressIndicator *progressIndicator;

    //Outlets in the redshift tab
    IBOutlet RedshiftPlotView *theRedshiftPlotView;
    IBOutlet NSTextField *redshiftTabTrialRedshiftField;
    IBOutlet NSTextField *redshiftTabNormalizationField;
    IBOutlet NSTextField *redshiftTabBinWidth;
    IBOutlet NSButton *redshiftTabUseFluxCalibrationButton;
    IBOutlet NSButton *redshiftTabUseRedEndCorrectionButton;
    IBOutlet NSButton *redshiftTabUseAtmosphericCorrectionButton;
    IBOutlet NSButton *redshiftTabUseOptimalExtractionButton;
    IBOutlet NSButton *redshiftTabUseExternalSpectrumButton;
    IBOutlet NSButton *redshiftTabShowLabelsButton;
    IBOutlet NSButton *redshiftTabShowSkyButton;
    IBOutlet NSButton *redshiftTabShowLogFLambdaButton;
    IBOutlet NSButton *redshiftTabShowLogFNuButton;
    IBOutlet NSButton *redshiftPlotToggleHoldStateButton;
    IBOutlet FITSImageView *theRedshiftTabImageView;

    //Outlets in the redshift tab / templates sub-tab
    IBOutlet TemplateTableController *theRedshiftTabTemplatesTabTableViewController; 

    //Outlets in the redshift tab / statistics sub-tab
    IBOutlet NSTextField *statisticsTabStartMarkerWavelengthField;
    IBOutlet NSTextField *statisticsTabEndMarkerWavelengthField;
    IBOutlet NSTextView *statisticsTextView;

    //Outlines the redshift tab / external spectrum sub-tab
    IBOutlet NSMatrix *redshiftTabExternalSpectrumMatrix;
    IBOutlet NSTextField *redshiftTabExternalSpectrumField;
    IBOutlet NSTextField *redshiftTabExternalSpectrumNumberOfCombinedFramesField;
    IBOutlet NSTextField *redshiftTabTemplateWavelengthField;

    //Outlets in the notes tab
    IBOutlet NSTextField *notesTabFinalAssignedRedshiftField;
    IBOutlet NSTextField *notesTabConfidenceGradeField;    

    BOOL imageNeedsUpdate;
    float scale;
    float currentAbsoluteAnnotationScale;
    int yOffsetCCD;
    NSSize imageSize;
    bool annotationNeedsScaling;
    Plot *myPlot;
    Plot *myProfilePlot;
    Plot *myWavelengthSolutionPlot;
    NSMutableArray *plotarr;
    NSMutableArray *profilePlotArray;
    NSMutableArray *wavelengthSolutionPlotArray;
    NSMutableArray *skyCalibrationPlotArray;
    Slit *theSlit;
    LineLabelData *theTemplate;
    int naxis1;
    int xCCD;
}


- (IBAction) extract:(id)sender;
- (IBAction) refresh:(id)sender;
- (IBAction) refreshPlots:(id)sender;
- (IBAction) refreshImages:(id)sender;
- (IBAction) refreshImagesQuickly:(id)sender;
- (IBAction) autoScale:(id)sender;
- (IBAction) addCalPoint:(id)sender;
- (IBAction) deleteCalPoint:(id)sender;
- (IBAction) saveSpectrumAsFITS:(id)sender;
- (IBAction) plotTheBinnedSpectrum:(id)sender;
- (IBAction) plotWavelengthSolution:(id)sender;
- (IBAction) plotSkyCalibration:(id)sender;
- (IBAction) plotTheRedshiftTabSpectrum:(id)sender;
- (IBAction) plotSkyLine:(id)sender;
- (IBAction) deleteCalPoint:(id)sender;
- (IBAction) setTrialRedshift:(id)sender;
- (IBAction) toggleTheRedshiftPlotHoldState:(id)sender;
- (IBAction) updateWavelengthCalibrationSolution:(id)sender;
//- (IBAction) updateProfilePlot:(id)sender;
- (IBAction) importFITSCalibration:(id)sender;
- (IBAction) exportTheRedshiftTabSpectrumToAnASCIIFile:(id)sender;
- (IBAction) exportTheRedshiftTabSpectrumToAFITSFile:(id)sender;
//- (IBAction) toggleGaussianMode:(id)sender;
- (IBAction) apertureChanged:(id)sender;
- (IBAction) lowContrastObject:(id)sender;
- (IBAction) mediumContrastObject:(id)sendery;
- (IBAction) highContrastObject:(id)sendery;
- (IBAction) lowContrastSky:(id)sender;
- (IBAction) mediumContrastSky:(id)sendery;
- (IBAction) highContrastSky:(id)sendery;
- (IBAction) shiftAllSkyLinesLeft:(id)sender;
- (IBAction) shiftAllSkyLinesRight:(id)sender;
- (IBAction) shiftSkyLineLeft:(id)sender;
- (IBAction) shiftSkyLineRight:(id)sender;
- (IBAction) zapAperture:(id)sender;
- (IBAction) storeRedshiftAndGrade:(id)sender;
- (IBAction) calculateStatistics:(id)sender;
- (IBAction) updateMarkers:(id)sender;
- (IBAction) toggleExternalSpectrum:(id)sender;
- (IBAction) importExternalSpectrumWave:(id)sender;
- (IBAction) storeCompanionWaveInformation:(id)sender;


- (NSString *) description;

//methods triggered by notifications
- (void) updateLastMouseClickInformation:(NSNotification *)instruction;
- (void) drawScrollingViewBoundsInStickyView:(NSNotification *)instruction;
- (void) updateRedshiftTabSpectrumOnNotification:(NSNotification *)instruction;

//methods triggered by save sheets
- (void) didEndSaveASCIISaveSheet:(NSSavePanel *)savePanel returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void) didEndSaveFITSSaveSheet:(NSSavePanel *)savePanel returnCode:(int)returnCode contextInfo:(void *)contextInfo;

//process mouse click sent by a plot view
- (void) processPlotViewMouseDownAtWCSPoint:(NSPoint)pt;
- (void) processPlotViewLayerDragFrom:(NSPoint)worldPoint0 to:(NSPoint)worldDragPoint;

-(void) loadAperture;
-(void) setMasks;
-(void) setupWavelengthCalibration;
-(void) clearThePlotViews;
-(void) storeNote;
-(void) validateButtons;
-(void) restoreSavedPlots;


//Delegate methods
- (void)textDidEndEditing:(NSNotification *)aNotification;

//Accessor methods
idAccessor_h(note,setNote)
idAccessor_h(fits, setFits)
idAccessor_h(skyFits, setSkyFits)
idAccessor_h(segWithMasks, setSegWithMasks)
idAccessor_h(weights, setWeights)
idAccessor_h(annotationPaths, setAnnotationPaths)
floatAccessor_h(scale, setScale)
floatAccessor_h(currentAbsoluteAnnotationScale, setCurrentAbsoluteAnnotationScale)
intAccessor_h(yOffsetCCD,setYOffsetCCD)
idAccessor_h(thePlotView,setThePlotView)
idAccessor_h(theRedshiftPlotView,setTheRedshiftPlotView)
idAccessor_h(theProfilePlotView,setTheProfilePlotView)
idAccessor_h(theWavelengthSolutionPlotView,setTheWavelengthSolutionPlotView)
idAccessor_h(theSkyLinePlotView,setTheSkyLinePlotView)
idAccessor_h(theSkyCalibrationPlotView,setTheSkyCalibrationPlotView)
idAccessor_h(notesTextView,setNotesTextView)
idAccessor_h(plotarr,setPlotarr)
idAccessor_h(theSlit,setTheSlit)
idAccessor_h(wavelengthCalibrationTableView,setWavelengthCalibrationTableView)
idAccessor_h(calibrationInfoField,setCalibrationInfoField)
idAccessor_h(nBinField,setNBinField)
idAccessor_h(dYUpperSlider,setDYUpperSlider)
idAccessor_h(dYLowerSlider,setDYLowerSlider)
idAccessor_h(gapSlider,setGapSlider)
idAccessor_h(useWavelengthsButton,setUseWavelengthsButton)
idAccessor_h(redshiftTabTrialRedshiftField,setRedshiftTabTrialRedshiftField)
intAccessor_h(naxis1,setnaxis1)
intAccessor_h(xCCD,setXCCD)
idAccessor_h(statisticsTextView,setStatisticsTextView)



- (id)theImageView;
- (id)theScrollingImageView;

@end
