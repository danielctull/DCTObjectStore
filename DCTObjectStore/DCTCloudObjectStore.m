//
//  DCTCloudObjectStore.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import CloudKit;
#import "DCTCloudObjectStore.h"
#import "DCTCloudObjectStoreChange.h"
#import "DCTCloudObjectStoreDelegate.h"
#import "DCTDiskObjectStore.h"
#import "DCTObjectStoreIdentifier.h"

#import "DCTCloudObjectStoreDecoder.h"
#import "DCTObjectStoreCloudEncoder.h"

static NSString *const DCTCloudObjectStoreType = @"DCTCloudObjectStoreType";

@interface DCTCloudObjectStore ()
@property (nonatomic) CKContainer *container;
@property (nonatomic) CKDatabase *database;
@property (nonatomic) CKRecordZone *recordZone;
@property (nonatomic) CKSubscription *subscription;
@property (nonatomic) NSMutableDictionary *records;

@property (nonatomic) DCTDiskObjectStore *changesStore;
@property (nonatomic, readonly) NSDictionary *pendingChanges;
@end

@implementation DCTCloudObjectStore

- (void)dealloc {
	[self deleteSubscription];
}

- (instancetype)initWithStoreIdentifier:(NSString *)storeIdentifier
						cloudIdentifier:(NSString *)cloudIdentifier {

	NSParameterAssert(storeIdentifier);
	NSParameterAssert(cloudIdentifier);

	self = [super init];
	if (!self) return nil;

	_storeIdentifier = [storeIdentifier copy];
	_cloudIdentifier = [cloudIdentifier copy];
	_container = [CKContainer containerWithIdentifier:cloudIdentifier];
	_database = _container.privateCloudDatabase;
	_records = [NSMutableDictionary new];
	_changesStore = nil;

	[self fetchRecordZone];

	return self;
}

- (void)saveObject:(id<DCTObjectStoreCoding>)object {
	[self updateObject:object withChangeType:DCTCloudObjectStoreChangeTypeSave];
}

- (void)deleteObject:(id<DCTObjectStoreCoding>)object {
	[self updateObject:object withChangeType:DCTCloudObjectStoreChangeTypeDelete];
}

- (void)updateObject:(id<DCTObjectStoreCoding>)object withChangeType:(DCTCloudObjectStoreChangeType)type {
	NSString *identifier = [DCTObjectStoreIdentifier identifierForObject:object];
	DCTCloudObjectStoreChange *change = [[DCTCloudObjectStoreChange alloc] initWithIdentifier:identifier object:object type:type];
	[self.changesStore saveObject:change];
	[self uploadChanges];
}

- (void)destroy {
	[self.database deleteSubscriptionWithID:self.subscription.subscriptionID completionHandler:nil];
	[self.database deleteRecordZoneWithID:self.recordZone.zoneID completionHandler:nil];
}

#pragma mark - Changes

- (NSDictionary *)pendingChanges {
	NSSet *changes = self.changesStore.objects;
	NSMutableDictionary *pendingChanges = [NSMutableDictionary new];
	for (DCTCloudObjectStoreChange *change in changes) {
		NSString *identifier = change.idenitfier;
		pendingChanges[identifier] = change;
	}
	return [pendingChanges copy];
}

- (void)downloadChangesWithCompletion:(void(^)())completion {

	if (!self.recordZone) return;

	CKFetchRecordChangesOperation *operation = [[CKFetchRecordChangesOperation alloc] initWithRecordZoneID:self.recordZone.zoneID previousServerChangeToken:nil];
	operation.recordWithIDWasDeletedBlock = ^(CKRecordID *recordID) {
		NSString *identifier = recordID.recordName;
		id<DCTObjectStoreCoding> object = [self.delegate cloudObjectStore:self objectWithIdentifier:identifier];
		[self.delegate cloudObjectStore:self didRemoveObject:object];
	};
	operation.recordChangedBlock = ^(CKRecord *record) {

		CKRecordID *recordID = record.recordID;
		NSString *identifier = recordID.recordName;

		// If the object is to be uploaded, we'll use that data rather than that on the server.
		if (self.pendingChanges[identifier]) {
			return;
		}

		id<DCTObjectStoreCoding> object = [self.delegate cloudObjectStore:self objectWithIdentifier:identifier];
		if (object) {

			DCTCloudObjectStoreDecoder *decoder = [[DCTCloudObjectStoreDecoder alloc] initWithRecord:record];
			[object decodeWithCoder:decoder];
			[self.delegate cloudObjectStore:self didUpdateObject:object];

		} else {

			Class class = NSClassFromString(record.recordType);

			// If the class is nil, this may be an older version of the app, so we ignore.
			if (!class) return;

			object = [[class alloc] initWithCoder:nil];
			[self.delegate cloudObjectStore:self didInsertObject:object];
		}
	};

	[self.container addOperation:operation];
}

