//
//  DCTObjectStoreRequest.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 16/08/2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTObjectStoreRequest.h"

@implementation DCTObjectStoreRequest

- (instancetype)initWithPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors {
	self = [super init];
	if (!self) return nil;
	_predicate = [predicate copy];
	_sortDescriptors = [sortDescriptors copy];
	return self;
}

@end
