//
//  DCTObjectStore.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 13.01.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTObjectStore.h"
@import ObjectiveC.runtime;

const struct DCTObjectStoreAttributes DCTObjectStoreAttributes = {
	.name = @"name",
	.objects = @"objects",
	.sortDescriptors = @"sortDescriptors"
};

NSString *const DCTObjectStoreDidChangeNotification = @"DCTObjectStoreDidChangeNotification";

static void* DCTObjectStoreSaveUUID = &DCTObjectStoreSaveUUID;

@interface DCTObjectStore ()
@property (nonatomic, readonly) NSURL *objectStoreURL;

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
	return [self objectStoreWithName:name sortDescriptors:nil];
}

+ (instancetype)objectStoreWithName:(NSString *)name sortDescriptors:(NSArray *)sortDescriptors {

	NSMutableDictionary *objectStores = [self objectStores];
	DCTObjectStore *objectStore = objectStores[name];
	if (objectStore) return objectStore;

	objectStore = [[self alloc] initWithName:name sortDescriptors:sortDescriptors];
	objectStores[name] = objectStore;

	return objectStore;
}

- (instancetype)initWithName:(NSString *)name sortDescriptors:(NSArray *)sortDescriptors {
	self = [self init];
	if (!self) return nil;
	_name = [name copy];
	_sortDescriptors = sortDescriptors;
	[self reload];
	return self;
}

- (void)reload {

	if (![NSThread isMainThread]) {
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self reload];
		});
		return;
	}

	NSFileManager *fileManager = [NSFileManager new];
	NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:self.objectStoreURL
										  includingPropertiesForKeys:nil
															 options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
														errorHandler:nil];

	for (NSURL *URL in enumerator) {

		@try {
			NSData *data = [NSData dataWithContentsOfURL:URL];
			NSString *saveUUID = [URL lastPathComponent];
			id<DCTObjectStoreCoding> object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			objc_setAssociatedObject(object, DCTObjectStoreSaveUUID, saveUUID, OBJC_ASSOCIATION_COPY);
			[self updateObject:object];
		}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-exception-parameter"
		@catch (NSException *exception) {
			return;
		}
#pragma clang diagnostic pop
	}
}

- (NSURL *)objectStoreURL {
	NSURL *URL = [[self objectStoreDirectory] URLByAppendingPathComponent:self.name];
	[[NSFileManager defaultManager] createDirectoryAtURL:URL withIntermediateDirectories:YES attributes:nil error:NULL];
	return URL;
}

- (id<DCTObjectStoreCoding>)objectWithSaveUUID:(NSString *)saveUUID {

	for (id object in self.objects) {
		NSString *objectSaveUUID = [self saveUUIDForObject:object];
		if ([saveUUID isEqualToString:objectSaveUUID])
			return object;
	}

	return nil;
}

- (void)updateObject:(id<DCTObjectStoreCoding>)object {

	NSString *saveUUID = objc_getAssociatedObject(object, DCTObjectStoreSaveUUID);
	if (!saveUUID) {
		saveUUID = [[NSUUID UUID] UUIDString];
	}

	id<DCTObjectStoreCoding> currentObject = [self objectWithSaveUUID:saveUUID];

	// If no predicate is set, we show all the accounts we can
	BOOL shouldListAccount = self.objectPredicate ? [self.objectPredicate evaluateWithObject:object] : YES;
	if (!shouldListAccount) {

		if (currentObject)
			[self removeObject:currentObject];

		return;
	}

	[self removeObject:currentObject];
	[self insertObject:object];
}

- (void)insertObject:(id<DCTObjectStoreCoding>)object {

	NSMutableArray *sortObjects = [self.objects mutableCopy];
	[sortObjects addObject:object];
	[sortObjects sortUsingDescriptors:self.sortDescriptors];
	NSUInteger index = [sortObjects indexOfObject:object];

	NSMutableArray *array = [self mutableArrayValueForKey:DCTObjectStoreAttributes.objects];
	[array insertObject:object atIndex:index];

	[[NSNotificationCenter defaultCenter] postNotificationName:DCTObjectStoreDidChangeNotification object:self];
}

- (void)removeObject:(id<DCTObjectStoreCoding>)object {
	NSMutableArray *array = [self mutableArrayValueForKey:DCTObjectStoreAttributes.objects];
	[array removeObject:object];

	[[NSNotificationCenter defaultCenter] postNotificationName:DCTObjectStoreDidChangeNotification object:self];
}

- (void)saveObject:(id<DCTObjectStoreCoding>)object {
	NSString *saveUUID = [self saveUUIDForObject:object];
	NSURL *URL = [[self objectStoreURL] URLByAppendingPathComponent:saveUUID];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
	[data writeToURL:URL atomically:YES];
	[self updateObject:object];
}

- (void)deleteObject:(id<DCTObjectStoreCoding>)object {
	NSString *saveUUID = [self saveUUIDForObject:object];
	NSURL *URL = [[self objectStoreURL] URLByAppendingPathComponent:saveUUID];
	[[NSFileManager defaultManager] removeItemAtURL:URL error:NULL];
	[self removeObject:object];
}

- (NSString *)saveUUIDForObject:(id<DCTObjectStoreCoding>)object {

	NSString *saveUUID = objc_getAssociatedObject(object, DCTObjectStoreSaveUUID);
	if (!saveUUID) {
		saveUUID = [[NSUUID UUID] UUIDString];
		objc_setAssociatedObject(object, DCTObjectStoreSaveUUID, saveUUID, OBJC_ASSOCIATION_COPY);
	}
	return saveUUID;
}

#pragma mark - Internal

- (NSURL *)objectStoreDirectory {
    NSURL *URL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	return [URL URLByAppendingPathComponent:NSStringFromClass([self class])];
}

@end
