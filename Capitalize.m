//
//  Capitalize.m
//  iTelescope
//
//  Created by Roberto Abraham on Fri Aug 09 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "Capitalize.h"


@implementation NSString (Capitalize)

- (NSString *)capitalize
{
    NSString *newString;
    NSRange r;
    r.location=0;
    r.length=1;
    newString = [[self substringWithRange:r] uppercaseString];
    newString = [newString stringByAppendingString:[self substringFromIndex:1]];
    return newString;
}

@end
