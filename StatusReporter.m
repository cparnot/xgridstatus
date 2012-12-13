//
//  StatusReporter.m
//  XgridStatus
//
//  Created by Charles Parnot on 7/19/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "StatusReporter.h"
#import "GEZServerHook.h"
#import "GEZGridHook.h"
//#import "GEZAgentHook.h"
#import "GEZGridHookReport.h"
#import "PlistCategories.h"
#import "AgentCleaner.h"
#import "JobCleaner.h"

@implementation StatusReporter

#pragma mark *** Initializations ***

- (id)initWithServers:(NSArray *)serverArray reportInterval:(double)interval output:(NSString *)path
{
	self = [super init];
	if ( self != nil ) {
		servers = [serverArray copy];
		reportInterval = interval;
		outputFilePath = [[path stringByStandardizingPath] retain];
		verbose = 2;
		reportType = XgridStatusReportTypeOldPlist;
	}
	return self;
}

- (void)dealloc
{
	[servers release];
	[outputFilePath release];
	[agentCleaners release];
	[currentStatusDictionary release];
	[lastServerReports release];
	[super dealloc];
}

- (void)raiseConnectionError
{
	printf ("Connection error.\n");
	exit (0);
}

//used to notify the user of progress when things go slowly
#define INTERVAL_FOR_LOADING_PROGRESS_REPORTS_DEFAULT 5
- (NSTimeInterval)intervalForLoadingProgressReports
{
	[[NSUserDefaults standardUserDefaults] setObject:@"test" forKey:@"test"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	id userDefaultsValue;
	if ( userDefaultsValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"IntervalForLoadingProgressReports"] )
		return [userDefaultsValue doubleValue];
	else
		return INTERVAL_FOR_LOADING_PROGRESS_REPORTS_DEFAULT;
}

#pragma mark *** Accessors ***

- (void)setVerbose:(BOOL)flag
{
	verbose = (int)flag;
}

- (BOOL)verbose
{
	if ( verbose == 2 )
		return ( reportInterval > 0 || outputFilePath != nil );
	else
		return (BOOL)verbose;
}

- (BOOL)shouldCleanJobs
{
	return shouldCleanJobs;
}

- (void)setShouldCleanJobs:(BOOL)newValue
{
	shouldCleanJobs = newValue;
}

- (int)daysBeforeJobExpiration
{
	return daysBeforeJobExpiration;
}

- (void)setDaysBeforeJobExpiration:(int)newDaysBeforeJobExpiration
{
	daysBeforeJobExpiration = newDaysBeforeJobExpiration;
}

- (void)setShouldCleanAgents:(BOOL)value
{
	shouldCleanAgents = value;
}

- (BOOL)shouldCleanAgents
{
	return shouldCleanAgents;
}


- (BOOL)serverList {
    return serverList;
}

- (void)setServerList:(BOOL)value {
    if (serverList != value) {
        serverList = value;
    }
}

- (BOOL)gridList {
    return gridList;
}

- (void)setGridList:(BOOL)value {
    if (gridList != value) {
        gridList = value;
    }
}

- (BOOL)agentList {
    return agentList;
}

- (void)setAgentList:(BOOL)value {
    if (agentList != value) {
        agentList = value;
    }
}

- (BOOL)jobList {
    return jobList;
}

- (void)setJobList:(BOOL)value {
    if (jobList != value) {
        jobList = value;
    }
}

- (BOOL)agentStats {
    return agentStats;
}

- (void)setAgentStats:(BOOL)value {
    if (agentStats != value) {
        agentStats = value;
    }
}

- (BOOL)jobStats {
    return jobStats;
}

- (void)setJobStats:(BOOL)value {
    if (jobStats != value) {
        jobStats = value;
    }
}

- (BOOL)timeStamp {
    return timeStamp;
}

- (void)setTimeStamp:(BOOL)value {
    if (timeStamp != value) {
        timeStamp = value;
    }
}

- (void)setReportType:(XgridStatusReportType)type
{
	reportType = type;
}



- (BOOL)allServersLoaded
{
	return ( [[servers valueForKeyPath:@"@sum.isLoaded"] intValue] >= [servers count] );
}



#pragma mark *** Status construction ***

//sum of values in a dictionary are calculated using KVC and the @sum operator
NSMutableDictionary *SumOfValuesInDictionaries(NSDictionary *dictionaries, NSArray *keys)
{
	NSMutableDictionary *sum = [NSMutableDictionary dictionaryWithCapacity:[keys count]];
	NSEnumerator *e = [keys objectEnumerator];
	NSString *aKey;
	while ( aKey = [e nextObject] ) {
		NSString *keyPath = [NSString stringWithFormat:@"@sum.%@", aKey];
		[sum setObject:[[dictionaries allValues] valueForKeyPath:keyPath] forKey:aKey];
	}
	return sum;
}

