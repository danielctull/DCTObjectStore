//
//  DCTObjectStoreChange.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 30.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTObjectStoreChange.h"
#import "DCTObjectStoreIdentifier.h"

const struct DCTObjectStoreChangeAttributes DCTObjectStoreChangeAttributes = {
	.date = @"date",
	.identifier = @"identifier",
	.object = @"object",
	.type = @"type"
};

@implementation DCTObjectStoreChange

- (instancetype)initWithObject:(id<DCTObjectStoreCoding>)object type:(DCTObjectStoreChangeType)type {
	self = [super init];
	if (!self) return nil;
	_date = [NSDate new];
	_identifier = [DCTObjectStoreIdentifier identifierForObject:object];
	_object = object;
	_type = type;
	return self;
}

#pragma mark - DCTObjectStoreCoding

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (!self) return nil;
	_date = [decoder decodeObjectForKey:DCTObjectStoreChangeAttributes.date];
	_identifier = [decoder decodeObjectOfClass:[NSString class] forKey:DCTObjectStoreChangeAttributes.identifier];
	_object = [decoder decodeObjectForKey:DCTObjectStoreChangeAttributes.object];
	_type = [decoder decodeIntegerForKey:DCTObjectStoreChangeAttributes.type];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:self.date forKey:DCTObjectStoreChangeAttributes.date];
	[encoder encodeObject:self.identifier forKey:DCTObjectStoreChangeAttributes.identifier];
	[encoder encodeObject:self.object forKey:DCTObjectStoreChangeAttributes.object];
	[encoder encodeInteger:self.type forKey:DCTObjectStoreChangeAttributes.type];
}

- (void)decodeWithCoder:(NSCoder *)coder {}

@end