//
//  StatusReporter.m
//  XgridStatus
//
//  Created by Charles Parnot on 7/19/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "StatusReporter.h"
#import "XgridPrivate.h"

@implementation StatusReporter

#pragma mark *** Initializations ***

- (id)initWithXgridController:(NSString *)hostname password:(NSString *)password reportInterval:(double)interval output:(NSString *)path
{
	self = [super init];
	if ( self != nil ) {
		xgridControllerHostname = [hostname retain];
		xgridControllerPassword = [password retain];
		reportInterval = (interval>0)?interval:60;
		outputFilePath = [[path stringByStandardizingPath] retain];
		
		BOOL isRemoteHost = ( [hostname rangeOfString:@"."].location != NSNotFound );
		if ( [hostname isEqualToString:@"localhost"] )
			isRemoteHost = YES;
		BOOL usePassword = ( [password length] > 0 );
		if ( usePassword && isRemoteHost )
			connectionSelectors = [NSArray arrayWithObjects:@"5",@"2",@"4",@"6",@"1",@"3",nil];
		else if ( usePassword && !isRemoteHost )
			connectionSelectors = [NSArray arrayWithObjects:@"2",@"5",@"1",@"3",@"4",@"6",nil];
		else if ( !usePassword && isRemoteHost )
			connectionSelectors = [NSArray arrayWithObjects:@"4",@"6",@"1",@"3",nil];
		else if ( !usePassword && !isRemoteHost )
			connectionSelectors = [NSArray arrayWithObjects:@"1",@"3",@"4",@"6",nil];
		else
			connectionSelectors = [NSArray array];
		[connectionSelectors retain];
		selectorEnumerator = [[connectionSelectors objectEnumerator] retain];
		
		xgridController = nil;
		xgridConnection = nil;
	}
	return self;
}

- (void)dealloc
{
	[xgridControllerHostname release];
	[xgridControllerPassword release];
	[outputFilePath release];
	[xgridConnection release];
	[xgridController release];
	[selectorEnumerator release];
	[connectionSelectors release];
	
	[super dealloc];
}

- (void)raiseConnectionError
{
	printf ("Connection error.\n");
	exit (0);
}


#pragma mark *** Status construction ***

- (NSDictionary *)statusDictionary
{
	//get the information about agents
	float totalMegaHertz = 0;
	float workingMegaHertzAgents = 0;
	float workingMegaHertzProcessors = 0;
	int onlineProcessorCount = 0;
	int agentCount[6] = { 0, 0, 0, 0, 0, 0 };
	int processorCount[7] = { 0, 0, 0, 0, 0, 0, 0 };
	NSArray *agents = [xgridController agents];
	NSEnumerator *e = [agents objectEnumerator];
	id <Agent> agent;
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
		}
		processorCount[state] += inactive;
		
		//printf ( "agent '%s' at IP '%s' : %d\n", [[agent name] UTF8String], [[agent address] UTF8String], [agent state] );
	}
	
	//get the working CPU
	float workingMegaHertzJobs = 0;
	XGGrid *grid;
	XGJob *job;
	NSEnumerator *ee = [[xgridController grids] objectEnumerator];
	while ( grid = [ee nextObject] ) {
		NSEnumerator *eee = [[grid jobs] objectEnumerator];
		while ( job = [eee nextObject] )
			workingMegaHertzJobs += [job activeCPUPower];
	}
	
	NSDate *now = [NSDate date];
	NSDictionary *statusDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
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

		[now dateWithCalendarFormat:@"%Y" timeZone:nil],@"Year",
		[now dateWithCalendarFormat:@"%m" timeZone:nil],@"MonthIndex",
		[now dateWithCalendarFormat:@"%B" timeZone:nil],@"MonthName",
		[now dateWithCalendarFormat:@"%b" timeZone:nil],@"MonthNameShort",
		[now dateWithCalendarFormat:@"%e" timeZone:nil],@"Day",
		[now dateWithCalendarFormat:@"%H" timeZone:nil],@"Hours",
		[now dateWithCalendarFormat:@"%M" timeZone:nil],@"Minutes",
		[now dateWithCalendarFormat:@"%S" timeZone:nil],@"Seconds",
		[now dateWithCalendarFormat:@"%Z" timeZone:nil],@"TimeZone",
		nil];

#ifdef DEBUG
	NSMutableDictionary *moreStuff = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithFloat:workingMegaHertzJobs],@"workingMegaHertzJobs",
		[NSNumber numberWithFloat:workingMegaHertzAgents],@"workingMegaHertzAgents",
		[NSNumber numberWithFloat:workingMegaHertzProcessors],@"workingMegaHertzProcessors",
		[NSNumber numberWithFloat:totalMegaHertz],@"totalMegaHertz",


		[NSNumber numberWithInt:processorCount[XGResourceStateOffline]],@"offlineStateProcessorCount",
		nil];
	[moreStuff addEntriesFromDictionary:statusDictionary];
	statusDictionary = [NSDictionary dictionaryWithDictionary:moreStuff];
