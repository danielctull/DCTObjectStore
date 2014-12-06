//
//  ViewController.m
//  DCTObjectStore Demo
//
//  Created by Daniel Tull on 28.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import DCTObjectStore;
#import "ViewController.h"
#import "EventCell.h"
#import "Event.h"

@interface ViewController () <DCTObjectStoreQueryDelegate>
@property (nonatomic) IBOutlet UIBarButtonItem *doneEditingButton;
@property (nonatomic) DCTObjectStore *objectStore;
@property (nonatomic) DCTObjectStoreQuery *objectStoreQuery;
@end

@implementation ViewController

- (void)dealloc {
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	[notificationCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	self.objectStore = [DCTObjectStore objectStoreWithName:@"Test" groupIdentifier:nil cloudIdentifier:@"iCloud.uk.co.danieltull.DCTObjectStore"];

	NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:EventAttributes.name ascending:YES]];
	self.objectStoreQuery = [[DCTObjectStoreQuery alloc] initWithObjectStore:self.objectStore predciate:nil sortDescriptors:sortDescriptors];
	self.objectStoreQuery.delegate = self;

	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
	self.navigationItem.leftBarButtonItem = nil;
}

- (void)keyboardWillHideNotification:(NSNotification *)notification {
	[self.navigationItem setLeftBarButtonItem:nil animated:YES];
}

- (void)keyboardWillShowNotification:(NSNotification *)notification {
	[self.navigationItem setLeftBarButtonItem:self.doneEditingButton animated:YES];
}

- (IBAction)dismissKeyboard:(id)sender {
	[self.view endEditing:YES];
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
	EventCell *cell = (EventCell *)[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
	Event *event = self.objectStoreQuery.objects[indexPath.row];
	DCTObjectStore *objectStore = self.objectStore;
	cell.name = event.name;
	cell.nameDidChangeBlock = ^(NSString *name) {
		if (![event.name isEqualToString:name]) {
			event.name = name;
			[objectStore saveObject:event];
		}
	};
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
