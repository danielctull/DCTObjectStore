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
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *date;
} EventAttributes;


@interface Event : NSObject <NSSecureCoding>

@property (nonatomic) NSString *name;
@property (nonatomic) NSDate *date;

- (BOOL)isEqualToEvent:(Event *)event;

@end
