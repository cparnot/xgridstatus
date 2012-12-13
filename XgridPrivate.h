

@interface XGController (XGControllerPrivateForXgridStatus)

- (NSArray *)agents;
- (void)sendAgentListRequest;

@end


@protocol Agent

- (XGResourceState)state;
- (NSString *)name;
- (NSString *)address;
- (float)activeCPUPower;
- (float)totalCPUPower;
- (int)activeProcessorCount;
- (int)totalProcessorCount;

@end