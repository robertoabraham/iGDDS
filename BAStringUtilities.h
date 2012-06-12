//
//  BAStringUtilities.h
//  FeatureTests
//
//  Created by Brent Gulanowski on Thu May 22 2003.
//  Copyright (c) 2003 Bored Astronaut Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/* convert a string into a series of tokens while removing white space */

@interface NSString ( BAStringUtilities )

-(NSArray *)componentsUsingCharacters:(NSCharacterSet *)content;

-(NSArray *)componentsSeparatedByCharacters:(NSCharacterSet *)formatting;

-(NSArray *)componentsSeparatedByCharacter:(char)separator;
@end
