#import "Alarm.h"
#import "Prefs.h"
#import "CalendarAdditions.h"

// For calculating powers
#import <math.h>

// Declare keys to be used in userDefaults
#define TIME_KEY                   @"time"
#define IS_ENABLED_KEY             @"status"
#define USES_SHUFFLE_KEY           @"shuffle"
#define USES_EASY_WAKE_KEY         @"easyWake"
#define SCHEDULE_KEY               @"schedule"
#define TYPE_KEY                   @"type"
#define TRACK_ID_KEY               @"trackID"
#define PLAYLIST_ID_KEY            @"playlistID"
#define PERSISTENT_TRACK_ID_KEY    @"persistentTrackID"
#define PERSISTENT_PLAYLIST_ID_KEY @"persistentPlaylistID"

// For archiving, and unarchiving NSCalendarDates
#define CALENDAR_FORMAT @"%Y-%m-%d %H:%M %z"


@implementation Alarm

// CLASS VARIABLES
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Stores the path to the default alarm file
// This is the default file stored within the application's bundle
static NSString *defaultAlarmFile;

// Stores the index of the first day of the week for the user's locale
static int firstDayOfWeek;

// INITIALIZATION
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Initializes global alarm variables.
 
 This method is automatically called (courtesy of Cocoa) before the first instantiation of this class.
 We use it to initialize all 'static' variables.
**/
+ (void)initialize
{
	static BOOL initialized = NO;
	if(!initialized)
	{
		// Determine what the first day of the week is based on the user's locale
		// Sunday = 1
		// Monday = 2
		// etc...
		// We subtract one because the internal code uses Sunday as 0
		// This makes it easier to do modulus arithmetic (i = ++i % 7)
		firstDayOfWeek = [[NSCalendar currentCalendar] firstWeekday] - 1;
		
		// Store the path to the default alarm (the one in the app package)
		NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
		NSString *resourcePath = [thisBundle resourcePath];
		
		defaultAlarmFile = [[resourcePath stringByAppendingString:@"/defaultAlarm.m4a"] retain];
		
		initialized = YES;
	}
}

// CLASS METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString *)defaultAlarmFile
{
	return [[defaultAlarmFile copy] autorelease];
}

// INIT, COPY, DEALLOC
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Default Constructor
 
 Initializes a new alarm with the following properties:
 Enabled, with no schedule, the default alarm, and set to 8AM.

 @result  A new alarm with default values.
**/
- (id)init
{
	if(self = [super init])
	{
		isEnabled    = YES;
		usesShuffle  = NO;
		usesEasyWake = [Prefs useEasyWakeByDefault];
		schedule     = 0;
		type         = ALARMTYPE_DEFAULT;
		trackID      = -1;
		playlistID   = -1;
		
		persistentTrackID = nil;
		persistentPlaylistID = nil;
		
		NSCalendarDate *now = [NSCalendarDate calendarDate];
		
		// Use a default time of NOW, but make sure to set the seconds to ZERO
		time = [[NSCalendarDate alloc] initWithYear:[now yearOfCommonEra]
											  month:[now monthOfYear]
												day:[now dayOfMonth]
											   hour:[now hourOfDay]
											 minute:[now minuteOfHour]
											 second:0
										   timeZone:[now timeZone]];
	}
	return self;
}


