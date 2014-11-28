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

	NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:EventAttributes.date ascending:NO]];
	self.objectStoreController = [[DCTObjectStoreController alloc] initWithObjectStore:self.objectStore predciate:nil sortDescriptors:sortDescriptors];
	self.objectStoreController.delegate = self;

	Event *event = [Event new];
	event.date = [NSDate new];
	[self.objectStore saveObject:event];


	event.date = [NSDate new];
	[self.objectStore saveObject:event];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self.objectStore deleteObject:event];
	});

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
