//
//  GEZResourceArrayObserver.h
//  XgridStatus
//
//  Created by Charles Parnot on 8/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GEZResourceArrayObserver : NSObject {
	NSMutableArray *xgridResources;
	id delegate;
	NSSet *observedKeys;
}

- (id)initWithResources:(NSArray *)resourceArray;
- (id)initWithResources:(NSArray *)resourceArray observedKeys:(NSSet *)keys;

// resource array can be changed even after the GEZResourceArrayObserver was instantiated
- (void)setXgridResources:(NSArray *)resourceArray;

- (id)delegate;
- (void)setDelegate:(id)anObject;

- (NSArray *)xgridResources;
- (NSSet *)observedKeys;
- (void)setObservedKeys:(NSSet *)keys;

- (BOOL)allXgridResourcesUpdated;

@end


@interface NSObject (GEZResourceArrayObserverDelegate)
- (void)resourceArrayObserver:(GEZResourceArrayObserver *)observer xgridResourceDidUpdate:(XGResource *)resource;
- (void)resourceArrayObserver:(GEZResourceArrayObserver *)observer xgridResourcesDidUpdate:(NSArray *)resourceArray;
//the GEZResourceObserver will dynamically generate a call to the appropriate method, where _KEY_ is the key path corresponding to the changed ivar
- (void)resourceArrayObserver:(GEZResourceArrayObserver *)observer xgridResource_KEY_DidChange:(XGResource *)resource;
@end