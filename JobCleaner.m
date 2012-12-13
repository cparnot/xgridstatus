//
//  JobCleaner.m
//  XgridStatus
//
//  Created by Charles Parnot on 8/27/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "JobCleaner.h"
#import "GEZGridHook.h"

@implementation JobCleaner


- (id)initWithGrid:(GEZGridHook *)aGrid;
{	
	NSAssert( aGrid != nil, @"ERROR:  aGrid is nil");
	self = [super init];
	if ( self != nil ) {
		grid = [aGrid retain];
		isRunning = NO;
		daysBeforeExpiration = 30;
		verbose = NO;
	}
	return self;
}

- (void)dealloc
{
	[grid release];
	[cleaningTimer invalidate];
	[cleaningTimer autorelease];
	[super dealloc];
}

- (GEZGridHook *)grid
{
	return grid;
}

- (BOOL)verbose
{
	return verbose;
}

- (void)setVerbose:(BOOL)newVerbose
{
	verbose = newVerbose;
}

- (int)daysBeforeExpiration
{
	return daysBeforeExpiration;
}

- (void)setDaysBeforeExpiration:(int)newDaysBeforeExpiration
{	
	if ( newDaysBeforeExpiration > 0 )
		daysBeforeExpiration = newDaysBeforeExpiration;
}

- (void)start
{
	if ( cleaningTimer != nil || isRunning == YES )
		return;
	cleaningTimer = [[NSTimer scheduledTimerWithTimeInterval:3600 target:self selector:@selector(cleanJobs) userInfo:nil repeats:YES] retain];
	isRunning = YES;
}

- (void)stop
{
	[cleaningTimer invalidate];
	[cleaningTimer autorelease];
	isRunning = NO;
}

- (void)cleanJobs
{
	printf( "ERROR: job cleaning is off");
	exit(0);
	return;
	
	if ( [grid isLoaded] == NO )
		return;
	NSEnumerator *e = [[[grid xgridGrid] jobs] objectEnumerator];
	XGJob *aJob;
	while ( aJob = [e nextObject] ) {
		XGResourceState jobState = [aJob state];
		if ( ( ( jobState == XGResourceStateFinished ) || ( jobState == XGResourceStateFailed ) || ( jobState == XGResourceStateCanceled ) ) && ( [[aJob dateStopped] compare:[NSDate dateWithTimeIntervalSinceNow:3600*24*daysBeforeExpiration]] == NSOrderedAscending ) ) {
			if ( [self verbose] )
				printf("removing job %p = '%s'\n", aJob, [[aJob name] UTF8String]);
			[aJob performDeleteAction];
		}
	}
}

@end
