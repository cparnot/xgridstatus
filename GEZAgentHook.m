//
//  GEZAgentHook.m
//  XgridStatus
//
//  Created by Charles Parnot on 8/10/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "GEZAgentHook.h"

NSString *GEZAgentHookDidSyncNotification = @"GEZAgentHookDidSyncNotification";

@interface GEZAgentHook (GEZAgentHookPrivate)
- (void)setXgridAgent:(XGAgent *)agent;
- (void)startObservingXgridAgent;
- (void)stopObservingXgridAgent;
@end



@implementation GEZAgentHook

+ (GEZAgentHook *)agentHookWithXgridAgent:(XGAgent *)agent
{
	return [[[self alloc] initWithXgridAgent:agent] autorelease];
}


- (id)initWithXgridAgent:(XGAgent *)agent
{
	self = [super init];
	if ( self != nil ) {
		isSynced = NO;
		isObserving = NO;
		[self setXgridAgent:agent];
	}
	return self;
}

- (void)dealloc
{
	[self setXgridAgent:nil];
	[super dealloc];
}

- (NSString *)shortDescription
{
	return [NSString stringWithFormat:@"Agent '%@' (state %d)", [xgridAgent name], [xgridAgent state]];
}


- (BOOL)isSynced
{
	return isSynced;
}

- (XGAgent *)xgridAgent
{
	return xgridAgent;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@\nObject = <%@:%p>\nKey Path = %@\nChange = %@",[self class],self,_cmd, [self shortDescription], [object class], object, keyPath, [change description]);

	[self stopObservingXgridAgent];
	[NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(xgridAgentDidSyncInstanceVariables:) userInfo:nil repeats:NO];
	
	/*
	return;	
	
	//if already synced, no more observing necessary
	if ( isSynced ) {
		[self stopObservingXgridAgent];
		return;
	}
			
	if ( object == xgridAgent && [xgridAgent isUpdated] == YES && [keyPath isEqualToString:@"isUpdated"] ) {
		[self stopObservingXgridAgent];
		isSynced = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:GEZAgentHookDidSyncNotification object:self];
	}*/
}

- (void)xgridAgentDidSyncInstanceVariables:(NSTimer *)aTimer
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	isSynced = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:GEZAgentHookDidSyncNotification object:self];
}

@end




@implementation GEZAgentHook (GEZAgentHookPrivate)

- (void)setXgridAgent:(XGAgent *)agent
{
	if ( agent != xgridAgent ) {

		//clean up old ivar
		[self stopObservingXgridAgent];
		[xgridAgent release];
		isObserving = NO;
		
		//set up new ivar
		xgridAgent = [agent retain];
		if ( [xgridAgent isUpdated] )
			isSynced = YES;
		else {
			isSynced = NO;
			[self startObservingXgridAgent];
		}
	}
}


- (void)startObservingXgridAgent
{
	if ( isObserving == YES )
		return;
	isObserving = YES;
	[xgridAgent addObserver:self forKeyPath:@"totalCPUPower" options:0 context:NULL];
}

- (void)stopObservingXgridAgent
{
	if ( isObserving == NO )
		return;
	[xgridAgent removeObserver:self forKeyPath:@"totalCPUPower"];
	isObserving = NO;
}

@end