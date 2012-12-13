//
//  JobCleaner.h
//  XgridStatus
//
//  Created by Charles Parnot on 8/27/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GEZGridHook;

@interface JobCleaner : NSObject {
	GEZGridHook *grid;
	int daysBeforeExpiration;
	BOOL isRunning;
	BOOL verbose;
	NSTimer *cleaningTimer;
}
- (id)initWithGrid:(GEZGridHook *)aGrid;

- (GEZGridHook *)grid;

- (void)start;
- (void)stop;

- (void)setVerbose:(BOOL)flag;
- (BOOL)verbose;

- (void)setDaysBeforeExpiration:(int)flag;
- (int)daysBeforeExpiration;

@end
