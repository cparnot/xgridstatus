//
//  AgentCleaner.h
//  XgridStatus
//
//  Created by Charles Parnot on 8/23/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GEZGridHook;
@class GEZResourceObserver;
@class GEZResourceArrayObserver;

@interface AgentCleaner : NSObject {
	GEZGridHook *grid;
	GEZResourceObserver *xgridGridObserver;
	GEZResourceArrayObserver *xgridAgentsObserver;
	BOOL isRunning;
	BOOL verbose;
}

- (id)initWithGrid:(GEZGridHook *)aGrid;

- (GEZGridHook *)grid;

- (void)start;
- (void)stop;

- (void)setVerbose:(BOOL)flag;
- (BOOL)verbose;

@end
