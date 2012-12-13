//
//  GEZGridHookReport.m
//  XgridStatus
//
//  Created by Charles Parnot on 7/25/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "GEZGridHookReport.h"
#import "XgridPrivate.h"
#import "ResourceStateToStringTransformer.h"

@implementation GEZGridHook (GEZGridHookReport)

//returns empty string if nil, otherwise the object itself
//useful to avoid nil entries in NSDictionary factory methods
id nonNilValue(id inputValue)
{
	return inputValue?inputValue:@"";
}

- (NSDictionary *)gridInfo
{
	//avoid nil values
	return [NSDictionary dictionaryWithObjectsAndKeys: nonNilValue([[self xgridGrid] name]), @"name", nonNilValue([[self xgridGrid] identifier]), @"identifier", nil];
}


- (NSDictionary *)agentList
{
	NSEnumerator *e = [[[self xgridGrid] agents] objectEnumerator];
	XGAgent *agent;
	NSMutableDictionary *agentList = [NSMutableDictionary dictionaryWithCapacity:[[[self xgridGrid] agents] count]];
	while ( agent = [e nextObject] ) {
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
			nonNilValue([agent identifier]),@"Identifier",
			nonNilValue([agent name]),@"Name",
			nonNilValue([agent address]),@"Address",
			[agent humanReadableState],@"State",
			[NSNumber numberWithFloat:[agent totalCPUPower]],@"TotalCPUPower",
			[NSNumber numberWithFloat:[agent activeCPUPower]],@"ActiveCPUPower",
			[NSNumber numberWithInt:[agent totalProcessorCount]],@"TotalProcessorCount",
			[NSNumber numberWithInt:[agent activeProcessorCount]],@"ActiveProcessorCount",
			nil];
		[agentList setObject:info forKey:[agent identifier]];
	}
	return [[agentList copy] autorelease];
}

- (NSDictionary *)agentStats
{
	//variables to add agent contributions
	float totalMegaHertz = 0;
	float workingMegaHertzAgents = 0;
	float workingMegaHertzProcessors = 0;
	int onlineProcessorCount = 0;
	int agentCount[6] = { 0, 0, 0, 0, 0, 0 };
	int processorCount[7] = { 0, 0, 0, 0, 0, 0, 0 };
	
	//looping thru the list of agents
	//XGAgent is a private class, so we use a protocol instead to avoid compiler warnings (see XgridPrivate.h)
	NSArray *agents = [[self xgridGrid] agents];
	NSEnumerator *e = [agents objectEnumerator];
	XGAgent *agent;
	while ( agent = [e nextObject] ) {
		
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
			if ( inactive > 0 )
				processorCount[XGResourceStateAvailable] += inactive;
		}
		processorCount[state] += inactive;
	}
	
	//final dictionary
	float workingAgentPercentage = 100.0 * agentCount[XGResourceStateWorking] / (([agents count])?[agents count]:1.0);
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithFloat:workingMegaHertzProcessors],@"workingMegaHertz",
		
		[NSNumber numberWithInt:agentCount[XGResourceStateOffline]],@"offlineAgentCount",
		[NSNumber numberWithInt:[agents count]-agentCount[XGResourceStateOffline]],@"onlineAgentCount",
		[NSNumber numberWithInt:agentCount[XGResourceStateWorking]],@"workingAgentCount",
		[NSNumber numberWithInt:agentCount[XGResourceStateAvailable]],@"availableAgentCount",
		[NSNumber numberWithInt:agentCount[XGResourceStateUnavailable]],@"unavailableAgentCount",
		[NSNumber numberWithInt:[agents count]],@"totalAgentCount",

		[NSNumber numberWithFloat:workingAgentPercentage],@"workingAgentPercentage",
		
		[NSNumber numberWithInt:onlineProcessorCount],@"onlineProcessorCount",
		[NSNumber numberWithInt:processorCount[XGResourceStateWorking]],@"workingProcessorCount",
		[NSNumber numberWithInt:processorCount[XGResourceStateAvailable]],@"availableProcessorCount",
		[NSNumber numberWithInt:processorCount[XGResourceStateUnavailable]],@"unavailableProcessorCount",
		[NSNumber numberWithInt:onlineProcessorCount - processorCount[XGResourceStateWorking] - processorCount[XGResourceStateAvailable] - processorCount[XGResourceStateUnavailable]], @"offlineProcessorCount",
		
		nil];
}


