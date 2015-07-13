#import "Prefs.h"

// General Preferences
#define COLORED_ICONS_KEY      @"ColoredIcons"
#define ALARM_VOLUME_KEY       @"AlarmVolume"
#define SNOOZE_DURATION_KEY    @"SnoozeDuration"
#define KILL_DURATION_KEY      @"KillDuration"

// Easy Wake Preferences
#define EASY_WAKE_DEFAULT_KEY  @"EasyWakeDefault"
#define INITIAL_VOLUME_KEY     @"InitialVolume"
#define FINAL_VOLUME_KEY       @"FinalVolume"
#define EASY_WAKE_DURATION_KEY @"EasyWakeDuration"

// Advanced Preferences
#define WAKE_FROM_SLEEP_KEY    @"WakeFromSleep"
#define ANY_KEY_STOPS_KEY      @"AnyKeyStops"
#define LAUNCH_AT_LOGIN_KEY    @"LaunchAtLogin"
#define APPLE_REMOTE_KEY       @"AppleRemote"

// Hidden Preferences
#define FIRST_RUN_KEY          @"FirstRun"
#define XML_PATH_KEY           @"XMLPath"
#define DIGITAL_AUDIO_KEY      @"DigitalAudio"


@implementation Prefs

// INITIALIZATION, DEINITIALIZATION
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 This method is automatically called (courtesy of Cocoa) before the first instantiation of this class.
 We use it to register default values for the app's preferences.
**/
+ (void)initialize
{
	static BOOL initialized = NO;
	if(!initialized)
	{
		NSLog(@"Initializing Prefs...");
		
		/* Register Default Values */
		
		// Create a dictionary to hold the default preferences
		NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
		
		// General Preferences
		[defaultValues setObject:[NSNumber numberWithBool:YES]  forKey:COLORED_ICONS_KEY];
		[defaultValues setObject:[NSNumber numberWithFloat:0.6] forKey:ALARM_VOLUME_KEY];
		[defaultValues setObject:[NSNumber numberWithInt:8]     forKey:SNOOZE_DURATION_KEY];
		[defaultValues setObject:[NSNumber numberWithInt:15]    forKey:KILL_DURATION_KEY];
		
		// Alarm Preferences
		[defaultValues setObject:[NSNumber numberWithFloat:0.25] forKey:INITIAL_VOLUME_KEY];
		[defaultValues setObject:[NSNumber numberWithFloat:1.0] forKey:FINAL_VOLUME_KEY];
		[defaultValues setObject:[NSNumber numberWithInt:2]     forKey:EASY_WAKE_DURATION_KEY];
		
		// Advanced Preferences
		[defaultValues setObject:[NSNumber numberWithBool:NO]  forKey:WAKE_FROM_SLEEP_KEY];
		[defaultValues setObject:[NSNumber numberWithBool:NO]  forKey:ANY_KEY_STOPS_KEY];
		[defaultValues setObject:[NSNumber numberWithBool:NO]  forKey:LAUNCH_AT_LOGIN_KEY];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:APPLE_REMOTE_KEY];
		
		// Hidden Preferences
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:FIRST_RUN_KEY];
		[defaultValues setObject:@"" forKey:XML_PATH_KEY];
		[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:DIGITAL_AUDIO_KEY];
		
		// Register default values
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
		
		// Update initialization status
		initialized = YES;
	}
}

/**
 Called (via our application delegate) when the application is terminating.
 All cleanup tasks should go here.
**/
+ (void)deinitialize
{
	// Nothing to do here.
	// NSUserDefaults automatically takes flushes changes to the disk, and forces a flush prior to termination.
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark General Preferences
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL)useColoredIcons
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:COLORED_ICONS_KEY];
}

+ (void)setUseColoredIcons:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:COLORED_ICONS_KEY];
}

+ (float)prefVolume
{
	return [[NSUserDefaults standardUserDefaults] floatForKey:ALARM_VOLUME_KEY];
}

+ (void)setPrefVolume:(float)volume
{
	[[NSUserDefaults standardUserDefaults] setFloat:volume forKey:ALARM_VOLUME_KEY];
}

+ (int)snoozeDuration
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:SNOOZE_DURATION_KEY];
}

+ (void)setSnoozeDuration:(int)time
{
	[[NSUserDefaults standardUserDefaults] setInteger:time forKey:SNOOZE_DURATION_KEY];
}

+ (int)killDuration
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:KILL_DURATION_KEY];
}

+ (void)setKillDuration:(int)duration
{
	[[NSUserDefaults standardUserDefaults] setInteger:duration forKey:KILL_DURATION_KEY];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Easy Wake Preferences
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL)useEasyWakeByDefault
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:EASY_WAKE_DEFAULT_KEY];
}

+ (void)setUseEasyWakeByDefault:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:EASY_WAKE_DEFAULT_KEY];
}

+ (float)minVolume
{
	return [[NSUserDefaults standardUserDefaults] floatForKey:INITIAL_VOLUME_KEY];
}

+ (void)setMinVolume:(float)volume
{
	[[NSUserDefaults standardUserDefaults] setFloat:volume forKey:INITIAL_VOLUME_KEY];
}

+ (float)maxVolume
{
	return [[NSUserDefaults standardUserDefaults] floatForKey:FINAL_VOLUME_KEY];
}

+ (void)setMaxVolume:(float)volume
{
	[[NSUserDefaults standardUserDefaults] setFloat:volume forKey:FINAL_VOLUME_KEY];
}

+ (int)easyWakeDuration
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:EASY_WAKE_DURATION_KEY];
}

+ (void)setEasyWakeDuration:(int)duration
{
	[[NSUserDefaults standardUserDefaults] setInteger:duration forKey:EASY_WAKE_DURATION_KEY];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Advanced Preferences
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL)wakeFromSleep
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:WAKE_FROM_SLEEP_KEY];
}

+ (void)setWakeFromSleep:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:WAKE_FROM_SLEEP_KEY];
}

+ (BOOL)anyKeyStops
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:ANY_KEY_STOPS_KEY];
}

+ (void)setAnyKeyStops:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:ANY_KEY_STOPS_KEY];
}

+ (BOOL)launchAtLogin
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:LAUNCH_AT_LOGIN_KEY];
}

+ (void)setLaunchAtLogin:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:LAUNCH_AT_LOGIN_KEY];
}

+ (BOOL)supportAppleRemote
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:APPLE_REMOTE_KEY];
}

+ (void)setSupportAppleRemote:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:APPLE_REMOTE_KEY];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Hidden Preferences
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL)isFirstRun
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:FIRST_RUN_KEY];
}

+ (void)setIsFirstRun:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:FIRST_RUN_KEY];
}

+ (NSString *)xmlPath
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:XML_PATH_KEY];
}

+ (BOOL)digitalAudio
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:DIGITAL_AUDIO_KEY];
}

@end
