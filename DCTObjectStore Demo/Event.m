//
//  Event.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 28.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "Event.h"

const struct EventAttributes EventAttributes = {
	.date = @"date",
	.identifier = @"identifier"
};

@interface Event ()
@property (nonatomic, readonly) NSString *identifier;
@end

@implementation Event

- (instancetype)init {
	self = [super init];
	if (!self) return nil;
	_identifier = [[NSUUID UUID] UUIDString];
	return self;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (!self) return nil;
	_identifier = [decoder decodeObjectOfClass:[NSString class] forKey:@"identifier"];
	_date = [decoder decodeObjectOfClass:[NSString class] forKey:@"date"];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:self.identifier forKey:@"identifier"];
	[encoder encodeObject:self.date forKey:@"date"];
}

@end
