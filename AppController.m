//
//  AppController.m
//  iGDDS
//
//  Created by Roberto Abraham on Wed Oct 30 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"
#import "PreferenceController.h"

@implementation AppController

- (IBAction)showPreferencePanel:(id)sender
{
    if(!preferenceController) {
        preferenceController = [[PreferenceController alloc] init];
    }
    [preferenceController showWindow:self];
}


+ (void)initialize {
    // Create a dictionary
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    //Archive some objects
    NSData *specColorAsData = [NSArchiver archivedDataWithRootObject:[NSColor redColor]];
    NSData *skyColorAsData = [NSArchiver archivedDataWithRootObject:[NSColor blueColor]];
    //Put defaults in the dictionary
    [defaultValues setObject:specColorAsData forKey:RGASpecColorWellKey];
    [defaultValues setObject:skyColorAsData forKey:RGASkyColorWellKey];
    [defaultValues setObject:@"gdds_" forKey:RGAOutputFilePrefixKey];
    [defaultValues setObject:NSHomeDirectory() forKey:RGAOutputFileLocationKey];
    [defaultValues setObject:NSHomeDirectory() forKey:RGAInputFileLocationKey];
    //Register the dictionary of defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
    //NSLog(@"registered defaults: %@", defaultValues);
}

    
- (void)dealloc
{
    [preferenceController release];
    [super dealloc];
}

@end
