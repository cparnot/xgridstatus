//
//  GEZGridHookPoser.m
//  XgridStatus
//
//  Created by Charles Parnot on 3/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GEZGridHookPoser.h"
#import "GEZGridHookExtended.h"

@implementation GEZGridHookPoser

- (id)initWithXgridGrid:(XGGrid *)aGrid serverHook:(GEZServerHook *)aServer
{
	//if self is the subclass, the substitution already happened and the message simply needs to go to the superclass
	if ( [self class] == [GEZGridHookExtended class] )
		 return [super initWithXgridGrid:aGrid serverHook:aServer];
	
	//otherwise, do the substitution
	else {
		[self release];
		self = [[GEZGridHookExtended alloc] initWithXgridGrid:aGrid serverHook:aServer];
		return self;
	} 
	
}

@end
