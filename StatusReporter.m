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
#import "GEZAgentHook.h"
#import "GridReport.h"
#import "PlistCategories.h"

//used to notify the user of progress when things go slowly
#define PROGRESS_NOTIFICATION_INTERVAL 10.0

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
	[super dealloc];
}

- (void)raiseConnectionError
{
	printf ("Connection error.\n");
	exit (0);
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

- (void)setAgentDetails:(BOOL)flag
{
	agentDetails = flag;
}

- (void)setGridDetails:(BOOL)flag
{
	gridDetails = flag;
}

- (void)setServerDetails:(BOOL)flag
{
	serverDetails = flag;
}

- (void)setReportType:(XgridStatusReportType)type
{
	reportType = type;
}


- (int)countServerLoaded
{
	int countServerLoaded = 0;
	NSEnumerator *e = [servers objectEnumerator];
	GEZServerHook *aServer;
	while ( aServer = [e nextObject] )
		if ( [aServer isLoaded] )
			countServerLoaded++;
	return countServerLoaded;
}

- (BOOL)allServersLoaded
{
	return ( [self countServerLoaded] >= [servers count] );
}

- (int)countAgents
{
	int countAgents = 0;
	NSEnumerator *e = [servers objectEnumerator];
	GEZServerHook *aServer;
	while ( aServer = [e nextObject] ) {
		NSEnumerator *ee = [[aServer grids] objectEnumerator];
		GEZGridHook *aGrid;
		while ( aGrid = [ee nextObject] )
			countAgents += [[[aGrid xgridGrid] agents] count];
	}
	return countAgents;
}

- (int)countAgentLoaded
{
	int countAgentLoaded = 0;
	NSEnumerator *e = [servers objectEnumerator];
	GEZServerHook *aServer;
	while ( aServer = [e nextObject] ) {
		NSEnumerator *ee = [[aServer grids] objectEnumerator];
		GEZGridHook *aGrid;
		while ( aGrid = [ee nextObject] ) {
			NSEnumerator *eee = [[aGrid agentHooks] objectEnumerator];
			GEZAgentHook *anAgent;
			while ( anAgent = [eee nextObject] )
				if ( [anAgent isSynced] )
					countAgentLoaded ++;
		}
	}
	return countAgentLoaded;
}

- (BOOL)allAgentsLoaded
{
	BOOL allReady = YES;
	NSEnumerator *e1 = [servers objectEnumerator];
	GEZServerHook *aServer;
	while ( aServer = [e1 nextObject] ) {
		NSArray *grids = [aServer grids];
		if ( [grids count] == 0 ) {
			allReady = NO;
			[e1 allObjects];
		}
		NSEnumerator *e2 = [grids objectEnumerator];
		GEZGridHook *aGrid;
		while ( aGrid = [e2 nextObject]) {
			if ( [aGrid agentsLoaded] == NO ) {
				allReady = NO;
				[e2 allObjects];
				[e1 allObjects];
			}
		}
	}
	return allReady;
}


#pragma mark *** Status construction ***

NSNumber *floatSum(NSDictionary *dic1, NSDictionary *dic2, NSString *key)
{
	return [NSNumber numberWithFloat:[[dic1 objectForKey:key] floatValue]+[[dic2 objectForKey:key] floatValue]];
}

NSNumber *intSum(NSDictionary *dic1, NSDictionary *dic2, NSString *key)
{
	return [NSNumber numberWithInt:[[dic1 objectForKey:key] intValue]+[[dic2 objectForKey:key] intValue]];
}


- (NSMutableDictionary *)addStatusDictionaries:(NSArray *)dictionaries
{
	NSMutableDictionary *sum = [NSMutableDictionary dictionaryWithCapacity:20];
	NSMutableDictionary *agents = [NSMutableDictionary dictionary];
	NSEnumerator *e = [dictionaries objectEnumerator];
	NSDictionary *dict;
	while ( dict = [e nextObject] ) {
		
		[sum setObject:floatSum(sum,dict,@"workingMegaHertz") forKey:@"workingMegaHertz"];
		
		[sum setObject:intSum(sum,dict,@"offlineAgentCount") forKey:@"offlineAgentCount"];
		[sum setObject:intSum(sum,dict,@"onlineAgentCount") forKey:@"onlineAgentCount"];
		[sum setObject:intSum(sum,dict,@"workingAgentCount") forKey:@"workingAgentCount"];
		[sum setObject:intSum(sum,dict,@"availableAgentCount") forKey:@"availableAgentCount"];
		[sum setObject:intSum(sum,dict,@"unavailableAgentCount") forKey:@"unavailableAgentCount"];
		[sum setObject:intSum(sum,dict,@"totalAgentCount") forKey:@"totalAgentCount"];
		
		[sum setObject:intSum(sum,dict,@"onlineProcessorCount") forKey:@"onlineProcessorCount"];
		[sum setObject:intSum(sum,dict,@"workingProcessorCount") forKey:@"workingProcessorCount"];
		[sum setObject:intSum(sum,dict,@"availableProcessorCount") forKey:@"availableProcessorCount"];
		[sum setObject:intSum(sum,dict,@"unavailableProcessorCount") forKey:@"unavailableProcessorCount"];
		[sum setObject:intSum(sum,dict,@"offlineProcessorCount") forKey:@"offlineProcessorCount"];
		
		if ( [dict objectForKey:@"agents"] )
			[agents addEntriesFromDictionary:[dict objectForKey:@"agents"]];

	}

	float percentageWorking = 100.0 * [[sum objectForKey:@"workingAgentCount"] intValue] / [[sum objectForKey:@"totalAgentCount"] intValue];
	[sum setObject:[NSNumber numberWithFloat:percentageWorking] forKey:@"workingAgentPercentage"];
	
	if ( [agents count] > 0 )
		[sum setObject:agents forKey:@"agents"];	
	
	return sum;
}


- (NSDictionary *)statusDictionary
{
	NSMutableDictionary *serverReports = [NSMutableDictionary dictionaryWithCapacity:[servers count]];
	
	//level 1 and level 2 dictionaries = grids and servers
	NSEnumerator *e = [servers objectEnumerator];
	GEZServerHook *aServer;
	while ( aServer = [e nextObject] ) {
		NSArray *grids = [aServer grids];
		NSMutableDictionary *gridReports = [NSMutableDictionary dictionaryWithCapacity:[grids count]];
		NSEnumerator *ee = [grids objectEnumerator];
		GEZGridHook *aGrid;
		while ( aGrid = [ee nextObject] )
			[gridReports setObject:[aGrid reportWithAgentList:agentDetails] forKey:[[aGrid xgridGrid] name]];
		NSMutableDictionary *serverDictionary = [self addStatusDictionaries:[gridReports allValues]];
		if ( gridDetails ) {
			[serverDictionary setObject:gridReports forKey:@"grids"];
			//if agents are listed in the grids, no need for them in the controller details
			if ( agentDetails && serverDetails )
				[serverDictionary removeObjectForKey:@"agents"];
		}
		[serverReports setObject:serverDictionary forKey:[aServer address]];
	}
	
	//final dictionary could be just the aggregated result or could contain details for each controller and/or grid
	NSMutableDictionary *finalDictionary = [self addStatusDictionaries:[serverReports allValues]];
	if ( serverDetails ) {
		[finalDictionary setObject:serverReports forKey:@"controllers"];
		//agents will be listed for each individual controller, no need to aggregate
		[finalDictionary removeObjectForKey:@"agents"];
	}
	
	//add time info
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
	
	return finalDictionary;
}

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

- (void)report
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	if ( outputFilePath == nil ) {
		printf ( "%s\n", [[self statusString] UTF8String] );
	} else {
		NSData *statusData = [self statusData];
		if ( [statusData writeToFile:outputFilePath atomically:YES] ==NO )
			printf ( "Error writing output file.\n" );
	}
	
	if ( reportInterval <= 0.0 )
		exit (0);
}

