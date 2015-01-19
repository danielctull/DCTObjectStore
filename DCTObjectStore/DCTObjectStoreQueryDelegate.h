//
//  DCTObjectStoreQueryDelegate.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 28.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@class DCTObjectStoreQuery;

@protocol DCTObjectStoreQueryDelegate <NSObject>

- (void)objectStoreQuery:(DCTObjectStoreQuery *)query didInsertObject:(id)object atIndex:(NSUInteger)index;
- (void)objectStoreQuery:(DCTObjectStoreQuery *)query didRemoveObject:(id)object fromIndex:(NSUInteger)index;
- (void)objectStoreQuery:(DCTObjectStoreQuery *)query didMoveObject:(id)object fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;
- (void)objectStoreQuery:(DCTObjectStoreQuery *)query didUpdateObject:(id)object atIndex:(NSUInteger)index;

@end
