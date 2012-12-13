//
//  ResourceStateToStringTransformer.m
//  XgridStatus
//
//  Created by Charles Parnot on 8/4/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ResourceStateToStringTransformer.h"


@implementation ResourceStateToStringTransformer

static ResourceStateToStringTransformer *sharedTransformer = nil;

+ (id)sharedTransformer
{
	if ( sharedTransformer == nil )
		sharedTransformer = [[ResourceStateToStringTransformer alloc] init];
	return sharedTransformer;
}


//use to convert XGResourceState enum into NSStrings
static NSString *StatusStrings[20];

+ (void)initialize
{
	StatusStrings[0] = @"Unknown";
	StatusStrings[XGResourceStateUninitialized+1] = @"Uninitialized";
	StatusStrings[XGResourceStateOffline+1] = @"Offline";
	StatusStrings[XGResourceStateConnecting+1] = @"Connecting";
	StatusStrings[XGResourceStateUnavailable+1] = @"Unavailable";
	StatusStrings[XGResourceStateAvailable+1] = @"Available";
	StatusStrings[XGResourceStateWorking+1] = @"Working";
	StatusStrings[XGResourceStatePending+1] = @"Pending";
	StatusStrings[XGResourceStateStarting+1] = @"Starting";
	StatusStrings[XGResourceStateStagingIn+1] = @"StagingIn";
	StatusStrings[XGResourceStateRunning+1] = @"Running";
	StatusStrings[XGResourceStateSuspended+1] = @"Suspended";
	StatusStrings[XGResourceStateStagingOut+1] = @"StagingOut";
	StatusStrings[XGResourceStateCanceled+1] = @"Canceled";
	StatusStrings[XGResourceStateFailed+1] = @"Failed";
	StatusStrings[XGResourceStateFinished+1] = @"Finished";
}

+ (Class)transformedValueClass;
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation;
{
    return NO;   
}

- (id)transformedValue:(id)value;
{
	return [self transformedIntValue:[value intValue]];

	/*
	int state;
	if ( [value respondsToSelector:@selector(intValue)] )
		state = [value intValue] + 1;
	else
		state = 0;
	
	if ( state > 19 || state < 0)
		state = 0;
	
	return StatusStrings[state];
	 */
}

- (id)transformedIntValue:(int)intValue
{
	int state = intValue + 1;
	if ( state > 19 || state < 0)
		state = 0;
	
	return StatusStrings[state];
	
	return [self transformedValue:[NSNumber numberWithInt:intValue]];
}

@end