/**
 Initializes alarm from stored settings.
 
 Extracts the settings from the dictionary, and sets the alarm based on these settings.
 Dictionary should contain all required fields, such as time, status, schedule, etc.
 
 @param dict  A dictionary with stored settings of an alarm.
**/
- (id)initWithDict:(NSDictionary *)dict
{
	if(self = [super init])
	{
		// Set simple variables
		isEnabled    = [[dict objectForKey:IS_ENABLED_KEY] boolValue];
		usesShuffle  = [[dict objectForKey:USES_SHUFFLE_KEY] boolValue];
		usesEasyWake = [[dict objectForKey:USES_EASY_WAKE_KEY] boolValue];
		schedule     = [[dict objectForKey:SCHEDULE_KEY] intValue];
		type         = [[dict objectForKey:TYPE_KEY] intValue];
		trackID      = [[dict objectForKey:TRACK_ID_KEY] intValue];
		playlistID   = [[dict objectForKey:PLAYLIST_ID_KEY] intValue];
		
		// Get the persistent ID's
		persistentTrackID = [[dict objectForKey:PERSISTENT_TRACK_ID_KEY] retain];
		persistentPlaylistID = [[dict objectForKey:PERSISTENT_PLAYLIST_ID_KEY] retain];
		
		// Get the stored time
		id storedTime = [dict objectForKey:TIME_KEY];
		
		// Versions prior to 2.2.4 stored the date as an archived NSDate
		// This only stored the UTC, thus not effectively supporting time zone changes
		if([storedTime isKindOfClass:[NSDate class]])
		{
			NSLog(@"Upgrading old time format to new version...");
			
			// Cast stored time as an NSDate
			NSDate *date = storedTime;
			
			// Convert NSDate to NSCalendarDate
			time = [[date dateWithCalendarFormat:nil timeZone:nil] retain];
		}
		else
		{
			// Convert stored time into NSCalendarDate
			NSCalendarDate *date = [NSCalendarDate dateWithString:storedTime calendarFormat:CALENDAR_FORMAT];
			
			// Ensure that the date is correct for whatever time zone we're using
			time = [[date dateBySwitchingToTimeZone:[NSTimeZone systemTimeZone]] retain];
		}
		
		// Pre 2.2 versions supported a termination date in the schedule (get rid of it)
		while(schedule >= 128)
		{
			schedule -= 128;
		}
		
		// Pre 2.2.1 versions didn't have a type variable
		// Instead they relied on setting the trackID or playlistID to 0, when not in use
		if((trackID > 0) && (playlistID <= 0))
		{
			type = ALARMTYPE_TRACK;
		}
		if((playlistID > 0) && (trackID <= 0))
		{
			type = ALARMTYPE_PLAYLIST;
		}
	}
	
	return self;
}


/**
 Returns a copy of this alarm object
 
 This method is required for implementations of the NSCopying protocol.
 It is typically invoked by calling 'copy' on the object.
 The copy is a deep copy, and all variables may be changed without affecting the original.
 The copy is implicitly retained by the sender, who is responsible for releasing it.
 
 @param  zone - The zone in which the copy is done.
**/
- (id)copyWithZone:(NSZone *)zone
{
	// Create a new alarm, and set all variables to be the same as this one's
	// This is just conceptually simpler than using NSCopyObject (in my opinion)
	// Plus it doesn't give me any weird compiler errors
	
	Alarm *alarmCopy = [[Alarm alloc] init];
	
	[alarmCopy setIsEnabled:[self isEnabled]];
	[alarmCopy setUsesShuffle:[self usesShuffle]];
	[alarmCopy setUsesEasyWake:[self usesEasyWake]];
	[alarmCopy setSchedule:[self schedule]];
	[alarmCopy setTrackID:[self trackID] withPersistentTrackID:[self persistentTrackID]];
	[alarmCopy setPlaylistID:[self playlistID] withPersistentPlaylistID:[self persistentPlaylistID]];
	[alarmCopy setTime:[self time]];
	
	// Don't forget to set the 'private' variables
	// Make sure to set the type after setting the trackID and playlistID
	alarmCopy->type = type;
	
	return alarmCopy;
}


/**
 Standard deallocation method.
 Releases all resources for this object
**/
- (void)dealloc
{
	// Release our objects
	[persistentTrackID release];
	[persistentPlaylistID release];
	[time release];
	
	// Move up the inheritance chain
	[super dealloc];
}

// SAVING PREFERENCES
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Returns a dictionary with all the settings for this alarm.
  
 Returns an autoreleased dictionary that contains all settings for the alarm in its current state.
 This dictionary may be stored to disk, and may later be used to created a duplicate of it.
**/
- (NSDictionary *)prefsDictionary
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	[dictionary setObject:[NSNumber numberWithBool:isEnabled]    forKey:IS_ENABLED_KEY];
	[dictionary setObject:[NSNumber numberWithBool:usesShuffle]  forKey:USES_SHUFFLE_KEY];
	[dictionary setObject:[NSNumber numberWithBool:usesEasyWake] forKey:USES_EASY_WAKE_KEY];
	[dictionary setObject:[NSNumber numberWithInt:schedule]      forKey:SCHEDULE_KEY];
	[dictionary setObject:[NSNumber numberWithInt:type]          forKey:TYPE_KEY];
	[dictionary setObject:[NSNumber numberWithInt:trackID]       forKey:TRACK_ID_KEY];
	[dictionary setObject:[NSNumber numberWithInt:playlistID]    forKey:PLAYLIST_ID_KEY];
	
	// Make sure we don't add nil, as this causes a crash
	if(persistentTrackID != nil)
		[dictionary setObject:persistentTrackID forKey:PERSISTENT_TRACK_ID_KEY];
	
	if(persistentPlaylistID != nil)
		[dictionary setObject:persistentPlaylistID forKey:PERSISTENT_PLAYLIST_ID_KEY];
	
	// And finally, add the time to the dictionray
	[dictionary setObject:[time descriptionWithCalendarFormat:CALENDAR_FORMAT] forKey:TIME_KEY];
	
	return dictionary;
}

