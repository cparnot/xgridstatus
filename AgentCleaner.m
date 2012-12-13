//
//  AgentCleaner.m
//  XgridStatus
//
//  Created by Charles Parnot on 8/23/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "AgentCleaner.h"
#import "GEZGridHook.h"
#import "GEZResourceObserver.h"
#import "GEZResourceArrayObserver.h"

@interface AgentCleaner (AgentCleanerPrivate)
- (void)checkAgents;
@end


@implementation AgentCleaner

- (id)initWithGrid:(GEZGridHook *)aGrid;
{
	NSAssert( aGrid != nil, @"ERROR:  aGrid is nil");
	self = [super init];
	if ( self != nil ) {
		grid = [aGrid retain];
		isRunning = NO;
	}
	return self;
}

- (void)dealloc
{
	[grid release];
	[xgridAgentsObserver setDelegate:nil];
	[xgridAgentsObserver release];
	[xgridGridObserver setDelegate:nil];
	[xgridGridObserver release];
	[super dealloc];
}

- (GEZGridHook *)grid
{
	return grid;
}

- (void)start
{
	NSAssert( grid != nil, @"ERROR: ivar grid is nil");

	if ( isRunning )
		return;
	
	NSAssert( xgridGridObserver == nil, @"ERROR: ivar xgridGridObserver is not nil");
	NSAssert( xgridAgentsObserver == nil, @"ERROR: ivar xgridAgentsObserver is not nil");

	//setup observer of the "agents" key on the grid
	xgridGridObserver= [[GEZResourceObserver alloc] initWithResource:[grid xgridGrid] observedKeys:[NSSet setWithObject:@"agents"]];
	[xgridGridObserver setDelegate:self];
	
	//setup observer of the agents objects
	xgridAgentsObserver = [[GEZResourceArrayObserver alloc] initWithResources:[[grid xgridGrid] agents] observedKeys:[NSSet setWithObjects:@"state", @"activeCPUPower", nil]];
	[xgridAgentsObserver setDelegate:self];

	[self checkAgents];
	
	isRunning=YES;
}

- (void)stop
{
	NSAssert( grid != nil, @"ERROR: ivar grid is nil" );
	NSAssert( 0, @"ERROR: stop method not implemented" );
}

- (void)setVerbose:(BOOL)flag
{
	verbose = flag;
}

- (BOOL)verbose
{
	return verbose;
}

@end

@implementation AgentCleaner (AgentCleanerPrivate)

- (void)checkAgent:(XGAgent *)anAgent
{
	NSAssert1( [anAgent class] == NSClassFromString(@"XGAgent"), @"ERROR: anAgent is a %@, not an XGAgent instance", [anAgent class]);
	
	// remove only agents that are Offline and not processing any job
	if ( ( [anAgent state] != XGResourceStateOffline ) || ( [anAgent activeCPUPower] > 1.0 ) )
		return;
	
	// remove agent from the grid
	NSAssert( grid != nil, @"ERROR: ivar grid is nil");
	if ( verbose) 
		printf("removing agent %p = '%s'\n", anAgent, [[anAgent name] UTF8String]);
	[anAgent performDeleteAction];
}

- (void)checkAgents
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	NSEnumerator *e = [[[grid xgridGrid] agents] objectEnumerator];
	id anAgent;
	while ( anAgent = [e nextObject] )
		[self checkAgent:anAgent];
}

//delegate callback from GEZResourceObserver
- (void)xgridResourceDidUpdate:(XGResource *)resource
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s : %@",[self class],self,_cmd,resource);	
	[self checkAgents];
}

- (void)xgridResourceAgentsDidChange:(XGResource *)resource
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);	
	
	[xgridAgentsObserver setXgridResources:[[grid xgridGrid] agents]];
	[self checkAgents];
}



// an XGAgent state did change
- (void)resourceArrayObserver:(GEZResourceArrayObserver *)observer xgridResourceStateDidChange:(XGResource *)resource;
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s : %@",[self class],self,_cmd,resource);
	[self checkAgent:(XGAgent *)resource];
}

- (void)resourceArrayObserver:(GEZResourceArrayObserver *)observer xgridResourceActiveCPUPowerDidChange:(XGResource *)resource;
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s : %@",[self class],self,_cmd,resource);
	[self checkAgent:(XGAgent *)resource];
}


@end
