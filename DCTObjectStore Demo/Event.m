//
//  Event.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 28.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "Event.h"

const struct EventAttributes EventAttributes = {
	.name = @"name",
	.date = @"date"
};

@implementation Event

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; %@ = %@; %@ = %@>",
			NSStringFromClass([self class]),
			self,
			EventAttributes.name, self.name,
			EventAttributes.date, self.date];
}

- (BOOL)isEqualToEvent:(Event *)event {
	
	if (self.class != event.class) {
		return NO;
	}
	
	if (self.name && ![self.name isEqualToString:event.name]) {
		return NO;
	}
	
	if (self.date && ![self.date isEqualToDate:event.date]) {
		return NO;
	}
	
	return YES;
}

#pragma mark - DCTObjectStoreCoding

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (!self) return nil;
	[self decodeWithCoder:decoder];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:self.name forKey:EventAttributes.name];
	[encoder encodeObject:self.date forKey:EventAttributes.date];
}

- (void)decodeWithCoder:(NSCoder *)decoder {

	NSString *name = [decoder decodeObjectOfClass:[NSString class] forKey:EventAttributes.name];
	if (name) self.name = name;

	NSDate *date = [decoder decodeObjectOfClass:[NSDate class] forKey:EventAttributes.date];
	if (date) self.date = date;
}

@end
