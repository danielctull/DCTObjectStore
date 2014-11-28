//
//  DCTObjectStoreController.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 16/08/2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;
@class DCTObjectStore;
@protocol DCTObjectStoreControllerDelegate;


@interface DCTObjectStoreController : NSObject

- (instancetype)initWithObjectStore:(DCTObjectStore *)objectStore predciate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors;

@property (nonatomic, readonly) DCTObjectStore *objectStore;
@property (nonatomic, readonly) NSPredicate *predicate;
@property (nonatomic, readonly) NSArray *sortDescriptors;

@property (nonatomic, readonly) NSArray *objects;
@property (nonatomic, weak) id<DCTObjectStoreControllerDelegate> delegate;

@end
