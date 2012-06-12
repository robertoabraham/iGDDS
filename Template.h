//
//  Template.h
//  iGDDS
//
//  Created by Roberto Abraham on Mon Sep 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Wave.h"


@interface Template : NSObject {

    NSString *_description;
    BOOL _isDisplayed;
    Wave *_wave;
    NSColor *_color;
    
}

//Accessor methods
-(NSString *)description;
-(BOOL)isDisplayed;
-(Wave *)wave;
-(NSColor *)color;
-(void)setDescription:(NSString *)desc;
-(void)setIsDisplayed:(BOOL)isdisp;
-(void)setWave:(Wave *)w;
-(void)setColor:(NSColor *)c;


@end
