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
#import "GridReport.h"
#import "PlistCategories.h"

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



- (BOOL)allServersLoaded
{
	return ( [[servers valueForKeyPath:@"@sum.isLoaded"] intValue] >= [servers count] );
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
		
		NSMutableDictionary *serverDictionary = nil;

		//if the server is loaded, it is up to date and we can get the correct information from it
		if ( [aServer isLoaded] ) {
			//printf("    Server %s loaded\n",[[aServer address] UTF8String]);
			NSArray *grids = [aServer grids];
			//this dictionary will contain a list of subdictionaries, one for each grid of the server
			NSMutableDictionary *gridReports = [NSMutableDictionary dictionaryWithCapacity:[grids count]];
			NSEnumerator *ee = [grids objectEnumerator];
			GEZGridHook *aGrid;
			while ( aGrid = [ee nextObject] )
				[gridReports setObject:[aGrid reportWithAgentList:agentDetails] forKey:[[aGrid xgridGrid] name]];
			serverDictionary = [self addStatusDictionaries:[gridReports allValues]];
			if ( gridDetails ) {
				[serverDictionary setObject:gridReports forKey:@"grids"];
				//if agents are listed in the grids, no need for them in the controller details
				if ( agentDetails && serverDetails )
					[serverDictionary removeObjectForKey:@"agents"];
			}
			
		//if the server is not loaded and thus does not have valid information, we use previous values
		} else {
			//printf("    Server %s not loaded\n",[[aServer address] UTF8String]);
			serverDictionary = [lastServerReports objectForKey:[aServer address]];
		}
		if ( serverDictionary != nil )
			[serverReports setObject:serverDictionary forKey:[aServer address]];
	}
	
	//keep the info for the next time, in case some servers get disconnected
	[lastServerReports release];
	lastServerReports = [serverReports copy];
	
	
	//final dictionary could be just the aggregated result or could contain details for each controller
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
	
	[currentStatusDictionary release];
	currentStatusDictionary = [finalDictionary copy];
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
		int countAgents = [allAgents count];
		if ( [aServer isLoaded] )
			printf("In progress: Controller '%s' loaded, %d grids, %d agents\n", address, countGrids, countAgents);
		else if ( [aServer isUpdated] ) {
			int countUpdatedGrids = [[aServer valueForKeyPath:@"grids.@sum.isUpdated"] intValue];
			//if all grids are updated, we know for sure the number of agents
			if ( countUpdatedGrids == countGrids ) {
				int countLoadedGrids = [[aServer valueForKeyPath:@"grids.@sum.isLoaded"] intValue];
				int countUpdatedAgents = [[allAgents valueForKeyPath:@"@sum.isUpdated"] intValue];
				printf("In progress: Controller '%s' updated, %d/%d grids loaded, %d/%d agents loaded\n", address, countLoadedGrids, countGrids, countUpdatedAgents, countAgents);
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
	
	//report about the server just loaded
	if ( [self verbose] ) {
		GEZServerHook *theServer = [notification object];
		NSString *message = [NSString stringWithFormat:@"Controller '%@' loaded, %@ grids, %d agents\n", [theServer address], [theServer valueForKeyPath:@"grids.@count"], [[theServer valueForKeyPath:@"grids.@distinctUnionOfArrays.xgridGrid.agents"]count]];
		printf ( "%s", [message UTF8String] );
	}
	
	//maybe all servers are loaded
	if ( [self allServersLoaded] )
		[self setShouldReportStatus:YES];

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
	}
}

@end
