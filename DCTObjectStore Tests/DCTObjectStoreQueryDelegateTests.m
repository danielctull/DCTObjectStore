//
//  DCTObjectStoreQueryDelegateTests.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 05.12.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import XCTest;
@import DCTObjectStore;
#import "DCTTestObjectStoreQueryDelegate.h"
#import "DCTTestObjectStoreQueryDelegateEvent.h"
#import "Event.h"

@interface DCTObjectStoreQueryDelegateTests : XCTestCase
@property (nonatomic) DCTObjectStore *store;
@property (nonatomic) DCTObjectStoreQuery *query;
@property (nonatomic) DCTTestObjectStoreQueryDelegate *queryDelegate;
@end

@implementation DCTObjectStoreQueryDelegateTests

- (void)setUp {
	[super setUp];
	self.store = [DCTObjectStore objectStoreWithName:[[NSUUID UUID] UUIDString]];
	NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:EventAttributes.name ascending:YES]];
	self.queryDelegate = [DCTTestObjectStoreQueryDelegate new];
	self.query = [[DCTObjectStoreQuery alloc] initWithObjectStore:self.store predciate:nil sortDescriptors:sortDescriptors];
	self.query.delegate = self.queryDelegate;
}

- (void)tearDown {
	self.queryDelegate = nil;
	self.query = nil;
	[self.store destroy];
	[super tearDown];
}

- (void)testInsert {

	Event *event = [Event new];
	[self.store saveObject:event];

	XCTAssertEqual(self.queryDelegate.events.count, (NSUInteger)1, @"Delegate should have received 1 callback.");
	DCTTestObjectStoreQueryDelegateEvent *insert = self.queryDelegate.events[0];
	XCTAssertEqualObjects(insert.query, self.query, @"Query should be the same query object.");
	XCTAssertEqualObjects(insert.object, event, @"Object should be the event.");
	XCTAssertEqual(insert.type, DCTTestObjectStoreQueryDelegateEventTypeInsert, @"Should receive insert callback.");
	XCTAssertEqual(insert.fromIndex, (NSUInteger)0, @"Should be inserted at index 0.");
	XCTAssertEqual(insert.toIndex, (NSUInteger)0, @"Should be inserted at index 0.");
}

- (void)testRemove {

	Event *event = [Event new];
	[self.store saveObject:event];

	XCTAssertEqual(self.queryDelegate.events.count, (NSUInteger)1, @"Delegate should have received 1 callback.");
	DCTTestObjectStoreQueryDelegateEvent *insert = self.queryDelegate.events[0];
	XCTAssertEqualObjects(insert.query, self.query, @"Query should be the same query object.");
	XCTAssertEqualObjects(insert.object, event, @"Object should be the event.");
	XCTAssertEqual(insert.type, DCTTestObjectStoreQueryDelegateEventTypeInsert, @"Should receive insert callback.");
	XCTAssertEqual(insert.fromIndex, (NSUInteger)0, @"Should be inserted at index 0.");
	XCTAssertEqual(insert.toIndex, (NSUInteger)0, @"Should be inserted at index 0.");

	[self.store deleteObject:event];

	XCTAssertEqual(self.queryDelegate.events.count, (NSUInteger)2, @"Delegate should have received 2 callbacks.");
	DCTTestObjectStoreQueryDelegateEvent *delete = self.queryDelegate.events[1];
	XCTAssertEqualObjects(delete.query, self.query, @"Query should be the same query object.");
	XCTAssertEqualObjects(delete.object, event, @"Object should be our event.");
	XCTAssertEqual(delete.type, DCTTestObjectStoreQueryDelegateEventTypeRemove, @"Should receive insert callback.");
	XCTAssertEqual(delete.fromIndex, (NSUInteger)0, @"Should be inserted at index 0.");
	XCTAssertEqual(delete.toIndex, (NSUInteger)0, @"Should be inserted at index 0.");
}

