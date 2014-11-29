//
//  DCTCloudObjectStore.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTCloudObjectStore.h"

@implementation DCTCloudObjectStore

- (instancetype)initWithStoreIdentifier:(NSString *)storeIdentifier
						cloudIdentifier:(NSString *)cloudIdentifier {
	self = [super init];
	if (!self) return nil;
	_storeIdentifier = [storeIdentifier copy];
	_cloudIdentifier = [cloudIdentifier copy];
	return self;
}

- (void)saveObject:(id<NSSecureCoding>)object {}
- (void)deleteObject:(id<NSSecureCoding>)object {}

- (void)destroy {}

@end
