//
//  DCTObjectStoreControllerDelegate.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 28.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTObjectStoreController.h"
@import CoreData;


@protocol DCTObjectStoreControllerDelegate <NSObject>

- (void)objectStoreController:(DCTObjectStoreController *)controller didInsertObject:(id)object atIndex:(NSUInteger)index;
- (void)objectStoreController:(DCTObjectStoreController *)controller didRemoveObject:(id)object fromIndex:(NSUInteger)index;
- (void)objectStoreController:(DCTObjectStoreController *)controller didMoveObject:(id)object fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;
- (void)objectStoreController:(DCTObjectStoreController *)controller didUpdateObject:(id)object atIndex:(NSUInteger)index;

@end
