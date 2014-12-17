//
//  DCTObjectStoreChange.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 30.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTObjectStoreChange.h"
#import "DCTObjectStoreIdentifierInternal.h"

const struct DCTObjectStoreChangeAttributes DCTObjectStoreChangeAttributes = {
	.date = @"date",
	.identifier = @"identifier",
	.object = @"object",
	.type = @"type",
	.requiresForceSave = @"requiresForceSave"
};

static NSString *const DCTObjectStoreChangeTypeString[] = {
	@"Save",
	@"Delete"
};


@implementation DCTObjectStoreChange

- (instancetype)initWithObject:(id<DCTObjectStoreCoding>)object type:(DCTObjectStoreChangeType)type {
	self = [super init];
	if (!self) return nil;
	_date = [NSDate new];
	_identifier = [DCTObjectStoreIdentifierInternal identifierForObject:object];
	_object = object;
	_type = type;
	return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; %@ = %@; %@ = %@; %@ = %@; %@ = %@>",
			NSStringFromClass([self class]),
			self,
			DCTObjectStoreChangeAttributes.date, self.date,
			DCTObjectStoreChangeAttributes.identifier, self.identifier,
			DCTObjectStoreChangeAttributes.type, DCTObjectStoreChangeTypeString[self.type],
			DCTObjectStoreChangeAttributes.requiresForceSave, self.requiresForceSave ? @"YES" : @"NO"];
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
	_requiresForceSave = [decoder decodeBoolForKey:DCTObjectStoreChangeAttributes.requiresForceSave];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:self.date forKey:DCTObjectStoreChangeAttributes.date];
	[encoder encodeObject:self.identifier forKey:DCTObjectStoreChangeAttributes.identifier];
	[encoder encodeObject:self.object forKey:DCTObjectStoreChangeAttributes.object];
	[encoder encodeInteger:self.type forKey:DCTObjectStoreChangeAttributes.type];
	[encoder encodeBool:self.requiresForceSave forKey:DCTObjectStoreChangeAttributes.requiresForceSave];
}

- (void)decodeWithCoder:(NSCoder *)coder {}

@end
