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

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (!self) return nil;
	_name = [decoder decodeObjectOfClass:[NSString class] forKey:EventAttributes.name];
	_date = [decoder decodeObjectOfClass:[NSString class] forKey:EventAttributes.date];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:self.name forKey:EventAttributes.name];
	[encoder encodeObject:self.date forKey:EventAttributes.date];
}

@end
