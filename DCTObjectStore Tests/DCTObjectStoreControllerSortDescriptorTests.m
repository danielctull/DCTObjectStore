//
//  DCTObjectStoreControllerSortDescriptorTests.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import XCTest;
@import DCTObjectStore;
#import "Event.h"

@interface DCTObjectStoreControllerSortDescriptorTests : XCTestCase
@property (nonatomic) DCTObjectStore *store;
@property (nonatomic) DCTObjectStoreController *controller;
@end

@implementation DCTObjectStoreControllerSortDescriptorTests

- (void)setUp {
	[super setUp];
	self.store = [DCTObjectStore objectStoreWithName:[[NSUUID UUID] UUIDString]];
	NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:EventAttributes.name ascending:YES]];
	self.controller = [[DCTObjectStoreController alloc] initWithObjectStore:self.store predciate:nil sortDescriptors:sortDescriptors];
}

- (void)tearDown {
	self.controller = nil;
	[DCTObjectStore deleteStore:self.store];
	[super tearDown];
}

- (void)testSort {
	Event *event1 = [Event new];
	Event *event2 = [Event new];
	event1.name = @"1";
	event2.name = @"2";
	[self.store saveObject:event1];
	[self.store saveObject:event2];
	
	XCTAssertEqual(self.controller.objects.count, (NSUInteger)2, @"Store should have two objects.");
	XCTAssertEqualObjects(self.controller.objects[0], event1, @"First object should be event1.");
	XCTAssertEqualObjects(self.controller.objects[1], event2, @"First object should be event2.");
}

- (void)testSort2 {
	Event *event1 = [Event new];
	Event *event2 = [Event new];
	event1.name = @"2";
	event2.name = @"1";
	[self.store saveObject:event1];
	[self.store saveObject:event2];
	
	XCTAssertEqual(self.controller.objects.count, (NSUInteger)2, @"Store should have two objects.");
	XCTAssertEqualObjects(self.controller.objects[0], event2, @"First object should be event2.");
	XCTAssertEqualObjects(self.controller.objects[1], event1, @"First object should be event1.");
}

@end
