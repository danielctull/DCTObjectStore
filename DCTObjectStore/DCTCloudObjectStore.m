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

@interface DCTCloudObjectStore ()
@property (nonatomic) CKContainer *container;
@property (nonatomic) CKRecordZone *recordZone;
@end

@implementation DCTCloudObjectStore

- (instancetype)initWithStoreIdentifier:(NSString *)storeIdentifier
						cloudIdentifier:(NSString *)cloudIdentifier {

	NSParameterAssert(storeIdentifier);
	NSParameterAssert(cloudIdentifier);

	self = [super init];
	if (!self) return nil;
	_storeIdentifier = [storeIdentifier copy];
	_cloudIdentifier = [cloudIdentifier copy];
	_container = [CKContainer containerWithIdentifier:cloudIdentifier];
	_recordZone = [[CKRecordZone alloc] initWithZoneName:storeIdentifier];

	CKFetchRecordChangesOperation *operation = [[CKFetchRecordChangesOperation alloc] initWithRecordZoneID:_recordZone.zoneID
																				 previousServerChangeToken:nil];
	operation.recordWithIDWasDeletedBlock = ^(CKRecordID *recordID) {
		NSString *identifier = recordID.recordName;
		id<NSSecureCoding> object = [self.delegate cloudObjectStore:self objectWithIdentifier:identifier];
		[self.delegate cloudObjectStore:self didRemoveObject:object];
	};

	operation.recordChangedBlock = ^(CKRecord *record) {
		CKRecordID *recordID = record.recordID;
		NSString *identifier = recordID.recordName;
		id<NSSecureCoding> object = [self.delegate cloudObjectStore:self objectWithIdentifier:identifier];

		
		[self.delegate cloudObjectStore:self didUpdateObject:object];
	};

	return self;
}

- (void)saveObject:(id<NSSecureCoding>)object {}
- (void)deleteObject:(id<NSSecureCoding>)object {}

- (void)destroy {}

@end
