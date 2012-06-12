//
//  RedshiftPlotView.h
//  iGDDS
//
//  Created by Roberto Abraham on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "PlotView.h"
#include "AccessorMacros.h"


@interface RedshiftPlotView : PlotView {
    BOOL hold;
}

- (void)flagLine:(id)sender;

//Accessors
boolAccessor_h(hold,setHold)

@end
