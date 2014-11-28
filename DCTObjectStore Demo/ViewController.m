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

@interface ViewController () <DCTObjectStoreControllerDelegate>
@property (nonatomic) DCTObjectStore *objectStore;
@property (nonatomic) DCTObjectStoreController *objectStoreController;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.objectStore = [DCTObjectStore objectStoreWithName:@"Test"];

	NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:EventAttributes.name ascending:YES]];
	self.objectStoreController = [[DCTObjectStoreController alloc] initWithObjectStore:self.objectStore predciate:nil sortDescriptors:sortDescriptors];
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

#pragma mark - DCTObjectStoreControllerDelegate

- (void)objectStoreController:(DCTObjectStoreController *)controller didInsertObject:(id)object atIndex:(NSUInteger)index {
	NSLog(@"%@:%@ %@ %@", self, NSStringFromSelector(_cmd), object, @(index));
}

- (void)objectStoreController:(DCTObjectStoreController *)controller didMoveObject:(id)object fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
	NSLog(@"%@:%@ %@ %@ %@", self, NSStringFromSelector(_cmd), object, @(fromIndex), @(toIndex));
}

- (void)objectStoreController:(DCTObjectStoreController *)controller didRemoveObject:(id)object fromIndex:(NSUInteger)index {
	NSLog(@"%@:%@ %@ %@", self, NSStringFromSelector(_cmd), object, @(index));
}

- (void)objectStoreController:(DCTObjectStoreController *)controller didUpdateObject:(id)object atIndex:(NSUInteger)index {
	NSLog(@"%@:%@ %@ %@", self, NSStringFromSelector(_cmd), object, @(index));
}

@end
