//
//  ResourceStateToStringTransformer.h
//  XgridStatus
//
//  Created by Charles Parnot on 8/4/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//


@interface ResourceStateToStringTransformer : NSValueTransformer
{

}

+ (id)sharedTransformer;
- (id)transformedValue:(id)value;
- (id)transformedIntValue:(int)intValue;

@end
