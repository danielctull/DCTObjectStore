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

- (instancetype)initWithStoreIdentifier:(NSString *)storeIdentifier groupIdentifier:(NSString *)groupIdentifier {
	self = [super init];
	if (!self) return nil;
	_storeIdentifier = [storeIdentifier copy];
	_groupIdentifier = [groupIdentifier copy];
	_fileManager = [NSFileManager new];
	
	NSURL *baseURL;
	if (self.groupIdentifier.length > 0) {
		baseURL = [_fileManager containerURLForSecurityApplicationGroupIdentifier:_groupIdentifier];
	} else {
		baseURL = [[_fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	}
	baseURL = [baseURL URLByAppendingPathComponent:NSStringFromClass([self class])];
	
	_URL = [baseURL URLByAppendingPathComponent:storeIdentifier];
	[_fileManager createDirectoryAtURL:_URL withIntermediateDirectories:YES attributes:nil error:NULL];
	
	return self;
}

- (void)saveObject:(id<NSSecureCoding>)object {
	NSString *identifier = [DCTObjectStoreIdentifier identifierForObject:object];
	NSURL *URL = [self.URL URLByAppendingPathComponent:identifier];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
	[data writeToURL:URL atomically:YES];
}

- (void)deleteObject:(id<NSSecureCoding>)object {
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
			id<NSSecureCoding> object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
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
