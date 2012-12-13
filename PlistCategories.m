//
//  PlistCategories.m
//  XgridStatus
//
//  Created by Charles Parnot on 8/18/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PlistCategories.h"

static NSString *tabs[11] = {
	@"",
	@"\t",
	@"\t\t",
	@"\t\t\t",
	@"\t\t\t\t",
	@"\t\t\t\t\t",
	@"\t\t\t\t\t\t",
	@"\t\t\t\t\t\t\t",
	@"\t\t\t\t\t\t\t\t",
	@"\t\t\t\t\t\t\t\t\t",
	@"\t\t\t\t\t\t\t\t\t\t"
};

@implementation NSObject (XgridStatusPlistCategory)

- (NSString *)xmlStringRepresentation
{
	return [self description];
}

- (NSString *)xmlStringRepresentationWithIndent:(int)indent
{
	return [self description];
	
}
@end

@implementation NSArray (XgridStatusArrayPlistCategory)

- (NSString *)xmlStringRepresentation
{
	return [self xmlStringRepresentationWithIndent:0];
}

- (NSString *)xmlStringRepresentationWithIndent:(int)indent
{
	if ( indent > 10 )
		indent = 10;
	NSMutableString *rep = [NSMutableString stringWithString:@"\n"];
	NSEnumerator *e = [self objectEnumerator];
	id element;
	int i = 0;
	while ( element = [e nextObject] ) {
		NSString *elementString = [element xmlStringRepresentationWithIndent:indent+1];
		[rep appendFormat:@"%@<%d>%@",tabs[indent],i,elementString];
		if ( [elementString rangeOfString:@"\n"].location != NSNotFound )
			[rep appendString:tabs[indent]];
		[rep appendFormat:@"</%d>\n",i];
		i++;
	}
	[rep appendString:@"\n"];
	return rep;
}

@end


@implementation NSDictionary (XgridStatusDictionaryPlistCategory)

- (NSString *)xmlStringRepresentation
{
	return [self xmlStringRepresentationWithIndent:0];
}


- (NSString *)xmlStringRepresentationWithIndent:(int)indent
{
	if ( indent > 10 )
		indent = 10;
	NSMutableString *rep = [NSMutableString stringWithString:@"\n"];
	NSEnumerator *e = [self keyEnumerator];
	id key;
	while ( key = [e nextObject] ) {
		NSString *elementString = [[self objectForKey:key]  xmlStringRepresentationWithIndent:indent+1];
		[rep appendFormat:@"%@<%@>%@",tabs[indent],[key description],elementString];
		if ( [elementString rangeOfString:@"\n"].location != NSNotFound )
			[rep appendString:tabs[indent]];
		[rep appendFormat:@"</%@>\n",[key description]];
	}
	return rep;
}
@end