//agent stats need to be aggregated a special way
- (NSMutableDictionary *)sumOfAgentStats:(NSDictionary *)dictionaries
{
	//adding all values except workingAgentPercentage
	NSMutableDictionary *sum = SumOfValuesInDictionaries(dictionaries, [NSArray arrayWithObjects:@"workingMegaHertz", @"offlineAgentCount", @"onlineAgentCount", @"workingAgentCount", @"availableAgentCount", @"unavailableAgentCount", @"totalAgentCount", @"onlineProcessorCount", @"workingProcessorCount", @"availableProcessorCount", @"unavailableProcessorCount", @"offlineProcessorCount", nil]);
	
	//workingAgentPercentage is a special case
	double percentageWorking = 0.0;
	int totalAgentCount = [[sum objectForKey:@"totalAgentCount"] intValue];
	if ( totalAgentCount != 0 )
		percentageWorking = 100.0 * [[sum objectForKey:@"workingAgentCount"] intValue] / totalAgentCount;
	[sum setObject:[NSNumber numberWithFloat:percentageWorking] forKey:@"workingAgentPercentage"];
	
	return sum;
}

//job stats need to be aggregated a special way
- (NSMutableDictionary *)sumOfJobStats:(NSDictionary *)dictionaries
{
	return SumOfValuesInDictionaries(dictionaries, [NSArray arrayWithObjects:@"totalJobCount", @"workingJobCount", @"pendingJobCount", @"startingJobCount", @"runningJobCount", @"suspendedJobCount", @"canceledJobCount", @"failedJobCount", @"finishedJobCount", nil]);
}

//logic to put together several reports that include all kind of agent and job info
- (NSMutableDictionary *)aggregateReports:(NSDictionary *)dictionaries keepChildren:(BOOL)keepChildren childrenKey:(NSString *)childrenKey
{
	NSMutableDictionary *aggregate = [NSMutableDictionary dictionary];
	if ( agentStats ) [aggregate addEntriesFromDictionary:[self sumOfAgentStats:dictionaries]];
	if ( jobStats ) [aggregate addEntriesFromDictionary:[self sumOfJobStats:dictionaries]];
	if ( keepChildren )
		[aggregate setObject:dictionaries forKey:childrenKey];
	//agent and job lists should only be added if not already in the grid list
	else  {
		if ( agentList ) {
			NSMutableDictionary *allAgents = [NSMutableDictionary dictionary];
			NSEnumerator *e = [dictionaries objectEnumerator];
			NSDictionary *oneReport;
			while ( oneReport = [e nextObject] )
				[allAgents addEntriesFromDictionary:[oneReport objectForKey:@"agents"]];
			[aggregate setValue:allAgents forKey:@"agents"];
		}
		if ( jobList ) {
			NSMutableDictionary *allJobs = [NSMutableDictionary dictionary];
			NSEnumerator *e = [dictionaries objectEnumerator];
			NSDictionary *oneReport;
			while ( oneReport = [e nextObject] )
				[allJobs addEntriesFromDictionary:[oneReport objectForKey:@"jobs"]];
			[aggregate setValue:allJobs forKey:@"jobs"];
		}
	}	
	return aggregate;
}


//the dictionary is actually created when calling 'updateStatusDictionary'
- (NSDictionary *)statusDictionary
{
	return currentStatusDictionary;
}

