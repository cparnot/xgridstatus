//
//  StatusReporter.h
//  XgridStatus
//
//  Created by Charles Parnot on 7/19/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	XgridStatusReportTypeOldPlist = 0,
	XgridStatusReportTypePlist = 1,
	XgridStatusReportTypeXML = 2,
	XgridStatusReportTypeBinary = 3,
} XgridStatusReportType;

@interface StatusReporter : NSObject
{
	//parameters
	NSArray *servers;
	double reportInterval;
	NSString *outputFilePath;

	//options
	int verbose;
	BOOL agentDetails;
	BOOL gridDetails;
	BOOL serverDetails;
	XgridStatusReportType reportType;
	
	//internals
	NSDictionary *currentStatusDictionary;
	NSDictionary *lastServerReports;
	NSTimer *reportStatusTimer;
}

- (id)initWithServers:(NSArray *)servers reportInterval:(double)interval output:(NSString *)path;

- (void)start;

- (void)setVerbose:(BOOL)flag;
- (BOOL)verbose;
- (void)setAgentDetails:(BOOL)flag;
- (void)setGridDetails:(BOOL)flag;
- (void)setServerDetails:(BOOL)flag;
- (void)setReportType:(XgridStatusReportType)type;

//handling GEZServerHook notifications
- (void)serverDidConnect:(NSNotification *)notification;
- (void)serverDidLoad:(NSNotification *)notification;
- (void)serverDidNotConnect:(NSNotification *)notification;
- (void)serverDidDisconnect:(NSNotification *)notification;


@end
