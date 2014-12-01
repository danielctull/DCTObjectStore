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
@property (nonatomic) NSMutableArray *internalChanges;
@end

@implementation DCTChangeObjectStore

- (instancetype)initWithURL:(NSURL *)URL {
	self = [self init];
	if (!self) return nil;
	_URL = [URL copy];
	_internalChanges = [NSMutableArray new];
	_diskStore = [[DCTDiskObjectStore alloc] initWithURL:URL];
	[_internalChanges addObjectsFromArray:_diskStore.objects.allObjects];
	return self;
}

- (void)saveChange:(DCTObjectStoreChange *)change {
	NSString *identifier = change.identifier;
	DCTObjectStoreChange *oldChange = [self changeForIdentifier:identifier];
	if (oldChange) [self deleteChange:oldChange];

	[self.internalChanges addObject:change];
	[self.diskStore saveObject:change];
}

- (void)deleteChange:(DCTObjectStoreChange *)change {
	[self.internalChanges removeObject:change];
	[self.diskStore deleteObject:change];
}

- (DCTObjectStoreChange *)changeForIdentifier:(NSString *)identifier {
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", DCTObjectStoreChangeAttributes.identifier, identifier];
	NSArray *filteredChanges = [self.internalChanges filteredArrayUsingPredicate:predicate];
	return [filteredChanges firstObject];
}

- (NSArray *)changes {
	return [self.internalChanges copy];
}

@end