//the report dictionary created by this method is used by all other 'statusXXX' methods
- (BOOL)updateStatusDictionary
{
	//if no server loaded, no new status
	if ( [[servers valueForKeyPath:@"@sum.isLoaded"] intValue] < 1 )
		return NO;
	
	//this will contain a list of subdictionaries, one for each server
	NSMutableDictionary *serverReports = [NSMutableDictionary dictionaryWithCapacity:[servers count]];
	
	//level 1 and level 2 dictionaries = grids and servers
	NSEnumerator *e = [servers objectEnumerator];
	GEZServerHook *aServer;
	while ( aServer = [e nextObject] ) {
		
		//set to nil, so that if nothing comes out of this, it won't be used (see later in the code)
		NSMutableDictionary *oneServerReport = nil;

		//if the server is loaded, it is up to date and we can get the correct information from it
		if ( [aServer isLoaded] ) {
			
			//get report for individual grids
			NSArray *grids = [aServer grids];
			NSMutableDictionary *gridReports = [NSMutableDictionary dictionaryWithCapacity:[grids count]];
			NSEnumerator *ee = [grids objectEnumerator];
			GEZGridHook *aGrid;
			while ( aGrid = [ee nextObject] ) {
				NSMutableDictionary *oneGridReport = [NSMutableDictionary dictionaryWithDictionary:[aGrid gridInfo]];
				if ( agentList ) [oneGridReport setObject:[aGrid agentList] forKey:@"agents"];
				if ( jobList ) [oneGridReport setObject:[aGrid jobList] forKey:@"jobs"];
				if ( agentStats ) [oneGridReport addEntriesFromDictionary:[aGrid agentStats]];
				if ( jobStats) [oneGridReport addEntriesFromDictionary:[aGrid jobStats]];
				[gridReports setObject:oneGridReport forKey:[[aGrid xgridGrid] name]];
			}
			
			//aggregate results for the whole server
			oneServerReport = [self aggregateReports:gridReports keepChildren:gridList childrenKey:@"grids"];
				
		//if the server is not loaded and thus does not have valid information, we use previous values
		} else {
			//printf("    Server %s not loaded\n",[[aServer address] UTF8String]);
			oneServerReport = [lastServerReports objectForKey:[aServer address]];
		}
		
		//add the ser
		if ( oneServerReport != nil )
			[serverReports setObject:oneServerReport forKey:[aServer address]];
	}
	
	//keep the info for the next time, in case some servers get disconnected
	[lastServerReports release];
	lastServerReports = [serverReports copy];
	
	
	//final dictionary could be just the aggregated result or could contain details for each controller
	NSMutableDictionary *finalDictionary = [self aggregateReports:serverReports keepChildren:serverList childrenKey:@"controllers"];
	
	//add time info
	if ( timeStamp ) {
		NSDate *now = [NSDate date];
		[finalDictionary addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
			[now dateWithCalendarFormat:@"%Y" timeZone:nil],@"Year",
			[now dateWithCalendarFormat:@"%m" timeZone:nil],@"MonthIndex",
			[now dateWithCalendarFormat:@"%B" timeZone:nil],@"MonthName",
			[now dateWithCalendarFormat:@"%b" timeZone:nil],@"MonthNameShort",
			[now dateWithCalendarFormat:@"%e" timeZone:nil],@"Day",
			[now dateWithCalendarFormat:@"%H" timeZone:nil],@"Hours",
			[now dateWithCalendarFormat:@"%M" timeZone:nil],@"Minutes",
			[now dateWithCalendarFormat:@"%S" timeZone:nil],@"Seconds",
			[now dateWithCalendarFormat:@"%Z" timeZone:nil],@"TimeZone",
			nil]];
	}
	
	//keep the current report in memory
	[currentStatusDictionary release];
	currentStatusDictionary = [finalDictionary copy];
	
	//we did it!!!
	return YES;
}


#pragma mark *** Status in different formats ***

- (NSData *)statusBinaryData
{
	NSString *error = nil;
	NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:[self statusDictionary] format:NSPropertyListBinaryFormat_v1_0 errorDescription:&error];
	if ( error != nil ) {
		printf("could not generate a report in binary format from the data because of error:\n%s\n",[error UTF8String]);
		return [NSData data];
	}
	return plistData;
}

- (NSString *)statusBinaryString
{
	return [[self statusBinaryData] description];
}


- (NSData *)statusPlistData
{
	NSString *error = nil;
	NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:[self statusDictionary] format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
	if ( error != nil ) {
		printf("could not generate a report in plist format from the data because of error:\n%s\n",[error UTF8String]);
		return [NSData data];
	}
	return plistData;
}

- (NSString *)statusPlistString
{
	return [[[NSString alloc] initWithData:[self statusPlistData] encoding:NSUTF8StringEncoding] autorelease];
}


- (NSString *)statusXMLString
{
	return [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gauge>%@</gauge>\n",
		[[self statusDictionary] xmlStringRepresentation]];
}

