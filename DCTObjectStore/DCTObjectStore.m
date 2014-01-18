//
//  DCTObjectStore.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 13.01.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTObjectStore.h"

const struct DCTObjectStoreAttributes DCTObjectStoreAttributes = {
	.name = @"name",
	.objects = @"objects",
	.sortDescriptors = @"sortDescriptors"
};

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
	DCTObjectStore *objectStore = [objectStores objectForKey:name];
	if (objectStore) return objectStore;

	NSURL *URL = [self objectStoreDirectory];
	URL = [URL URLByAppendingPathComponent:name];
	NSData *data = [NSData dataWithContentsOfURL:URL];
	if (data)
		objectStore = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	else
		objectStore = [[self alloc] initWithName:name sortDescriptors:sortDescriptors];

	[objectStores setObject:objectStore forKey:name];
	return objectStore;
}

- (void)addObject:(id<DCTObjectStoreCoding>)object {

	NSMutableArray *sortObjects = [self.objects mutableCopy];
	[sortObjects addObject:object];
	[sortObjects sortUsingDescriptors:self.sortDescriptors];
	NSUInteger index = [sortObjects indexOfObject:object];

	NSMutableArray *array = [self mutableArrayValueForKey:DCTObjectStoreAttributes.objects];
	[array insertObject:object atIndex:index];
}

- (void)removeObject:(id<DCTObjectStoreCoding>)object {
	NSMutableArray *array = [self mutableArrayValueForKey:DCTObjectStoreAttributes.objects];
	[array removeObject:object];
}

- (void)updateObject:(id<DCTObjectStoreCoding>)object {

	NSUInteger index = [self.objects indexOfObject:object];
	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];

	[self willChange:NSKeyValueChangeReplacement
	 valuesAtIndexes:indexSet
			  forKey:DCTObjectStoreAttributes.objects];

	[self didChange:NSKeyValueChangeReplacement
	valuesAtIndexes:indexSet
			 forKey:DCTObjectStoreAttributes.objects];
}

- (BOOL)save:(NSError *__autoreleasing*)error {
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
	NSURL *URL = [[self class] objectStoreDirectory];
	[[NSFileManager defaultManager] createDirectoryAtURL:URL withIntermediateDirectories:YES attributes:nil error:nil];
	URL = [URL URLByAppendingPathComponent:self.name];
	return [data writeToURL:URL options:NSDataWritingAtomic error:error];
}

#pragma mark - NSSecureCoding

- (id)initWithCoder:(NSCoder *)coder {
	self = [self init];
	if (!self) return nil;
	_name = [coder decodeObjectOfClass:[NSString class] forKey:DCTObjectStoreAttributes.name];
	_objects = [coder decodeObjectOfClass:[NSArray class] forKey:DCTObjectStoreAttributes.objects];
	_sortDescriptors = [coder decodeObjectOfClass:[NSArray class] forKey:DCTObjectStoreAttributes.sortDescriptors];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.name forKey:DCTObjectStoreAttributes.name];
	[coder encodeObject:self.objects forKey:DCTObjectStoreAttributes.objects];
	[coder encodeObject:self.sortDescriptors forKey:DCTObjectStoreAttributes.sortDescriptors];
}

+ (BOOL)supportsSecureCoding {
	return YES;
}

#pragma mark - Internal

+ (NSURL *)objectStoreDirectory {
    NSURL *URL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	return [URL URLByAppendingPathComponent:NSStringFromClass(self)];
}

- (instancetype)initWithName:(NSString *)name sortDescriptors:(NSArray *)sortDescriptors {
	self = [self init];
	if (!self) return nil;
	_name = [name copy];
	_sortDescriptors = sortDescriptors;
	return self;
}

@end
