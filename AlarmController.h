#import <Cocoa/Cocoa.h>
#import "RoundedController.h"
@class  Alarm;
@class  ITunesData;
@class  ITunesPlayer;
@class  MTCoreAudioDevice;

#define STATUS_ACTIVE      1
#define STATUS_SNOOZING    2
#define STATUS_TERMINATED  3
#define STATUS_STOPPED     4

@interface AlarmController : NSWindowController <RoundedController>
{
	// The alarm to go off
	Alarm *lastAlarm;
	
	// For updating the time
	NSTimer *timer;
	
	// For playing songs with quicktime and core audio
	ITunesData *data;
	ITunesPlayer *player;
	MTCoreAudioDevice *outputDevice;
	
	// Time when alarm started, or (if snoozing) when it will start again
	NSCalendarDate *startTime;
	
	// For displaying the current time
	NSDateFormatter *timeFormatter;
	
	// Status of alarm
	int alarmStatus;
	BOOL isDataReady;
	BOOL isPlayerReady;
	
	// Status line control
	int statusOffset;
	BOOL shouldDisplaySongInfo;
	
	// Lock for threads
	NSLock *lock;
	
	// Preferences
	BOOL anyKeyStops;
	BOOL isDigitalAudio;
	int easyWakeDuration;
	int snoozeDuration;
	int killDuration;
	float prefVolume;
	float minVolume;
	float maxVolume;
	
	// Localized strings
	NSString *anyKeyStopStr;
	NSString *enterKeySnoozeStr;
	NSString *anyKeySnoozeStr;
	NSString *enterKeyStopStr;
	NSString *snoozingTilStr;
	NSString *alarmStartStr;
	NSString *alarmKillStr;
	NSString *snoozeStr;
	NSString *stopStr;
	NSString *timeStr;
	
	// Initial system volumes
	// This is the volume the system was at before the alarm went off
	// We store this, so that after the alarm is stopped, we can restore the system volume for the user
	float initialLeftVolume;
	float initialRightVolume;
	
	// Interface builder outlets
    IBOutlet id roundedView;
}

- (int)alarmStatus;

@end