- (NSDictionary *)jobList
{
	NSMutableDictionary *jobList = [NSMutableDictionary dictionaryWithCapacity:[[[self xgridGrid] jobs] count]];
	NSEnumerator *e = [[[self xgridGrid] jobs] objectEnumerator];
	XGJob *job;
	while ( job = [e nextObject] ) {
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
			nonNilValue([job identifier]),@"Identifier",
			nonNilValue([job name]),@"Name",
			[job humanReadableState],@"State",
			nonNilValue([job applicationIdentifier]),@"ApplicationIdentifier",
			//nonNilValue([job applicationInfo]),@"ApplicationInfo",
			[NSNumber numberWithFloat:[job activeCPUPower]],@"ActiveCPUPower",
			[NSNumber numberWithFloat:[job percentDone]],@"PercentDone",
			[NSNumber numberWithInt:[job completedTaskCount]],@"CompletedTaskCount",
			[NSNumber numberWithInt:[job taskCount]],@"TaskCount",
			nonNilValue([job dateStarted]),@"DateStarted",
			nonNilValue([job dateStopped]),@"DateStopped",
			nonNilValue([job dateSubmitted]),@"DateSubmitted",
			nil];
		[jobList setObject:info forKey:[job identifier]];
	}
	return [[jobList copy] autorelease];
}


- (NSDictionary *)jobStats
{
	
	//counting the number of jobs in the different states
	int stateCount[15] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
	NSArray *jobs = [[self xgridGrid] jobs];
	NSEnumerator *e = [jobs objectEnumerator];
	XGJob *job;
	while ( job = [e nextObject] )
		stateCount[[job state]] ++;
	
	//I could later add more entries if it turns out they are relevant
	return [ NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:[jobs count]], @"totalJobCount",
	    //[NSNumber numberWithInt:stateCount[XGResourceStateUninitialized]   ]   , @"uninitializedJobCount",
	    //[NSNumber numberWithInt:stateCount[XGResourceStateOffline]         ]   , @"offlineJobCount",
	    //[NSNumber numberWithInt:stateCount[XGResourceStateConnecting]      ]   , @"connectingJobCount",
	    //[NSNumber numberWithInt:stateCount[XGResourceStateUnavailable]     ]   , @"unavailableJobCount",
	    //[NSNumber numberWithInt:stateCount[XGResourceStateAvailable]       ]   , @"availableJobCount",
	    [NSNumber numberWithInt:stateCount[XGResourceStateWorking]         ]   , @"workingJobCount",
	    [NSNumber numberWithInt:stateCount[XGResourceStatePending]         ]   , @"pendingJobCount",
	    [NSNumber numberWithInt:stateCount[XGResourceStateStarting]        ]   , @"startingJobCount",
	    //[NSNumber numberWithInt:stateCount[XGResourceStateStagingIn]       ]   , @"stagingInJobCount",
	    [NSNumber numberWithInt:stateCount[XGResourceStateRunning]         ]   , @"runningJobCount",
	    [NSNumber numberWithInt:stateCount[XGResourceStateSuspended]       ]   , @"suspendedJobCount",
	    //[NSNumber numberWithInt:stateCount[XGResourceStateStagingOut]      ]   , @"stagingOutJobCount",
	    [NSNumber numberWithInt:stateCount[XGResourceStateCanceled]        ]   , @"canceledJobCount",
	    [NSNumber numberWithInt:stateCount[XGResourceStateFailed]          ]   , @"failedJobCount",
	    [NSNumber numberWithInt:stateCount[XGResourceStateFinished]        ]   , @"finishedJobCount",
		nil];
	
}

@end
