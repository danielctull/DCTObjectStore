//
//  DCTCloudObjectStoreChange.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 30.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTCloudObjectStoreChange.h"

extern const struct DCTCloudObjectStoreChangeAttributes {
	__unsafe_unretained NSString *date;
	__unsafe_unretained NSString *identifier;
	__unsafe_unretained NSString *object;
	__unsafe_unretained NSString *type;
} DCTCloudObjectStoreChangeAttributes;

const struct DCTCloudObjectStoreChangeAttributes DCTCloudObjectStoreChangeAttributes = {
	.date = @"date",
	.identifier = @"identifier",
	.object = @"object",
	.type = @"type"
};

@implementation DCTCloudObjectStoreChange

- (instancetype)initWithIdentifier:(NSString *)identifier object:(id<DCTObjectStoreCoding>)object type:(DCTCloudObjectStoreChangeType)type {
	self = [super init];
	if (!self) return nil;
	_date = [NSDate new];
	_idenitfier = [identifier copy];
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
	_date = [decoder decodeObjectForKey:DCTCloudObjectStoreChangeAttributes.date];
	_idenitfier = [decoder decodeObjectOfClass:[NSString class] forKey:DCTCloudObjectStoreChangeAttributes.identifier];
	_object = [decoder decodeObjectForKey:DCTCloudObjectStoreChangeAttributes.object];
	_type = [decoder decodeIntegerForKey:DCTCloudObjectStoreChangeAttributes.type];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:self.date forKey:DCTCloudObjectStoreChangeAttributes.date];
	[encoder encodeObject:self.idenitfier forKey:DCTCloudObjectStoreChangeAttributes.identifier];
	[encoder encodeObject:self.object forKey:DCTCloudObjectStoreChangeAttributes.object];
	[encoder encodeInteger:self.type forKey:DCTCloudObjectStoreChangeAttributes.type];
}

- (void)decodeWithCoder:(NSCoder *)coder {}

@end