#endif
	
	return statusDictionary;
}

- (NSString *)statusXMLString
{
	NSDictionary *statusDictionary = [self statusDictionary];
	NSArray *keys = [[statusDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
	NSMutableArray *strings = [NSMutableArray arrayWithCapacity:[keys count]];
	NSEnumerator *e = [keys objectEnumerator];
	NSString *key;
	while ( key = [e nextObject] )
		[strings addObject:[NSString stringWithFormat:@"<%@>%@</%@>", [key description], [[statusDictionary objectForKey:key] description], [key description]]];
	return [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gauge>\n%@\n</gauge>\n",
		[strings componentsJoinedByString:@"\n"]];
}

- (NSString *)statusSimpleString
{
	NSDictionary *statusDictionary = [self statusDictionary];
	NSArray *keys=[[statusDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
	NSMutableArray *strings=[NSMutableArray arrayWithCapacity:[keys count]];
	NSEnumerator *e=[keys objectEnumerator];
	NSString *key;
	while (key=[e nextObject])
		[strings addObject:[NSString stringWithFormat:@"%@ = %@", [key description], [[statusDictionary objectForKey:key] description]]];
	return [strings componentsJoinedByString:@"\n"];
}

- (void)report
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//printf ("Connection state = %d\n", [xgridConnection state] );
	//printf ("Controller state = %d\n", [xgridController state] );
	
	if ( selectorEnumerator != nil )
		return;
	
	XGResourceState connectionState = [xgridConnection state];
	XGResourceState controllerState = [xgridController state];
	BOOL connectionOK =  connectionState == XGResourceStateConnecting ||  connectionState == XGResourceStateAvailable;
	BOOL controllerOK =  controllerState == XGResourceStateConnecting ||  controllerState == XGResourceStateAvailable;
	if ( !connectionOK )
		[self raiseConnectionError];
	if ( !controllerOK )
		;
	
	if ( outputFilePath == nil ) {
		printf ( "%s\n", [[self statusSimpleString] UTF8String] );
	} else {
		NSString *xmlString = [self statusXMLString];
		NSData *xmlData = [xmlString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
		if ( [xmlData writeToFile:outputFilePath atomically:YES] ==NO )
			printf ( "Error writing output file.\n" );
	}
}

- (void)reportWithTimer:(NSTimer *)aTimer
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	[self report];
}

#pragma mark *** Connection ***

//first attempt to connect
//trying to use a Bonjour connection without password
- (void)connect1
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	printf ("Connecting to Bonjour controller '%s' without password\n",[xgridControllerHostname UTF8String]);

	//release the old XGConnection
	[xgridConnection setDelegate:nil];
	[xgridConnection release];
	
	//create a new XGConnection with a NSNetService
	NSNetService *netService = [[NSNetService alloc] initWithDomain:@"local."
															   type:@"_xgrid._tcp."
															   name:xgridControllerHostname];
	xgridConnection = [[XGConnection alloc] initWithNetService:netService];
	[netService release];
	
	//set the delegate and authenticator... and go!!
	[xgridConnection setDelegate:self];
	[xgridConnection setAuthenticator:nil];
	[xgridConnection open];
}

//second attempt to connect
//trying to use a Bonjour connection with a password
- (void)connect2
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	printf ("Connecting to Bonjour controller '%s' with the provided password\n",[xgridControllerHostname UTF8String]);

	//release the old XGConnection
	[xgridConnection setDelegate:nil];
	[xgridConnection release];
	
	//create a new XGConnection with a NSNetService
	NSNetService *netService = [[NSNetService alloc] initWithDomain:@"local."
															   type:@"_xgrid._tcp."
															   name:xgridControllerHostname];
	xgridConnection = [[XGConnection alloc] initWithNetService:netService];
	[netService release];
	
	//set the authenticator
	XGTwoWayRandomAuthenticator *authenticator = [[XGTwoWayRandomAuthenticator alloc] init];
	[authenticator setUsername:@"one-xgrid-client"];
	[authenticator setPassword:xgridControllerPassword];
	[xgridConnection setAuthenticator:authenticator];
	[authenticator release];

	//go!!
	[xgridConnection setDelegate:self];
	[xgridConnection open];
}

//third attempt to connect
//trying to use a Bonjour connection with Kerberos
- (void)connect3
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	printf ("Connecting to Bonjour controller '%s' using single sign-on credentials\n",[xgridControllerHostname UTF8String]);

	//release the old XGConnection
	[xgridConnection setDelegate:nil];
	[xgridConnection release];
	
	//create a new XGConnection with a NSNetService
	NSNetService *netService = [[NSNetService alloc] initWithDomain:@"local."
															   type:@"_xgrid._tcp."
															   name:xgridControllerHostname];
	xgridConnection = [[XGConnection alloc] initWithNetService:netService];
	[netService release];
	
	//set the authenticator
	XGGSSAuthenticator *authenticator = [[XGGSSAuthenticator alloc] init];
	NSString *servicePrincipal = [xgridConnection servicePrincipal];
	if (servicePrincipal == nil)
		servicePrincipal=[NSString stringWithFormat:@"xgrid/%@", [xgridConnection name]];		
	[authenticator setServicePrincipal:servicePrincipal];
	[xgridConnection setAuthenticator:authenticator];
	[authenticator release];
	
	//go!!
	[xgridConnection setDelegate:self];
	[xgridConnection open];
}

