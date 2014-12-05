//
//  DCTTestObjectStoreQueryDelegateEvent.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 05.12.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTTestObjectStoreQueryDelegateEvent.h"

@implementation DCTTestObjectStoreQueryDelegateEvent

- (instancetype)initWithObjectStoreQuery:(DCTObjectStoreQuery *)query
								  object:(id)object
									type:(DCTTestObjectStoreQueryDelegateEventType)type
							   fromIndex:(NSUInteger)fromIndex
								 toIndex:(NSUInteger)toIndex {

	self = [super init];
	if (!self) return nil;
	_query = query;
	_object = object;
	_type = type;
	_fromIndex = fromIndex;
	_toIndex = toIndex;
	return self;
}

@end
