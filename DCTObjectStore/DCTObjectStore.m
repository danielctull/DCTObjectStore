//
//  DCTObjectStore.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 13.01.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import CloudKit;
#import "DCTObjectStore.h"
#import "DCTObjectStoreAttributes.h"
#import "DCTObjectStoreIdentifier.h"
#import "DCTDiskObjectStore.h"
#import "DCTCloudObjectStore.h"
#import "DCTCloudObjectStoreDelegate.h"

NSString *const DCTObjectStoreDidInsertObjectNotification = @"DCTObjectStoreDidInsertObjectNotification";
NSString *const DCTObjectStoreDidChangeObjectNotification = @"DCTObjectStoreDidChangeObjectNotification";
NSString *const DCTObjectStoreDidRemoveObjectNotification = @"DCTObjectStoreDidRemoveObjectNotification";
NSString *const DCTObjectStoreObjectKey = @"DCTObjectStoreObjectKey";

@interface DCTObjectStore () <DCTCloudObjectStoreDelegate>
@property (nonatomic, readonly) DCTDiskObjectStore *diskStore;
@property (nonatomic, readonly) DCTCloudObjectStore *cloudStore;
@property (nonatomic, readwrite) NSSet *objects;
@end

@implementation DCTObjectStore

+ (void)handleRemoteNotification:(NSDictionary *)remoteNotification {
	CKRecordZoneNotification *notification = [CKRecordZoneNotification notificationFromRemoteNotificationDictionary:remoteNotification];
	if (![notification isKindOfClass:[CKRecordZoneNotification class]]) {
		return;
	}

	NSString *name = notification.recordZoneID.zoneName;
	NSString *cloudIdentifier = notification.containerIdentifier;
	for (DCTObjectStore *objectStore in self.objectStores.allValues) {
		if ([objectStore.name isEqualToString:name] && [objectStore.cloudIdentifier isEqualToString:cloudIdentifier]) {
			[objectStore.cloudStore handleNotification:notification];
		}
	}
}

+ (NSMutableDictionary *)objectStores {
	static NSMutableDictionary *objectStores;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		objectStores = [NSMutableDictionary new];
	});
	return objectStores;
}

+ (instancetype)objectStoreWithName:(NSString *)name {
	return [self objectStoreWithName:name groupIdentifier:nil cloudIdentifier:nil];
}

+ (instancetype)objectStoreWithName:(NSString *)name
					groupIdentifier:(NSString *)groupIdentifier
					cloudIdentifier:(NSString *)cloudIdentifier {

	NSMutableDictionary *objectStores = [self objectStores];
	NSString *storeIdentifier = [DCTObjectStoreIdentifier storeIdentifierWithName:name
																  groupIdentifier:groupIdentifier
																  cloudIdentifier:cloudIdentifier];
	
	DCTObjectStore *objectStore = objectStores[storeIdentifier];
	
	if (!objectStore) {
		objectStore = [[self alloc] initWithName:name
								 storeIdentifier:storeIdentifier
								 groupIdentifier:groupIdentifier
								 cloudIdentifier:cloudIdentifier];
		
		objectStores[storeIdentifier] = objectStore;
	}

	return objectStore;
}

- (void)saveObject:(id<DCTObjectStoreCoding>)object {

	NSString *identifier = [DCTObjectStoreIdentifier identifierForObject:object];
	if (!identifier) {
		identifier = [[NSUUID UUID] UUIDString];
		[DCTObjectStoreIdentifier setIdentifier:identifier forObject:object];
	}

	[self.diskStore saveObject:object];
	[self.cloudStore saveObject:object];
	[self updateObject:object];
}

- (void)deleteObject:(id<DCTObjectStoreCoding>)object {
	[self.diskStore deleteObject:object];
	[self.cloudStore deleteObject:object];
	[self removeObject:object];
}

- (void)destroy {
	[self.diskStore destroy];
	[self.cloudStore destroy];
	[[[self class] objectStores] removeObjectForKey:self.storeIdentifier];
}

#pragma mark - Internal

