

@interface XGController (XGControllerPrivateForXgridStatus)

- (NSArray *)agents;
- (void)sendAgentListRequest;

@end


@interface XGGrid (XGGridPrivateForXgridStatus)

- (NSString *)name;
- (NSArray *)agents;
- (void)sendAgentsRequest;
- (void)sendJobsRequest;
- (void)sendRequestsAndSubscribeToNotifications;
@end

@protocol Agent

- (NSString *)identifier;
- (XGResourceState)state;
- (NSString *)name;
- (NSString *)address;
- (float)activeCPUPower;
- (float)totalCPUPower;
- (int)activeProcessorCount;
- (int)totalProcessorCount;

@end

@interface XGAgent : XGResource
{
    id mystery;
}

- (id)initWithController:(id)fp8 identifier:(id)fp12;
- (void)dealloc;
- (void)cancelRequestsAndUnsubscribeFromNotifications;
- (NSString *)name;
- (NSString *)address;
- (float)activeCPUPower;
- (float)totalCPUPower;
- (int)activeProcessorCount;
- (int)totalProcessorCount;
- (XGActionMonitor *)performDeleteAction;
- (void)setAttributes:(id)fp8;
- (void)setAddress:(id)fp8;
- (void)setActiveCPUPower:(float)fp8;
- (void)setTotalCPUPower:(float)fp8;
- (void)setActiveProcessorCount:(float)fp8;
- (void)setTotalProcessorCount:(float)fp8;
- (void)sendRequestsAndSubscribeToNotifications;
- (void)sendAttributesRequest;
- (void)checkForLoadCompletion;
- (void)attributesReplyDidArrive:(id)fp8;
- (void)attributesNotificationDidArrive:(id)fp8;

@end
