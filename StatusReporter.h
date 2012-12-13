//
//  StatusReporter.h
//  XgridStatus
//
//  Created by Charles Parnot on 7/19/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface StatusReporter : NSObject
{
	NSString *xgridControllerHostname;
	NSString *xgridControllerPassword;
	double reportInterval;
	NSString *outputFilePath;
	
	XGController *xgridController;
	XGConnection *xgridConnection;
	
	//keeping track of connection attempts
	NSArray *connectionSelectors;
	NSEnumerator *selectorEnumerator;
}

- (id)initWithXgridController:(NSString *)hostname password:(NSString *)password reportInterval:(double)interval output:(NSString *)path;

- (void)start;

@end
