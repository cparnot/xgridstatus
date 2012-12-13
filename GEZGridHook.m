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
//#import "GEZAgentHook.h"
#import "GEZResourceObserver.h"

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


//private methods of the superclass GEZGridHookBase that I want to expose here and not in the GridEZ framework
@interface GEZGridHookBase (GEZGridHookBasePrivate)
- (id)initWithXgridGrid:(XGGrid *)aGrid serverHook:(GEZServerHook *)aServer;
@end

@implementation GEZGridHook


#pragma mark *** Initializations ***

- (id)initWithXgridGrid:(XGGrid *)aGrid serverHook:(GEZServerHook *)aServer
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	if ( self = [super initWithXgridGrid:aGrid serverHook:aServer] ) {
		allAgentsUpdated = NO;
		[[aGrid controller] sendAgentListRequest];
		[aGrid sendAgentsRequest];
	}
	return self;
}


- (void)dealloc
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	[xgridAgentObservers release];
	[super dealloc];
}


#pragma mark *** agent observing ***

//public
- (BOOL)agentsLoaded
{
	return allAgentsUpdated;
}


- (void)startAgentObservation
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//create GEZResourceObserver objects to observe them until they are all updated
	NSArray *xgridAgents = [xgridGrid agents];
	NSMutableSet *observers = [NSMutableSet setWithCapacity:[xgridAgents count]];
	NSEnumerator *e = [xgridAgents objectEnumerator];
	XGAgent *oneAgent;
	while ( oneAgent = [e nextObject] ) {
		GEZResourceObserver *resourceObserver = [[[GEZResourceObserver alloc] initWithResource:oneAgent] autorelease];
		[resourceObserver setDelegate:self];
		[observers addObject:resourceObserver];
		
	}
	xgridAgentObservers = [observers copy];
	
}

- (BOOL)checkIfAllAgentsUpdated
{
	if ( allAgentsUpdated == YES )
		return YES;
	
	//looping through the XGAgent, hoping all are updated
	allAgentsUpdated = YES;
	NSEnumerator *e = [[xgridGrid agents] objectEnumerator];
	XGAgent *oneAgent;
	while ( oneAgent = [e nextObject] ) {
		if ( [oneAgent isUpdated] == NO ) {
			allAgentsUpdated = NO;
			[e allObjects];
		}
	}
	
	//if all agents are updated, we are done; otherwise, we might need to start observing them
	if ( allAgentsUpdated ) {
		[xgridAgentObservers release];
		xgridAgentObservers = nil;
	} else if ( xgridAgentObservers == nil )
		[self startAgentObservation];
	
	return allAgentsUpdated;
}


#pragma mark *** XGGrid observing, going from "Connected" to "Updated" ***

- (BOOL)checkIfAllChildrenUpdated
{
	return ( [super checkIfAllChildrenUpdated] && [self checkIfAllAgentsUpdated] );
}


@end