- (void)uploadChanges {

	if (!self.recordZone) return;

	dispatch_group_t group = dispatch_group_create();
	NSMutableArray *recordsToSave = [NSMutableArray new];
	NSMutableArray *recordIDsToDelete = [NSMutableArray new];
	NSDictionary *pendingChanges = self.pendingChanges;

	for (DCTCloudObjectStoreChange *change in pendingChanges.allValues) {

		NSString *identifier = change.idenitfier;
		dispatch_group_enter(group);
		[self fetchRecordWithName:identifier competion:^(CKRecord *record) {

			switch (change.type) {
				case DCTCloudObjectStoreChangeTypeSave: {

					id<DCTObjectStoreCoding> object = change.object;
					NSString *className = NSStringFromClass([object class]);
					if (!record) {
						CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:identifier zoneID:self.recordZone.zoneID];
						record = [[CKRecord alloc] initWithRecordType:className recordID:recordID];
					}

					DCTObjectStoreCloudEncoder *encoder = [[DCTObjectStoreCloudEncoder alloc] initWithRecord:record];
					[object encodeWithCoder:encoder];
					[recordsToSave addObject:record];
					break;
				}

				case DCTCloudObjectStoreChangeTypeDelete: {
					if (record) {
						[recordIDsToDelete addObject:record.recordID];
					}
				}
			}

			dispatch_group_leave(group);
		}];
	}

	dispatch_group_notify(group, dispatch_get_main_queue(), ^{
		CKModifyRecordsOperation *modifyOperation = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:nil];
		modifyOperation.queuePriority = NSOperationQueuePriorityHigh;
		modifyOperation.modifyRecordsCompletionBlock = ^(NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *operationError) {

			NSArray *savedRecordIDs = [savedRecords valueForKey:@"recordID"];
			NSArray *recordIDs = [savedRecordIDs arrayByAddingObjectsFromArray:deletedRecordIDs];

			for	(CKRecordID *recordID in recordIDs) {
				NSString *identifier = recordID.recordName;
				DCTCloudObjectStoreChange *change = pendingChanges[identifier];
				[self.changesStore deleteObject:change];
			}
		};
		[self.container addOperation:modifyOperation];
	});
}

- (void)fetchRecordWithName:(NSString *)recordName competion:(void(^)(CKRecord *))completion {

	CKRecord *record = self.records[recordName];
	if (record) {
		completion(record);
		return;
	}

	if (!self.recordZone) return;

	CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:recordName zoneID:self.recordZone.zoneID];
	[self fetchRecordsWithIDs:@[recordID] completion:^(NSDictionary *records, NSError *error) {
		CKRecord *record = records[recordName];
		self.records[recordName] = record;
		completion(record);
	}];
}

#pragma mark - Subscription

- (void)deleteSubscription {

	if (!self.subscription) return;

	[self.database deleteSubscriptionWithID:self.subscription.subscriptionID completionHandler:nil];
}

- (void)saveSubscription {

	if (!self.recordZone) return;

	self.subscription = [[CKSubscription alloc] initWithZoneID:self.recordZone.zoneID options:(CKSubscriptionOptions)(CKSubscriptionOptionsFiresOnRecordCreation | CKSubscriptionOptionsFiresOnRecordDeletion | CKSubscriptionOptionsFiresOnRecordUpdate)];
	[self.database saveSubscription:self.subscription completionHandler:nil];
}

#pragma mark - Record Zone

- (void)setRecordZone:(CKRecordZone *)recordZone {
	_recordZone = recordZone;
	[self saveSubscription];
	[self downloadChangesWithCompletion:^{
		[self uploadChanges];
	}];
}

#pragma mark - CloudKit Operations

- (void)fetchRecordsWithIDs:(NSArray *)recordIDs completion:(void(^)(NSDictionary *records, NSError *error))completion {
	CKFetchRecordsOperation *fetchOperation = [[CKFetchRecordsOperation alloc] initWithRecordIDs:recordIDs];
	fetchOperation.queuePriority = NSOperationQueuePriorityHigh;
	fetchOperation.fetchRecordsCompletionBlock = completion;
	[self.container addOperation:fetchOperation];
}

- (void)fetchRecordZone {

	NSString *storeIdentifier = self.storeIdentifier;
	CKRecordZoneID *zoneID = [[CKRecordZoneID alloc] initWithZoneName:storeIdentifier ownerName:CKOwnerDefaultName];
	CKFetchRecordZonesOperation *fetchRecordZones = [[CKFetchRecordZonesOperation alloc] initWithRecordZoneIDs:@[zoneID]];
	fetchRecordZones.queuePriority = NSOperationQueuePriorityVeryHigh;
	[fetchRecordZones setFetchRecordZonesCompletionBlock:^(NSDictionary *zones, NSError *error) {

		CKRecordZone *recordZone = zones[storeIdentifier];
		if (recordZone) {
			self.recordZone = recordZone;
			return;
		}

		recordZone = [[CKRecordZone alloc] initWithZoneName:storeIdentifier];
		CKModifyRecordZonesOperation *addZoneOperation = [[CKModifyRecordZonesOperation alloc] initWithRecordZonesToSave:@[recordZone] recordZoneIDsToDelete:nil];
		addZoneOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
		addZoneOperation.modifyRecordZonesCompletionBlock = ^(NSArray *savedRecordZones, NSArray *deletedRecordZoneIDs, NSError *operationError) {
			for (CKRecordZone *recordZone in savedRecordZones) {
				if ([recordZone.zoneID.zoneName isEqualToString:storeIdentifier]) {
					self.recordZone = recordZone;
				}
			}
		};
		[self.container addOperation:addZoneOperation];
	}];
	[self.container addOperation:fetchRecordZones];
}

@end
