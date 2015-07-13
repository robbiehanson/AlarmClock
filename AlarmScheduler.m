#import "AlarmScheduler.h"
#import "Alarm.h"
#import "CalendarAdditions.h"


// Declare private methods
@interface AlarmScheduler (PrivateAPI)
+ (void)sortAndAddAlarm:(Alarm *)newAlarm;
@end


@implementation AlarmScheduler

// GLOBAL VARIABLES
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Alarm Array
static NSMutableArray *alarms;

// Storage of last alarm to sound
static Alarm *lastAlarm;

// INITIALIZATION, DEINITIALIZATION
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Initializes all the alarms and updates all the alarm times.
 The alarms are initialized by by reading from app's prefs on disk.
 The preferences are handled by Cocoa's NSUserDefaults system.
 The preference file is stored at ~/Library/Preferences/com.digitallity.alarmclock2.plist
  
 Note that this method is automatically called (courtesy of Cocoa) before the first method of this class is called.
 However, it is directly called by the MenuController during the startup of the application.
 This is because this class is in charge of storing all the alarms, and must be started immediately.
 Since it's called directly, we use a static variable to prevent multiple calls to this method.
 (One directly at startup, and the other indirectly via Cocoa the first time a method within it is called)
 
 @result All alarms are initialized and ready to go.
**/
+ (void)initialize
{
	static BOOL initialized = NO;
	if(!initialized)
	{
		NSLog(@"Initializing AlarmScheduler...");
		initialized = YES;
		
		// Initialize alarms
		NSArray *alarmsPrefs = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Alarms"];
		
		alarms = [[NSMutableArray alloc] initWithCapacity:[alarmsPrefs count]];
		
		int i;
		for(i=0; i<[alarmsPrefs count]; i++)
		{
			// Create alarm from dictionary
			Alarm *temp = [[Alarm alloc] initWithDict:[alarmsPrefs objectAtIndex:i]];
			
			// Update the alarm's time, and add into array if not expired
			if([temp updateTime])
			{
				[self sortAndAddAlarm:temp];
			}
			
			// Release the alarm
			// If it was added to the array, it will still be retained
			[temp release];
		}
		
		// Save changes to defaults
		[self savePrefs];
		
		// Add listener for time zone change notifications
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
															selector:@selector(timeZoneDidChange:) 
																name:@"NSSystemTimeZoneDidChangeDistributedNotification" 
															  object:nil];
		
		// Note: The alarms individually update themselves during init if the time zone has changed
		// since the last time the application was run.
	}
}

/**
 Called (via our application delegate) when the application is terminating.
 All cleanup tasks should go here.
**/
+ (void)deinitialize
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

// SAVING INFORMATION TO USER DEFAULTS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Loops through all the alarms, extracting their preferences (NSDictionary),
 and then adds all alarms into an Array called Alarms, and adds this to the user defaults system.
**/
+ (void)savePrefs
{
	NSMutableArray *alarmsPrefs = [NSMutableArray array];
	
	int i;
	for(i=0; i<[alarms count]; i++)
	{
		[alarmsPrefs addObject:[[alarms objectAtIndex:i] prefsDictionary]];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:alarmsPrefs forKey:@"Alarms"];
	
	// Flush changes to disk
	//[[NSUserDefaults standardUserDefaults] synchronize];
}

// GETTING ALARMS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Returns a reference to the alarm at the given index.
  
 This reference is mainly to be used as a parameter for setAlarm.
 It may be used for read only purposes, and should not be altered in any way.

 @param index - Index of alarm in array.
**/
+ (Alarm *)alarmReferenceForIndex:(int)index
{
	return [alarms objectAtIndex:index];
}

/**
 Returns a clone (autoreleased copy) of the alarm at the given index.
  
 This alarm is a completely separate copy, and may be freely altered.
 This is the alarm object that should be edited when editing an alarm. (Not the alarm reference)
 
 @param index - Index of alarm in vector.
**/
+ (Alarm *)alarmCloneForIndex:(int)index
{
	return [[[alarms objectAtIndex:index] copy] autorelease];
}

// CHANGING ALARMS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Sets the alarm.
 Since alarms may be changed, added, deleted or rescheduled, their position in an array is not constant.
 For this reason a reference is used instead of an index.
 The passed alarm is inserted directly into an array.
 It is not copied, and therefore should not be altered after calling this method.
 The reference in the array is replaced by the passed alarm (and thus released).
**/
+ (void)setAlarm:(Alarm *)clone forReference:(Alarm *)reference
{
	// Remove the old alarm
	[alarms removeObject:reference];
	
	// Add the new alarm
	[self sortAndAddAlarm:clone];
	
	// Save changes to defaults
	[self savePrefs];
	
	// Post notification for changed alarm
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AlarmChanged" object:self];
}

/**
 Adds the alarm to the list of alarms.
 The passed alarm is inserted directly into an array.
 It is not copied, and therefore should not be altered after calling this method.
**/
+ (void)addAlarm:(Alarm *)newAlarm
{
	// Add the new alarm
	[self sortAndAddAlarm:newAlarm];
	
	// Save changes to defaults
	[self savePrefs];
	
	// Post notification for changed alarm
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AlarmChanged" object:self];
}

