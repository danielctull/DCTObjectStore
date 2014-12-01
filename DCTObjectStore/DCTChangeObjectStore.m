//
//  DCTChangeObjectStore.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 01.12.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTChangeObjectStore.h"
#import "DCTObjectStoreChange.h"
#import "DCTDiskObjectStore.h"

@interface DCTChangeObjectStore ()
@property (nonatomic) DCTDiskObjectStore *diskStore;
@property (nonatomic) NSMutableDictionary *changesDictionary;
@end

@implementation DCTChangeObjectStore

- (instancetype)initWithURL:(NSURL *)URL {
	self = [self init];
	if (!self) return nil;

	_URL = [URL copy];
	_changesDictionary = [NSMutableDictionary new];
	_diskStore = [[DCTDiskObjectStore alloc] initWithURL:URL];

	NSSet *changes = _diskStore.objects;
	for (DCTObjectStoreChange *change in changes) {
		_changesDictionary[change.identifier] = change;
	}

	return self;
}

- (void)saveChange:(DCTObjectStoreChange *)change {
	NSString *identifier = change.identifier;
	[self deleteChangeWithIdentifier:identifier];

	self.changesDictionary[identifier] = change;
	[self.diskStore saveObject:change];
}

- (void)deleteChange:(DCTObjectStoreChange *)change {
	[self.changesDictionary removeObjectForKey:change.identifier];
	[self.diskStore deleteObject:change];
}

- (void)deleteChangeWithIdentifier:(NSString *)identifier {
	DCTObjectStoreChange *change = self.changesDictionary[identifier];
	[self.changesDictionary removeObjectForKey:identifier];
	[self.diskStore deleteObject:change];
}

- (DCTObjectStoreChange *)changeForIdentifier:(NSString *)identifier {
	return self.changesDictionary[identifier];
}

- (NSArray *)changes {
	return [self.changesDictionary allValues];
}

@end
