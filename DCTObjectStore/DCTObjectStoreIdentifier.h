//
//  DCTObjectStoreIdentifier.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;
@class DCTObjectStore;

@interface DCTObjectStoreIdentifier : NSObject

+ (NSString *)storeIdentifierWithName:(NSString *)name
					  groupIdentifier:(NSString *)groupIdentifier
					  cloudIdentifier:(NSString *)cloudIdentifier;

+ (NSString *)identifierForObject:(id)object;

+ (void)setIdentifier:(NSString *)identifier
			forObject:(id)object;

@end
