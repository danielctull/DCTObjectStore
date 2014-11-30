//
//  DCTCloudObjectStoreDecoder.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 30.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTCloudObjectStoreDecoder.h"

@implementation DCTCloudObjectStoreDecoder

- (instancetype)initWithRecord:(CKRecord *)record {
	self = [super init];
	if (!self) return nil;
	_record = record;
	return self;
}

- (id)decodeObjectOfClass:(Class)aClass forKey:(NSString *)key {
	id object = [self.record objectForKey:key];
	if ([object isKindOfClass:aClass]) {
		return object;
	}

	return nil;
}

@end
