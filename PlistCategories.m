//
//  PlistCategories.m
//  XgridStatus
//
//  Created by Charles Parnot on 8/18/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PlistCategories.h"

static NSString *tabs[13] = {
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
	@"\t\t\t\t\t\t\t\t\t\t",
	@"\t\t\t\t\t\t\t\t\t\t\t",
	@"\t\t\t\t\t\t\t\t\t\t\t\t"
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
		[rep appendFormat:@"%@<array_item>%@",tabs[indent],elementString];
		if ( [elementString rangeOfString:@"\n"].location != NSNotFound )
			[rep appendString:tabs[indent]];
		[rep appendFormat:@"</array_item>\n"];
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
		NSString *elementString = [[self objectForKey:key]  xmlStringRepresentationWithIndent:indent+2];
		[rep appendFormat:@"%@<dictionary_item>",tabs[indent]];
		[rep appendFormat:@"%@<dictionary_key>%@</dictionary_key>", tabs[indent+1], [key description]];
		[rep appendFormat:@"%@<dictionary_content>\n%@",tabs[indent+1],elementString];
		if ( [elementString rangeOfString:@"\n"].location != NSNotFound )
			[rep appendString:tabs[indent+1]];
		[rep appendFormat:@"</dictionary_content>\n%@</dictionary_item>\n",tabs[indent]];
	}
	return rep;
}
@end
