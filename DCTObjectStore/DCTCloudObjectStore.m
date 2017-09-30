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
#import "DCTDiskObjectStore.h"
#import "DCTObjectStoreChange.h"
#import "DCTCloudObjectStoreDecoder.h"
#import "DCTCloudObjectStoreEncoder.h"
#import "DCTObjectStoreIdentifierInternal.h"
#import "CKRecordID+DCTObjectStoreCoding.h"
#import "CKRecord+DCTObjectStoreCoding.h"
#import "DCTObjectStoreReachability.h"

static NSString *const DCTCloudObjectStoreChanges = @"Changes";
static NSString *const DCTCloudObjectStoreRecordIDs = @"RecordIDs";
static NSString *const DCTCloudObjectStoreRecords = @"Records";
static NSString *const DCTCloudObjectStoreServerChangeToken = @"ServerChangeToken";
static NSString *const DCTCloudObjectStoreRecordZone = @"RecordZone";

@interface DCTCloudObjectStore ()
@property (nonatomic) CKDatabase *database;
@property (nonatomic) CKRecordZone *recordZone;
@property (nonatomic) CKSubscription *subscription;
@property (nonatomic) CKServerChangeToken *serverChangeToken;

@property (nonatomic) DCTDiskObjectStore *changeStore;
@property (nonatomic) DCTDiskObjectStore *recordIDStore;
@property (nonatomic) DCTDiskObjectStore *recordStore;
@end

@implementation DCTCloudObjectStore
@synthesize recordZone = _recordZone;
@synthesize serverChangeToken = _serverChangeToken;

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:DCTObjectStoreReachabilityDidChangeNotification object:nil];
}

- (instancetype)initWithName:(NSString *)name
			 storeIdentifier:(NSString *)storeIdentifier
			 cloudIdentifier:(NSString *)cloudIdentifier
						 URL:(NSURL *)URL
					cacheURL:(NSURL *)cacheURL {

	NSParameterAssert(storeIdentifier);
	NSParameterAssert(cloudIdentifier);

	self = [super init];
	if (!self) return nil;

	_name = [name copy];
	_storeIdentifier = [storeIdentifier copy];
	_cloudIdentifier = [cloudIdentifier copy];
	_URL = [URL copy];
	_cacheURL = [URL copy];

	NSURL *changesURL = [URL URLByAppendingPathComponent:DCTCloudObjectStoreChanges];
	_changeStore = [[DCTDiskObjectStore alloc] initWithURL:changesURL];

	NSURL *recordIDsURL = [URL URLByAppendingPathComponent:DCTCloudObjectStoreRecordIDs];
	_recordIDStore = [[DCTDiskObjectStore alloc] initWithURL:recordIDsURL];

	NSURL *recordsURL = [cacheURL URLByAppendingPathComponent:DCTCloudObjectStoreRecords];
	_recordStore = [[DCTDiskObjectStore alloc] initWithURL:recordsURL];

	CKContainer *container = [CKContainer containerWithIdentifier:cloudIdentifier];
	_database = container.privateCloudDatabase;

	[self fetchRecordZone];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChangeNotification:) name:DCTObjectStoreReachabilityDidChangeNotification object:nil];

	return self;
}

- (void)saveObject:(id<DCTObjectStoreCoding>)object {
	[self updateObject:object changeType:DCTObjectStoreChangeTypeSave];
}

- (void)deleteObject:(id<DCTObjectStoreCoding>)object {
	[self updateObject:object changeType:DCTObjectStoreChangeTypeDelete];
}

- (void)updateObject:(id<DCTObjectStoreCoding>)object changeType:(DCTObjectStoreChangeType)changeType {
	DCTObjectStoreChange *change = [[DCTObjectStoreChange alloc] initWithObject:object type:changeType];
	[DCTObjectStoreIdentifierInternal setIdentifier:change.identifier forObject:change];
	[self.changeStore saveObject:change];
	[self uploadChanges];
}

- (void)destroy {
	[self.changeStore destroy];
	[self.recordIDStore destroy];

	NSError *error;
	BOOL success = [[NSFileManager new] removeItemAtURL:self.URL error:&error];
	if (!success) NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), error);

	if (self.subscription) [self.database deleteSubscriptionWithID:self.subscription.subscriptionID completionHandler:^(NSString *subscriptionID, NSError *error) {}];
	if (self.recordZone) [self.database deleteRecordZoneWithID:self.recordZone.zoneID completionHandler:^(CKRecordZoneID *zoneID, NSError *error) {}];
}

