#import <notify.h>
#import <Social/Social.h>
#import <prefs.h>

#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.julioverne.exchangent2.plist"
#define PLIST_PATH_CACHE_BUILDS "/Library/PreferenceBundles/Exchangent2Prefs.bundle/cache.plist"

@interface UIProgressHUD : UIView
- (void) hide;
- (void) setText:(NSString*)text;
- (void) showInView:(UIView *)view;
@end


@interface ExchangentPrefsRootListController : PSListController
{
	UILabel* _label;
	UILabel* underLabel;
}

@property (strong) NSMutableDictionary *devices;
@property (strong) NSMutableDictionary *builds;

@property (strong) UIProgressHUD *hud;

- (void)HeaderCell;
- (void)fetchDeviceType;
@end




static id currentDeviceSet()
{
	@autoreleasepool {
		NSDictionary *Prefs = [[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings];
		id deviceSet = Prefs[@"device"];
		if(deviceSet) {
			return deviceSet;
		}
		return @"iPhone13,4";
	}
}

static id currentBuildSet()
{
	@autoreleasepool {
		NSDictionary *Prefs = [[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings];
		id buildSet = Prefs[@"iosVersion"];
		if(buildSet) {
			return buildSet;
		}
		return @"18E212";
	}
}

static id encodedDevice(NSString* deviceSt)
{
	return [deviceSt stringByReplacingOccurrencesOfString:@"," withString:@"C"];
}

static id encodedBuild(NSString* buildSt)
{
	@autoreleasepool {
		NSString* newbuildSt = [buildSt copy];
		NSArray* letterArr = @[@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",];
		for(NSString* letterNow in letterArr) {
			if([newbuildSt rangeOfString:letterNow].location != NSNotFound) {
				newbuildSt = [newbuildSt stringByReplacingOccurrencesOfString:letterNow withString:[NSString stringWithFormat:@"%02d.", (int)[letterArr indexOfObject:letterNow]+1]];
			}
		}
		
		NSArray* letterArrMin = @[@"a",@"b",@"c",@"d",@"e",@"f",@"g",@"h",@"i",@"j",@"k",@"l",@"m",@"n",@"o",@"p",@"q",@"r",@"s",@"t",@"u",@"v",@"w",@"x",@"y",@"z",];
		for(NSString* letterNow in letterArrMin) {
			if([newbuildSt rangeOfString:letterNow].location != NSNotFound) {
				newbuildSt = [newbuildSt stringByReplacingOccurrencesOfString:letterNow withString:[NSString stringWithFormat:@"%05d", (int)[letterArrMin indexOfObject:letterNow]+1]];
			}
		}
		
		return newbuildSt;
	}
}


static NSString* CurrentUserAgent()
{
	@autoreleasepool {
		return [NSString stringWithFormat:@"Apple-%@/%@", encodedDevice(currentDeviceSet()), encodedBuild(currentBuildSet())];
	}
}


@implementation ExchangentPrefsRootListController
@synthesize devices, builds, hud;

- (id)init
{
	self = [super init];
	
	devices = [[NSMutableDictionary alloc] init];
	builds = [[NSMutableDictionary alloc] init];
	
	[self loadFromCache];
	
	return self;
}

- (void)loadFromCache
{
	@autoreleasepool {
		NSDictionary *Prefs = [[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_CACHE_BUILDS]?:@{};
		devices = [Prefs[@"devices"]?:@{} mutableCopy];
		builds = [Prefs[@"builds"]?:@{} mutableCopy];
	}
}

- (void)saveToCache
{
	@autoreleasepool {
		NSMutableDictionary *Prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH_CACHE_BUILDS]?:[NSMutableDictionary dictionary];
		Prefs[@"devices"] = devices;
		Prefs[@"builds"] = builds;
		[Prefs writeToFile:@PLIST_PATH_CACHE_BUILDS atomically:YES];
	}
}

- (id)specifiers {
	if (!_specifiers) {
		NSMutableArray* specifiers = [NSMutableArray array];
		PSSpecifier* spec;
		
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Enabled"
                                                  target:self
											         set:@selector(setPreferenceValue:specifier:)
											         get:@selector(readPreferenceValue:)
                                                  detail:Nil
											        cell:PSSwitchCell
											        edit:Nil];
		[spec setProperty:@"enabled" forKey:@"key"];
		[spec setProperty:@NO forKey:@"default"];
        [specifiers addObject:spec];
		
		if([[self readPreferenceValue:spec]?:@NO boolValue]) {
			
			PSSpecifier* specCustom = [PSSpecifier preferenceSpecifierNamed:@"Use Custom User-Agent"
													target:self
														set:@selector(setPreferenceValue:specifier:)
														get:@selector(readPreferenceValue:)
													detail:Nil
														cell:PSSwitchCell
														edit:Nil];
			[specCustom setProperty:@"useCustom" forKey:@"key"];
			[specCustom setProperty:@NO forKey:@"default"];
			
			if(![[self readPreferenceValue:specCustom]?:@NO boolValue]) {
				spec = [PSSpecifier preferenceSpecifierNamed:@"Preset Versions"
													target:self
													set:Nil
													get:Nil
													detail:Nil
													cell:PSGroupCell
													edit:Nil];
				[spec setProperty:@"Preset Versions" forKey:@"label"];
				[specifiers addObject:spec];
				
				
				NSArray *sortedDeviceKeysArr = [[devices allKeys] sortedArrayUsingSelector:@selector(compare:)];
				NSMutableArray* sortedDeviceKeys = [NSMutableArray array];
				NSMutableArray* sortedDeviceValues = [NSMutableArray array];
				for(NSString* keyNow in sortedDeviceKeysArr) {
					[sortedDeviceKeys addObject:[NSString stringWithFormat:@"%@ - (%@)", keyNow, devices[keyNow]]];
					[sortedDeviceValues addObject:devices[keyNow]];
				}
				
				spec = [PSSpecifier preferenceSpecifierNamed:@"Device"
													target:self
													set:@selector(setPreferenceValue:specifier:)
													get:@selector(readPreferenceValue:)
													detail:PSListItemsController.class
													cell:PSLinkListCell
													edit:Nil];
				[spec setProperty:@"device" forKey:@"key"];
				[spec setProperty:currentDeviceSet() forKey:@"default"];
				[spec setValues:sortedDeviceValues titles:sortedDeviceKeys];
				[specifiers addObject:spec];
				
				NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self"
                              ascending:YES
                               selector:@selector(localizedStandardCompare:)];
				NSArray *sortedBuildsKeysArr = [[builds allKeys] sortedArrayUsingDescriptors:@[sortDescriptor]];
				NSMutableArray* sortedBuildsKeys = [NSMutableArray array];
				NSMutableArray* sortedBuildsValues = [NSMutableArray array];
				for(NSString* keyNow in sortedBuildsKeysArr) {
					[sortedBuildsKeys addObject:[NSString stringWithFormat:@"%@ - (%@)", keyNow, builds[keyNow]]];
					[sortedBuildsValues addObject:builds[keyNow]];
				}
				
				spec = [PSSpecifier preferenceSpecifierNamed:@"iOS Version"
													target:self
													set:@selector(setPreferenceValue:specifier:)
													get:@selector(readPreferenceValue:)
													detail:PSListItemsController.class
													cell:PSLinkListCell
													edit:Nil];
				[spec setProperty:@"iosVersion" forKey:@"key"];
				[spec setProperty:currentBuildSet() forKey:@"default"];
				[spec setValues:sortedBuildsValues titles:sortedBuildsKeys];
				[specifiers addObject:spec];
				
				
				spec = [PSSpecifier preferenceSpecifierNamed:@"User-Agent For Device And Version"
													target:self
													set:Nil
													get:Nil
													detail:Nil
													cell:PSGroupCell
													edit:Nil];
				[spec setProperty:@"Preset Versions" forKey:@"label"];
				[specifiers addObject:spec];
				spec = [PSSpecifier preferenceSpecifierNamed:@"User-Agent"
								target:self
								set:NULL
								get:@selector(currentAgentValue)
								detail:Nil
								cell:PSTitleValueCell
								edit:Nil];
				[spec setProperty:@"kCurrentAgent" forKey:@"key"];
				[spec setProperty:@"" forKey:@"default"];
				[specifiers addObject:spec];
			}
			
			spec = [PSSpecifier preferenceSpecifierNamed:@"Custom"
												target:self
												set:Nil
												get:Nil
												detail:Nil
												cell:PSGroupCell
												edit:Nil];
			[spec setProperty:@"Custom" forKey:@"label"];
			[specifiers addObject:spec];
			
			
			[specifiers addObject:specCustom];
			
			if([[self readPreferenceValue:specCustom]?:@NO boolValue]) {
				spec = [PSSpecifier preferenceSpecifierNamed:@"User-Agent:"
								target:self
													set:@selector(setPreferenceValue:specifier:)
													get:@selector(readPreferenceValue:)
													detail:Nil
													cell:PSEditTextCell
													edit:Nil];
				[spec setProperty:@"customUserAgent" forKey:@"key"];
				[spec setProperty:@"Apple-iPhone13C4/1805.212" forKey:@"default"];
				[specifiers addObject:spec];
			}
		}

		spec = [PSSpecifier emptyGroupSpecifier];
        [specifiers addObject:spec];
		spec = [PSSpecifier emptyGroupSpecifier];
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Reset Settings"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
        spec->action = @selector(reset);
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Developer"
		                                      target:self
											  set:Nil
											  get:Nil
                                              detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"Developer" forKey:@"label"];
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Follow julioverne"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
        spec->action = @selector(twitter);
		[spec setProperty:[NSNumber numberWithBool:TRUE] forKey:@"hasIcon"];
		[spec setProperty:[UIImage imageWithContentsOfFile:[[self bundle] pathForResource:@"twitter" ofType:@"png"]] forKey:@"iconImage"];
        [specifiers addObject:spec];
		spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"derv82 & julioverne © 2021" forKey:@"footerText"];
        [specifiers addObject:spec];
		_specifiers = [specifiers copy];
	}
	return _specifiers;
}

