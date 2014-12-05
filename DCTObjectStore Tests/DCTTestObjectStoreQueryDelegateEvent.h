//
//  DCTTestObjectStoreQueryDelegateEvent.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 05.12.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;
@class DCTObjectStoreQuery;

typedef NS_ENUM(NSInteger, DCTTestObjectStoreQueryDelegateEventType) {
	DCTTestObjectStoreQueryDelegateEventTypeInsert,
	DCTTestObjectStoreQueryDelegateEventTypeRemove,
	DCTTestObjectStoreQueryDelegateEventTypeMove,
	DCTTestObjectStoreQueryDelegateEventTypeUpdate
};

@interface DCTTestObjectStoreQueryDelegateEvent : NSObject

- (instancetype)initWithObjectStoreQuery:(DCTObjectStoreQuery *)query
								  object:(id)object
									type:(DCTTestObjectStoreQueryDelegateEventType)type
							   fromIndex:(NSUInteger)fromIndex
								 toIndex:(NSUInteger)toIndex;

@property (nonatomic, readonly) DCTObjectStoreQuery *query;
@property (nonatomic, readonly) id object;
@property (nonatomic, readonly) DCTTestObjectStoreQueryDelegateEventType type;
@property (nonatomic, readonly) NSUInteger fromIndex;
@property (nonatomic, readonly) NSUInteger toIndex;

@end
