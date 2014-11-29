//
//  DCTObjectStore.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 13.01.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTObjectStore.h"
#import "DCTObjectStoreAttributes.h"
#import "DCTObjectStoreIdentifier.h"
#import "DCTDiskObjectStore.h"

@interface DCTObjectStore ()
@property (nonatomic) DCTDiskObjectStore *diskStore;
@property (nonatomic, readwrite) NSSet *objects;
@end

@implementation DCTObjectStore

+ (NSMutableDictionary *)objectStores {
	static NSMutableDictionary *objectStores;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		objectStores = [NSMutableDictionary new];
	});
	return objectStores;
}

+ (instancetype)objectStoreWithName:(NSString *)name {
	return [self objectStoreWithName:name groupIdentifier:nil synchonizable:NO];
}

+ (instancetype)objectStoreWithName:(NSString *)name
					groupIdentifier:(NSString *)groupIdentifier
					  synchonizable:(BOOL)synchonizable {

	NSMutableDictionary *objectStores = [self objectStores];
	NSString *storeIdentifier = [DCTObjectStoreIdentifier storeIdentifierWithName:name
																  groupIdentifier:groupIdentifier
																	synchonizable:synchonizable];
	
	DCTObjectStore *objectStore = objectStores[storeIdentifier];
	
	if (!objectStore) {
		
		objectStore = [[self alloc] initWithName:name
								 storeIdentifier:storeIdentifier
								 groupIdentifier:groupIdentifier
								   synchonizable:synchonizable];
		
		objectStores[storeIdentifier] = objectStore;
	}

	return objectStore;
}

- (void)saveObject:(id<NSSecureCoding>)object {
	[self.diskStore saveObject:object];
	[self updateObject:object];
}

- (void)deleteObject:(id<NSSecureCoding>)object {
	[self.diskStore deleteObject:object];
	[self removeObject:object];
}

- (void)destroy {
	[self.diskStore destroy];
	[[[self class] objectStores] removeObjectForKey:self.storeIdentifier];
}

#pragma mark - Internal

- (instancetype)initWithName:(NSString *)name
			 storeIdentifier:(NSString *)storeIdentifier
			 groupIdentifier:(NSString *)groupIdentifier
			   synchonizable:(BOOL)synchonizable {
	
	self = [self init];
	if (!self) return nil;
	_name = [name copy];
	_storeIdentifier = [storeIdentifier copy];
	_groupIdentifier = [groupIdentifier copy];
	_synchonizable = synchonizable;
	_diskStore = [[DCTDiskObjectStore alloc] initWithStoreIdentifier:storeIdentifier groupIdentifier:groupIdentifier];
	_objects = _diskStore.objects;
	return self;
}

- (void)updateObject:(id<NSSecureCoding>)object {

	if ([self.objects containsObject:object]) {
		return;
	}
	
	[self insertObject:object];
}

- (void)insertObject:(id<NSSecureCoding>)object {
	NSMutableSet *set = [self mutableSetValueForKey:DCTObjectStoreAttributes.objects];
	[set addObject:object];
}

- (void)removeObject:(id<NSSecureCoding>)object {
	NSMutableSet *set = [self mutableSetValueForKey:DCTObjectStoreAttributes.objects];
	[set removeObject:object];
}

@end
