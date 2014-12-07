//
//  DCTObjectStoreQuery.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 16/08/2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTObjectStoreQuery.h"
#import "DCTObjectStore.h"
#import "DCTObjectStoreAttributes.h"

const struct DCTObjectStoreQueryAttributes DCTObjectStoreQueryAttributes = {
	.predicate = @"predicate",
	.sortDescriptors = @"sortDescriptors",
	.objects = @"objects"
};

@interface DCTObjectStoreQuery ()
@property (nonatomic, readwrite) NSArray *objects;
@end

@implementation DCTObjectStoreQuery

- (void)dealloc {
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self name:DCTObjectStoreDidInsertObjectNotification object:_objectStore];
	[notificationCenter removeObserver:self name:DCTObjectStoreDidChangeObjectNotification object:_objectStore];
	[notificationCenter removeObserver:self name:DCTObjectStoreDidRemoveObjectNotification object:_objectStore];
}

- (instancetype)initWithObjectStore:(DCTObjectStore *)objectStore predciate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors {
	self = [self init];
	if (!self) return nil;

	NSParameterAssert(objectStore);
	NSParameterAssert(sortDescriptors);

	_objectStore = objectStore;
	_predicate = [predicate copy];
	_sortDescriptors = [sortDescriptors copy];
	_objects = [self objectsFromObjectStore:objectStore predciate:predicate sortDescriptors:sortDescriptors];

	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(objectStoreDidInsertObjectNotification:) name:DCTObjectStoreDidInsertObjectNotification object:objectStore];
	[notificationCenter addObserver:self selector:@selector(objectStoreDidChangeObjectNotification:) name:DCTObjectStoreDidChangeObjectNotification object:objectStore];
	[notificationCenter addObserver:self selector:@selector(objectStoreDidRemoveObjectNotification:) name:DCTObjectStoreDidRemoveObjectNotification object:objectStore];

	return self;
}

#pragma mark - Notifications

- (void)objectStoreDidInsertObjectNotification:(NSNotification *)notification {
	id object = notification.userInfo[DCTObjectStoreObjectKey];
	[self insertObject:object];
}

- (void)objectStoreDidChangeObjectNotification:(NSNotification *)notification {
	id object = notification.userInfo[DCTObjectStoreObjectKey];
	[self updateObject:object];
}

- (void)objectStoreDidRemoveObjectNotification:(NSNotification *)notification {
	id object = notification.userInfo[DCTObjectStoreObjectKey];
	[self removeObject:object];
}

- (void)insertObject:(id)object {

	BOOL shouldInsert = self.predicate ? [self.predicate evaluateWithObject:object] : YES;
	if (!shouldInsert) return;

	NSUInteger index = [self newIndexOfObject:object];
	[self insertObject:object atIndex:index];
}

- (void)removeObject:(id)object {
	NSUInteger index = [self.objects indexOfObject:object];
	[self removeObject:object fromIndex:index];
}

- (void)moveObject:(id)object {
	NSUInteger oldIndex = [self.objects indexOfObject:object];
	NSUInteger newIndex = [self newIndexOfObject:object];
	[self moveObject:object fromIndex:oldIndex toIndex:newIndex];
}

- (void)updateObject:(id)object {
	NSUInteger index = [self.objects indexOfObject:object];
	NSUInteger newIndex = [self newIndexOfObject:object];

	if (index != newIndex) {
		[self moveObject:object fromIndex:index toIndex:newIndex];
		return;
	}

	[self updateObject:object atIndex:index];
}

- (NSUInteger)newIndexOfObject:(id)object {
	NSMutableArray *objects = [self.objects mutableCopy];
	[objects addObject:object];
	NSArray *sortedObjects = [objects sortedArrayUsingDescriptors:self.sortDescriptors];
	return [sortedObjects indexOfObject:object];
}

#pragma mark - Raw

- (void)insertObject:(id)object atIndex:(NSUInteger)index {
	NSMutableArray *array = [self mutableArrayValueForKey:DCTObjectStoreQueryAttributes.objects];
	[array insertObject:object atIndex:index];

	[self.delegate objectStoreQuery:self didInsertObject:object atIndex:index];
}

- (void)removeObject:(id)object fromIndex:(NSUInteger)index {
	NSMutableArray *array = [self mutableArrayValueForKey:DCTObjectStoreQueryAttributes.objects];
	[array removeObject:object];

	[self.delegate objectStoreQuery:self didRemoveObject:object fromIndex:index];
}

- (void)moveObject:(id)object fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
	NSMutableArray *array = [self mutableArrayValueForKey:DCTObjectStoreQueryAttributes.objects];
	[array sortUsingDescriptors:self.sortDescriptors];

	[self.delegate objectStoreQuery:self didMoveObject:object fromIndex:fromIndex toIndex:toIndex];
}

- (void)updateObject:(id)object atIndex:(NSUInteger)index {
	NSMutableArray *array = [self mutableArrayValueForKey:DCTObjectStoreQueryAttributes.objects];
	[array removeObject:object];
	[array insertObject:object atIndex:index];

	[self.delegate objectStoreQuery:self didUpdateObject:object atIndex:index];
}

#pragma mark - Helper methods

- (NSArray *)objectsFromObjectStore:(DCTObjectStore *)objectStore predciate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors {
	NSArray *objects = [objectStore.objects allObjects];
	
	if (!objects) {
		objects = @[];
		return objects;
	}

	if (predicate) {
		objects = [objects filteredArrayUsingPredicate:predicate];
	}

	return [objects sortedArrayUsingDescriptors:sortDescriptors];
}

@end
