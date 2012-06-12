//
//  SpectralTemplate.h
//  iGDDS
//
//  Created by Roberto Abraham on Wed Nov 06 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "AccessorMacros.h"
#import "PlotView.h"
#import "PlotData.h"

@interface SpectralTemplate : PlotData {
	float redshift;
        NSMutableArray *lines;
        PlotView *view;
}

-(void)plotWithTransform:(NSAffineTransform *)trans;
- (id) initWithView:(id)v;
-(void)paintLabel:(NSString *)aLabel angle:(float)anAngle x:(float)anX y:(float)anY attr:(NSMutableDictionary *)attrs;
floatAccessor_h(redshift,setRedshift)
idAccessor_h(lines,setLines)
idAccessor_h(view,setView)

@end
