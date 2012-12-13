//
//  GEZGridHookReport.h
//  XgridStatus
//
//  Created by Charles Parnot on 7/25/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

/* Category on GEZGridHook that can produce reports for the corresponding XGGrid object */



#import "GEZGridHook.h"


@interface GEZGridHook (GEZGridHookReport)

- (NSDictionary *)gridInfo;
- (NSDictionary *)agentList;
- (NSDictionary *)agentStats;
- (NSDictionary *)jobStats;
- (NSDictionary *)jobList;

@end
