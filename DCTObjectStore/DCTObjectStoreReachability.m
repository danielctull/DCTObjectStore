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

static NSString *const DCTObjectStoreReachabilityStatusString[] = {
	@"Unknown",
	@"Connected",
	@"NotConnected"
};

NSString *const DCTObjectStoreReachabilityDidChangeNotification = @"DCTObjectStoreReachabilityDidChangeNotification";

@interface DCTObjectStoreReachability ()
@property (nonatomic, readwrite) DCTObjectStoreReachabilityStatus status;
@property (nonatomic) SCNetworkReachabilityRef reachabilityRef;
@property (nonatomic) dispatch_queue_t queue;
@end

static BOOL DCTObjectStoreReachabilityIsReachable(SCNetworkReachabilityFlags flags) {
	return (flags & kSCNetworkReachabilityFlagsReachable) && !(flags & kSCNetworkReachabilityFlagsConnectionRequired);
}

static DCTObjectStoreReachabilityStatus DCTObjectStoreReachabilityStatusFromFlags(SCNetworkReachabilityFlags flags) {
	return DCTObjectStoreReachabilityIsReachable(flags) ? DCTObjectStoreReachabilityStatusConnected : DCTObjectStoreReachabilityStatusNotConnected;
}

static void DCTObjectStoreReachabilityCallback(__unused SCNetworkReachabilityRef reachabilityRef, SCNetworkReachabilityFlags flags, void* info) {

	NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");

	DCTObjectStoreReachability *reachability = (__bridge DCTObjectStoreReachability *)info;
	NSCAssert([reachability isKindOfClass:[DCTObjectStoreReachability class]], @"Info is wrong class, %@", info);

	reachability.status = DCTObjectStoreReachabilityStatusFromFlags(flags);
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

	_queue = dispatch_queue_create("DCTObjectStoreReachability", DISPATCH_QUEUE_SERIAL);

	const char *host = [@"www.apple.com" UTF8String];
	if (host == NULL) return self;
	_reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, host);
	if (_reachabilityRef == NULL) return self;

	dispatch_async(_queue, ^{
		SCNetworkReachabilityFlags flags;
		if (SCNetworkReachabilityGetFlags(self->_reachabilityRef, &flags)) {
			self.status = DCTObjectStoreReachabilityStatusFromFlags(flags);
		}
	});

	SCNetworkReachabilityContext context = { 0, (__bridge void *)self, NULL, NULL, NULL };

	if (SCNetworkReachabilitySetCallback(_reachabilityRef, DCTObjectStoreReachabilityCallback, &context) && SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, _queue)) {
		SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	}

	return self;
}

- (void)setStatus:(DCTObjectStoreReachabilityStatus)status {

	if (_status == status) {
		return;
	}

	_status = status;
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:DCTObjectStoreReachabilityDidChangeNotification object:self];
	});
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; status = %@>",
			NSStringFromClass([self class]),
			self,
			DCTObjectStoreReachabilityStatusString[self.status]];
}

@end
