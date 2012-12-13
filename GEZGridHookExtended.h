//
//  GEZGridHookExtended.h
//
//  GridEZ
//
//  Copyright 2006, 2007 Charles Parnot. All rights reserved.
//


/*
 The GEZGridHook class is a private class.
 It is only used by GEZServerHook to monitor XGGrid objects owned by an XGController. The GEZServerHook simply implements the GEZGridHookServerProtocol to receive callbacks when the grid is updated, loaded, deleted,...
 The code for this class is designed to work with GEZServerHook and is not very portable
 */


//APPKIT_EXTERN NSString *GEZGridHookDidChangeAgentsNotification;
//APPKIT_EXTERN NSString *GEZGridHookDidLoadAgentsNotification;

#import "GEZGridHookPoser.h"

@class GEZServerHook;
@class GEZResourceObserver;
@class GEZResourceArrayObserver;

@interface GEZGridHookExtended : GEZGridHookPoser
{
	GEZResourceObserver *xgridGridObserverForAgentsKey;
	//observing XGAgent objects
	GEZResourceArrayObserver *xgridAgentsObserver;
	BOOL allAgentsUpdated;
}

- (BOOL)agentsLoaded;

@end

