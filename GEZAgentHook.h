//
//  GEZAgentHook.h
//  XgridStatus
//
//  Created by Charles Parnot on 8/10/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XgridPrivate.h"

APPKIT_EXTERN NSString *GEZAgentHookDidSyncNotification;


@interface GEZAgentHook : NSObject
{
	XGAgent *xgridAgent;
	BOOL isSynced;
	BOOL isObserving;
}

+ (GEZAgentHook *)agentHookWithXgridAgent:(XGAgent *)agent;

- (id)initWithXgridAgent:(XGAgent *)agent;
- (XGAgent *)xgridAgent;
- (BOOL)isSynced;


@end
