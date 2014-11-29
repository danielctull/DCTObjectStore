//
//  DCTObjectStoreControllerTests.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import XCTest;
@import DCTObjectStore;
#import "Event.h"

@interface DCTObjectStoreControllerTests : XCTestCase
@property (nonatomic) DCTObjectStore *store;
@property (nonatomic) DCTObjectStoreController *controller;
@end

@implementation DCTObjectStoreControllerTests

- (void)setUp {
	[super setUp];
	self.store = [DCTObjectStore objectStoreWithName:[[NSUUID UUID] UUIDString]];
	NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:EventAttributes.name ascending:YES]];
	self.controller = [[DCTObjectStoreController alloc] initWithObjectStore:self.store predciate:nil sortDescriptors:sortDescriptors];
}

- (void)tearDown {
	self.controller = nil;
	[self.store destroy];
	[super tearDown];
}

- (void)testInsertion {
	Event *event = [Event new];
	[self.store saveObject:event];
	XCTAssertEqual(self.controller.objects.count, (NSUInteger)1, @"Object count should be 1.");
	XCTAssertEqualObjects([self.controller.objects firstObject], event, @"Object should be the event.");
}

- (void)testInsertion2 {
	Event *event1 = [Event new];
	Event *event2 = [Event new];
	[self.store saveObject:event1];
	[self.store saveObject:event2];
	
	XCTAssertEqual(self.controller.objects.count, (NSUInteger)2, @"Store should have two objects.");
	XCTAssertTrue([self.controller.objects containsObject:event1], @"Store should contain event1.");
	XCTAssertTrue([self.controller.objects containsObject:event2], @"Store should contain event2.");
}

- (void)testDeletion {
	Event *event = [Event new];
	[self.store saveObject:event];
	[self.store deleteObject:event];
	XCTAssertEqual(self.controller.objects.count, (NSUInteger)0, @"Should contain no objects.");
}

- (void)testDeletion2 {
	Event *event1 = [Event new];
	Event *event2 = [Event new];
	[self.store saveObject:event1];
	[self.store saveObject:event2];
	[self.store deleteObject:event1];
	XCTAssertEqual(self.controller.objects.count, (NSUInteger)1, @"The store should contain one object.");
	XCTAssertEqualObjects([self.controller.objects firstObject], event2, @"The object should be event2.");
}

@end