/**
 Removes the given alarm from the list of alarms.
 
 @param deletedAlarm - reference to alarm that is to be deleted.
**/
+ (void)removeAlarm:(Alarm *)deletedAlarm
{
	// Remove alarm from array
	[alarms removeObject:deletedAlarm];
	
	// Save changes to defaults
	[self savePrefs];
	
	// Post notification for changed alarm
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AlarmChanged" object:self];
}

// UPDATING ALARMS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Loops through all the alarms in the list, and updates all of their times.
 If the alarms are expired, they are removed from the list and deleted.
 This method should be run when starting up the app, and after sleeping (if not set to wake the computer from sleep).
**/
+ (void)updateAllAlarms
{
	int i;
	for(i=0; i<[alarms count]; i++)
	{
		// Remove the alarm from the array
		// We retain it first so it doesn't get released when removed
		Alarm *temp = [[alarms objectAtIndex:i] retain];
		[alarms removeObjectAtIndex:i];
		
		// Now update the alarm, and add it back into the array if not expired
		if([temp updateTime])
		{
			[self sortAndAddAlarm:temp];
		}
		
		// Release the alarm
		// If it was added to the array, it will still be retained
		[temp release];
	}
	
	// Save changes to defaults
	[self savePrefs];
	
	// Post notification for changed alarm
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AlarmChanged" object:self];
}

/**
 This method is called when the time zone is changed.
 It takes care of updating the times for all the alarms,
 as well as storing the new time zone into the defaults system.
**/
+ (void)timeZoneDidChange:(NSNotification *)note
{
	// Since the time zone has been changed, we need to first reset it
	// This is because the time zone is set for our application when it starts (just like the language)
	[NSTimeZone resetSystemTimeZone];
	
	NSLog(@"Using Time Zone: %@", [[NSTimeZone systemTimeZone] name]);
	
	// Loop through all the alarms, and update them to the new time zone
	int i;
	for(i = 0; i < [alarms count]; i++)
	{
		[[alarms objectAtIndex:i] updateTimeZone];
	}
	
	// Since the time has changed for all the alarms, we should go ahead and update the user defaults system
	[self savePrefs];
	
	// We might as well go ahead and update the menu too, just in case anything went wrong
	// Post notification for changed alarm
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AlarmChanged" object:self];
}

// GETTING NUMBER OF ALARMS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* Returns the number of alarms that have been scheduled */
+ (int)numberOfAlarms
{
	return [alarms count];
}

// GETTING INFO ABOUT NEXT AND LAST ALARM
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Returns a clone (autoreleased copy) of the last alarm to go off
**/
+ (Alarm *)lastAlarmClone
{
	return [[lastAlarm copy] autorelease];
}

/**
 Returns the date of the alarm that is scheduled to go off next.
 The returned date is a clone (autoreleased copy).
 If no alarm is scheduled, nil is returned
**/
+ (NSCalendarDate *)nextAlarmDate
{
	int i;
	for(i = 0; i < [alarms count]; i++)
	{
		if([[alarms objectAtIndex:i] isEnabled])
		{
			return [[[[alarms objectAtIndex:i] time] copy] autorelease];
		}
	}
	
	return nil;
}

// QUERYING FOR SOUNDING ALARMS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Checks to see if any alarms are at the time they are scheduled to go off.
 This method returns 3 possible responses.
 It returns a negative value if there are no alarms ready to go off.
 It returns zero is an alarm is ready to go off, but the alarm isn't enabled.
 It returns a positive value if an alarm is ready to go off, and the alarm is enabled.
 
 Note, that if this method returns a non-negative value (either zero or positive), it should continually be queried,
 as there may be multiple alarms set for the same time.
**/
+ (int)alarmStatus:(NSCalendarDate *)now
{
	if([alarms count] > 0)
	{
		Alarm *next = [alarms objectAtIndex:0];
		
		//NSString *format = @"%Y-%m-%d %H:%M:%S %z";
		//NSLog(@"Currt time: %@", [now descriptionWithCalendarFormat:format]);
		//NSLog(@"Next alarm: %@", [[next time] descriptionWithCalendarFormat:format]);
		
		if([[next time] timeIntervalSinceDate:now] <= 0.0)
		{
			// Set the lastAlarm
			[lastAlarm autorelease];
			lastAlarm = [next copy];
			
			// Remove the alarm from the array
			// First retain it so it doesn't get released when removed
			[next retain];
			[alarms removeObject:next];
			
			// Update the alarm and resort in array if not expired
			if([next updateTime])
			{
				[self sortAndAddAlarm:next];
			}
			
			// Release the alarm
			// If it was added to the array, it will still be retained
			[next release];
			
			// Post notification for changed alarm
			[[NSNotificationCenter defaultCenter] postNotificationName:@"AlarmChanged" object:self];
			
			// Return YES if the alarm was enabled
			if([lastAlarm isEnabled])
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
	}
	
	return -1;
}

// PRIVATE API
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Adds the given alarm to the list of alarms and sorts it into the correct position.
 Remember, we keep the alarms array sorted by alarm time.
**/
+ (void)sortAndAddAlarm:(Alarm *)newAlarm
{
	// Put it in the right place
	int i = 0;
	BOOL done = false;
	NSCalendarDate *newTime = [newAlarm time];
	
	while(i<[alarms count] && !done)
	{
		Alarm *temp = [alarms objectAtIndex:i];
		
		if([newTime isEarlierDate:[temp time]])
			done = YES;
		else
			i++;
	}
	
	[alarms insertObject:newAlarm atIndex:i];
}

@end