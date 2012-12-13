//
//  GEZGridHookPoser.h
//  XgridStatus
//
//  Created by Charles Parnot on 3/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

/* used to poseAsClass for GEZGridHook */

#import "GEZGridHook.h"

@interface GEZGridHookPoser : GEZGridHook
{

}

//this is the only method overriding the superclass that this class will pose for
//this method will actually return an instance of GEZGridHookExtended by changing the value of self
- (id)initWithXgridGrid:(XGGrid *)aGrid serverHook:(GEZServerHook *)aServer;

@end


//private methods of the superclass GEZGridHook that I want to expose here and not in the GridEZ framework
@interface GEZGridHook (GEZGridHookPrivate)
- (id)initWithXgridGrid:(XGGrid *)aGrid serverHook:(GEZServerHook *)aServer;
@end

