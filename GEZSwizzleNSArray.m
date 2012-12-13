//
//  GEZSwizzleNSArray.m
//  XgridStatus
//
//  Created by Charles Parnot on 8/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GEZSwizzleNSArray.h"


@implementation NSArray (GEZSwizzleNSArray)

- (void)GEZSwizzleNSArray_addObject:(id)anObject
{
	if ( anObject == nil ) {
		printf("skipping exception raised by [<%s:%p> %s (null)] to work around occasional Xgrid database bug\n", [[[self class] description] UTF8String], self, _cmd);
		return;
		//[self GEZSwizzleNSArray_addObject:[NSNull null]];
	}

	//calling the original implementation
	[self GEZSwizzleNSArray_addObject:anObject];
}

@end
