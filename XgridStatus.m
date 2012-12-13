#import <Foundation/Foundation.h>
#import "StatusReporter.h"
#import "GEZServerHook.h"


void print_usage ( )
{
	printf ("usage: xgridstatus [ [-h hostname] [-p password | -k password] ]* [-r interval] [-o file] [-abcglstvx]\n");
	printf ("\n");
	printf ("Result: aggregated report status for all controllers listed,\n");
	printf ("        with optional details for each agent, grids and controller\n");
	printf ("\n");
	printf ("    -h hostname  Bonjour name or address of an xgrid controller\n");
	printf ("                 (default is localhost)\n");
	printf ("    -p password  client password, only needed if one was set.\n");
	printf ("                 A hostname is attributed the first password found\n");
	printf ("                 after it in the list of arguments, if any.\n");
	printf ("    -k password  when -k is used instead of the -p flag, the password\n");
	printf ("                 will be saved in the user defalt Keychain, if it is available.\n");
	printf ("                 Once a password is stored, it will always be tried and you\n");
	printf ("                 do not need to include it in subsequence connections.\n");
	printf ("                 The password is stored and may overwrite a previous value\n");
	printf ("                 even if the connection fails.\n");
	printf ("    -r interval  interval at which to repeat the status report, in seconds\n");
	printf ("                 (if 0 or unspecified, xgridstatus exits after the first report)\n");
	printf ("    -o file      path at which to save the output. If interval\n");
	printf ("                 is set, the file is overwritten at each report.\n");
	printf ("    -v           verbose (default tries to be smart)\n");
	printf ("    -s           silent (default tries to be smart)\n");
	printf ("    -c           include report for individual controllers.\n");
	printf ("    -g           include report for individual grids (implies -c)\n");
	printf ("    -a           include detailed agent information\n");
	printf ("    -b           output format is plist binary (see man page for plutil)\n");
	printf ("    -l           output format is plist xml\n");
	printf ("    -t           output format is old plist (default)\n");
	printf ("    -x           output format is xml (compatible with Xgrid@Stanford widget)\n");
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
	BOOL agentDetails = NO;
	BOOL gridDetails = NO;
	BOOL serverDetails = NO;
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
			if ( [arg rangeOfString:@"a"].location != NSNotFound )
				agentDetails = YES;
			if ( [arg rangeOfString:@"g"].location != NSNotFound )
				gridDetails = YES;
			if ( [arg rangeOfString:@"c"].location != NSNotFound )
				serverDetails = YES;
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
	if ( gridDetails )
		serverDetails = YES;
	
	//the last hostname needs to be added to the list, or the default used
	if ( currentHostname == nil )
		currentHostname = @"localhost";
	GEZServerHook *newServer = [GEZServerHook serverHookWithAddress:currentHostname];
	if ( currentHostnameUsesKeychain == YES )
		[newServer storePasswordInKeychain:currentPassword];
	else
		[newServer setPassword:currentPassword];
	[servers addObject:newServer];	
	
	DLog(nil,0,@"Servers: %@\nInterval: %d\nFile path: %@\n",servers,[interval intValue],file);
	
	//start the status reporter
	StatusReporter *reporter = [[StatusReporter alloc] initWithServers:servers reportInterval:(double)[interval doubleValue] output:file];
	if ( verbose == 0 || verbose == 1) 
		[reporter setVerbose:(BOOL)verbose];
	[reporter setAgentDetails:agentDetails];
	[reporter setGridDetails:gridDetails];
	[reporter setServerDetails:serverDetails];
	[reporter setReportType:reportType];
	[reporter start];
	[[NSRunLoop currentRunLoop] run];
	
    [pool release];
    return 0;
}
