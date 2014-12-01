//
//  DCTObjectStoreReachability.m
//  DCTObjectStore
//
//  Created by Daniel Tull on 01.12.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import SystemConfiguration;
@import Darwin.POSIX.sys.socket;
@import Darwin.POSIX.netinet.in;
@import Darwin.POSIX.arpa.inet;
@import Darwin.POSIX.netdb;
#import "DCTObjectStoreReachability.h"

NSString *const DCTObjectStoreReachabilityDidChangeNotification = @"DCTObjectStoreReachabilityDidChangeNotification";

@interface DCTObjectStoreReachability ()
@property (nonatomic, readwrite, getter=isReachable) BOOL reachable;
@property (nonatomic) SCNetworkReachabilityRef reachabilityRef;
@end

static BOOL DCTObjectStoreReachabilityIsReachable(SCNetworkReachabilityFlags flags) {
	return (flags & kSCNetworkReachabilityFlagsReachable) && !(flags & kSCNetworkReachabilityFlagsConnectionRequired);
}

static void DCTObjectStoreReachabilityCallback(SCNetworkReachabilityRef reachabilityRef, SCNetworkReachabilityFlags flags, void* info) {

	NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");

	DCTObjectStoreReachability *reachability = (__bridge DCTObjectStoreReachability *)info;
	NSCAssert([reachability isKindOfClass:[DCTObjectStoreReachability class]], @"Info is wrong class, %@", info);

	BOOL reachable = DCTObjectStoreReachabilityIsReachable(flags);
	if (reachable != reachability.reachable) {
		reachability.reachable = reachable;
	}
}

@implementation DCTObjectStoreReachability

+ (void)load {
	[self sharedReachability];
}

+ (instancetype)sharedReachability {
	static DCTObjectStoreReachability *reachability;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		reachability = [self new];
	});
	return reachability;
}

- (instancetype)init {
	self = [super init];
	if (!self) return nil;

	NSString *host = @"www.apple.com";
	_reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, [host UTF8String]);
	if (_reachabilityRef == NULL) return self;

	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
		_reachable = DCTObjectStoreReachabilityIsReachable(flags);
	}

	SCNetworkReachabilityContext context = { 0, (__bridge void *)self, NULL, NULL, NULL };

	if (SCNetworkReachabilitySetCallback(_reachabilityRef, DCTObjectStoreReachabilityCallback, &context)) {
		SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	}
	return self;
}

- (void)setReachable:(BOOL)reachable {
	_reachable = reachable;
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTObjectStoreReachabilityDidChangeNotification object:self];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; reachable = %@>",
			NSStringFromClass([self class]),
			self,
			self.reachable ? @"YES" : @"NO"];
}

@end
