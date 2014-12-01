//
//  DCTDiskObjectStore.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTDiskObjectStore.h"
#import "DCTObjectStoreIdentifier.h"

@interface DCTDiskObjectStore ()
@property (nonatomic) NSFileManager *fileManager;
@property (nonatomic) NSMutableDictionary *internalObjects;
@end

@implementation DCTDiskObjectStore

- (instancetype)initWithURL:(NSURL *)URL {
	self = [super init];
	if (!self) return nil;
	_URL = [URL copy];
	_internalObjects = [NSMutableDictionary new];
	_fileManager = [NSFileManager new];
	[_fileManager createDirectoryAtURL:_URL withIntermediateDirectories:YES attributes:nil error:NULL];

	NSDirectoryEnumerator *enumerator = [_fileManager enumeratorAtURL:self.URL
										   includingPropertiesForKeys:nil
															  options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
														 errorHandler:nil];

	for (NSURL *URL in enumerator) {
		@try {
			NSData *data = [NSData dataWithContentsOfURL:URL];
			NSString *identifier = [URL lastPathComponent];
			id<DCTObjectStoreCoding> object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			[DCTObjectStoreIdentifier setIdentifier:identifier forObject:object];
			_internalObjects[identifier] = object;
		}
		@catch (__unused NSException *exception) {}
	}


	return self;
}

- (void)saveObject:(id<DCTObjectStoreCoding>)object {
	NSString *identifier = [DCTObjectStoreIdentifier identifierForObject:object];
	NSParameterAssert(identifier);
	NSURL *URL = [self.URL URLByAppendingPathComponent:identifier];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
	[data writeToURL:URL atomically:YES];
	self.internalObjects[identifier] = object;
}

- (void)deleteObject:(id<DCTObjectStoreCoding>)object {

	NSString *identifier = [DCTObjectStoreIdentifier identifierForObject:object];
	NSParameterAssert(identifier);

	// If this particular instance is not in the store, ignore
	id ourObject = [self objectForIdentifier:identifier];
	if (![ourObject isEqual:object]) {
		return;
	}

	NSURL *URL = [self.URL URLByAppendingPathComponent:identifier];
	[self.fileManager removeItemAtURL:URL error:NULL];
	[self.internalObjects removeObjectForKey:identifier];
}

- (id<DCTObjectStoreCoding>)objectForIdentifier:(NSString *)identifier {
	return self.internalObjects[identifier];
}

- (NSSet *)objects {
	return [NSSet setWithArray:self.internalObjects.allValues];
}

- (void)destroy {
	[self.fileManager removeItemAtURL:self.URL error:NULL];
}

@end
