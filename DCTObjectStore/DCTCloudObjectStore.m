//
//  DCTCloudObjectStore.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import CloudKit;
#import "DCTCloudObjectStore.h"
#import "DCTCloudObjectStoreDelegate.h"
#import "DCTChangeObjectStore.h"
#import "DCTObjectStoreChange.h"
#import "DCTCloudObjectStoreDecoder.h"
#import "DCTCloudObjectStoreEncoder.h"

static NSString *const DCTCloudObjectStoreChanges = @"Changes";
static NSString *const DCTCloudObjectStoreServerChangeToken = @"ServerChangeToken";
static NSString *const DCTCloudObjectStoreRecordZone = @"RecordZone";

@interface DCTCloudObjectStore ()
@property (nonatomic) CKDatabase *database;
@property (nonatomic) CKRecordZone *recordZone;
@property (nonatomic) CKSubscription *subscription;
@property (nonatomic) CKServerChangeToken *serverChangeToken;

@property (nonatomic) NSMutableDictionary *records;

@property (nonatomic) DCTChangeObjectStore *changeStore;
@end

@implementation DCTCloudObjectStore
@synthesize recordZone = _recordZone;
@synthesize serverChangeToken = _serverChangeToken;

- (instancetype)initWithStoreIdentifier:(NSString *)storeIdentifier
						cloudIdentifier:(NSString *)cloudIdentifier
									URL:(NSURL *)URL {

	NSParameterAssert(storeIdentifier);
	NSParameterAssert(cloudIdentifier);

	self = [super init];
	if (!self) return nil;

	_storeIdentifier = [storeIdentifier copy];
	_cloudIdentifier = [cloudIdentifier copy];
	_URL = [URL copy];

	NSURL *changesURL = [URL URLByAppendingPathComponent:DCTCloudObjectStoreChanges];
	_changeStore = [[DCTChangeObjectStore alloc] initWithURL:changesURL];

	CKContainer *container = [CKContainer containerWithIdentifier:cloudIdentifier];
	_database = container.privateCloudDatabase;
	_records = [NSMutableDictionary new];

	[self fetchRecordZone];

	return self;
}

- (void)saveObject:(id<DCTObjectStoreCoding>)object {
	DCTObjectStoreChange *change = [[DCTObjectStoreChange alloc] initWithObject:object type:DCTObjectStoreChangeTypeSave];
	[self.changeStore saveChange:change];
	[self uploadChanges];
}

- (void)deleteObject:(id<DCTObjectStoreCoding>)object {
	DCTObjectStoreChange *change = [[DCTObjectStoreChange alloc] initWithObject:object type:DCTObjectStoreChangeTypeDelete];
	[self.changeStore saveChange:change];
	[self uploadChanges];
}

- (void)destroy {
	[self.database deleteSubscriptionWithID:self.subscription.subscriptionID completionHandler:nil];
	[self.database deleteRecordZoneWithID:self.recordZone.zoneID completionHandler:nil];
}

- (void)handleNotification:(CKRecordZoneNotification *)notification {
	[self downloadChangesWithCompletion:nil];
}

#pragma mark - Changes

- (void)downloadChangesWithCompletion:(void(^)())completion {

	[self fetchRecordChangesWithDeletionHandler:^(CKRecordID *recordID) {

		NSString *identifier = recordID.recordName;
		id<DCTObjectStoreCoding> object = [self.delegate cloudObjectStore:self objectWithIdentifier:identifier];
		[self.delegate cloudObjectStore:self didRemoveObject:object];

	} updateHandler:^(CKRecord *record) {

		CKRecordID *recordID = record.recordID;
		NSString *identifier = recordID.recordName;
		self.records[identifier] = record;

		// Not the most ideal way, I know
		DCTObjectStoreChange *change = [self.changeStore changeForIdentifier:identifier];
		if ([change.date compare:record.modificationDate] == NSOrderedDescending) {
			return;
		}

		id<DCTObjectStoreCoding> object = [self.delegate cloudObjectStore:self objectWithIdentifier:identifier];
		DCTCloudObjectStoreDecoder *decoder = [[DCTCloudObjectStoreDecoder alloc] initWithRecord:record];
		if (object) {

			[object decodeWithCoder:decoder];
			[self.delegate cloudObjectStore:self didUpdateObject:object];

		} else {

			Class class = NSClassFromString(record.recordType);

			// If the class is nil, this may be an older version of the app, so we ignore.
			if (!class) return;

			object = [[class alloc] initWithCoder:decoder];
			[self.delegate cloudObjectStore:self didInsertObject:object];
		}

	} completion:completion];
}

