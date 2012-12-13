//
//  GridReport.m
//  XgridStatus
//
//  Created by Charles Parnot on 7/25/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "GridReport.h"
#import "XgridPrivate.h"
#import "ResourceStateToStringTransformer.h"

@implementation GEZGridHook (GridReport)



- (NSDictionary *)reportWithAgentList:(BOOL)flag
{
	//dictionary to keep information about individual agents (if flag == YES)
	//NSArray *agents = [[[self xgridGrid] controller] agents];
	NSArray *agents = [[self xgridGrid] agents];
	NSMutableDictionary *agentInfo = [NSMutableDictionary dictionaryWithCapacity:[agents count]];
	
	//variables to add agent contributions ––> final summary
	float totalMegaHertz = 0;
	float workingMegaHertzAgents = 0;
	float workingMegaHertzProcessors = 0;
	int onlineProcessorCount = 0;
	int agentCount[6] = { 0, 0, 0, 0, 0, 0 };
	int processorCount[7] = { 0, 0, 0, 0, 0, 0, 0 };
	
	//looping thru the list of agents
	//XGAgent is a private class, so we use a protocol instead to avoid compiler warnings (see XgridPrivate.h)
	NSEnumerator *e = [agents objectEnumerator];
	XGAgent *agent;
	while ( agent = [e nextObject] ) {

		//add individual info if requested
		if (flag) {
			NSString *identifier = [agent identifier];
			NSString *name = [agent name];
			NSString *address = [agent address];
			NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
				(identifier?identifier:@""),@"Identifier",
				(name?name:@""),@"Name",
				(address?address:@""),@"Address",
				[[ResourceStateToStringTransformer sharedTransformer] transformedIntValue:[agent state]],@"State",
				[NSNumber numberWithFloat:[agent totalCPUPower]],@"TotalCPUPower",
				[NSNumber numberWithFloat:[agent activeCPUPower]],@"ActiveCPUPower",
				[NSNumber numberWithInt:[agent totalProcessorCount]],@"TotalProcessorCount",
				[NSNumber numberWithInt:[agent activeProcessorCount]],@"ActiveProcessorCount",
				nil];
			[agentInfo setObject:info forKey:[agent name]];
		}
		
		//the CPUPower is in MegaHertz
		totalMegaHertz += [agent totalCPUPower];
		workingMegaHertzAgents += [agent activeCPUPower];
		
		//keep trak of the number of agents in each state
		XGResourceState state = [agent state];
		agentCount[state] ++;
		
		//for the processors, it is more subtle
		//I use onlineProcessorCount to count TOTAL number of processors
		int total = [agent totalProcessorCount];
		int active = [agent activeProcessorCount];
		int inactive = total - active;
		onlineProcessorCount += total;
		if ( active > 0 ) {
			processorCount[XGResourceStateWorking] += active;
			float cpu = [agent totalCPUPower] / total;
			workingMegaHertzProcessors += active * cpu;
		}
		processorCount[state] += inactive;
		
		//printf ( "agent '%s' at IP '%s' : %d\n", [[agent name] UTF8String], [[agent address] UTF8String], [agent state] );
	}
	
	//get the working CPU
	float workingMegaHertzJobs = 0;
	XGJob *job;
	NSEnumerator *eee = [[[self xgridGrid] jobs] objectEnumerator];
	while ( job = [eee nextObject] )
		workingMegaHertzJobs += [job activeCPUPower];
	
	//final dictionary
	NSString *name = [[self xgridGrid] name];
	NSString *identifier = [[self xgridGrid] identifier];
	NSDictionary *reportDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		
		name?name:@"", @"name",
		identifier?identifier:@"", @"identifier",
		
		[NSNumber numberWithFloat:workingMegaHertzProcessors],@"workingMegaHertz",
		
		[NSNumber numberWithInt:agentCount[XGResourceStateOffline]],@"offlineAgentCount",
		[NSNumber numberWithInt:[agents count]-agentCount[XGResourceStateOffline]],@"onlineAgentCount",
		[NSNumber numberWithInt:agentCount[XGResourceStateWorking]],@"workingAgentCount",
		[NSNumber numberWithInt:agentCount[XGResourceStateAvailable]],@"availableAgentCount",
		[NSNumber numberWithInt:agentCount[XGResourceStateUnavailable]],@"unavailableAgentCount",
		[NSNumber numberWithInt:[agents count]],@"totalAgentCount",
		
		
		[NSNumber numberWithFloat:100.0 * agentCount[XGResourceStateWorking] / [agents count]],@"workingAgentPercentage",
		
		[NSNumber numberWithInt:onlineProcessorCount],@"onlineProcessorCount",
		[NSNumber numberWithInt:processorCount[XGResourceStateWorking]],@"workingProcessorCount",
		[NSNumber numberWithInt:processorCount[XGResourceStateAvailable]],@"availableProcessorCount",
		[NSNumber numberWithInt:processorCount[XGResourceStateUnavailable]],@"unavailableProcessorCount",
		[NSNumber numberWithInt:onlineProcessorCount - processorCount[XGResourceStateWorking] - processorCount[XGResourceStateAvailable] - processorCount[XGResourceStateUnavailable]], @"offlineProcessorCount",
		
		nil];
	if ( flag ) {
		NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithDictionary:reportDictionary];
		[tempDic setObject:[NSDictionary dictionaryWithDictionary:agentInfo] forKey:@"agents"];
		reportDictionary = [NSDictionary dictionaryWithDictionary:tempDic];
	}
	
#ifdef DEBUG
	NSMutableDictionary *moreStuff = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithFloat:workingMegaHertzJobs],@"workingMegaHertzJobs",
		[NSNumber numberWithFloat:workingMegaHertzAgents],@"workingMegaHertzAgents",
		[NSNumber numberWithFloat:workingMegaHertzProcessors],@"workingMegaHertzProcessors",
		[NSNumber numberWithFloat:totalMegaHertz],@"totalMegaHertz",
		
		
		[NSNumber numberWithInt:processorCount[XGResourceStateOffline]],@"offlineStateProcessorCount",
		nil];
	[moreStuff addEntriesFromDictionary:reportDictionary];
	reportDictionary = [NSDictionary dictionaryWithDictionary:moreStuff];
#endif
	
	return  reportDictionary;
}


@end
