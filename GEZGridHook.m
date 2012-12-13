//
//  GEZGridHook.m
//
//  GridEZ
//
//  Copyright 2006 Charles Parnot. All rights reserved.
//

/* __BEGIN_LICENSE_GRIDEZ__
This file is part of "GridEZ.framework". "GridEZ.framework" is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version. "GridEZ.framework" is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details. You should have received a copy of the GNU Lesser General Public License along with GridEZ.framework; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
__END_LICENSE__ */



#import "GEZGridHook.h"
#import "GEZServerHook.h"
#import "GEZAgentHook.h"

NSString *GEZGridHookDidSyncNotification = @"GEZGridHookDidSyncNotification";
NSString *GEZGridHookDidLoadNotification = @"GEZGridHookDidLoadNotification";
NSString *GEZGridHookDidChangeNameNotification = @"GEZGridHookDidChangeNameNotification";
NSString *GEZGridHookDidChangeJobsNotification = @"GEZGridHookDidChangeJobsNotification";
NSString *GEZGridHookDidChangeAgentsNotification = @"GEZGridHookDidChangeAgentsNotification";
NSString *GEZGridHookDidLoadAgentsNotification = @"GEZGridHookDidLoadAgentsNotification";


//the state changes as the connection progresses from not being connected to having loaded all the attributes of the server
typedef enum {
	GEZGridHookStateUninitialized = 1,
	GEZGridHookStateConnected,
	GEZGridHookStateSynced,
	GEZGridHookStateLoaded,
	GEZGridHookStateDisconnected,
} GEZGridHookState;


@implementation GEZGridHook


#pragma mark *** Initializations ***

- (id)initWithXgridGrid:(XGGrid *)aGrid serverHook:(GEZServerHook *)aServer
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	if ( self = [super init] ) {
		
		//set up ivars
		[self setXgridGrid:aGrid];
		serverHook = aServer; //no retain to avoid cycles
		gridHookState = GEZGridHookStateUninitialized;
		agentsLoaded = NO;
		shouldObserveJobs = NO;
		shouldObserveAgents = NO;
		agentsLoaded = NO;
		agentHooks = nil;
		
	}
	return self;
}


- (id)initWithIdentifier:(NSString *)identifier serverHook:(GEZServerHook *)aServer;
{

	//get the XGGrid object
	NSEnumerator *e = [[[serverHook xgridController] grids] objectEnumerator];
	XGGrid *aGrid = nil;
	while ( ( aGrid = [e nextObject] ) && ( ! [[aGrid identifier] isEqualToString:identifier] ) ) ;
	if ( aGrid == nil ) {
		[self release];
		return nil;
	} else
		return [self initWithXgridGrid:aGrid serverHook:aServer];

}

+ (GEZGridHook *)gridHookWithXgridGrid:(XGGrid *)aGrid serverHook:(GEZServerHook *)aServer
{
	GEZGridHook *gridHook = [aServer gridHookWithIdentifier:[aGrid identifier]];
	if ( gridHook != nil )
		return gridHook;
	else
		return [[[self alloc] initWithXgridGrid:aGrid serverHook:aServer] autorelease];
}

+ (GEZGridHook *)gridHookWithIdentifier:(NSString *)identifier serverHook:(GEZServerHook *)aServer;
{
	GEZGridHook *gridHook = [aServer gridHookWithIdentifier:identifier];
	if ( gridHook != nil )
		return gridHook;
	else
		return [[[self alloc] initWithIdentifier:identifier serverHook:aServer] autorelease];
}

- (void)dealloc
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	gridHookState = GEZGridHookStateUninitialized;
	serverHook = nil;
	[self setXgridGrid:nil];
	[agentHooks release];
	[super dealloc];
}

- (NSString *)shortDescription
{
	return [NSString stringWithFormat:@"Grid Connection to '%@-%@' (state %d)", [serverHook address], [xgridGrid name], gridHookState];
}

#pragma mark *** Accessors ***

- (GEZServerHook *)serverHook
{
	return serverHook;
}

- (void)setXgridGrid:(XGGrid *)newGrid
{
	if ( newGrid != xgridGrid ) {
		
		//clean the old ivar
		[xgridGrid removeObserver:self forKeyPath:@"name"];
		if ( shouldObserveJobs == YES )
			[xgridGrid removeObserver:self forKeyPath:@"jobs"];
		if ( shouldObserveAgents == YES )
			[xgridGrid removeObserver:self forKeyPath:@"agents"];
		[xgridGrid release];

		//setup the new ivar
		xgridGrid = [newGrid retain];
		[xgridGrid addObserver:self forKeyPath:@"name" options:0 context:NULL];
		if ( shouldObserveJobs == YES )
			[xgridGrid addObserver:self forKeyPath:@"jobs" options:0 context:NULL];
		if ( shouldObserveAgents == YES ) {
			[[xgridGrid controller] sendAgentListRequest];
			[xgridGrid sendAgentsRequest];
			[xgridGrid addObserver:self forKeyPath:@"agents" options:0 context:NULL];
		}
		
		//if ready, notify self to be synced on the next iteration of the run loop
		if ( [xgridGrid name] != nil )
			[NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(xgridGridDidSyncInstanceVariables:) userInfo:nil repeats:NO];
	}
}

- (XGGrid *)xgridGrid
{
	return xgridGrid;
}

- (BOOL)isSynced
{
	return ( gridHookState == GEZGridHookStateSynced ) || ( gridHookState == GEZGridHookStateLoaded );
}

- (BOOL)isLoaded
{
	return gridHookState == GEZGridHookStateLoaded;
}

