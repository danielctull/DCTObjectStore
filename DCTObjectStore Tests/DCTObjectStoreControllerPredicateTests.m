//
//  DCTObjectStoreControllerPredicateTests.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import XCTest;
@import DCTObjectStore;
#import "Event.h"

static NSString *const DCTObjectStoreControllerPredicateTestsString = @"A";
static NSString *const DCTObjectStoreControllerPredicateTestsNotString = @"B";

@interface DCTObjectStoreControllerPredicateTests : XCTestCase
@property (nonatomic) DCTObjectStore *store;
@property (nonatomic) DCTObjectStoreController *controller;
@end

@implementation DCTObjectStoreControllerPredicateTests

- (void)setUp {
	[super setUp];
	self.store = [DCTObjectStore objectStoreWithName:[[NSUUID UUID] UUIDString]];
	NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:EventAttributes.name ascending:YES]];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", EventAttributes.name, DCTObjectStoreControllerPredicateTestsString];
	self.controller = [[DCTObjectStoreController alloc] initWithObjectStore:self.store predciate:predicate sortDescriptors:sortDescriptors];
}

- (void)tearDown {
	self.controller = nil;
	[self.store destroy];
	[super tearDown];
}

- (void)testInsertion {
	Event *event = [Event new];
	event.name = DCTObjectStoreControllerPredicateTestsString;
	[self.store saveObject:event];
	XCTAssertEqual(self.controller.objects.count, (NSUInteger)1, @"Object count should be 1.");
	XCTAssertEqualObjects([self.controller.objects firstObject], event, @"Object should be the event.");
}

- (void)testNotInsertion {
	Event *event = [Event new];
	event.name = DCTObjectStoreControllerPredicateTestsNotString;
	[self.store saveObject:event];
	XCTAssertEqual(self.controller.objects.count, (NSUInteger)0, @"Object count should be 0.");
}

@end