- (instancetype)initWithName:(NSString *)name
			 storeIdentifier:(NSString *)storeIdentifier
			 groupIdentifier:(NSString *)groupIdentifier
			 cloudIdentifier:(NSString *)cloudIdentifier {
	
	self = [self init];
	if (!self) return nil;
	_name = [name copy];
	_storeIdentifier = [storeIdentifier copy];
	_groupIdentifier = [groupIdentifier copy];
	_cloudIdentifier = [cloudIdentifier copy];

	NSURL *storeURL = [self URLWithBaseURL:self.documentsURL];

	NSURL *diskStoreURL = [storeURL URLByAppendingPathComponent:NSStringFromClass([DCTDiskObjectStore class])];
	_diskStore = [[DCTDiskObjectStore alloc] initWithURL:diskStoreURL];
	_objects = _diskStore.objects;

	if (cloudIdentifier) {
		NSURL *cacheURL = [self URLWithBaseURL:self.cachesURL];
		NSURL *cloudStoreURL = [storeURL URLByAppendingPathComponent:NSStringFromClass([DCTCloudObjectStore class])];
		NSURL *cloudCacheURL = [cacheURL URLByAppendingPathComponent:NSStringFromClass([DCTCloudObjectStore class])];
		_cloudStore = [[DCTCloudObjectStore alloc] initWithName:name
												storeIdentifier:storeIdentifier
												cloudIdentifier:cloudIdentifier
															URL:cloudStoreURL
													   cacheURL:cloudCacheURL];
		_cloudStore.delegate = self;
	}

	return self;
}

- (NSURL *)cachesURL {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	return [[fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)documentsURL {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (self.groupIdentifier.length > 0) {
		return [fileManager containerURLForSecurityApplicationGroupIdentifier:self.groupIdentifier];
	} else {
		return [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	}
}

- (NSURL *)URLWithBaseURL:(NSURL *)baseURL {
	baseURL = [baseURL URLByAppendingPathComponent:NSStringFromClass([self class])];
	baseURL = [baseURL URLByAppendingPathComponent:self.storeIdentifier];
	return baseURL;
}

- (void)postNotificationWithName:(NSString *)name forObject:(id)object {
	NSDictionary *info = @{ DCTObjectStoreObjectKey : object };
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:info];
}

- (void)updateObject:(id<DCTObjectStoreCoding>)object {

	if ([self.objects containsObject:object]) {
		[self postNotificationWithName:DCTObjectStoreDidChangeObjectNotification forObject:object];
		return;
	}

	[self insertObject:object];
}

- (void)insertObject:(id<DCTObjectStoreCoding>)object {
	NSMutableSet *set = [self mutableSetValueForKey:DCTObjectStoreAttributes.objects];
	[set addObject:object];
	[self postNotificationWithName:DCTObjectStoreDidInsertObjectNotification forObject:object];
}

- (void)removeObject:(id<DCTObjectStoreCoding>)object {
	NSMutableSet *set = [self mutableSetValueForKey:DCTObjectStoreAttributes.objects];
	[set removeObject:object];
	[self postNotificationWithName:DCTObjectStoreDidRemoveObjectNotification forObject:object];
}

#pragma mark - DCTCloudObjectStoreDelegate

- (void)cloudObjectStore:(DCTCloudObjectStore *)cloudObjectStore didInsertObject:(id)object {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.diskStore saveObject:object];
		[self insertObject:object];
	});
}

- (void)cloudObjectStore:(DCTCloudObjectStore *)cloudObjectStore didRemoveObject:(id)object {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.diskStore deleteObject:object];
		[self removeObject:object];
	});
}

- (void)cloudObjectStore:(DCTCloudObjectStore *)cloudObjectStore didUpdateObject:(id)object {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.diskStore saveObject:object];
		[self updateObject:object];
	});
}

- (id<DCTObjectStoreCoding>)cloudObjectStore:(DCTCloudObjectStore *)cloudObjectStore objectWithIdentifier:(NSString *)identifier {

	for (id<DCTObjectStoreCoding> object in self.objects) {
		NSString *objectIdentifier = [DCTObjectStoreIdentifier identifierForObject:object];
		if ([objectIdentifier isEqualToString:identifier]) {
			return object;
		}
	}

	return nil;
}

@end
