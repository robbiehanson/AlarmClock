#import <Foundation/Foundation.h>


@interface Prefs : NSObject

+ (void)initialize;
+ (void)deinitialize;

// General
+ (BOOL)useColoredIcons;
+ (void)setUseColoredIcons:(BOOL)flag;

+ (float)prefVolume;
+ (void)setPrefVolume:(float)volume;

+ (int)snoozeDuration;
+ (void)setSnoozeDuration:(int)time;

+ (int)killDuration;
+ (void)setKillDuration:(int)duration;

// Easy Wake
+ (BOOL)useEasyWakeByDefault;
+ (void)setUseEasyWakeByDefault:(BOOL)flag;

+ (float)minVolume;
+ (void)setMinVolume:(float)volume;

+ (float)maxVolume;
+ (void)setMaxVolume:(float)volume;

+ (int)easyWakeDuration;
+ (void)setEasyWakeDuration:(int)duration;

// Advanced
+ (BOOL)wakeFromSleep;
+ (void)setWakeFromSleep:(BOOL)flag;

+ (BOOL)anyKeyStops;
+ (void)setAnyKeyStops:(BOOL)flag;

+ (BOOL)launchAtLogin;
+ (void)setLaunchAtLogin:(BOOL)flag;

+ (BOOL)supportAppleRemote;
+ (void)setSupportAppleRemote:(BOOL)flag;

// Hidden
+ (BOOL)isFirstRun;
+ (void)setIsFirstRun:(BOOL)flag;

+ (NSString *)xmlPath;

+ (BOOL)digitalAudio;

@end