- (id)currentAgentValue
{
	return CurrentUserAgent();
}

- (void)twitter
{
	UIApplication *app = [UIApplication sharedApplication];
	if ([app canOpenURL:[NSURL URLWithString:@"twitter://user?screen_name=ijulioverne"]]) {
		[app openURL:[NSURL URLWithString:@"twitter://user?screen_name=ijulioverne"]];
	} else if ([app canOpenURL:[NSURL URLWithString:@"tweetbot:///user_profile/ijulioverne"]]) {
		[app openURL:[NSURL URLWithString:@"tweetbot:///user_profile/ijulioverne"]];		
	} else {
		[app openURL:[NSURL URLWithString:@"https://mobile.twitter.com/ijulioverne"]];
	}
}
- (void)love
{
	SLComposeViewController *twitter = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
	[twitter setInitialText:@"#Exchangent2 by @ijulioverne is cool!"];
	if (twitter != nil) {
		[[self navigationController] presentViewController:twitter animated:YES completion:nil];
	}
}
- (void)reset
{
	[@{} writeToFile:@PLIST_PATH_Settings atomically:YES];
	[self reloadSpecifiers];
	//[self showPrompt];
	
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.julioverne.exchangent2/saved"), NULL, NULL, YES);
	
	[self fetchDeviceType];
}

