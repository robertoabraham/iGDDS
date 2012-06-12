//
//  TemplateTableController.h
//  iGDDS
//
//  Created by Roberto Abraham on Mon Sep 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface TemplateTableController : NSWindowController {

    IBOutlet NSTableView* table;

    NSMutableArray *templates;
    NSMutableArray *colors;
    int colorRow;
}

- (void)updateUI;

//Accessors
-(NSMutableArray *)templates;

@end


