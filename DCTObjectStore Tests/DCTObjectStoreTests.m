//
//  DCTObjectStore_Tests.m
//  DCTObjectStore Tests
//
//  Created by Daniel Tull on 28.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import XCTest;
@import DCTObjectStore;
#import "Event.h"

@interface DCTObjectStoreTests : XCTestCase
@property (nonatomic) DCTObjectStore *store;
@end

@implementation DCTObjectStoreTests

- (void)setUp {
    [super setUp];
	self.store = [DCTObjectStore objectStoreWithName:[[NSUUID UUID] UUIDString]];
}

- (void)tearDown {
	[DCTObjectStore deleteStore:self.store];
    [super tearDown];
}

- (void)testSame {
	NSString *name = [[NSUUID UUID] UUIDString];
	DCTObjectStore *store1 = [DCTObjectStore objectStoreWithName:name];
	DCTObjectStore *store2 = [DCTObjectStore objectStoreWithName:name];
	XCTAssertEqualObjects(store1, store2, @"Should retrieve exactly the same store object.");
	[DCTObjectStore deleteStore:store1];
}

- (void)testDifferent {
	NSString *name1 = [[NSUUID UUID] UUIDString];
	NSString *name2 = [[NSUUID UUID] UUIDString];
	DCTObjectStore *store1 = [DCTObjectStore objectStoreWithName:name1];
	DCTObjectStore *store2 = [DCTObjectStore objectStoreWithName:name2];
	XCTAssertNotEqualObjects(store1, store2, @"Should retrieve different store objects.");
	[DCTObjectStore deleteStore:store1];
	[DCTObjectStore deleteStore:store2];
}

- (void)testInsertion {
	Event *event = [Event new];
	[self.store saveObject:event];
	XCTAssertTrue(self.store.objects.count == 1, @"Store should have one object.");
	XCTAssertEqualObjects([self.store.objects anyObject], event, @"The object should be the inserted event.");
}

- (void)testInsertion2 {
	Event *event1 = [Event new];
	Event *event2 = [Event new];
	[self.store saveObject:event1];
	[self.store saveObject:event2];
	
	XCTAssertEqual(self.store.objects.count, (NSUInteger)2, @"Store should have two objects.");
	XCTAssertTrue([self.store.objects containsObject:event1], @"Store should contain event1.");
	XCTAssertTrue([self.store.objects containsObject:event2], @"Store should contain event2.");
}

- (void)testDeletion {
	Event *event = [Event new];
	[self.store saveObject:event];
	[self.store deleteObject:event];
	XCTAssertEqual(self.store.objects.count, (NSUInteger)0, @"The store should contain no objects.");
}

- (void)testDeletion2 {
	Event *event1 = [Event new];
	Event *event2 = [Event new];
	[self.store saveObject:event1];
	[self.store saveObject:event2];
	[self.store deleteObject:event1];
	XCTAssertEqual(self.store.objects.count, (NSUInteger)1, @"The store should contain one object.");
	XCTAssertEqualObjects([self.store.objects anyObject], event2, @"The object should be event2.");
}

@end