- (void)showPrompt
{
	if(objc_getClass("UIAlertController")!=nil) {
		UIAlertController* alert = [objc_getClass("UIAlertController") alertControllerWithTitle:self.title message:@"An Respring is Requerid for this option." preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction* defaultAction = [objc_getClass("UIAlertAction") actionWithTitle:@"Respring" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
			system("killall backboardd SpringBoard");
		}];
		[alert addAction:defaultAction];
		UIAlertAction* defaultActionCancel = [objc_getClass("UIAlertAction") actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
		[alert addAction:defaultActionCancel];
		[self presentViewController:alert animated:YES completion:nil];
	} else {
		UIAlertView *alert = [[objc_getClass("UIAlertView") alloc] initWithTitle:self.title message:@"An Respring is Requerid for this option." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Respring", nil];
		alert.tag = 55;
		[alert show];
	}
}

- (void)reloadSpec
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_reloadSpec) object:nil];
	[self performSelector:@selector(_reloadSpec) withObject:nil afterDelay:0.5f];
}

- (void)_reloadSpec
{
	[self reloadSpecifiers];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier
{
	@autoreleasepool {
		NSMutableDictionary *Prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSMutableDictionary dictionary];
		[Prefs setObject:value forKey:[specifier identifier]];
		
		
		if ([[[specifier properties] objectForKey:@"key"]?:@"" isEqualToString:@"device"]) {
			[Prefs setObject:encodedDevice(value) forKey:@"device_"];
		}
		if ([[[specifier properties] objectForKey:@"key"]?:@"" isEqualToString:@"iosVersion"]) {
			[Prefs setObject:encodedBuild(value) forKey:@"iosVersion_"];
			
			NSArray *temp = [builds allKeysForObject:value];
			[Prefs setObject:[temp lastObject] forKey:@"iosVersionNum"];
		}
		
		[Prefs writeToFile:@PLIST_PATH_Settings atomically:YES];
		
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.julioverne.exchangent2/saved"), NULL, NULL, YES);
		
		if ([[specifier properties] objectForKey:@"PromptRespring"]) {
			[self showPrompt];
		}
		
		if ([[[specifier properties] objectForKey:@"key"]?:@"" isEqualToString:@"device"]) {
			[self fetchDeviceType];
		}
		
		[self reloadSpec];
	}
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 55 && buttonIndex == 1) {
        system("killall backboardd SpringBoard");
    }
}
- (id)readPreferenceValue:(PSSpecifier*)specifier
{
	@autoreleasepool {		
		NSDictionary *Prefs = [[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings];
		return Prefs[[specifier identifier]]?:[[specifier properties] objectForKey:@"default"];
	}
}
- (void)_returnKeyPressed:(id)arg1
{
	[super _returnKeyPressed:arg1];
	[self.view endEditing:YES];
}

- (void)HeaderCell
{
	@autoreleasepool {
		UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 120)];
		int width = [[UIScreen mainScreen] bounds].size.width;
		CGRect frame = CGRectMake(0, 20, width, 60);
		CGRect botFrame = CGRectMake(0, 55, width, 60);
	
		_label = [[UILabel alloc] initWithFrame:frame];
		[_label setNumberOfLines:1];
		_label.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:48];
		[_label setText:self.title];
		[_label setBackgroundColor:[UIColor clearColor]];
		//_label.textColor = [UIColor blackColor];
		_label.textAlignment = NSTextAlignmentCenter;
		_label.alpha = 0;
	
		underLabel = [[UILabel alloc] initWithFrame:botFrame];
		[underLabel setNumberOfLines:1];
		underLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
		[underLabel setText:@"Custom Exchange User-Agent"];
		[underLabel setBackgroundColor:[UIColor clearColor]];
		underLabel.textColor = [UIColor grayColor];
		underLabel.textAlignment = NSTextAlignmentCenter;
		underLabel.alpha = 0;
		
		[headerView addSubview:_label];
		[headerView addSubview:underLabel];
		
		[_table setTableHeaderView:headerView];
		
		[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(increaseAlpha) userInfo:nil repeats:NO];
	}
}

