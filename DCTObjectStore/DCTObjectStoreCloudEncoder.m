//
//  DCTObjectStoreCloudEncoder.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 11.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTObjectStoreCloudEncoder.h"
#import "DCTObjectStore.h"

@interface DCTObjectStoreCloudEncoder ()
@property (nonatomic) NSMutableDictionary *records;
@property (nonatomic) CKRecord *currentRecord;
@end

@implementation DCTObjectStoreCloudEncoder

- (instancetype)init {
	self = [super init];
	if (!self) return nil;
	_records = [NSMutableDictionary new];
	return self;
}

+ (NSArray *)archivedRecordsWithRootObject:(id)object {
	NSString *classname = NSStringFromClass([object class]);
	CKRecord *record = [[CKRecord alloc] initWithRecordType:classname];
	DCTObjectStoreCloudEncoder *encoder = [[self class] new];
	encoder.currentRecord = record;
	encoder.records[object] = record;
	[object encodeWithCoder:encoder];
	return [encoder.records allValues];
}

- (void)encodeObject:(id)object forKey:(NSString *)key {

//	NSAssert([obj conformsToProtocol:@protocol(DCTObjectStoreCoding)], @"Object %@ should conform to DCTObjectStoreCoding.", obj);
//	id<DCTObjectStoreCoding> object = obj;

	if ([object conformsToProtocol:@protocol(CKRecordValue)]) {

		[self.currentRecord setObject:object forKey:key];

	} else {

		CKRecord *record = self.records[object];

		if (!record) {

			NSAssert([object conformsToProtocol:@protocol(NSSecureCoding)], @"Object %@ should conform to NSSecureCoding.", object);
			id<NSSecureCoding> secureCoding = object;

			CKRecord *currentRecord = self.currentRecord;

			NSString *classname = NSStringFromClass([object class]);
			record = [[CKRecord alloc] initWithRecordType:classname];
			self.records[object] = record;

			self.currentRecord = record;
			[secureCoding encodeWithCoder:self];
			self.currentRecord = currentRecord;
		}

		CKReference *reference = [[CKReference alloc] initWithRecord:record action:CKReferenceActionDeleteSelf];
		[self.currentRecord setObject:reference forKey:key];
	}
}

@end