- (void)testMove {

	Event *event1 = [Event new];
	event1.name = @"A";
	[self.store saveObject:event1];

	XCTAssertEqual(self.queryDelegate.events.count, (NSUInteger)1, @"Delegate should have received 1 callbacks.");
	DCTTestObjectStoreQueryDelegateEvent *insert1 = self.queryDelegate.events[0];
	XCTAssertEqualObjects(insert1.query, self.query, @"Query should be the same query object.");
	XCTAssertEqualObjects(insert1.object, event1, @"Object should be event1.");
	XCTAssertEqual(insert1.type, DCTTestObjectStoreQueryDelegateEventTypeInsert, @"Should receive insert callback.");
	XCTAssertEqual(insert1.fromIndex, (NSUInteger)0, @"Should be inserted at index 0.");
	XCTAssertEqual(insert1.toIndex, (NSUInteger)0, @"Should be inserted at index 0.");

	Event *event2 = [Event new];
	event2.name = @"B";
	[self.store saveObject:event2];

	XCTAssertEqual(self.queryDelegate.events.count, (NSUInteger)2, @"Delegate should have received 2 callbacks.");
	DCTTestObjectStoreQueryDelegateEvent *insert2 = self.queryDelegate.events[1];
	XCTAssertEqualObjects(insert2.query, self.query, @"Query should be the same query object.");
	XCTAssertEqualObjects(insert2.object, event2, @"Object should be event2.");
	XCTAssertEqual(insert2.type, DCTTestObjectStoreQueryDelegateEventTypeInsert, @"Should receive insert callback.");
	XCTAssertEqual(insert2.fromIndex, (NSUInteger)1, @"Should be inserted at index 1.");
	XCTAssertEqual(insert2.toIndex, (NSUInteger)1, @"Should be inserted at index 1.");

	event1.name = @"C";
	[self.store saveObject:event1];

	XCTAssertEqual(self.queryDelegate.events.count, (NSUInteger)3, @"Delegate should have received 2 callbacks.");
	DCTTestObjectStoreQueryDelegateEvent *move = self.queryDelegate.events[2];
	XCTAssertEqualObjects(move.query, self.query, @"Query should be the same query object.");
	XCTAssertEqualObjects(move.object, event1, @"Object should be event1.");
	XCTAssertEqual(move.type, DCTTestObjectStoreQueryDelegateEventTypeMove, @"Should receive move callback.");
	XCTAssertEqual(move.fromIndex, (NSUInteger)0, @"Should be moved from index 0.");
	XCTAssertEqual(move.toIndex, (NSUInteger)1, @"Should be moved to index 1.");
}

- (void)testUpdate {

	Event *event = [Event new];
	event.name = @"A";
	[self.store saveObject:event];

	XCTAssertEqual(self.queryDelegate.events.count, (NSUInteger)1, @"Delegate should have received 1 callback.");
	DCTTestObjectStoreQueryDelegateEvent *insert = self.queryDelegate.events[0];
	XCTAssertEqualObjects(insert.query, self.query, @"Query should be the same query object.");
	XCTAssertEqualObjects(insert.object, event, @"Object should be the event.");
	XCTAssertEqual(insert.type, DCTTestObjectStoreQueryDelegateEventTypeInsert, @"Should receive insert callback.");
	XCTAssertEqual(insert.fromIndex, (NSUInteger)0, @"Should be inserted at index 0.");
	XCTAssertEqual(insert.toIndex, (NSUInteger)0, @"Should be inserted at index 0.");

	event.name = @"B";
	[self.store saveObject:event];

	XCTAssertEqual(self.queryDelegate.events.count, (NSUInteger)2, @"Delegate should have received 2 callbacks.");
	DCTTestObjectStoreQueryDelegateEvent *update = self.queryDelegate.events[1];
	XCTAssertEqualObjects(update.query, self.query, @"Query should be the same query object.");
	XCTAssertEqualObjects(update.object, event, @"Object should be the event.");
	XCTAssertEqual(update.type, DCTTestObjectStoreQueryDelegateEventTypeUpdate, @"Should receive insert callback.");
	XCTAssertEqual(update.fromIndex, (NSUInteger)0, @"Should be updated at index 0.");
	XCTAssertEqual(update.toIndex, (NSUInteger)0, @"Should be updated at index 0.");
}

@end