- (void)uploadChanges {

	if (!self.recordZone) return;

	dispatch_group_t group = dispatch_group_create();
	NSMutableArray *recordsToSave = [NSMutableArray new];
	NSMutableArray *recordIDsToDelete = [NSMutableArray new];
	NSArray *changes = self.changeStore.changes;

	for (DCTObjectStoreChange *change in changes) {

		NSString *identifier = change.identifier;
		dispatch_group_enter(group);
		[self fetchRecordWithName:identifier competion:^(CKRecord *record) {

			switch (change.type) {
				case DCTObjectStoreChangeTypeSave: {

					id<DCTObjectStoreCoding> object = change.object;
					NSString *className = NSStringFromClass([object class]);
					if (!record) {
						CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:identifier zoneID:self.recordZone.zoneID];
						record = [[CKRecord alloc] initWithRecordType:className recordID:recordID];
					}

					DCTCloudObjectStoreEncoder *encoder = [[DCTCloudObjectStoreEncoder alloc] initWithRecord:record];
					[object encodeWithCoder:encoder];
					[recordsToSave addObject:record];
					break;
				}

				case DCTObjectStoreChangeTypeDelete: {
					if (record) {
						[recordIDsToDelete addObject:record.recordID];
					}
				}
			}

			dispatch_group_leave(group);
		}];
	}

	dispatch_group_notify(group, dispatch_get_main_queue(), ^{

		[self saveRecords:recordsToSave deleteRecordIDs:recordIDsToDelete completion:^(NSArray *modifiedRecordIDs, NSError *operationError) {
			for	(CKRecordID *recordID in modifiedRecordIDs) {
				NSString *identifier = recordID.recordName;
				[self.changeStore deleteChangeWithIdentifier:identifier];
			}
		}];
	});
}

#pragma mark - Records

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
		if (record) self.records[recordName] = record;
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
	self.subscription = [[CKSubscription alloc] initWithZoneID:self.recordZone.zoneID options:0];
#pragma clang diagnostic pop

	[self.database saveSubscription:self.subscription completionHandler:nil];
}

#pragma mark - Record Zone

- (NSURL *)recordZoneURL {
	return [self.URL URLByAppendingPathComponent:DCTCloudObjectStoreRecordZone];
}

- (void)setRecordZone:(CKRecordZone *)recordZone {
	_recordZone = recordZone;
	[NSKeyedArchiver archiveRootObject:recordZone toFile:self.recordZoneURL.path];
}

- (CKRecordZone *)recordZone {

	if (!_recordZone) {
		_recordZone = [NSKeyedUnarchiver unarchiveObjectWithFile:self.recordZoneURL.path];
	}

	return _recordZone;
}

- (void)fetchRecordZone {

	if (self.recordZone) {
	[self saveSubscription];
	[self downloadChangesWithCompletion:^{
		[self uploadChanges];
	}];
		return;
}

	__weak DCTCloudObjectStore *weakSelf = self;
	NSString *storeIdentifier = self.storeIdentifier;
	CKRecordZoneID *zoneID = [[CKRecordZoneID alloc] initWithZoneName:storeIdentifier ownerName:CKOwnerDefaultName];
	[self fetchZonesWithIDs:@[zoneID] completion:^(NSDictionary *zones, NSError *error) {

		CKRecordZone *recordZone = zones[storeIdentifier];
		if (recordZone) {
			weakSelf.recordZone = recordZone;
			return;
		}

		recordZone = [[CKRecordZone alloc] initWithZoneID:zoneID];
		[self addRecordZone:recordZone completion:^(CKRecordZone *recordZone, NSError *operationError) {
			DCTCloudObjectStore *strongSelf = weakSelf;
			strongSelf.recordZone = recordZone;
			[strongSelf saveSubscription];
			[strongSelf downloadChangesWithCompletion:^{
				[strongSelf uploadChanges];
			}];
		}];
	}];
}

#pragma mark - Server Change Token

- (NSURL *)serverChangeTokenURL {
	return [self.URL URLByAppendingPathComponent:DCTCloudObjectStoreServerChangeToken];
}

