#import <dlfcn.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>
#import <AppSupport/CPDistributedMessagingCenter.h>

#define NSLog(...)

static BOOL prefIsEnabled;
static BOOL shouldUseCustom;

const char * userAgentChar;
//const char * buildChar;
//const char * versionChar;
//static size_t versionCharLen;

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	@autoreleasepool {
		memset((void*)userAgentChar, 0, 600);
		//memset((void*)buildChar, 0, 600);
		//memset((void*)versionChar, 0, 600);
		
		NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.julioverne.exchangent2.plist"]?:@{};
		
		prefIsEnabled = [prefs[@"enabled"]?:@NO boolValue];
		
		//NSString* buildSet = [prefs[@"iosVersion"]?:@"18E212" copy];
		//memcpy((void*)buildChar,(const void*)buildSet.UTF8String, [buildSet length]);
		//
		//NSString* versionSet = [prefs[@"iosVersionNum"]?:@"14.5.1" copy];
		//versionCharLen = [versionSet length];
		//memcpy((void*)versionChar,(const void*)versionSet.UTF8String, versionCharLen);
		
		shouldUseCustom = [prefs[@"useCustom"]?:@NO boolValue];
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


//%hook UIDevice
//- (id)buildVersion
//{
//	if(prefIsEnabled && !shouldUseCustom) {
//		return [NSString stringWithFormat:@"%s", buildChar];
//	}
//	
//	return %orig;
//}
//- (id)systemVersion
//{	
//	if(prefIsEnabled && !shouldUseCustom) {
//		return [NSString stringWithFormat:@"%s", versionChar];
//	}
//	
//	return %orig;
//}
//%end
//
//
//// spoof for /System/Library/CoreServices/SystemVersion.plist
//static CFPropertyListRef (*original_CFPropertyListCreateWithData)(CFAllocatorRef allocator, CFDataRef data, CFOptionFlags options, CFPropertyListFormat *format, CFErrorRef *error);
//static CFPropertyListRef replaced_CFPropertyListCreateWithData(CFAllocatorRef allocator, CFDataRef data, CFOptionFlags options, CFPropertyListFormat *format, CFErrorRef *error)
//{
//	CFPropertyListRef ret = original_CFPropertyListCreateWithData(allocator, data, options, format, error);
//	
//	if(ret && prefIsEnabled && !shouldUseCustom) {
//		NSDictionary* dic = (__bridge NSDictionary*)ret;
//		
//		if([dic isKindOfClass:%c(NSDictionary)] && dic[@"ProductVersion"]
//												&& dic[@"ProductBuildVersion"]
//												&& dic[@"ProductCopyright"]
//												&& dic[@"ProductName"]
//												&& dic[@"BuildID"]) {
//			NSLog(@">>> [Exchangent]  key: %@", @"BuildVersion");
//			NSLog(@">>> [Exchangent]  key: %@", @"ProductVersion");
//			NSMutableDictionary* dicM = [dic mutableCopy];
//			
//			dicM[@"ProductBuildVersion"] = [NSString stringWithFormat:@"%s", buildChar];
//			dicM[@"ProductVersion"] = [NSString stringWithFormat:@"%s", versionChar];
//			
//			ret = (CFPropertyListRef)CFBridgingRetain(dicM);
//		}
//		
//	}
//	
//	return ret;
//}
//
//
//static int (*original_sysctlbyname)(const char *name, void *oldp, size_t *oldlenp, const void *newp, size_t newlen);
//static int replaced_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, const void *newp, size_t newlen)
//{
//	int ret = original_sysctlbyname(name, oldp, oldlenp, newp, newlen);
//	
//	if(name && prefIsEnabled && !shouldUseCustom) {
//		if(strcmp(name, "kern.osversion")==0) {
//			size_t len = versionCharLen;
//			if(oldp) {
//				bzero(oldp, len);
//				memcpy(oldp, versionChar, len);
//			}
//			if(oldlenp) {
//				oldlenp = &len;
//			}
//		}
//	}
//	return ret;
//}



%ctor
{
	NSLog(@">>> [Exchangent2]  START");
	
	userAgentChar = (const char*)(malloc(600));
	//versionChar = (const char*)(malloc(600));
	//buildChar = (const char*)(malloc(600));
	
	dlopen("/System/Library/PrivateFrameworks/DataAccess.framework/DataAccess", RTLD_LAZY);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &prefsChanged, CFSTR("com.julioverne.exchangent2/saved"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	prefsChanged(NULL, NULL, NULL, NULL, NULL);
	
	//#define HOOKFN(fName) \
	//void* sym##fName = dlsym(RTLD_DEFAULT, ""#fName""); \
	//if(sym##fName != NULL) { \
	//	MSHookFunction(sym##fName,(void *)  replaced_##fName, (void **) &original_##fName); \
	//} else { \
	//	NSLog(@">>> [Exchangent]  Symbol[%s] ignored.", ""#fName""); \
	//}
	//
	//HOOKFN(CFPropertyListCreateWithData);
	//HOOKFN(sysctlbyname);
	
	%init;
}