- (void)fetchDeviceType
{
	//if(!self.hud) {
	//	hud = [[UIProgressHUD alloc] init];
	//}
	//[hud setText:@"Getting Device List..."];
	//UIWindow* appWindow = [[UIApplication sharedApplication] keyWindow];
	//[hud showInView:appWindow];
	//appWindow.userInteractionEnabled = NO;
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		@try{
			@autoreleasepool {
				NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
				[request setURL:[NSURL URLWithString:@"https://api.ipsw.me/v4/devices"]];
				[request setHTTPMethod:@"GET"];
				
				NSURLResponse* imageresponse_link = nil;
				NSHTTPURLResponse *httpResponse_link = nil;
				__autoreleasing NSData *imageresult_link = [NSURLConnection sendSynchronousRequest:request returningResponse:&imageresponse_link error:nil];
				httpResponse_link = (NSHTTPURLResponse*)imageresponse_link;
				NSArray *arrResp = [NSJSONSerialization JSONObjectWithData:imageresult_link?:[NSData data] options:kNilOptions error:nil]?:@[];
				for(NSDictionary* deviceDicNow in arrResp) {
					NSString* name = deviceDicNow[@"name"];
					NSString* identifier = deviceDicNow[@"identifier"];
					if(name && identifier) {
						devices[name] = identifier;
					}
				}
				
				//dispatch_async(dispatch_get_main_queue(), ^(void) {
				//	[hud setText:[NSString stringWithFormat:@"Getting Builds List For %@...", currentDeviceSet()]];
				//});
				
				request = [[NSMutableURLRequest alloc] init];
				[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.ipsw.me/v4/device/%@?type=ipsw", currentDeviceSet()]]];
				[request setHTTPMethod:@"GET"];
				
				imageresponse_link = nil;
				httpResponse_link = nil;
				__autoreleasing NSData *imageresult_link2 = [NSURLConnection sendSynchronousRequest:request returningResponse:&imageresponse_link error:nil];
				httpResponse_link = (NSHTTPURLResponse*)imageresponse_link;
				NSDictionary* dicResp = [NSJSONSerialization JSONObjectWithData:imageresult_link2?:[NSData data] options:kNilOptions error:nil]?:@{};
				
				NSArray* firmArr = dicResp[@"firmwares"]?:@[];
				
				for(NSDictionary* buildDicNow in firmArr) {
					NSString* version = buildDicNow[@"version"];
					NSString* buildid = buildDicNow[@"buildid"];
					if(version && buildid) {
						builds[version] = buildid;
					}
				}
				
				[self saveToCache];
			}
		}@catch(NSException* ex) {
		}
		
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			//appWindow.userInteractionEnabled = YES;
			//[hud hide];
			[self reloadSpec];
		});
	});
}

- (void) loadView
{
	[super loadView];
	self.title = @"Exchangent2";
	[UISwitch appearanceWhenContainedIn:self.class, nil].onTintColor = [UIColor colorWithRed:0.09 green:0.99 blue:0.99 alpha:1.0];
	UIButton *heart = [[UIButton alloc] initWithFrame:CGRectZero];
	[heart setImage:[[UIImage alloc] initWithContentsOfFile:[[self bundle] pathForResource:@"Heart" ofType:@"png"]] forState:UIControlStateNormal];
	[heart sizeToFit];
	[heart addTarget:self action:@selector(love) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:heart];
	[self HeaderCell];
	
	
	[self fetchDeviceType];
	
}
- (void)increaseAlpha
{
	[UIView animateWithDuration:0.5 animations:^{
		_label.alpha = 1;
	}completion:^(BOOL finished) {
		[UIView animateWithDuration:0.5 animations:^{
			underLabel.alpha = 1;
		}completion:nil];
	}];
}


@end