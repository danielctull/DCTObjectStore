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
@property (nonatomic) DCTObjectStoreQuery *objectStoreQuery;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.objectStore = [DCTObjectStore objectStoreWithName:@"Test" groupIdentifier:nil cloudIdentifier:@"iCloud.uk.co.danieltull.DCTObjectStore"];

	NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:EventAttributes.date ascending:YES]];
	self.objectStoreQuery = [[DCTObjectStoreQuery alloc] initWithObjectStore:self.objectStore predciate:nil sortDescriptors:sortDescriptors];
	self.objectStoreQuery.delegate = self;
}

- (IBAction)addEvent:(id)sender {
	Event *event = [Event new];
	event.date = [NSDate new];
	event.name = @"The Event";
	[self.objectStore saveObject:event];
}

#pragma mark - UITableViewDataSource 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.objectStoreQuery.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
	Event *event = self.objectStoreQuery.objects[indexPath.row];
	cell.textLabel.text = event.date.description;
	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewRowAction *action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Remove" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
		Event *event = self.objectStoreQuery.objects[indexPath.row];
		[self.objectStore deleteObject:event];
	}];
	return @[action];
}

#pragma mark - DCTObjectStoreQueryDelegate

- (void)objectStoreQuery:(DCTObjectStoreQuery *)query didInsertObject:(id)object atIndex:(NSUInteger)index {
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
	[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)objectStoreQuery:(DCTObjectStoreQuery *)query didMoveObject:(id)object fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
	NSIndexPath *fromIndexPath = [NSIndexPath indexPathForRow:fromIndex inSection:0];
	NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:toIndex inSection:0];
	[self.tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
}

- (void)objectStoreQuery:(DCTObjectStoreQuery *)query didRemoveObject:(id)object fromIndex:(NSUInteger)index {
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
	[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)objectStoreQuery:(DCTObjectStoreQuery *)query didUpdateObject:(id)object atIndex:(NSUInteger)index {
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
	[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