- (BOOL)shouldObserveJobs
{
	return shouldObserveJobs;
}

- (BOOL)agentsLoaded
{
	if ( agentsLoaded == YES )
		return YES;
	if ( agentHooks == nil )
		return NO;
	
	BOOL allAgentsSynced = YES;
	NSEnumerator *e = [agentHooks objectEnumerator];
	GEZAgentHook *oneAgent;
	while ( oneAgent = [e nextObject] ) {
		if ( [oneAgent isSynced] == NO ) {
			allAgentsSynced = NO;
			[e allObjects];
		}
	}
	if ( allAgentsSynced )
		agentsLoaded = YES;
	
	return agentsLoaded;
}

- (void)setShouldObserveJobs:(BOOL)flag
{
	if ( shouldObserveJobs == flag )
		return;

	shouldObserveJobs = flag;
	if ( flag )
		[xgridGrid addObserver:self forKeyPath:@"jobs" options:0 context:NULL];
}

- (BOOL)shouldObserveAgents
{
	return shouldObserveAgents;
}

- (void)setShouldObserveAgents:(BOOL)flag
{
	if ( shouldObserveAgents == flag )
		return;
	
	shouldObserveAgents = flag;
	if ( flag ) {
		[[xgridGrid controller] sendAgentListRequest];
		[xgridGrid sendAgentsRequest];
		[xgridGrid addObserver:self forKeyPath:@"agents" options:0 context:NULL];
	}
}

- (NSSet *)agentHooks
{
	return agentHooks;
}

#pragma mark *** agent observing ***

- (void)startAgentObservation
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	if ( agentHooks != nil )
		return;
	
	//create GEZAgentHook to observe them until they are all synced
	NSArray *xgridAgents = [[self xgridGrid] agents];
	NSMutableSet *agentList = [NSMutableSet setWithCapacity:[xgridAgents count]];
	NSEnumerator *e = [xgridAgents objectEnumerator];
	XGAgent *oneAgent;
	while ( oneAgent = [e nextObject] )
		[agentList addObject:[GEZAgentHook agentHookWithXgridAgent:oneAgent]];
	agentHooks = [agentList copy];
	
	//maybe all agents are actually ready
	if ( [self agentsLoaded] )
		[[NSNotificationCenter defaultCenter] postNotificationName:GEZGridHookDidLoadAgentsNotification object:self];
	else
		//otherwise, get notifications of agents when synced
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(agentDidSync:) name:GEZAgentHookDidSyncNotification object:nil];
}

- (void)agentDidSync:(NSNotification *)notification
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	if ( [self agentsLoaded] ) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:GEZAgentHookDidSyncNotification object:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:GEZGridHookDidLoadAgentsNotification object:self];
	}
}


#pragma mark *** XGGrid observing, going from "Connected" to "Synced" ***

//when the state of the XGGrid is modified by the XgridFoundation framework, we know all its instance variables will be set by the end of this run loop
//so we call a timer with interval 0 to be back when all the instance variables are set (e.g. grids,...)
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@\nObject = <%@:%p>\nKey Path = %@\nChange = %@",[self class],self,_cmd, [self shortDescription], [object class], object, keyPath, [change description]);
	
	if ( [keyPath isEqualToString:@"name"] ) {
		//the first change in value is when the name is set, which means in the next run loop, all the ivars will be set
		if ( gridHookState == GEZGridHookStateUninitialized && [xgridGrid state] != 0 )
			[NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(xgridGridDidSyncInstanceVariables:) userInfo:nil repeats:NO];		
		//otherwise, it means the name of the grid was changed
		else
			[[NSNotificationCenter defaultCenter] postNotificationName:GEZGridHookDidChangeNameNotification object:self];
	}
	
	//the first change for the "jobs" value is when the jobs are set during the initialization, so we ignore that
	else if ( [keyPath isEqualToString:@"jobs"] && gridHookState != GEZGridHookStateUninitialized ) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GEZGridHookDidChangeJobsNotification object:self];
	}

	//the first change for the "agents" value is when the agents are set during the initialization, so we ignore that
	else if ( [keyPath isEqualToString:@"agents"] && gridHookState != GEZGridHookStateUninitialized ) {
		//if this is the first time agents are set, we need to observe them all
		if ( [self agentsLoaded] == NO )
			[self startAgentObservation];
		[[NSNotificationCenter defaultCenter] postNotificationName:GEZGridHookDidChangeAgentsNotification object:self];
	}
}

//callback on the iteration of the run loop following the change in the state of the XGGrid
- (void)xgridGridDidSyncInstanceVariables:(NSTimer *)aTimer
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	if ( gridHookState != GEZGridHookStateUninitialized )
		return;
	
	//update gridHookState to be consistent with XGGrid state
	XGResourceState gridState = [xgridGrid state];
	if ( gridState == XGResourceStateAvailable )
		gridHookState = GEZGridHookStateSynced;
	else if ( gridState == XGResourceStateOffline || gridState == XGResourceStateUnavailable )
		gridHookState = GEZGridHookStateDisconnected;

	//this log shows that the jobs are loaded, but only their identifier is properly set
	//which means -jobWithIdentifier will work if the identifier is valid, but will return a job that is not yet "loaded" from the grid
	DLog(NSStringFromClass([self class]),12,@"<%@:%p> jobs:\n%@",[self class],self,[[self xgridGrid] jobs]);

	//notify of the change of state
	[[NSNotificationCenter defaultCenter] postNotificationName:GEZGridHookDidSyncNotification object:self];

}


@end
