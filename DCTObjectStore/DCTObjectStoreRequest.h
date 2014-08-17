//
//  DCTObjectStoreRequest.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 16/08/2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;

@interface DCTObjectStoreRequest : NSObject

- (instancetype)initWithPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors;
@property (nonatomic, readonly) NSPredicate *predicate;
@property (nonatomic, readonly) NSArray *sortDescriptors;

@end
