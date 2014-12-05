//
//  DCTTestObjectStoreQueryDelegate.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 05.12.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;
@import DCTObjectStore;

@interface DCTTestObjectStoreQueryDelegate : NSObject <DCTObjectStoreQueryDelegate>
@property (nonatomic, readonly) NSArray *events;
@end
