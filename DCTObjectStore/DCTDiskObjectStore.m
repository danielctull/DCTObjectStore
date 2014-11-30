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
@end

@implementation DCTDiskObjectStore

- (instancetype)initWithURL:(NSURL *)URL {
	self = [super init];
	if (!self) return nil;
	_URL = [URL copy];
	_fileManager = [NSFileManager new];
	[_fileManager createDirectoryAtURL:_URL withIntermediateDirectories:YES attributes:nil error:NULL];
	return self;
}

- (void)saveObject:(id<DCTObjectStoreCoding>)object {
	NSString *identifier = [DCTObjectStoreIdentifier identifierForObject:object];
	NSURL *URL = [self.URL URLByAppendingPathComponent:identifier];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
	[data writeToURL:URL atomically:YES];
}

- (void)deleteObject:(id<DCTObjectStoreCoding>)object {
	NSString *identifier = [DCTObjectStoreIdentifier identifierForObject:object];
	NSURL *URL = [self.URL URLByAppendingPathComponent:identifier];
	[[NSFileManager defaultManager] removeItemAtURL:URL error:NULL];
}

- (NSSet *)objects {
	NSFileManager *fileManager = [NSFileManager new];
	NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:self.URL
										  includingPropertiesForKeys:nil
															 options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
														errorHandler:nil];
	
	NSMutableSet *objects = [NSMutableSet new];
	for (NSURL *URL in enumerator) {
		@try {
			NSData *data = [NSData dataWithContentsOfURL:URL];
			NSString *identifier = [URL lastPathComponent];
			id<DCTObjectStoreCoding> object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			[DCTObjectStoreIdentifier setIdentifier:identifier forObject:object];
			[objects addObject:object];
		}
		@catch (__unused NSException *exception) {}
	}
	
	return [objects copy];
}

- (void)destroy {
	[self.fileManager removeItemAtURL:self.URL error:NULL];
}

@end
