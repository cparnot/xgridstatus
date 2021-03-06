//
//  GEZResourceArrayObserver.m
//  XgridStatus
//
//  Created by Charles Parnot on 8/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GEZResourceArrayObserver.h"


//
//  GEZResourceObserver.m
//
//  GridEZ
//
//  Copyright 2006, 2007 Charles Parnot. All rights reserved.
//

/* __BEGIN_LICENSE_GRIDEZ__
This file is part of "GridEZ.framework". "GridEZ.framework" is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version. "GridEZ.framework" is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details. You should have received a copy of the GNU Lesser General Public License along with GridEZ.framework; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
__END_LICENSE__ */


@implementation GEZResourceArrayObserver


- (id)initWithResources:(NSArray *)resourceArray observedKeys:(NSSet *)keys;
{
	self = [super init];
	if ( self != nil ) {
		xgridResources = [resourceArray copy];
		delegate = nil;
		[self setObservedKeys:keys];
	}
	return self;
}

- (id)initWithResources:(NSArray *)resourceArray;
{
	return [self initWithResources:resourceArray observedKeys:[NSSet set]];
}

- (void)dealloc
{
	delegate = nil;
	[self setObservedKeys:nil];
	[xgridResources release];
	[super dealloc];
}

- (NSString *)shortDescription
{
	return [NSString stringWithFormat:@"Resource array observer for %@", xgridResources];
}


- (id)delegate
{
	return delegate;
}

- (void)setDelegate:(id)anObject
{
	//by convention, no retain for delegates
	delegate = anObject;
}

- (NSArray *)xgridResources;
{
	return xgridResources;
}

- (void)setXgridResources:(NSArray *)resourceArray
{
	if ( [resourceArray isEqualToArray:xgridResources] )
		return;
		
	//clean-up old resources
	NSEnumerator *e = [observedKeys objectEnumerator];
	NSString *aKey;
	while ( aKey = [e nextObject] ) {
		NSEnumerator *ee = [xgridResources objectEnumerator];
		XGResource *res;
		while ( res = [ee nextObject] )
			[res removeObserver:self forKeyPath:aKey];
	}
	[xgridResources autorelease];
	
	//observe new resources
	xgridResources = [resourceArray copy];
	e = [observedKeys objectEnumerator];
	while ( aKey = [e nextObject] ) {
		NSEnumerator *ee = [xgridResources objectEnumerator];
		XGResource *res;
		while ( res = [ee nextObject] )
			[res addObserver:self forKeyPath:aKey options:0 context:nil];
	}
}


- (NSSet *)observedKeys
{
	return observedKeys;
}


- (void)setObservedKeys:(NSSet *)keys
{
	if ( keys == observedKeys )
		return;
	
	// "isUpdated" is always observed
	if ( keys != nil && [keys member:@"updated"] == NO ) {
		NSMutableSet *moreKeys = [NSMutableSet setWithSet:keys];
		[moreKeys addObject:@"updated"];
		keys = [[moreKeys copy] autorelease];
	}
	
	// clean-up old keys
	NSEnumerator *e = [observedKeys objectEnumerator];
	NSString *aKey;
	while ( aKey = [e nextObject] ) {
		NSEnumerator *ee = [xgridResources objectEnumerator];
		XGResource *res;
		while ( res = [ee nextObject] )
			[res removeObserver:self forKeyPath:aKey];
	}
	[observedKeys release];
	
	// observe new keys
	observedKeys = [keys copy];
	e = [observedKeys objectEnumerator];
	while ( aKey = [e nextObject] ) {
		NSEnumerator *ee = [xgridResources objectEnumerator];
		XGResource *res;
		while ( res = [ee nextObject] )
			[res addObserver:self forKeyPath:aKey options:0 context:nil];
	}
}


- (void)notifyDelegateWithSelector:(SEL)delegateSelector changedObject:(id)changedObject
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - Sending message %s to %@",[self class],self,_cmd, delegateSelector, delegate);

	//builds an invocation if the delegate responds to the selector
	if ( delegate == nil || [delegate respondsToSelector:delegateSelector] == NO )
		return;
	NSMethodSignature *delegateSelectorSignature = [delegate methodSignatureForSelector:delegateSelector];
	if ( delegateSelectorSignature == nil )
		return;
	if ( [delegateSelectorSignature numberOfArguments] != 4 )
		return;
	NSInvocation *delegateInvocation = [NSInvocation invocationWithMethodSignature:delegateSelectorSignature];
	[delegateInvocation setSelector:delegateSelector];
	[delegateInvocation setTarget:delegate];
	[delegateInvocation setArgument:&self atIndex:2];
	[delegateInvocation setArgument:&changedObject atIndex:3];
	
	//fire a timer that will call the delegate on the next iteration of the run loop
	[NSTimer scheduledTimerWithTimeInterval:0 invocation:delegateInvocation repeats:NO];

}

- (BOOL)allXgridResourcesUpdated
{
	NSEnumerator *e = [xgridResources objectEnumerator];
	XGResource *res;
	while ( res = [e nextObject] ) {
		if ( [res isUpdated] == NO )
			return NO;
	}
	return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@\nObject = <%@:%p>\nKey Path = %@\nChange = %@",[self class],self,_cmd, [self shortDescription], [object class], object, keyPath, [change description]);
	
	//otherwise, we need to notify the delegate of the change in the next iteration of the run loop, using the appropriate selector:
	// - @selector(xgridResourceDidUpdate:) if the changed key is "updated"
	// - @selector(xgridResource_KEY_DidChange:) if the changed key is "_KEY_"
	SEL delegateSelector;
	
	//if the key is "updated", we need to notify the delegate using the method defined in the delegate informal protocol
	if ( [keyPath isEqualToString:@"updated"] ) {
		[self notifyDelegateWithSelector:@selector(resourceArrayObserver:xgridResourceDidUpdate:) changedObject:object];
		if ( [self allXgridResourcesUpdated] )
			[self notifyDelegateWithSelector:@selector(resourceArrayObserver:xgridResourcesDidUpdate:) changedObject:xgridResources];
	}
	else {
		NSString *capitalizedKey = [NSString stringWithFormat:@"%@%@",[[keyPath substringToIndex:1] uppercaseString], [keyPath substringFromIndex:1]];
		delegateSelector = NSSelectorFromString([NSString stringWithFormat:@"resourceArrayObserver:xgridResource%@DidChange:",capitalizedKey]);
		[self notifyDelegateWithSelector:delegateSelector changedObject:object];
	}
}


@end