// UTILITY METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Updates the time and returns whether the alarm is expired or not.
  
 Updates the time of the alarm, based on the schedule, to be after now.
 If the alarm has no updates, or has updates but is now expired, 'No' is returned.
 If it has updates and isn't expired, the time is properly updated and 'Yes' is returned.
 
 @result Time is updated and expiration status is returned.
**/
- (BOOL)updateTime
{
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	
	// If we don't need to update the time, return YES
	if([time isLaterDate:now]) return YES;
	
	// If the alarm doesn't repeat, return NO
	if(schedule == 0) return NO;
	
	// Calculate the nex date based on the repeat schedule
	int scheduleCopy = schedule;
	
	// Calculate weekday repeat schedule
	// First get the days it is set to repeat
	BOOL days[7];
	int i;
	for(i=6; i>=0; i--)
	{
		if(scheduleCopy >= pow(2, i))
		{
			days[i] = YES;
			scheduleCopy -= pow(2, i);
		}
		else
		{
			days[i] = NO;
		}
	}
	
	// Now increment the time until it's after now
	BOOL found = YES;
	while(![time isLaterDate:now] && found)
	{
		found = NO;
		int daysChecked = 1;
		int nextDay = [time dayOfWeek];
		while(!found && daysChecked <= 7)
		{
			nextDay = (nextDay + 1) % 7;
			if(days[nextDay] == YES)
			{
				[time autorelease];
				time = [[time dateByAddingYears:0 months:0 days:daysChecked hours:0 minutes:0 seconds:0] retain];
				found = YES;
			}
			daysChecked++;
		}
	}
	
	return YES;
}

/**
 This method takes care of updating the time of the alarm to match the new system time zone.
**/
- (void)updateTimeZone
{
	[self setTime:[time dateBySwitchingToTimeZone:[NSTimeZone systemTimeZone]]];
	NSLog(@"Updated time: %@", time);
}

// GET AND SET METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Returns the current status (enabled/disabled) of the alarm.
**/
- (BOOL)isEnabled
{
	return isEnabled;
}

/**
 Sets the status (enabled/disabled) of the alarm.
**/
- (void)setIsEnabled:(BOOL)enabledFlag
{
	isEnabled = enabledFlag;
}

/**
 Returns the shuffle status (enabled/disabled) of the alarm.
**/
- (BOOL)usesShuffle
{
	return usesShuffle;
}

/**
 Sets the shuffle status (enabled/disabled) of the alarm.
**/
- (void)setUsesShuffle:(BOOL)shuffleFlag
{
	usesShuffle = shuffleFlag;
}

/**
 Returns the easy wake status (enabled/disabled) of the alarm.
**/
- (BOOL)usesEasyWake
{
	return usesEasyWake;
}

/**
 Sets the easy wake status (enabled/disabled) of the alarm.
**/
- (void)setUsesEasyWake:(BOOL)easyWakeFlag
{
	usesEasyWake = easyWakeFlag;
}

/**
 Returns the repeat schedule for the alarm.
 The repeat schedule is formatted as follows:
 
 Schedule : 
 64  : Saturday   (2^(7-1))
 32  : Friday     (2^(6-1))
 16  : Thursday   (2^(5-1))
 8   : Wednesday  (2^(4-1))
 4   : Tuesday    (2^(3-1))
 2   : Monday     (2^(2-1))
 1   : Sunday     (2^(1-1))
 0   : No schedule
 
 Example : (42 = 32 + 8 + 2 = Fri, Wed, Mon)
**/
- (int)schedule
{
	return schedule;
}

/**
 Sets the repeat schedule for the alarm.
 See the documentation for the schedule method for proper schedule formatting.
**/
- (void)setSchedule:(int)newSchedule
{
	schedule = newSchedule;
}

/**
Returns whether or not the alarm is properly configured to play a track.
 
 This method takes into account the internal alarm type setting,
 as well as the trackID.  So if, for example, the alarm is configured to play a track,
 but the trackID is invalid, this method will return NO. 
 **/
- (BOOL)isTrack
{
	return ((type == ALARMTYPE_TRACK) && (trackID >= 0));
}

/**
Returns whether or not the alarm is properly configured to play a playlist.
 
 This method takes into account the internal alarm type setting,
 as well as the playlistID.  So if, for example, the alarm is configured to play a playlist,
 but the playlistID is invalid, this method will return NO.
 **/
