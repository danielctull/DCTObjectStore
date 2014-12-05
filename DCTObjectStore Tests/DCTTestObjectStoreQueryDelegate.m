//
//  DCTTestObjectStoreQueryDelegate.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 05.12.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTTestObjectStoreQueryDelegate.h"
#import "DCTTestObjectStoreQueryDelegateEvent.h"

@interface DCTTestObjectStoreQueryDelegate ()
@property (nonatomic) NSMutableArray *internalEvents;
@end

@implementation DCTTestObjectStoreQueryDelegate

- (instancetype)init {
	self = [super init];
	if (!self) return nil;
	_internalEvents = [NSMutableArray new];
	return self;
}

- (NSArray *)events {
	return [self.internalEvents copy];
}

- (void)objectStoreController:(DCTObjectStoreQuery *)query didInsertObject:(id)object atIndex:(NSUInteger)index {
	DCTTestObjectStoreQueryDelegateEvent *event = [[DCTTestObjectStoreQueryDelegateEvent alloc] initWithObjectStoreQuery:query
																												  object:object
																													type:DCTTestObjectStoreQueryDelegateEventTypeInsert
																											   fromIndex:index
																												 toIndex:index];
	[self.internalEvents addObject:event];
}

- (void)objectStoreController:(DCTObjectStoreQuery *)query didRemoveObject:(id)object fromIndex:(NSUInteger)index {
	DCTTestObjectStoreQueryDelegateEvent *event = [[DCTTestObjectStoreQueryDelegateEvent alloc] initWithObjectStoreQuery:query
																												  object:object
																													type:DCTTestObjectStoreQueryDelegateEventTypeRemove
																											   fromIndex:index
																												 toIndex:index];
	[self.internalEvents addObject:event];
}

- (void)objectStoreController:(DCTObjectStoreQuery *)query didMoveObject:(id)object fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
	DCTTestObjectStoreQueryDelegateEvent *event = [[DCTTestObjectStoreQueryDelegateEvent alloc] initWithObjectStoreQuery:query
																												  object:object
																													type:DCTTestObjectStoreQueryDelegateEventTypeMove
																											   fromIndex:fromIndex
																												 toIndex:toIndex];
	[self.internalEvents addObject:event];
}

- (void)objectStoreController:(DCTObjectStoreQuery *)query didUpdateObject:(id)object atIndex:(NSUInteger)index {
	DCTTestObjectStoreQueryDelegateEvent *event = [[DCTTestObjectStoreQueryDelegateEvent alloc] initWithObjectStoreQuery:query
																												  object:object
																													type:DCTTestObjectStoreQueryDelegateEventTypeUpdate
																											   fromIndex:index
																												 toIndex:index];
	[self.internalEvents addObject:event];
}

@end