//fourth attempt to connect
//trying to use a remote connection without a password
- (void)connect4
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	printf ("Connecting to remote controller at address '%s' without password\n",[xgridControllerHostname UTF8String]);

	//release the old XGConnection
	[xgridConnection setDelegate:nil];
	[xgridConnection release];
	
	//create a new XGConnection
	xgridConnection = [[XGConnection alloc] initWithHostname:xgridControllerHostname portnumber:0];
	
	//set the authenticator
	[xgridConnection setAuthenticator:nil];
	
	//go!!
	[xgridConnection setDelegate:self];
	[xgridConnection open];
}

//fifth attempt to connect
//trying to use a remote connection with a password
- (void)connect5
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	printf ("Connecting to remote controller at address '%s' with the provided password\n",[xgridControllerHostname UTF8String]);

	//release the old XGConnection
	[xgridConnection setDelegate:nil];
	[xgridConnection release];
	
	//create a new XGConnection
	xgridConnection = [[XGConnection alloc] initWithHostname:xgridControllerHostname portnumber:0];
	
	//set the authenticator
	XGTwoWayRandomAuthenticator *authenticator = [[XGTwoWayRandomAuthenticator alloc] init];
	[authenticator setUsername:@"one-xgrid-client"];
	[authenticator setPassword:xgridControllerPassword];
	[xgridConnection setAuthenticator:authenticator];
	[authenticator release];
	
	//go!!
	[xgridConnection setDelegate:self];
	[xgridConnection open];
}

//sixth attempt to connect
//trying to use a remote connection with Kerberos
- (void)connect6
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	printf ("Connecting to remote controller at address '%s' using single sign-on credentials\n",[xgridControllerHostname UTF8String]);

	//release the old XGConnection
	[xgridConnection setDelegate:nil];
	[xgridConnection release];
	
	//create a new XGConnection
	xgridConnection = [[XGConnection alloc] initWithHostname:xgridControllerHostname portnumber:0];
	
	//set the authenticator
	XGGSSAuthenticator *authenticator = [[XGGSSAuthenticator alloc] init];
	NSString *servicePrincipal = [xgridConnection servicePrincipal];
	if (servicePrincipal == nil)
		servicePrincipal=[NSString stringWithFormat:@"xgrid/%@", [xgridConnection name]];		
	[authenticator setServicePrincipal:servicePrincipal];
	[xgridConnection setAuthenticator:authenticator];
	[authenticator release];
	
	//go!!
	[xgridConnection setDelegate:self];
	[xgridConnection open];
}


- (void)connect
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	//depending on the hostname and password values, we have decided on a series of connection type to make,
	//as defined by the array connectionSelectors, enumerated by selectorEnumerator
	NSString *selectorString = [selectorEnumerator nextObject];
	if ( selectorString == nil )
		[self raiseConnectionError];
	else {
		selectorString = [@"connect" stringByAppendingString:selectorString];
		SEL selector = NSSelectorFromString (selectorString);
		[self performSelector:selector];
	}
}

- (void)start
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	[self connect];
	//[NSTimer scheduledTimerWithTimeInterval:reportInterval target:self selector:@selector(reportWithTimer:) userInfo:nil repeats:YES];
}



#pragma mark *** XGConnection delegate methods ***

- (void)connectionDidOpen:(XGConnection *)connection;
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	printf ( "Connection established.\n" );
	printf ( "Writing report every %f seconds.\n", reportInterval );
	[self report];
	[NSTimer scheduledTimerWithTimeInterval:reportInterval target:self selector:@selector(reportWithTimer:) userInfo:nil repeats:YES];
	
	[xgridController release];
	xgridController = [[XGController alloc] initWithConnection:xgridConnection];
	[selectorEnumerator release];
	selectorEnumerator = nil;
	[connectionSelectors release];
	connectionSelectors = nil;
	
	[xgridController sendAgentListRequest];
	
}

- (void)connectionDidNotOpen:(XGConnection *)connection withError:(NSError *)error
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	[self connect];
}

- (void)connectionDidClose:(XGConnection *)connection;
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	[self connect];
}

@end