- (void)handleNotification:(__unused CKRecordZoneNotification *)notification {
	[self downloadChangesWithCompletion:nil];
}

- (void)reachabilityDidChangeNotification:(NSNotification *)notification {

	DCTObjectStoreReachability *reachability = notification.object;
	if (reachability.status != DCTObjectStoreReachabilityStatusConnected) {
		return;
	}

	[self saveSubscription];
	[self downloadChangesWithCompletion:^{
		[self uploadChanges];
	}];
}

#pragma mark - Changes

- (void)downloadChangesWithCompletion:(void(^)(void))completion {

	[self fetchRecordChangesWithDeletionHandler:^(CKRecordID *recordID, NSString *recordType) {

		NSString *identifier = recordID.recordName;
		[DCTObjectStoreIdentifierInternal setIdentifier:identifier forObject:recordID];
		[self.recordIDStore deleteObject:recordID];
		id<DCTObjectStoreCoding> object = [self.delegate cloudObjectStore:self objectWithIdentifier:identifier];
		if (object) [self.delegate cloudObjectStore:self didRemoveObject:object];

	} updateHandler:^(CKRecord *record) {

		CKRecordID *recordID = record.recordID;
		NSString *identifier = recordID.recordName;

		[DCTObjectStoreIdentifierInternal setIdentifier:identifier forObject:recordID];
		[self.recordIDStore saveObject:recordID];

		[DCTObjectStoreIdentifierInternal setIdentifier:identifier forObject:record];
		[self.recordStore saveObject:record];

		// Not the most ideal way, I know
		DCTObjectStoreChange *change = [self.changeStore objectForIdentifier:identifier];
		NSDate *modificationDate = record.modificationDate;
		if (modificationDate && [change.date compare:modificationDate] == NSOrderedDescending) {
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
			[DCTObjectStoreIdentifierInternal setIdentifier:identifier forObject:object];
			[self.delegate cloudObjectStore:self didInsertObject:object];
		}

	} completion:completion];
}

- (void)uploadChanges {

	if (!self.recordZone) return;

	NSSet *changes = self.changeStore.objects;
	if (changes.count == 0) {
		return;
	}

	dispatch_group_t group = dispatch_group_create();
	NSMutableArray *recordsToSave = [NSMutableArray new];
	NSMutableArray *recordIDsToDelete = [NSMutableArray new];
	NSMutableDictionary *workingChanges = [[NSMutableDictionary alloc] initWithCapacity:changes.count];

	CKRecordSavePolicy policy = CKRecordSaveIfServerRecordUnchanged;
	NSPredicate *forcePushPredicate = [NSPredicate predicateWithFormat:@"%K == %@", DCTObjectStoreChangeAttributes.requiresForceSave, @(YES)];
	NSSet *forceChanges = [changes filteredSetUsingPredicate:forcePushPredicate];
	if (forceChanges.count > 0) {
		changes = forceChanges;
		policy = CKRecordSaveChangedKeys;
	}

	for (DCTObjectStoreChange *change in changes) {

		NSString *identifier = change.identifier;
		workingChanges[identifier] = change;

		switch (change.type) {
		
			case DCTObjectStoreChangeTypeDelete: {

				CKRecordID *recordID = (CKRecordID *)[self.recordIDStore objectForIdentifier:identifier];
				if (recordID) {
					[recordIDsToDelete addObject:recordID];
				}

				break;
			}

				case DCTObjectStoreChangeTypeSave: {

				dispatch_group_enter(group);
				[self fetchRecordWithName:identifier competion:^(CKRecord *record) {

					id<DCTObjectStoreCoding> object = change.object;
					NSString *className = NSStringFromClass([object class]);

					if (!record) {
						CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:identifier zoneID:self.recordZone.zoneID];
						record = [[CKRecord alloc] initWithRecordType:className recordID:recordID];

						[DCTObjectStoreIdentifierInternal setIdentifier:identifier forObject:recordID];
						[self.recordIDStore saveObject:recordID];
					}

					DCTCloudObjectStoreEncoder *encoder = [[DCTCloudObjectStoreEncoder alloc] initWithRecord:record];
					[object encodeWithCoder:encoder];
					[recordsToSave addObject:record];

					dispatch_group_leave(group);
				}];

				break;
			}
		}
	}

	dispatch_group_notify(group, dispatch_get_main_queue(), ^{

		[self saveRecords:recordsToSave deleteRecordIDs:recordIDsToDelete policy:policy completion:^(NSArray *modifiedRecordIDs, NSError *operationError) {

			for (CKRecordID *recordID in modifiedRecordIDs) {
				NSString *identifier = recordID.recordName;
				DCTObjectStoreChange *change = workingChanges[identifier];
				[self.changeStore deleteObject:change];
			}

			if ([operationError.domain isEqualToString:CKErrorDomain] && operationError.code == CKErrorPartialFailure) {
				NSDictionary *errors = operationError.userInfo[CKPartialErrorsByItemIDKey];
				[errors enumerateKeysAndObjectsUsingBlock:^(CKRecordID *recordID, NSError *recordError, BOOL *stop) {

					if (recordError.code == CKErrorServerRecordChanged) {
						NSString *identifier = recordID.recordName;
						CKRecord *serverRecord = recordError.userInfo[CKRecordChangedErrorServerRecordKey];
						DCTObjectStoreChange *change = workingChanges[identifier];

						if (!serverRecord) {
							change.requiresForceSave = YES;
							[self.changeStore saveObject:change];
							return;
						}

						[DCTObjectStoreIdentifierInternal setIdentifier:identifier forObject:serverRecord];
						[self.recordStore saveObject:serverRecord];

						// If the server change is more recent, ignore the change
						NSDate *modificationDate = serverRecord.modificationDate;
						if (modificationDate && [change.date compare:modificationDate] == NSOrderedDescending) {
							[self.changeStore deleteObject:change];
						}
					}
				}];
				[self uploadChanges];
			}
		}];
	});
}

