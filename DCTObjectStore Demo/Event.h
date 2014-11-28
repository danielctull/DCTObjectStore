//
//  Event.h
//  DCTObjectStore
//
//  Created by Daniel Tull on 28.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;
@import DCTObjectStore;

extern const struct EventAttributes {
	__unsafe_unretained NSString *date;
	__unsafe_unretained NSString *identifier;
} EventAttributes;


@interface Event : NSObject <DCTObjectStoreCoding>

@property (nonatomic) NSDate *date;

@end
