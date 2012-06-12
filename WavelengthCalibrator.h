//
//  WavelengthCalibrator.h
//  iGDDS
//
//  Created by Roberto Abraham on Mon Oct 28 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//



#import <Cocoa/Cocoa.h>
#include "AccessorMacros.h"

#define MAX_ORDER 10

@interface WavelengthCalibrator : NSObject <NSCoding> {

    bool needsUpdate;
    bool solutionExists;
    int ncoeff;
    double c[MAX_ORDER];
    double d[MAX_ORDER];
    NSMutableArray *referencePoints;
    double _rms;
    int _pmin;
    int _pmax;
   
}

- (void) addReferencePointAtCCDPosition:(float)x withWavelength:(float)lambda;
- (int) numberOfReferencePoints;
- (float) ccdPosition:(int)n;
- (float) wavelength:(int)n;
- (double) coefficient:(int)n;
- (void) solve;
- (float) wavelengthAtCCDPosition:(float)x;
- (float) ccdPositionAtWavelength:(float)x;
- (double) rms;
- (void) setRms:(float)rms;


//datasource methods
-(int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(int)rowIndex;

//accessor methods
- (int) pMin;
- (void) setPMin:(int)p;
- (int) pMax;
- (void) setPMax:(int)p;
- (int) nCoeff;
- (void) setNCoeff:(int)n;
- (double *) coefficients;
boolAccessor_h(needsUpdate,setNeedsUpdate);
boolAccessor_h(solutionExists,setSolutionExists);
idAccessor_h(referencePoints,setReferencePoints);


@end
