#import <dlfcn.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>
#import <AppSupport/CPDistributedMessagingCenter.h>

#define NSLog(...)

static BOOL prefIsEnabled;
const char * userAgentChar;

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	@autoreleasepool {
		memset((void*)userAgentChar, 0, 600);
		NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.julioverne.exchangent2.plist"]?:@{};
		prefIsEnabled = [prefs[@"enabled"]?:@NO boolValue];
		BOOL shouldUseCustom = [prefs[@"useCustom"]?:@NO boolValue];
		NSString* userAgent = @"Apple-iPhone13C4/1805.212";
		if(shouldUseCustom) {
			userAgent = prefs[@"customUserAgent"]?:userAgent;
		} else {
			userAgent = [NSString stringWithFormat:@"Apple-%@/%@", prefs[@"device_"]?:@"iPhone13C4", prefs[@"iosVersion_"]?:@"1805.212"];
		}
		memcpy((void*)userAgentChar,(const void*)userAgent.UTF8String, [userAgent length]);
		NSLog(@"Exchangent userAgent to use: %s", userAgentChar);
	}
}

%hook DATaskManager
- (id)userAgent
{
	id defaultUserAgent = %orig;
	NSLog(@"Exchangent isEnabled: %d -- userAgent: %s -- defaultUserAgent: %@", prefIsEnabled, userAgentChar, defaultUserAgent);
	if(prefIsEnabled) {
		return [NSString stringWithFormat:@"%s", userAgentChar];
	}
	return defaultUserAgent;
}
%end


%ctor
{
	NSLog(@">>> [Exchangent2]  START");
	
	userAgentChar = (const char*)(malloc(600));
	
	dlopen("/System/Library/PrivateFrameworks/DataAccess.framework/DataAccess", RTLD_LAZY);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &prefsChanged, CFSTR("com.julioverne.exchangent2/saved"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	prefsChanged(NULL, NULL, NULL, NULL, NULL);
	
	%init;
}
