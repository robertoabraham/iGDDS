//
//  TemplateTableController.m
//  iGDDS
//
//  Created by Roberto Abraham on Mon Sep 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "TemplateTableController.h"
#import "Template.h"
#import "ColorCell.h"


@implementation TemplateTableController

- (void) awakeFromNib {
    NSTableColumn *colorColumn;
    NSTableColumn *isDisplayedColumn;
    ColorCell *colorPrototypeCell;
    NSButtonCell *isDisplayedPrototypeCell;
    NSArray *xml;
    NSEnumerator *e;
    NSDictionary *dict;
    NSBundle *myBundle = [NSBundle mainBundle];
    int i=0;

    //Set cell for color well cell
    colorPrototypeCell = [[[ColorCell alloc] init] autorelease];
    [colorPrototypeCell setEditable: YES];
    [colorPrototypeCell setTarget: self];
    [colorPrototypeCell setAction: @selector(colorClick:)];
    colorColumn = [table tableColumnWithIdentifier:@"color"];
    [colorColumn setDataCell:colorPrototypeCell];

    //Set cell for isDisplayed cell
    isDisplayedPrototypeCell = [[[NSButtonCell alloc] initTextCell: @""] autorelease];
    [isDisplayedPrototypeCell setEditable:YES];
    [isDisplayedPrototypeCell setButtonType:NSSwitchButton];
    [isDisplayedPrototypeCell setImagePosition:NSImageOnly];
    [isDisplayedPrototypeCell setControlSize:NSSmallControlSize];
    [isDisplayedPrototypeCell setAction:@selector(isDisplayedClick:)];
    isDisplayedColumn = [table tableColumnWithIdentifier:@"isDisplayed"];
    [isDisplayedColumn setDataCell:isDisplayedPrototypeCell];

    // Default colors for first 100 templates
    colors = [[NSMutableArray arrayWithObjects:[NSColor purpleColor],
        [NSColor blueColor],[NSColor blackColor],
        [NSColor blueColor],[NSColor magentaColor],
        [NSColor orangeColor],[NSColor purpleColor],
        [NSColor blackColor],[NSColor blackColor],
        [NSColor darkGrayColor],[NSColor purpleColor],
        [NSColor blueColor],[NSColor blackColor],
        [NSColor blueColor],[NSColor magentaColor],
        [NSColor orangeColor],[NSColor purpleColor],
        [NSColor blackColor],[NSColor blackColor],
        [NSColor darkGrayColor],[NSColor purpleColor],
        [NSColor blueColor],[NSColor blackColor],
        [NSColor blueColor],[NSColor magentaColor],
        [NSColor orangeColor],[NSColor purpleColor],
        [NSColor blackColor],[NSColor blackColor],
        [NSColor darkGrayColor],[NSColor purpleColor],
        [NSColor blueColor],[NSColor blackColor],
        [NSColor blueColor],[NSColor magentaColor],
        [NSColor orangeColor],[NSColor purpleColor],
        [NSColor blackColor],[NSColor blackColor],
        [NSColor darkGrayColor],[NSColor purpleColor],
        [NSColor blueColor],[NSColor blackColor],
        [NSColor blueColor],[NSColor magentaColor],
        [NSColor orangeColor],[NSColor purpleColor],
        [NSColor blackColor],[NSColor blackColor],
        [NSColor darkGrayColor], [NSColor purpleColor],
        [NSColor blueColor],[NSColor blackColor],
        [NSColor blueColor],[NSColor magentaColor],
        [NSColor orangeColor],[NSColor purpleColor],
        [NSColor blackColor],[NSColor blackColor],
        [NSColor darkGrayColor],[NSColor purpleColor],
        [NSColor blueColor],[NSColor blackColor],
        [NSColor blueColor],[NSColor magentaColor],
        [NSColor orangeColor],[NSColor purpleColor],
        [NSColor blackColor],[NSColor blackColor],
        [NSColor darkGrayColor],[NSColor purpleColor],
        [NSColor blueColor],[NSColor blackColor],
        [NSColor blueColor],[NSColor magentaColor],
        [NSColor orangeColor],[NSColor purpleColor],
        [NSColor blackColor],[NSColor blackColor],
        [NSColor darkGrayColor],[NSColor purpleColor],
        [NSColor blueColor],[NSColor blackColor],
        [NSColor blueColor],[NSColor magentaColor],
        [NSColor orangeColor],[NSColor purpleColor],
        [NSColor blackColor],[NSColor blackColor],
        [NSColor darkGrayColor],[NSColor purpleColor],
        [NSColor blueColor],[NSColor blackColor],
        [NSColor blueColor],[NSColor magentaColor],
        [NSColor orangeColor],[NSColor purpleColor],
        [NSColor blackColor],[NSColor blackColor],
        [NSColor darkGrayColor],nil] retain];

    templates = [[NSMutableArray alloc] init];
    xml = [NSArray arrayWithContentsOfFile:[myBundle pathForResource:@"templates" ofType:@"xml"]];
    e = [xml objectEnumerator];
    while (dict = [e nextObject])
    {
        NSString *file = [dict valueForKey:@"File"];
        NSString *type = [dict valueForKey:@"Type"];
        NSString *key = [dict valueForKey:@"Label"];
        Template *newTemplate = [[Template alloc] init];
		NSLog(@"Loading template %@",file);
        [newTemplate setIsDisplayed:NO];
        [newTemplate setDescription:key];
        [newTemplate setWave:[[Wave alloc] initWithFITS:[myBundle pathForResource:file ofType:type]]];
        [newTemplate setColor:[colors objectAtIndex:i++]];
        [templates addObject:newTemplate];
    }
    [table reloadData];
}


// Add any code here that need to be executed once the windowController has loaded the document's window.
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{  
    [self updateUI];
}



// Sender below is the table view
- (void) colorClick:(id)sender
{
    NSColorPanel* panel;

    colorRow = [sender clickedRow];
    panel = [NSColorPanel sharedColorPanel];
    [panel setTarget: self];
    [panel setAction: @selector (colorChanged:)];
    [panel setColor: [colors objectAtIndex: colorRow]];
    [panel makeKeyAndOrderFront: self];
}


// Sender below is the table view
- (void) isDisplayedClick:(id)sender
{
    int row = [sender clickedRow];
    if ([[templates objectAtIndex:row] isDisplayed])
        [[templates objectAtIndex:row] setIsDisplayed:NO];
   else
       [[templates objectAtIndex:row] setIsDisplayed:YES];
   [self updateUI];
}


// Sender below is the NSColorPanel
- (void)colorChanged:(id)sender
{
    [[templates objectAtIndex:colorRow] setColor:[sender color]];
    [colors replaceObjectAtIndex:colorRow withObject:[sender color]];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"RGATemplateColorDidChangeNotification" object:self];
    [table reloadData];
}


//Datasource methods
- (int) numberOfRowsInTableView: (NSTableView*) tableView {
    return [templates count];
}

- (id) tableView: (NSTableView*) aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(int)rowIndex
{
    NSString *identifier = [aTableColumn identifier];
    if ([identifier isEqualToString:@"color"]){
        return [[templates objectAtIndex:rowIndex] color];
        //return [colors objectAtIndex:rowIndex];
    }
    else{
        Template *t = [templates objectAtIndex:rowIndex];
        return [t valueForKey:identifier];
    }
}

//Private methods
- (void)updateUI
{
    [table reloadData];
}

//Accessors
-(NSMutableArray *)templates
{
    return templates;
}



@end
