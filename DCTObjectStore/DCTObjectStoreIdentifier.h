//
//  DCTObjectStoreIdentifier.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 16.12.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;
@class DCTObjectStore;

@protocol DCTObjectStoreIdentifier

- (NSString *)identifierForObjectStore:(DCTObjectStore *)objectStore;

@end
