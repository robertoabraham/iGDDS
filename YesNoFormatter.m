//
//  YesNoFormatter.m
//  iGDDS
//
//  Created by Roberto Abraham on Mon Mar 03 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "YesNoFormatter.h"


@implementation YesNoFormatter

- (NSString *)stringForObjectValue:(id)obj
{
    if (![obj respondsToSelector:@selector(intValue)]){
        return nil;
    }
    else{
        if([obj intValue]==1){
            return [NSString stringWithString:@"Yes"];
        }
        else{
            return [NSString stringWithString:@"No"];
        }
    }
}


- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error
{
    BOOL result = NO;
    NSLog(@" ----  Trying to deal with %@",string);
    *obj = [NSNumber numberWithInt:[string intValue]];
    result = YES;
    
    return result;
}



@end