- (NSData *)statusXMLData
{
	return [[self statusXMLString] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
}


- (NSString *)statusSimpleString
{
	return [[self statusDictionary] description];
}

- (NSData *)statusSimpleData
{
	return [[self statusSimpleString] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
}

- (NSString *)statusString
{
	if ( reportType == XgridStatusReportTypeOldPlist )
		return [self statusSimpleString];
	else if ( reportType == XgridStatusReportTypePlist )
		return [self statusPlistString];
	else if ( reportType == XgridStatusReportTypeXML )
		return [self statusXMLString];
	else if ( reportType == XgridStatusReportTypeBinary )
		return [self statusBinaryString];
	else
		return [NSString string];
}

- (NSData *)statusData
{
	if ( reportType == XgridStatusReportTypeOldPlist )
		return [self statusSimpleData];
	else if ( reportType == XgridStatusReportTypePlist )
		return [self statusPlistData];
	else if ( reportType == XgridStatusReportTypeXML )
		return [self statusXMLData];
	else if ( reportType == XgridStatusReportTypeBinary )
		return [self statusBinaryData];
	else
		return [NSData data];
}

#pragma mark *** Reports to the user ***

- (void)reportStatus:(NSTimer *)aTimer
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//only report if the status dictionary changed
	if ( [self updateStatusDictionary] ) {
		if ( outputFilePath == nil ) {
			printf ( "%s\n", [[self statusString] UTF8String] );
		} else {
			NSData *statusData = [self statusData];
			if ( [statusData writeToFile:outputFilePath atomically:YES] ==NO )
				printf ( "Error writing output file.\n" );
		}
	}
	
	if ( reportInterval <= 0.0 )
		exit (0);
}

- (void)setShouldReportStatus:(BOOL)flag
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	//stop the timer if necessary
	if ( flag == NO && reportStatusTimer != nil ) {
		[reportStatusTimer invalidate];
		[reportStatusTimer autorelease];
		reportStatusTimer = nil;
	}
	
	//start the timer if not yet started
	if ( flag == YES && reportStatusTimer == nil ) {
		if ( [self verbose] ) {
			if ( reportInterval > 0 )
				printf ( "All controllers ready. Writing report every %d seconds.\n", (int)(reportInterval) );
			else
				printf ( "All controllers ready. Writing report.\n");
		}
		[self reportStatus:nil];
		reportStatusTimer = [NSTimer scheduledTimerWithTimeInterval:reportInterval target:self selector:@selector(reportStatus:) userInfo:nil repeats:YES];
		[reportStatusTimer retain];
	}
}

- (void)start
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	NSEnumerator *e = [servers objectEnumerator];	
	GEZServerHook *aServer;
	while ( aServer = [e nextObject] ) {
		[aServer setAutoconnect:YES];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDidConnect:) name:GEZServerHookDidConnectNotification object:aServer];		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDidLoad:) name:GEZServerHookDidLoadNotification object:aServer];		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDidDisconnect:) name:GEZServerHookDidDisconnectNotification object:aServer];		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDidNotConnect:) name:GEZServerHookDidNotConnectNotification object:aServer];		
		[aServer connect];
		if ( [aServer isLoaded] )
			[self serverDidLoad:[NSNotification notificationWithName:GEZServerHookDidLoadNotification object:aServer]];
	}
	
	//report server loading to keep the user entertained if it takes a while
	if ( [self verbose] )
		[NSTimer scheduledTimerWithTimeInterval:[self intervalForLoadingProgressReports] target:self selector:@selector(reportProgress:) userInfo:nil repeats:YES];

}

- (void)reportProgressForServerHook:(GEZServerHook *)aServer
{
	const char *address = [[aServer address] UTF8String];
	if ( [aServer isLoaded] )
		return;
	else if ( [aServer isConnecting] )
		printf("In progress: Controller '%s' connecting...\n", address);
	else {
		int countGrids = [[aServer grids] count];
		NSArray *allAgents = [aServer valueForKeyPath:@"grids.@distinctUnionOfArrays.xgridGrid.agents"];
		NSArray *allJobs = [aServer valueForKeyPath:@"grids.@distinctUnionOfArrays.xgridGrid.jobs"];
		int countAgents = [allAgents count];
		int countJobs = [allJobs count];
		if ( [aServer isUpdated] ) {
			int countUpdatedGrids = [[aServer valueForKeyPath:@"grids.@sum.isUpdated"] intValue];
			//if all grids are updated, we know for sure the number of agents
			if ( countUpdatedGrids == countGrids ) {
				int countLoadedGrids = [[aServer valueForKeyPath:@"grids.@sum.isLoaded"] intValue];
				int countUpdatedAgents = [[allAgents valueForKeyPath:@"@sum.isUpdated"] intValue];
				int countUpdatedJobs = [[allJobs valueForKeyPath:@"@sum.isUpdated"] intValue];
				printf("In progress: Controller '%s' updated, %d/%d grids loaded, %d/%d agents loaded, %d/%d jobs loaded\n", address, countLoadedGrids, countGrids, countUpdatedAgents, countAgents, countUpdatedJobs, countJobs);
			} else
				printf("In progress: Controller '%s' updated, %d/%d grids updated\n", address, countUpdatedGrids, countGrids);
		} else {
			printf("In progress: Controller '%s' connected, waiting for grids...\n", address);
		}
	}
}