- (void)reportWithTimer:(NSTimer *)aTimer
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	[self report];
}


- (void)start
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	NSEnumerator *e = [servers objectEnumerator];	
	GEZServerHook *aServer;
	while ( aServer = [e nextObject] ) {
		if ( [aServer isLoaded] )
			[self serverDidLoad:[NSNotification notificationWithName:GEZServerHookDidLoadNotification object:aServer]];
		else {					
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDidLoad:) name:GEZServerHookDidLoadNotification object:aServer];		
			[aServer connect];
		}
	}
	
	//report server loading to keep the user entertained if it takes a while
	if ( [self verbose] )
		[NSTimer scheduledTimerWithTimeInterval:PROGRESS_NOTIFICATION_INTERVAL target:self selector:@selector(reportServerLoading:) userInfo:nil repeats:YES];

}

- (void)reportAgentLoading:(NSTimer *)aTimer
{
	if ( [self allAgentsLoaded] ) {
		[aTimer invalidate];
		return;
	}
	if ( [self verbose] )
		printf ( "Waiting for agent information: %d/%d agents ready\n", [self countAgentLoaded], [self countAgents] );
}

- (void)reportServerLoading:(NSTimer *)aTimer
{
	if ( [self allServersLoaded] ) {
		[aTimer invalidate];
		return;
	}
	if ( [self verbose] )
		printf ( "Waiting for grid information: %d/%d controllers ready\n", [self countServerLoaded], [servers count] );
}

#pragma mark *** notifications ***

- (void)serverDidLoad:(NSNotification *)notification
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	GEZServerHook *loadedServer = [notification object];
	
	if ( [self verbose] )
		printf ( "Connection established with controller '%s'.\n", [[loadedServer address] UTF8String] );

	NSEnumerator *e = [[loadedServer grids] objectEnumerator];
	GEZGridHook *aGrid;
	while  ( aGrid = [e nextObject] ) {
		[aGrid setShouldObserveAgents:YES];
		if ( [aGrid agentsLoaded] )
			[self agentsDidLoad:[NSNotification notificationWithName:GEZGridHookDidChangeAgentsNotification object:aGrid]];
		else
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(agentsDidLoad:) name:GEZGridHookDidLoadAgentsNotification object:aGrid];
	}
	
	//report on agent loading to keep the user entertained if it takes a while
	if ( [self allServersLoaded] && [self verbose] )
		[NSTimer scheduledTimerWithTimeInterval:PROGRESS_NOTIFICATION_INTERVAL target:self selector:@selector(reportAgentLoading:) userInfo:nil repeats:YES];

}

- (void)agentsDidLoad:(NSNotification *)notification
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	//one of the grid is ready
	GEZGridHook *loadedGrid = [notification object];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:GEZGridHookDidChangeAgentsNotification object:loadedGrid];
	if ( [self verbose] )
		printf ( "Grid '%s' for controller '%s' ready.\n", [[[loadedGrid xgridGrid] name] UTF8String], [[[loadedGrid serverHook] address] UTF8String] );
	
	//if all grids are ready, it is time for a first report
	if ( [self allAgentsLoaded] ) {
		if ( [self verbose] ) {
			if ( reportInterval != 0 )
				printf ( "All grids ready. Writing report every %d seconds.\n", (int)(reportInterval) );
			else
				printf ( "All grids ready. Writing report.\n");
		}
		[self report];
		[NSTimer scheduledTimerWithTimeInterval:reportInterval target:self selector:@selector(reportWithTimer:) userInfo:nil repeats:YES];
	}

}

@end
