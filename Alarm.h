#import <Foundation/Foundation.h>

#define ALARMTYPE_DEFAULT  0
#define ALARMTYPE_TRACK    1
#define ALARMTYPE_PLAYLIST 2

@interface Alarm : NSObject <NSCopying>
{
	BOOL isEnabled;
	BOOL usesShuffle;
	BOOL usesEasyWake;
	int schedule;
	int type;
	int trackID;
	int playlistID;
	NSString *persistentTrackID;
	NSString *persistentPlaylistID;
	NSCalendarDate *time;
}

// Global Class Methods
+ (NSString *)defaultAlarmFile;

// Init routines
- (id)init;
- (id)initWithDict:(NSDictionary *)dict;

// For alarm comparisons
- (BOOL)isEqualToAlarm:(Alarm *)anAlarm;

// For saving to the userDefaults dictionary
- (NSDictionary *)prefsDictionary;

// For updating the time of alarms
- (BOOL)updateTime;
- (void)updateTimeZone;

// Get and Set Methods

- (BOOL)isEnabled;
- (void)setIsEnabled:(BOOL)newStatus;

- (BOOL)usesShuffle;
- (void)setUsesShuffle:(BOOL)shuffleFlag;

- (BOOL)usesEasyWake;
- (void)setUsesEasyWake:(BOOL)easyWakeFlag;

- (int)schedule;
- (void)setSchedule:(int)schedule;

- (BOOL)isTrack;
- (BOOL)isPlaylist;
- (void)setType:(int)type;

- (int)trackID;
- (NSString *)persistentTrackID;
- (void)setTrackID:(int)trackID withPersistentTrackID:(NSString *)persistentTrackID;

- (int)playlistID;
- (NSString *)persistentPlaylistID;
- (void)setPlaylistID:(int)playlistID withPersistentPlaylistID:(NSString *)persistentPlaylistID;

- (NSCalendarDate *)time;
- (void)setTime:(NSCalendarDate *)time;

@end
