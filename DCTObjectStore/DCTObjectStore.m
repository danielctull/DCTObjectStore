//
//  DCTObjectStore.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 13.01.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTObjectStore.h"
#import "DCTObjectStoreAttributes.h"
@import ObjectiveC.runtime;

static void* DCTObjectStoreObjectIdentifier = &DCTObjectStoreObjectIdentifier;

@interface DCTObjectStore ()
@property (nonatomic, readonly) NSString *storeIdentifier;
@property (nonatomic, readonly) NSURL *storeURL;
@end

@implementation DCTObjectStore
@synthesize storeIdentifier = _storeIdentifier;
@synthesize storeURL = _storeURL;

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

+ (instancetype)objectStoreWithName:(NSString *)name groupIdentifier:(NSString *)groupIdentifier synchonizable:(BOOL)synchonizable {

	NSMutableDictionary *objectStores = [self objectStores];
	NSString *identifier = [self storeIdentifierWithName:name groupIdentifier:groupIdentifier synchonizable:synchonizable];
	
	DCTObjectStore *objectStore = objectStores[identifier];
	
	if (!objectStore) {
		objectStore = [[self alloc] initWithName:name groupIdentifier:groupIdentifier synchonizable:synchonizable];
		objectStores[identifier] = objectStore;
	}

	return objectStore;
}

- (void)saveObject:(id<NSSecureCoding>)object {
	NSString *saveUUID = [self identifierForObject:object];
	NSURL *URL = [self.storeURL URLByAppendingPathComponent:saveUUID];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
	[data writeToURL:URL atomically:YES];
	[self updateObject:object];
}

- (void)deleteObject:(id<NSSecureCoding>)object {
	NSString *saveUUID = [self identifierForObject:object];
	NSURL *URL = [self.storeURL URLByAppendingPathComponent:saveUUID];
	[[NSFileManager defaultManager] removeItemAtURL:URL error:NULL];
	[self removeObject:object];
}

+ (void)deleteStore:(DCTObjectStore *)store {
	[self.objectStores removeObjectForKey:store.storeIdentifier];
	[[NSFileManager defaultManager] removeItemAtURL:store.storeURL error:NULL];
}

#pragma mark - Internal

- (instancetype)initWithName:(NSString *)name groupIdentifier:(NSString *)groupIdentifier synchonizable:(BOOL)synchonizable {
	self = [self init];
	if (!self) return nil;
	_name = [name copy];
	_groupIdentifier = [groupIdentifier copy];
	_synchonizable = synchonizable;
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
	NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:self.storeURL
										  includingPropertiesForKeys:nil
															 options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
														errorHandler:nil];

	for (NSURL *URL in enumerator) {

		@try {
			NSData *data = [NSData dataWithContentsOfURL:URL];
			NSString *identifier = [URL lastPathComponent];
			id<DCTObjectStoreCoding> object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			[self setIdentifier:identifier forObject:object];
			[self updateObject:object];
		}
		@catch (__unused NSException *exception) {
			return;
		}
	}
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

#pragma mark - Properties

- (NSString *)storeIdentifier {
	
	if (!_storeIdentifier) {
		_storeIdentifier = [[self class] storeIdentifierWithName:self.name groupIdentifier:self.groupIdentifier synchonizable:self.synchonizable];
	}
	
	return _storeIdentifier;
}

- (NSURL *)storeURL {
	
	if (!_storeURL) {
		_storeURL = [[self objectStoreDirectory] URLByAppendingPathComponent:self.storeIdentifier];
		[[NSFileManager defaultManager] createDirectoryAtURL:_storeURL withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	return _storeURL;
}

#pragma mark - Object Identifiers

- (void)setIdentifier:(NSString *)identifier forObject:(id)object {
	objc_setAssociatedObject(object, DCTObjectStoreObjectIdentifier, identifier, OBJC_ASSOCIATION_COPY);
}

- (NSString *)identifierForObject:(id)object {

	NSString *identifier = objc_getAssociatedObject(object, DCTObjectStoreObjectIdentifier);
	if (!identifier) {
		identifier = [[NSUUID UUID] UUIDString];
		[self setIdentifier:identifier forObject:object];
	}
	return identifier;
}

#pragma mark - Internal

+ (NSString *)storeIdentifierWithName:(NSString *)name groupIdentifier:(NSString *)groupIdentifier synchonizable:(BOOL)synchonizable {
	
	NSString *string = @"";
	if (name) string = [string stringByAppendingString:name];
	string = [string stringByAppendingString:@"-"];
	if (groupIdentifier) string = [string stringByAppendingString:groupIdentifier];
	string = [string stringByAppendingString:@"-"];
	string = [string stringByAppendingString:[@(synchonizable) stringValue]];
	
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	NSString *identifier = [data base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
	return identifier;
}

- (NSURL *)objectStoreDirectory {

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *URL;
	if (self.groupIdentifier.length > 0) {
		URL = [fileManager containerURLForSecurityApplicationGroupIdentifier:self.groupIdentifier];
	} else {
		URL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	}

	return [URL URLByAppendingPathComponent:NSStringFromClass([self class])];
}

@end
