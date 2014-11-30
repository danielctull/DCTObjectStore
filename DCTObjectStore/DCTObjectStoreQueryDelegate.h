//
//  DCTObjectStoreQueryDelegate.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 28.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTObjectStoreQuery.h"
@import CoreData;


@protocol DCTObjectStoreQueryDelegate <NSObject>

- (void)objectStoreController:(DCTObjectStoreQuery *)controller didInsertObject:(id)object atIndex:(NSUInteger)index;
- (void)objectStoreController:(DCTObjectStoreQuery *)controller didRemoveObject:(id)object fromIndex:(NSUInteger)index;
- (void)objectStoreController:(DCTObjectStoreQuery *)controller didMoveObject:(id)object fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;
- (void)objectStoreController:(DCTObjectStoreQuery *)controller didUpdateObject:(id)object atIndex:(NSUInteger)index;

@end
