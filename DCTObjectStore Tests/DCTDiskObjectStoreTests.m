//
//  DCTDiskObjectStoreTests.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import XCTest;
#import "DCTDiskObjectStore.h"
#import "DCTObjectStoreIdentifierInternal.h"
#import "Event.h"

@interface DCTDiskObjectStoreTests : XCTestCase
@property (nonatomic) DCTDiskObjectStore *diskStore;
@end

@implementation DCTDiskObjectStoreTests

- (void)setUp {
    [super setUp];
	NSURL *URL = [[[NSFileManager new] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	URL = [URL URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	self.diskStore = [[DCTDiskObjectStore alloc] initWithURL:URL];
}

- (void)tearDown {
	[self.diskStore destroy];
    [super tearDown];
}

- (void)testUnidentifiedObject {
	Event *event = [Event new];
	XCTAssertThrows([self.diskStore saveObject:event], @"Should throw an exception because there's no associated identifier.");
}

- (void)testInsertion {
	Event *event = [Event new];
	[DCTObjectStoreIdentifierInternal setIdentifier:[[NSUUID UUID] UUIDString] forObject:event];
	[self.diskStore saveObject:event];
	NSSet *objects = self.diskStore.objects;
	XCTAssertEqual(objects.count, (NSUInteger)1, @"Should contain one object.");
	Event *event2 = objects.anyObject;
	XCTAssertEqualObjects(event, event2, @"Should be the same instance.");
}

- (void)testDeletion {
	Event *event = [Event new];
	[DCTObjectStoreIdentifierInternal setIdentifier:[[NSUUID UUID] UUIDString] forObject:event];
	[self.diskStore saveObject:event];
	[self.diskStore deleteObject:event];
	XCTAssertEqual(self.diskStore.objects.count, (NSUInteger)0, @"Shouldn't contain any objects.");
}

@end
