//
//  GEZSwizzleNSArray.h
//  XgridStatus
//
//  Created by Charles Parnot on 8/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//method swizzling to avoid a bug with Xgrid, when the database gets corrupted a certain way, resulting in a call to -[NSCFArray addObject:] with a 'nil' argument

@interface NSArray (GEZSwizzleNSArray)

- (void)GEZSwizzleNSArray_addObject:(id)anObject;

@end
