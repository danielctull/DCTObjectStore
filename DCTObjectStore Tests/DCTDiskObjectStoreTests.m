//
//  DCTDiskObjectStoreTests.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import XCTest;
#import "DCTDiskObjectStore.h"
#import "Event.h"

@interface DCTDiskObjectStoreTests : XCTestCase
@property (nonatomic) DCTDiskObjectStore *diskStore;
@end

@implementation DCTDiskObjectStoreTests

- (void)setUp {
    [super setUp];
	self.diskStore = [[DCTDiskObjectStore alloc] initWithStoreIdentifier:[[NSUUID UUID] UUIDString] groupIdentifier:nil];
}

- (void)tearDown {
	[self.diskStore destroy];
    [super tearDown];
}

- (void)testInsertion {
	Event *event = [Event new];
	[self.diskStore saveObject:event];
	NSSet *objects = self.diskStore.objects;
	XCTAssertEqual(objects.count, (NSUInteger)1, @"Should contain one object.");
	Event *event2 = objects.anyObject;
	XCTAssertNotEqualObjects(event, event2, @"Should be a different instances.");
	XCTAssert([event isEqualToEvent:event2], @"Should be equivalent events.");
}

- (void)testDeletion {
	Event *event = [Event new];
	[self.diskStore saveObject:event];
	[self.diskStore deleteObject:event];
	XCTAssertEqual(self.diskStore.objects.count, (NSUInteger)0, @"Shouldn't contain any objects.");
}

@end
