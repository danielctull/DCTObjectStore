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

	NSString *storeIdentifier = notification.recordZoneID.zoneName;
	DCTObjectStore *objectStore = self.objectStores[storeIdentifier];
	[objectStore.cloudStore handleNotification:notification];
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

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *baseURL;
	if (self.groupIdentifier.length > 0) {
		baseURL = [fileManager containerURLForSecurityApplicationGroupIdentifier:_groupIdentifier];
	} else {
		baseURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	}
	baseURL = [baseURL URLByAppendingPathComponent:NSStringFromClass([self class])];
	baseURL = [baseURL URLByAppendingPathComponent:storeIdentifier];

	NSURL *diskStoreURL = [baseURL URLByAppendingPathComponent:NSStringFromClass([DCTDiskObjectStore class])];
	_diskStore = [[DCTDiskObjectStore alloc] initWithURL:diskStoreURL];
	_objects = _diskStore.objects;

	if (cloudIdentifier) {
		NSURL *cloudStoreURL = [baseURL URLByAppendingPathComponent:NSStringFromClass([DCTCloudObjectStore class])];
		_cloudStore = [[DCTCloudObjectStore alloc] initWithStoreIdentifier:storeIdentifier
														   cloudIdentifier:cloudIdentifier
																	   URL:cloudStoreURL];
		_cloudStore.delegate = self;
	}

	return self;
}

- (void)updateObject:(id<DCTObjectStoreCoding>)object {

	if ([self.objects containsObject:object]) {
		return;
	}

	[self insertObject:object];
}

- (void)insertObject:(id<DCTObjectStoreCoding>)object {
	NSMutableSet *set = [self mutableSetValueForKey:DCTObjectStoreAttributes.objects];
	[set addObject:object];
}

- (void)removeObject:(id<DCTObjectStoreCoding>)object {
	NSMutableSet *set = [self mutableSetValueForKey:DCTObjectStoreAttributes.objects];
	[set removeObject:object];
}

#pragma mark - DCTCloudObjectStoreDelegate

- (void)cloudObjectStore:(DCTCloudObjectStore *)cloudObjectStore didInsertObject:(id)object {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self insertObject:object];
		[self.diskStore saveObject:object];
	});
}

- (void)cloudObjectStore:(DCTCloudObjectStore *)cloudObjectStore didRemoveObject:(id)object {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self insertObject:object];
		[self.diskStore deleteObject:object];
	});
}

- (void)cloudObjectStore:(DCTCloudObjectStore *)cloudObjectStore didUpdateObject:(id)object {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self updateObject:object];
		[self.diskStore saveObject:object];
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
