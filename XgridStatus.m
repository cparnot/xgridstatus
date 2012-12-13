#import <Foundation/Foundation.h>
#import "StatusReporter.h"


void print_usage ( )
{
	printf ("usage: xgridstatus -h hostname [-p password] [-r interval] [-o file]\n");
	printf ("\n");
	printf ("       hostname: Bonjour name or address of an xgrid controller\n");
	printf ("       password: client password, only needed if one was set\n");
	printf ("       interval: interval at which to repeat the status report, in seconds\n");
	printf ("       file:     path at which to save the output\n");
	printf ("                 if interval is set, the file is overwritten at each report\n");
	exit (0);
}

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	if ( argc < 3 )
		print_usage();
	
	//get the arguments
	NSString *hostname = nil;
	NSString *password = nil;
	NSString *interval = nil;
	NSString *file = nil;
	int i = 0;
	while ( ++i < argc ) {
		NSString *arg = [NSString stringWithUTF8String:argv[i]];
		if ( [arg isEqualToString:@"-h"] ) {
			i++;
			if ( i < argc )
				hostname = [NSString stringWithUTF8String:argv[i]];
			else
				print_usage();
		} else if ( [arg isEqualToString:@"-p"] ) {
			i++;
			if ( i < argc )
				password = [NSString stringWithUTF8String:argv[i]];
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
		} else
			print_usage();
	}
	DLog(nil,0,@"Hostname: %@\nPassword: %@\nInterval: %d\nFile path: %@\n",hostname,password,[interval intValue],file);
	
	//start the status reporter
	StatusReporter *reporter = [[StatusReporter alloc] initWithXgridController:hostname password:password reportInterval:[interval doubleValue] output:file];
	[reporter start];
	[[NSRunLoop currentRunLoop] run];
	
    [pool release];
    return 0;
}
