//
//  ViewController.m
//  DCTObjectStore Demo
//
//  Created by Daniel Tull on 28.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import DCTObjectStore;
#import "ViewController.h"
#import "Event.h"

@interface ViewController () <DCTObjectStoreQueryDelegate>
@property (nonatomic) DCTObjectStore *objectStore;
@property (nonatomic) DCTObjectStoreQuery *objectStoreController;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.objectStore = [DCTObjectStore objectStoreWithName:@"Test"];

	NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:EventAttributes.name ascending:YES]];
	self.objectStoreController = [[DCTObjectStoreQuery alloc] initWithObjectStore:self.objectStore predciate:nil sortDescriptors:sortDescriptors];
	self.objectStoreController.delegate = self;

	Event *eventB = [Event new];
	eventB.name = @"b";
	eventB.date = [NSDate new];
	[self.objectStore saveObject:eventB];


	Event *eventA = [Event new];
	eventA.date = [NSDate new];
	eventA.name = @"a";
	[self.objectStore saveObject:eventA];
	
	NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), self.objectStoreController.objects);
}

#pragma mark - DCTObjectStoreQueryDelegate

- (void)objectStoreController:(DCTObjectStoreQuery *)controller didInsertObject:(id)object atIndex:(NSUInteger)index {
	NSLog(@"%@:%@ %@ %@", self, NSStringFromSelector(_cmd), object, @(index));
}

- (void)objectStoreController:(DCTObjectStoreQuery *)controller didMoveObject:(id)object fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
	NSLog(@"%@:%@ %@ %@ %@", self, NSStringFromSelector(_cmd), object, @(fromIndex), @(toIndex));
}

- (void)objectStoreController:(DCTObjectStoreQuery *)controller didRemoveObject:(id)object fromIndex:(NSUInteger)index {
	NSLog(@"%@:%@ %@ %@", self, NSStringFromSelector(_cmd), object, @(index));
}

- (void)objectStoreController:(DCTObjectStoreQuery *)controller didUpdateObject:(id)object atIndex:(NSUInteger)index {
	NSLog(@"%@:%@ %@ %@", self, NSStringFromSelector(_cmd), object, @(index));
}

@end