#pragma mark - Records

- (void)fetchRecordWithName:(NSString *)recordName competion:(void(^)(CKRecord *))completion {

	CKRecord *record = (CKRecord *)[self.recordStore objectForIdentifier:recordName];
	if (record) {
		completion(record);
		return;
	}

	CKRecordID *recordID = (CKRecordID *)[self.recordIDStore objectForIdentifier:recordName];
	if (!recordID) {
		completion(nil);
		return;
	}

	[self fetchRecordWithID:recordID completion:^(CKRecord *record, NSError *error) {

		if (record) {
			[DCTObjectStoreIdentifierInternal setIdentifier:recordName forObject:recordID];
			[self.recordIDStore saveObject:recordID];
		}

		completion(record);
	}];
}

#pragma mark - Subscription

- (void)deleteSubscription {

	if (!self.subscription) return;

	[self.database deleteSubscriptionWithID:self.subscription.subscriptionID completionHandler:^(NSString *subscriptionID, NSError *error) {}];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"

- (void)saveSubscription {

	if (!self.recordZone) return;

	NSString *subscriptionID = self.storeIdentifier;
	[self.database fetchSubscriptionWithID:subscriptionID completionHandler:^(CKSubscription *subscription, NSError *error) {

		if (subscription) {
			self.subscription = subscription;
			return;
		}

		CKRecordZoneSubscription *newSubscription = [[CKRecordZoneSubscription alloc] initWithZoneID:self.recordZone.zoneID subscriptionID:subscriptionID];
		[self.database saveSubscription:newSubscription completionHandler:^(CKSubscription *subscription, NSError *error) {
			self.subscription = subscription;
		}];
	}];
}
#pragma clang diagnostic pop


#pragma mark - Record Zone

- (NSURL *)recordZoneURL {
	return [self.URL URLByAppendingPathComponent:DCTCloudObjectStoreRecordZone];
}

- (void)setRecordZone:(CKRecordZone *)recordZone {
	_recordZone = recordZone;
	NSString *path = self.recordZoneURL.path;
	if (path) {
		[NSKeyedArchiver archiveRootObject:recordZone toFile:path];
	}
	[self saveSubscription];
	[self downloadChangesWithCompletion:^{
		[self uploadChanges];
	}];
}

- (CKRecordZone *)recordZone {

	if (!_recordZone) {
		NSString *path = self.recordZoneURL.path;
		if (path) {
			_recordZone = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
		}
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
	CKRecordZoneID *zoneID = [[CKRecordZoneID alloc] initWithZoneName:self.name ownerName:CKCurrentUserDefaultName];
	[self fetchRecordZoneWithID:zoneID completion:^(CKRecordZone *recordZone, NSError *error) {

		if (recordZone) {
			weakSelf.recordZone = recordZone;
			return;
		}

		recordZone = [[CKRecordZone alloc] initWithZoneID:zoneID];
		[self addRecordZone:recordZone completion:^(CKRecordZone *recordZone, NSError *operationError) {
			weakSelf.recordZone = recordZone;
		}];
	}];
}

#pragma mark - Server Change Token

- (NSURL *)serverChangeTokenURL {
	return [self.URL URLByAppendingPathComponent:DCTCloudObjectStoreServerChangeToken];
}

- (CKServerChangeToken *)serverChangeToken {

	if (!_serverChangeToken) {
		NSString *path = self.serverChangeTokenURL.path;
		if (path) {
			_serverChangeToken = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
		}
	}

	return _serverChangeToken;
}

- (void)setServerChangeToken:(CKServerChangeToken *)serverChangeToken {
	_serverChangeToken = serverChangeToken;
	NSString *path = self.serverChangeTokenURL.path;
	if (path) {
		[NSKeyedArchiver archiveRootObject:serverChangeToken toFile:path];
	}
}

#pragma mark - CloudKit Operations

- (void)fetchRecordChangesWithDeletionHandler:(void(^)(CKRecordID *recordID, NSString *recordType))deletionHandler updateHandler:(void(^)(CKRecord *record))updateHandler completion:(void(^)(void))completion {

	if (!self.recordZone) return;

	CKRecordZoneID *zoneID = self.recordZone.zoneID;
	CKFetchRecordZoneChangesOptions *options = [CKFetchRecordZoneChangesOptions new];
	options.previousServerChangeToken = self.serverChangeToken;

	CKFetchRecordZoneChangesOperation *operation = [[CKFetchRecordZoneChangesOperation alloc] initWithRecordZoneIDs:@[zoneID] optionsByRecordZoneID:@{ zoneID : options }];
	operation.queuePriority = NSOperationQueuePriorityNormal;
	operation.recordWithIDWasDeletedBlock = deletionHandler;
	operation.recordChangedBlock = updateHandler;
	operation.recordZoneFetchCompletionBlock = ^(CKRecordZoneID *recordZoneID, CKServerChangeToken *serverChangeToken, NSData *clientChangeTokenData, BOOL moreComing, NSError * recordZoneError) {

		self.serverChangeToken = serverChangeToken;

		if (moreComing) {
			[self fetchRecordChangesWithDeletionHandler:deletionHandler updateHandler:updateHandler completion:completion];
		} else if (completion) {
			completion();
		}
	};
	[self.database addOperation:operation];
}

- (void)saveRecords:(NSArray *)records deleteRecordIDs:(NSArray *)recordIDs policy:(CKRecordSavePolicy)policy completion:(void(^)(NSArray *modifiedRecordIDs, NSError *operationError))completion {
	CKModifyRecordsOperation *operation = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:records recordIDsToDelete:recordIDs];
	operation.queuePriority = NSOperationQueuePriorityHigh;
	operation.savePolicy = policy;
	operation.modifyRecordsCompletionBlock = ^(NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *error) {
		NSArray *savedRecordIDs = [savedRecords valueForKey:@"recordID"];
		NSArray *modifiedRecordIDs = [savedRecordIDs arrayByAddingObjectsFromArray:deletedRecordIDs];
		completion(modifiedRecordIDs, error);
	};
	[self.database addOperation:operation];
}

- (void)fetchRecordWithID:(CKRecordID *)recordID completion:(void(^)(CKRecord *record, NSError *error))completion {
	CKFetchRecordsOperation *operation = [[CKFetchRecordsOperation alloc] initWithRecordIDs:@[recordID]];
	operation.queuePriority = NSOperationQueuePriorityHigh;
	operation.fetchRecordsCompletionBlock = ^(NSDictionary *recordsByRecordID, NSError *error) {
		CKRecord *record = recordsByRecordID[recordID];
		completion(record, error);
	};
	[self.database addOperation:operation];
}

- (void)fetchRecordZoneWithID:(CKRecordZoneID *)recordZoneID completion:(void(^)(CKRecordZone *recordZone, NSError *error))completion {
	CKFetchRecordZonesOperation *operation = [[CKFetchRecordZonesOperation alloc] initWithRecordZoneIDs:@[recordZoneID]];
	operation.queuePriority = NSOperationQueuePriorityVeryHigh;
	operation.fetchRecordZonesCompletionBlock = ^(NSDictionary *recordZonesByZoneID, NSError *error) {
		CKRecordZone *recordZone = recordZonesByZoneID[recordZoneID];
		completion(recordZone, error);
	};
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
