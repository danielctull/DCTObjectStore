//
//  DCTObjectStoreIdentifier.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 29.11.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import ObjectiveC.runtime;
#import "DCTObjectStoreIdentifier.h"

static void* DCTObjectStoreObjectIdentifier = &DCTObjectStoreObjectIdentifier;

@implementation DCTObjectStoreIdentifier

+ (NSString *)storeIdentifierWithName:(NSString *)name
					  groupIdentifier:(NSString *)groupIdentifier
					  cloudIdentifier:(NSString *)cloudIdentifier {
	
	NSString *string = @"";
	if (name) string = [string stringByAppendingString:name];
	string = [string stringByAppendingString:@"-"];
	if (groupIdentifier) string = [string stringByAppendingString:groupIdentifier];
	string = [string stringByAppendingString:@"-"];
	if (cloudIdentifier) string = [string stringByAppendingString:cloudIdentifier];
	
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	NSString *identifier = [data base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
	return identifier;
}

+ (NSString *)identifierForObject:(id)object {
	return objc_getAssociatedObject(object, DCTObjectStoreObjectIdentifier);
}

+ (void)setIdentifier:(NSString *)identifier forObject:(id)object {
	objc_setAssociatedObject(object, DCTObjectStoreObjectIdentifier, identifier, OBJC_ASSOCIATION_COPY);
}

@end