- (BOOL)isPlaylist
{
	return ((type == ALARMTYPE_PLAYLIST) && (playlistID >= 0));
}

/**
 Sets the type of the alarm (ex: track, playlist, etc)
 
 The type passed to this method should be one of the alarm types defined in Alarm.h.
 Examples include ALARMTYPE_DEFAULT, ALARMTYPE_TRACK, ALARMTYPE_PLAYLIST, etc.
**/
- (void)setType:(int)newType
{
	type = newType;
}

/**
 Returns the trackID, which may be used to lookup the song in the iTunes library.
 Note that this trackID is NOT persistent across multiple reads of the iTunes Music library XML file.
 The trackID should initially be validated against the persistentTrackID after a new read of the XML file.
**/
- (int)trackID
{
	return trackID;
}

/**
 Returns the alarm's persistent Track ID.
 This is a unique identification string that can reliably be used to find a song across multiple XML reads.
 The returned value is a reference to the original, and thus should not be altered in any way.
**/
- (NSString *)persistentTrackID
{
	return persistentTrackID;
}

/**
 Stores the alarm's trackID and persistentTrackID.
 The trackID is used to lookup the song information in the iTunes Music Library.
 The trackID is, however, not persistent across multiple reads of the librarie's XML file.
 The persistentTrackID is used for this, and can be found within the XML file.
 This persistent ID can be mapped to a regular track ID, which can in turn be used to quickly lookup the song.
**/
- (void)setTrackID:(int)newTrackID withPersistentTrackID:(NSString *)newPersistentTrackID
{
	// Store the trackID
	trackID = newTrackID;
	
	// Store the persistentTrackID
	[persistentTrackID autorelease];
	persistentTrackID = [newPersistentTrackID retain];
}

/**
 Returns the playlistID, which may be used to lookup the playlist in the iTunes library.
 Note that this playlistID is NOT persistent across multiple reads of the iTunes Music library XML file.
 The playlistID should initially be validated against the persistentPlaylistID after a new read of the XML file.
**/
- (int)playlistID
{
	return playlistID;
}

/**
 Returns the alarm's persistent Playlist ID.
 This is a unique identification string that can reliably be used to find a playlist across multiple XML reads.
 The returned value is a reference to the original, and thus should not be altered in any way.
**/
- (NSString *)persistentPlaylistID
{
	return persistentPlaylistID;
}

/**
 Stores the alarm's playlistID and persistentPlaylistID.
 The playlistID is used to lookup the song information in the iTunes Music Library.
 The playlistID is, however, not persistent across multiple reads of the librarie's XML file.
 The persistentPlaylistID is used for this, and can be found within the XML file.
 This persistent ID can be mapped to a regular playlist ID, which can in turn be used to quickly lookup the playlist.
**/
- (void)setPlaylistID:(int)newPlaylistID withPersistentPlaylistID:(NSString *)newPersistentPlaylistID
{
	// Store the playlistID
	playlistID = newPlaylistID;
	
	// Store the persistentPlaylistID
	[persistentPlaylistID autorelease];
	persistentPlaylistID = [newPersistentPlaylistID retain];
}

/**
 Returns the time this alarm is set to go off.
 If it's a repeating alarm, this is the next time it is set to go off.
 After a repeating alarm goes off, updateTime should be called to change this time to the next alarm time.
**/
- (NSCalendarDate *)time
{
	return time;
}

/**
 Sets the alarm's time.
 This is the next time the alarm is scheduled to go off.
**/
- (void)setTime:(NSCalendarDate *)newTime
{
	[time autorelease];
	time = [newTime retain];
}


// NSOBJECT METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Returns whether or not the given object is equal to this object.
 They are seen to be equal if all their instance variables are equal.
 
 For standard comparison (both point to the same object in memory), use NSObject's isEqual method.
**/
- (BOOL)isEqualToAlarm:(Alarm *)anAlarm
{
	// First make sure the given alarm isn't nil
	// If it is nil, then the alarm obviously isn't the same
	if(anAlarm == nil) return NO;
	
	// Check to make sure all the basic variables are the same
	if(isEnabled    != [anAlarm isEnabled])    return NO;
	if(usesShuffle  != [anAlarm usesShuffle])  return NO;
	if(usesEasyWake != [anAlarm usesEasyWake]) return NO;
	if(schedule     != [anAlarm schedule])     return NO;
	if(trackID      != [anAlarm trackID])      return NO;
	if(playlistID   != [anAlarm playlistID])   return NO;
	
	// Compare type
	if([self isTrack] != [anAlarm isTrack]) return NO;
	if([self isPlaylist] != [anAlarm isPlaylist]) return NO;
	
	// Compare string variables
	// If they're both nil, then isEqualToString will return NO, so we also do a standard comparison
	if(![persistentTrackID isEqualToString:[anAlarm persistentTrackID]]
	   && persistentTrackID != [anAlarm persistentTrackID])
	{
		return NO;
	}
	if(![persistentPlaylistID isEqualToString:[anAlarm persistentPlaylistID]]
	   && persistentPlaylistID != [anAlarm persistentPlaylistID])
	{
		return NO;
	}
	
	// Compare the times
	if(![time isEqualToDate:[anAlarm time]]) return NO;
	
	return YES;
}

