//
//  PlistCategories.h
//  XgridStatus
//
//  Created by Charles Parnot on 8/18/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/* These categories are used to produce different output from plist objects, handled by NSArray and NSDictionary */


@interface NSObject (XgridStatusPlistCategory)
- (NSString *)xmlStringRepresentation;
- (NSString *)xmlStringRepresentationWithIndent:(int)indent;
@end


@interface NSArray (XgridStatusArrayPlistCategory)
- (NSString *)xmlStringRepresentation;
- (NSString *)xmlStringRepresentationWithIndent:(int)indent;
@end


@interface NSDictionary (XgridStatusDictionaryPlistCategory)
- (NSString *)xmlStringRepresentation;
- (NSString *)xmlStringRepresentationWithIndent:(int)indent;
@end
