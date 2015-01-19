//
//  DCTObjectStoreQuerySortDescriptorTests.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import XCTest;
@import DCTObjectStore;
#import "Event.h"

@interface DCTObjectStoreQuerySortDescriptorTests : XCTestCase
@property (nonatomic) DCTObjectStore *store;
@property (nonatomic) DCTObjectStoreQuery *query;
@end

@implementation DCTObjectStoreQuerySortDescriptorTests

- (void)setUp {
	[super setUp];
	self.store = [DCTObjectStore objectStoreWithName:[[NSUUID UUID] UUIDString]];
	NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:EventAttributes.name ascending:YES]];
	self.query = [[DCTObjectStoreQuery alloc] initWithObjectStore:self.store predciate:nil sortDescriptors:sortDescriptors];
}

- (void)tearDown {
	self.query = nil;
	[self.store destroy];
	[super tearDown];
}

- (void)testSort {
	Event *event1 = [Event new];
	Event *event2 = [Event new];
	event1.name = @"1";
	event2.name = @"2";
	[self.store saveObject:event1];
	[self.store saveObject:event2];
	
	XCTAssertEqual(self.query.objects.count, (NSUInteger)2, @"Store should have two objects.");
	XCTAssertEqualObjects(self.query.objects[0], event1, @"First object should be event1.");
	XCTAssertEqualObjects(self.query.objects[1], event2, @"Second object should be event2.");
}

- (void)testSort2 {
	Event *event1 = [Event new];
	Event *event2 = [Event new];
	event1.name = @"2";
	event2.name = @"1";
	[self.store saveObject:event1];
	[self.store saveObject:event2];
	
	XCTAssertEqual(self.query.objects.count, (NSUInteger)2, @"Store should have two objects.");
	XCTAssertEqualObjects(self.query.objects[0], event2, @"First object should be event2.");
	XCTAssertEqualObjects(self.query.objects[1], event1, @"Second object should be event1.");
}

- (void)testMove {
	Event *event1 = [Event new];
	event1.name = @"1";
	[self.store saveObject:event1];
	
	Event *event2 = [Event new];
	event2.name = @"2";
	[self.store saveObject:event2];
	
	event1.name = @"3";
	[self.store saveObject:event1];
	
	XCTAssertEqual(self.query.objects.count, (NSUInteger)2, @"The store should contain one object.");
	XCTAssertEqualObjects(self.query.objects[0], event2, @"The first object should be event2.");
	XCTAssertEqualObjects(self.query.objects[1], event1, @"The second object should be event1.");
}

@end