/**
 Returns a string description of the alarm.
 This description is actually just a description of the schedule, and is made to be displayed in the NSStatusMenu.
**/
- (NSString *)description
{	
	/* Get time description (based on user's preferences) */
	
	// First we configure a date formatter
	NSDateFormatter *timeFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[timeFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[timeFormatter setDateStyle:NSDateFormatterNoStyle];
	[timeFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	// If using 12 hour clock
	// Force hours to be hh (08 instead of just 8)
	// This helps times to line up correctly in the menu bar (otherwise it looks like butt)
	NSRange padded12HourRange = [[timeFormatter dateFormat] rangeOfString:@"hh"];
	
	if(padded12HourRange.length == 0)
	{
		NSRange unpadded12HourRange = [[timeFormatter dateFormat] rangeOfString:@"h"];
		
		if(unpadded12HourRange.length > 0)
		{
			NSMutableString *timeFormat = [[[timeFormatter dateFormat] mutableCopy] autorelease];
			[timeFormat replaceCharactersInRange:unpadded12HourRange withString:@"hh"];
			
			// NSLog(@"New time format: %@", timeFormat);
			[timeFormatter setDateFormat:timeFormat];
		}
	}
	
	// If using 24 hour clock
	// Force hours to be HH (08 instead of just 8)
	// This helps times to line up correctly in the menu bar (otherwise it looks like butt)
	NSRange padded24HourRange = [[timeFormatter dateFormat] rangeOfString:@"HH"];
	
	if(padded24HourRange.length == 0)
	{
		NSRange unpadded24HourRange = [[timeFormatter dateFormat] rangeOfString:@"H"];
		
		if(unpadded24HourRange.length > 0)
		{
			NSMutableString *timeFormat = [[[timeFormatter dateFormat] mutableCopy] autorelease];
			[timeFormat replaceCharactersInRange:unpadded24HourRange withString:@"HH"];
			
			// NSLog(@"New time format: %@", timeFormat);
			[timeFormatter setDateFormat:timeFormat];
		}
	}
	
	// And finally set the timeStr to be the formatted representation of the time	
	NSString *timeStr = [timeFormatter stringFromDate:time];
	
	// And now it's time for the date...
	
	// Get date description
	if(schedule > 0)
	{
		int scheduleCopy = schedule;
		
		BOOL days[7];
		int i;
		for(i=6; i>=0; i--)
		{
			if(scheduleCopy >= pow(2, i))
			{
				days[i] = YES;
				scheduleCopy -= pow(2, i);
			}
			else
			{
				days[i] = NO;
			}
		}
		
		NSArray *shortWeekDays = [[NSUserDefaults standardUserDefaults] arrayForKey:NSShortWeekDayNameArray];
		
		NSMutableString *temp = [NSMutableString string];
		[temp appendString:@"("];
		
		BOOL found = NO;
		int daysChecked = 0;
		
		i = firstDayOfWeek;
		while(daysChecked < 7)
		{
			if(days[i])
			{
				if(found)
					[temp appendString:@","];
				
				[temp appendString:[shortWeekDays objectAtIndex:i]];
				found = YES;
			}
			i = (i + 1) % 7;
			daysChecked++;
		}
		[temp appendString:@")"];
		
		return [[timeStr stringByAppendingString:@"     "] stringByAppendingString:temp];
	}
	else
	{
		NSString *dateStr;
		
		int today = [[NSCalendarDate calendarDate] dayOfCommonEra];
		
		if([time dayOfCommonEra] == today)
		{
			dateStr = NSLocalizedString(@"Today", @"Today");
		}
		else if([time dayOfCommonEra] == (today+1))
		{
			dateStr = NSLocalizedString(@"Tomorrow", @"Tomorrow");
		}
		else
		{
			NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
			[dateFormatter setDateStyle:NSDateFormatterShortStyle];
			[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
			
			dateStr = [dateFormatter stringFromDate:time];
		}
		
		return [[timeStr stringByAppendingString:@"     "] stringByAppendingString:dateStr];
	}
}


@end
