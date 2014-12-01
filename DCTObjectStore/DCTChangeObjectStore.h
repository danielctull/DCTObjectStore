//
//  DCTChangeObjectStore.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 01.12.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;
@class DCTObjectStoreChange;

@interface DCTChangeObjectStore : NSObject

- (instancetype)initWithURL:(NSURL *)URL;
@property (nonatomic, readonly) NSURL *URL;

@property (nonatomic, readonly) NSArray *changes;

- (void)saveChange:(DCTObjectStoreChange *)change;
- (void)deleteChange:(DCTObjectStoreChange *)change;
- (void)deleteChangeWithIdentifier:(NSString *)identifier;

- (DCTObjectStoreChange *)changeForIdentifier:(NSString *)identifier;

@end
