//
//  BAStringUtilities.m
//  FeatureTests
//
//  Created by Brent Gulanowski on Thu May 22 2003.
//  Copyright (c) 2003 Bored Astronaut Software. All rights reserved.
//

#import "BAStringUtilities.h"

#define BUFFER_SIZE 512

@implementation NSString ( BAStringUtilities )

-(NSArray *)componentsUsingCharacters:(NSCharacterSet *)content {

  return [self componentsSeparatedByCharacters:[content invertedSet]];
}

-(NSArray *)componentsSeparatedByCharacters:(NSCharacterSet *)separators {

  const char *cString = [self UTF8String];
  NSMutableArray *tokens = [NSMutableArray array];
  unsigned start, end, length = [self length];
  BOOL readingContent = NO;

  start = 0;
  for(end=0; end<length; end++) {
    if(readingContent == NO && [separators characterIsMember:cString[end]] == NO ) {
      readingContent = YES;
      start = end;
    }
    else if( readingContent == YES && [separators characterIsMember:cString[end]] == YES ) {
      readingContent = NO;
      [tokens addObject:[self substringWithRange:NSMakeRange(start,end-start)]];
    }
  }
  if( readingContent == YES ) {
    [tokens addObject:[self substringWithRange:NSMakeRange(start,end-start)]];
  }    

  return [NSArray arrayWithArray:tokens];
}

-(NSArray *)componentsSeparatedByCharacter:(char)separator {

  const char *buffer;
  NSMutableArray *tokens = [NSMutableArray array];
  unsigned start, end, length = [self length];
  BOOL readingContent = NO;

  buffer = [self UTF8String];
  start = 0;
  for(end=0; end<length; end++) {
    if(readingContent == NO && buffer[end] != separator ) {
      readingContent = YES;
      start = end;
    }
    else if( readingContent == YES && buffer[end] == separator ) {
      readingContent = NO;
      [tokens addObject:[self substringWithRange:NSMakeRange(start,end-start)]];
    }
  }
  if( readingContent == YES ) {
    [tokens addObject:[self substringWithRange:NSMakeRange(start,end-start)]];
  }
  
  return [NSArray arrayWithArray:tokens];
}


@end
