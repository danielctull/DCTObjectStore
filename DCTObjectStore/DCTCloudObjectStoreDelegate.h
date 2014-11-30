//
//  DCTCloudObjectStoreDelegate.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@class DCTCloudObjectStore;

@protocol DCTCloudObjectStoreDelegate <NSObject>

- (void)cloudObjectStore:(DCTCloudObjectStore *)cloudObjectStore didInsertObject:(id)object;
- (void)cloudObjectStore:(DCTCloudObjectStore *)cloudObjectStore didRemoveObject:(id)object;
- (void)cloudObjectStore:(DCTCloudObjectStore *)cloudObjectStore didUpdateObject:(id)object;

- (id<DCTObjectStoreCoding>)cloudObjectStore:(DCTCloudObjectStore *)cloudObjectStore objectWithIdentifier:(NSString *)identifier;

@end
