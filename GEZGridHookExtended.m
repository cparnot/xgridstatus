//
//  GEZGridHookExtended.m
//
//  GridEZ
//
//  Copyright 2006 Charles Parnot. All rights reserved.
//


#import "GEZGridHookExtended.h"
#import "GEZServerHook.h"
#import "GEZResourceObserver.h"
#import "GEZResourceArrayObserver.h"

//NSString *GEZGridHookDidChangeAgentsNotification = @"GEZGridHookDidChangeAgentsNotification";
//NSString *GEZGridHookDidLoadAgentsNotification = @"GEZGridHookDidLoadAgentsNotification";

/*
//the state changes as the connection progresses from not being connected to having loaded all the attributes of the server
typedef enum {
	GEZGridHookStateUninitialized = 1,
	GEZGridHookStateConnected,
	GEZGridHookStateSynced,
	GEZGridHookStateLoaded,
	GEZGridHookStateDisconnected,
} GEZGridHookState;
*/


@implementation GEZGridHookExtended


#pragma mark *** Initializations ***

//this method will be called by the GEZGridHookPoser class to replace GEZGridHook instances with this subclass
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

	[xgridGridObserverForAgentsKey setDelegate:nil];
	[xgridGridObserverForAgentsKey release];
		
	[xgridAgentsObserver setDelegate:nil];
	[xgridAgentsObserver release];
	
	[super dealloc];
}


//public
- (BOOL)agentsLoaded
{
	return allAgentsUpdated;
}

#pragma mark *** XGGrid observing, going from "Updated" to "Loaded" ***


- (void)startAgentObservation
{
	if ( allAgentsUpdated == YES )
		return;
	
	if ( xgridAgentsObserver == nil ) {
		xgridAgentsObserver = [[GEZResourceArrayObserver alloc] initWithResources:[xgridGrid agents]];
		[xgridAgentsObserver setDelegate:self];
	} else
		[xgridAgentsObserver setXgridResources:[xgridGrid agents]];
	
	if ( xgridGridObserverForAgentsKey == nil ) {
		xgridGridObserverForAgentsKey = [[GEZResourceObserver alloc] initWithResource:xgridGrid observedKeys:[NSSet setWithObject:@"agents"]];
	}
	
}

- (BOOL)checkIfAllAgentsUpdated
{
	if ( allAgentsUpdated == YES )
		return YES;
	[self startAgentObservation];
	allAgentsUpdated = [xgridAgentsObserver allXgridResourcesUpdated];
	return allAgentsUpdated;
}

- (BOOL)checkIfAllChildrenUpdated
{
	return ( [self checkIfAllJobsUpdated] && [self checkIfAllAgentsUpdated] );
}



//delegate callback from GEZResourceObserver
- (void)xgridResourceAgentsDidChange:(XGResource *)resource
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);	
	
	[xgridAgentsObserver setXgridResources:[xgridGrid agents]];
	[self checkIfLoaded];
}



@end