- (void)reportProgress:(NSTimer *)aTimer
{
	if ( [self allServersLoaded] ) {
		[aTimer invalidate];
		return;
	}
	NSEnumerator *e = [servers objectEnumerator];
	GEZServerHook *aServer;
	while ( aServer = [e nextObject] )
		[self reportProgressForServerHook:aServer];
}

#pragma mark *** GEZServerHook Notifications ***

- (void)serverDidConnect:(NSNotification *)notification
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	if ( [self verbose] )
		printf ( "Controller '%s' connected.\n", [[[notification object] address] UTF8String] );
}


- (void)serverDidLoad:(NSNotification *)notification
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	GEZServerHook *theServer = [notification object];

	//report about the server just loaded
	if ( [self verbose] ) {
		NSString *message = [NSString stringWithFormat:@"Controller '%@' loaded, %@ grids, %d agents, %d jobs\n", [theServer address], [theServer valueForKeyPath:@"grids.@count"], [[theServer valueForKeyPath:@"grids.@distinctUnionOfArrays.xgridGrid.agents"] count], [[theServer valueForKeyPath:@"grids.@distinctUnionOfArrays.xgridGrid.jobs"] count]];
		printf ( "%s", [message UTF8String] );
	}

	// start the agent cleaners
	if (  [self shouldCleanAgents] ) {
		if ( agentCleaners == nil )
			agentCleaners = [[NSMutableArray alloc] init];
		NSEnumerator *e = [[theServer grids] objectEnumerator];
		GEZGridHook *aGrid;
		while ( aGrid = [e nextObject] ) {
			AgentCleaner *cleaner = [[[AgentCleaner alloc] initWithGrid:aGrid] autorelease];
			[cleaner setVerbose:[self verbose]];
			[agentCleaners addObject:cleaner];
			[cleaner start];
		}
	}

	// job cleaning is inactive for now
	if ( NO /* [self shouldCleanJobs] == YES && [self daysBeforeJobExpiration] > 0 */ ) {
		// start the job cleaners
		if ( jobCleaners == nil )
			jobCleaners = [[NSMutableArray alloc] init];
		NSEnumerator *e = [[theServer grids] objectEnumerator];
		GEZGridHook *aGrid;
		while ( aGrid = [e nextObject] ) {
			JobCleaner *cleaner = [[[JobCleaner alloc] initWithGrid:aGrid] autorelease];
			[cleaner setVerbose:[self verbose]];
			[cleaner setDaysBeforeExpiration:daysBeforeJobExpiration];
			[jobCleaners addObject:cleaner];
			[cleaner start];
		}
	}

	//maybe all servers are loaded
	if ( [self allServersLoaded] ) {
		[self setShouldReportStatus:YES];
	}

}

//failed connection at the first attempt will terminate the program
- (void)serverDidNotConnect:(NSNotification *)notification
{
	if ( [self statusDictionary] == nil ) {
		if ( [self verbose] ) {
			printf ( "Controller '%s' did not connect.\n", [[[notification object] address] UTF8String] );
			printf ( "The program will now exit.\n");
		}
		exit(0);
	}
	
}

//disconnection while running will display a message
- (void)serverDidDisconnect:(NSNotification *)notification
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	if ( [self verbose] ) {
		printf ( "Controller '%s' disconnected. Connection will be tried again later. [%s]\n", [[[notification object] address] UTF8String], [[[NSDate date] description] UTF8String] );
		if ( [[servers valueForKeyPath:@"@sum.isLoaded"] intValue] > 0 )
			printf ( "Reports will continue using the data available before disconnection.\n" );
		
		//remove agent cleaners for the corresponding grids
		NSEnumerator *e = [[[agentCleaners copy] autorelease] objectEnumerator];
		AgentCleaner *cleaner;
		while ( cleaner = [e nextObject] ) {
			if ( [[cleaner grid] serverHook] == [notification object] )
				[agentCleaners removeObjectIdenticalTo:cleaner];
		}

		//remove agent cleaners for the corresponding grids
		e = [[[jobCleaners copy] autorelease] objectEnumerator];
		JobCleaner *cleaner2;
		while ( cleaner2 = [e nextObject] ) {
			if ( [[cleaner2 grid] serverHook] == [notification object] )
				[jobCleaners removeObjectIdenticalTo:cleaner2];
		}

	}
}

@end
