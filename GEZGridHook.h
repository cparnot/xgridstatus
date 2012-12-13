//
//  GEZGridHook.h
//
//  GridEZ
//
//  Copyright 2006 Charles Parnot. All rights reserved.
//

/* __BEGIN_LICENSE_GRIDEZ__
This file is part of "GridEZ.framework". "GridEZ.framework" is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version. "GridEZ.framework" is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details. You should have received a copy of the GNU Lesser General Public License along with GridEZ.framework; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
__END_LICENSE__ */



/*
 The GEZGridHook class is a private class.
 It is only used by GEZServerHook to monitor XGGrid objects owned by an XGController. The GEZServerHook simply implements the GEZGridHookServerProtocol to receive callbacks when the grid is synced, loaded, deleted,...
 The code for this class is designed to work with GEZServerHook and is not very portable
 */


APPKIT_EXTERN NSString *GEZGridHookDidSyncNotification;
APPKIT_EXTERN NSString *GEZGridHookDidLoadNotification;
APPKIT_EXTERN NSString *GEZGridHookDidChangeNameNotification;
APPKIT_EXTERN NSString *GEZGridHookDidChangeJobsNotification;
APPKIT_EXTERN NSString *GEZGridHookDidChangeAgentsNotification;
APPKIT_EXTERN NSString *GEZGridHookDidLoadAgentsNotification;


@class GEZServerHook;

@interface GEZGridHook : NSObject
{
	XGGrid *xgridGrid;
	GEZServerHook *serverHook;
	int gridHookState; //private enum
	BOOL shouldObserveJobs;
	BOOL shouldObserveAgents;
	BOOL agentsLoaded;
	NSSet *agentHooks;
}

+ (GEZGridHook *)gridHookWithXgridGrid:(XGGrid *)aGrid serverHook:(GEZServerHook *)aServer;
+ (GEZGridHook *)gridHookWithIdentifier:(NSString *)identifier serverHook:(GEZServerHook *)aServer;

//accessors
- (GEZServerHook *)serverHook;
- (NSSet *)agentHooks;
- (void)setXgridGrid:(XGGrid *)newGrid;
- (XGGrid *)xgridGrid;
- (BOOL)isSynced;
- (BOOL)isLoaded;
- (BOOL)agentsLoaded;
- (BOOL)shouldObserveJobs;
- (void)setShouldObserveJobs:(BOOL)flag;
- (BOOL)shouldObserveAgents;
- (void)setShouldObserveAgents:(BOOL)flag;

@end

