//
//  GridReport.h
//  XgridStatus
//
//  Created by Charles Parnot on 7/25/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

/* produces report for an individual grid */
/* implemented as a category on GEZGridHook */


#import "GEZGridHook.h"


@interface GEZGridHook (GridReport)

- (NSDictionary *)reportWithAgentList:(BOOL)flag;

@end
