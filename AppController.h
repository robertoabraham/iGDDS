//
//  AppController.h
//  iGDDS
//
//  Created by Roberto Abraham on Wed Oct 30 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class PreferenceController;

@interface AppController : NSObject {
    PreferenceController *preferenceController;
}
-(IBAction)showPreferencePanel:(id)sender;

@end
