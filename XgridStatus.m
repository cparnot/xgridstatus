#import <Foundation/Foundation.h>
#import "StatusReporter.h"
#import "GEZServerHook.h"
#import "GEZGridHookPoser.h"
#import "GEZGridHook.h"

void print_usage ( )
{
	printf ("usage: xgridstatus [ [-h hostname] [-p password | -k password] ]* [-r interval] [-o file] [-abcgjlstvxAJT]\n");
	printf ("\n");
	printf ("Result: aggregated report status for all controllers listed,\n");
	printf ("        with optional details for each agent, grids and controller\n");
	printf ("\n");
	
	//controllers
	printf ("    -h hostname  Bonjour name or address of an xgrid controller\n");
	printf ("                 (default is localhost)\n");
	printf ("    -p password  client password, only needed if one was set.\n");
	printf ("                 A hostname is attributed the first password found\n");
	printf ("                 after it in the list of arguments, if any.\n");
	printf ("    -k password  when -k is used instead of the -p flag, the password\n");
	printf ("                 will be saved in the user default Keychain, if available.\n");
	printf ("                 Once a password is stored, it will always be tried and you\n");
	printf ("                 do not need to include it in subsequence connections.\n");
	printf ("                 The password is stored and may overwrite a previous value\n");
	printf ("                 even if the connection fails.\n");
	
	//output format
	printf ("    -r interval  interval at which to repeat the status report, in seconds\n");
	printf ("                 (if 0 or unspecified, xgridstatus exits after the first report)\n");
	printf ("    -o file      path at which to save the output. If interval\n");
	printf ("                 is set, the file is overwritten at each report.\n");
	printf ("    -b           output format is plist binary (see man page for plutil)\n");
	printf ("    -l           output format is plist xml\n");
	printf ("    -t           output format is text = old plist (default)\n");
	printf ("    -x           output format is xml (compatible with Xgrid@Stanford widget)\n");
	
	//report format
	printf ("    -c           include report for individual controllers\n");
	printf ("    -g           include report for individual grids (implies -c)\n");
	printf ("    -A           include agent stats\n");
	printf ("    -J           include job stats\n");
	printf ("    -a           include agent list\n");
	printf ("    -j           include job list\n");
	printf ("    -T           include time stamp\n");

	//misc
	printf ("    -v           verbose, opposite of silent\n");
	printf ("    -s           silent, opposite of verbose\n");
	printf ("\n");
	printf ("For output compatible with Xgrid@Stanford widget, use the following options:\n");
	printf ("\n");
	printf ("    xgridstatus -h host1 [-h host2 ...] [-s] -xAT -r 10 -o path/to/file.xml\n");
	
	printf ("\n");
	exit (0);
}

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	//get the arguments
	NSMutableArray *servers = [NSMutableArray arrayWithCapacity:10];
	NSString *currentHostname = nil;
	NSString *currentPassword = nil;
	BOOL currentHostnameUsesKeychain = NO;
	NSString *interval = @"";
	NSString *file = nil;
	int verbose = 2;
	BOOL serverList = NO;
	BOOL gridList = NO;
	BOOL agentStats = NO;
	BOOL jobStats = NO;
	BOOL agentList = NO;
	BOOL jobList = NO;
	BOOL timeStamp = NO;
	XgridStatusReportType reportType = XgridStatusReportTypeOldPlist;
	int i = 0;
	while ( ++i < argc ) {
		NSString *arg = [NSString stringWithUTF8String:argv[i]];
		if ( [arg isEqualToString:@"-h"] ) {
			i++;
			if ( i < argc ) {
				//save the current hostname, before starting a new one
				if ( currentHostname != nil ) {
					GEZServerHook *newServer = [GEZServerHook serverHookWithAddress:currentHostname];
					if ( currentHostnameUsesKeychain == YES )
						[newServer storePasswordInKeychain:currentPassword];
					else
						[newServer setPassword:currentPassword];
					[servers addObject:newServer];
				}
				//get ready for the next server
				currentPassword = nil;
				currentHostnameUsesKeychain = NO;
				currentHostname = [NSString stringWithUTF8String:argv[i]];
			}
			else
				print_usage();
		} else if ( [arg isEqualToString:@"-p"] || [arg isEqualToString:@"-k"] ) {
			i++;
			if ( i < argc ) {
				//set to the default hostname, in case no hostname was set
				currentPassword = [NSString stringWithUTF8String:argv[i]];
				if ( currentHostname == nil )
					currentHostname = @"localhost";
				if ( [arg isEqualToString:@"-k"] )
					currentHostnameUsesKeychain = YES;
			}
			else
				print_usage();
		} else if ( [arg isEqualToString:@"-r"] ) {
			i++;
			if ( i < argc )
				interval = [NSString stringWithUTF8String:argv[i]];
			else
				print_usage();
		} else if ( [arg isEqualToString:@"-o"] ) {
			i++;
			if ( i < argc )
				file = [NSString stringWithUTF8String:argv[i]];
			else
				print_usage();
		} else {
			if ( [arg length] < 2 || [[arg substringToIndex:1] isEqualToString:@"-"] == NO )
				print_usage();
			if ( [arg rangeOfString:@"c"].location != NSNotFound )
				serverList = YES;
			if ( [arg rangeOfString:@"g"].location != NSNotFound )
				gridList = YES;
			if ( [arg rangeOfString:@"a"].location != NSNotFound )
				agentList = YES;
			if ( [arg rangeOfString:@"j"].location != NSNotFound )
				jobList = YES;
			if ( [arg rangeOfString:@"A"].location != NSNotFound )
				agentStats = YES;
			if ( [arg rangeOfString:@"J"].location != NSNotFound )
				jobStats = YES;
			if ( [arg rangeOfString:@"T"].location != NSNotFound )
				timeStamp = YES;
			if ( [arg rangeOfString:@"v"].location != NSNotFound )
				verbose = 1;
			if ( [arg rangeOfString:@"s"].location != NSNotFound )
				verbose = 0;
			if ( [arg rangeOfString:@"b"].location != NSNotFound )
				reportType = XgridStatusReportTypeBinary;
			if ( [arg rangeOfString:@"l"].location != NSNotFound )
				reportType = XgridStatusReportTypePlist;
			if ( [arg rangeOfString:@"t"].location != NSNotFound )
				reportType = XgridStatusReportTypeOldPlist;
			if ( [arg rangeOfString:@"x"].location != NSNotFound )
				reportType = XgridStatusReportTypeXML;
		}
	}
	
	//-g implies -c
	if ( gridList == YES )
		serverList = YES;
	
	//the last hostname needs to be added to the list, or the default used
	if ( currentHostname == nil )
		currentHostname = @"localhost";
	GEZServerHook *newServer = [GEZServerHook serverHookWithAddress:currentHostname];
	if ( currentHostnameUsesKeychain == YES )
		[newServer storePasswordInKeychain:currentPassword];
	else
		[newServer setPassword:currentPassword];
	[servers addObject:newServer];	
	
	//display parameters
	if ( verbose == 1 ) {
		printf ("Starting xgridstatus with the following parameters:\n");
		printf ("Controllers: %s\n", [[[servers valueForKeyPath:@"@unionOfObjects.address"] description] UTF8String]);
		printf ("    -r = %s\n", [interval UTF8String]);
		printf ("    -o = %s\n", file?[file UTF8String]:"none");
		printf ("    -b = %s\n", (reportType==XgridStatusReportTypeBinary)?"YES":"NO");
		printf ("    -l = %s\n", (reportType==XgridStatusReportTypePlist)?"YES":"NO");
		printf ("    -t = %s\n", (reportType==XgridStatusReportTypeOldPlist)?"YES":"NO");
		printf ("    -x = %s\n", (reportType==XgridStatusReportTypeXML)?"YES":"NO");
		
		//report format
		printf ("    -c = %s\n", serverList?"YES":"NO");
		printf ("    -g = %s\n", gridList?"YES":"NO");
		printf ("    -A = %s\n", agentStats?"YES":"NO");
		printf ("    -J = %s\n", jobStats?"YES":"NO");
		printf ("    -a = %s\n", agentList?"YES":"NO");
		printf ("    -j = %s\n", jobList?"YES":"NO");
		printf ("    -T = %s\n", timeStamp?"YES":"NO");
		printf ("    -v = %s\n", verbose?"YES":"NO");
		printf ("    -s = %s\n", verbose?"NO":"YES");
		printf ("\n");
	}
	
	DLog(nil,0,@"Servers: %@\nInterval: %d\nFile path: %@\n",servers,[interval intValue],file);
	
	//if agentStats or agentList needed, use GEZGridHookExtended
	if ( agentList || agentStats )
		[GEZGridHookPoser poseAsClass:[GEZGridHook class]];
	
	//start the status reporter
	StatusReporter *reporter = [[StatusReporter alloc] initWithServers:servers reportInterval:(double)[interval doubleValue] output:file];
	if ( verbose == 0 || verbose == 1) 
		[reporter setVerbose:(BOOL)verbose];
	[reporter setServerList:serverList];
	[reporter setGridList:gridList];
	[reporter setAgentList:agentList];
	[reporter setJobList:jobList];
	[reporter setAgentStats:agentStats];
	[reporter setJobStats:jobStats];
	[reporter setReportType:reportType];
	[reporter start];
	[[NSRunLoop currentRunLoop] run];
	
    [pool release];
    return 0;
}