- (CKServerChangeToken *)serverChangeToken {

	if (!_serverChangeToken) {
		_serverChangeToken = [NSKeyedUnarchiver unarchiveObjectWithFile:self.serverChangeTokenURL.path];
	}

	return _serverChangeToken;
}

- (void)setServerChangeToken:(CKServerChangeToken *)serverChangeToken {
	_serverChangeToken = serverChangeToken;
	[NSKeyedArchiver archiveRootObject:serverChangeToken toFile:self.serverChangeTokenURL.path];
}

#pragma mark - CloudKit Operations

- (void)fetchRecordChangesWithDeletionHandler:(void(^)(CKRecordID *recordID))deletionHandler updateHandler:(void(^)(CKRecord *record))updateHandler completion:(void(^)())completion {

	if (!self.recordZone) return;

	CKFetchRecordChangesOperation *operation = [[CKFetchRecordChangesOperation alloc] initWithRecordZoneID:self.recordZone.zoneID previousServerChangeToken:self.serverChangeToken];
	operation.queuePriority = NSOperationQueuePriorityNormal;
	operation.recordWithIDWasDeletedBlock = deletionHandler;
	operation.recordChangedBlock = updateHandler;

	__weak CKFetchRecordChangesOperation *weakOperation = operation;
	operation.fetchRecordChangesCompletionBlock = ^(CKServerChangeToken *serverChangeToken, NSData *clientChangeTokenData, NSError *operationError) {

		self.serverChangeToken = serverChangeToken;

		if (weakOperation.moreComing) {
			[self fetchRecordChangesWithDeletionHandler:deletionHandler updateHandler:updateHandler completion:completion];
		} else if (completion) {
			completion();
		}
	};
	[self.database addOperation:operation];
}

- (void)saveRecords:(NSArray *)records deleteRecordIDs:(NSArray *)recordIDs completion:(void(^)(NSArray *modifiedRecordIDs, NSError *operationError))completion {
	CKModifyRecordsOperation *operation = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:records recordIDsToDelete:recordIDs];
	operation.queuePriority = NSOperationQueuePriorityHigh;
	operation.modifyRecordsCompletionBlock = ^(NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *error) {
		NSArray *savedRecordIDs = [savedRecords valueForKey:@"recordID"];
		NSArray *modifiedRecordIDs = [savedRecordIDs arrayByAddingObjectsFromArray:deletedRecordIDs];
		completion(modifiedRecordIDs, error);
	};
	[self.database addOperation:operation];
}

- (void)fetchRecordsWithIDs:(NSArray *)recordIDs completion:(void(^)(NSDictionary *records, NSError *error))completion {
	CKFetchRecordsOperation *operation = [[CKFetchRecordsOperation alloc] initWithRecordIDs:recordIDs];
	operation.queuePriority = NSOperationQueuePriorityHigh;
	operation.fetchRecordsCompletionBlock = completion;
	[self.database addOperation:operation];
}

- (void)fetchZonesWithIDs:(NSArray *)zoneIDs completion:(void(^)(NSDictionary *zones, NSError *error))completion {
	CKFetchRecordZonesOperation *operation = [[CKFetchRecordZonesOperation alloc] initWithRecordZoneIDs:zoneIDs];
	operation.queuePriority = NSOperationQueuePriorityVeryHigh;
	operation.fetchRecordZonesCompletionBlock = completion;
	[self.database addOperation:operation];
}

- (void)addRecordZone:(CKRecordZone *)recordZone completion:(void(^)(CKRecordZone *recordZone, NSError *operationError))completion {
	NSString *name = recordZone.zoneID.zoneName;
	CKModifyRecordZonesOperation *operation = [[CKModifyRecordZonesOperation alloc] initWithRecordZonesToSave:@[recordZone] recordZoneIDsToDelete:nil];
	operation.queuePriority = NSOperationQueuePriorityVeryHigh;
	operation.modifyRecordZonesCompletionBlock = ^(NSArray *savedRecordZones, NSArray *deletedRecordZoneIDs, NSError *error) {

		CKRecordZone *recordZone;
		for (CKRecordZone *savedRecordZone in savedRecordZones) {
			if ([savedRecordZone.zoneID.zoneName isEqualToString:name]) {
				recordZone = savedRecordZone;
			}
		}

		completion(recordZone, error);
	};
	[self.database addOperation:operation];
}

@end
