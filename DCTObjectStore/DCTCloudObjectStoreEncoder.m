//
//  DCTCloudObjectStoreEncoder.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 11.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTCloudObjectStoreEncoder.h"

@implementation DCTCloudObjectStoreEncoder

- (instancetype)initWithRecord:(CKRecord *)record {
	self = [super init];
	if (!self) return nil;
	_record = record;
	return self;
}

- (void)encodeObject:(id)object forKey:(NSString *)key {

	NSAssert(!object || [object conformsToProtocol:@protocol(CKRecordValue)], @"All given objects must conform to CKRecordValue.");

	[self.record setObject:object forKey:key];
}

@end
