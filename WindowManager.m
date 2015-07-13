/**
 This class manages the windows of the application.
 Since alarms windows, and alarm editor windows are loaded on demand, they're not autmatically managed by OS X.
 This method keeps an array of open alarm editor windows, so already open windows aren't loaded twice in memory.
 It also keeps track of open alarm windows, so they can be queried whenever needed.
**/

#import "WindowManager.h"
#import "Prefs.h"
#import "Alarm.h"
#import "AlarmScheduler.h"
#import "EditorController.h"
#import "TransparentController.h"
#import "AlarmController.h"
#import "TimerController.h"
#import "StopwatchController.h"
#import "AppleRemote.h"

#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/ps/IOPSKeys.h>


@implementation WindowManager

// GLOBAL VARIABLES
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Array to store references to currently open alarm windows
static NSMutableArray *alarmWindows;

// Array to store references to currently open timer windows
static NSMutableArray *timerWindows;

// Array to store references to currently open stopwatch windows
static NSMutableArray *stopwatchWindows;

// Array to store references to currently open alarm editor windows
static NSMutableArray *alarmEditorWindows;

static NSLock *lock;

// INTIALIZATION, DEINITIALIZATION
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Initializes global alarm variables.
 This method is automatically called (courtesy of Cocoa) before the first method of this class is called.
 We use it to initialize all 'static' variables.
**/
+ (void)initialize
{
	static BOOL initialized = NO;
	if(!initialized)
	{
		NSLog(@"Initializing WindowManager...");
		
		// Initialize the mutable array for alarm windows
		alarmWindows = [[NSMutableArray alloc] init];
		
		// Initialize the mutable array for timer windows
		timerWindows = [[NSMutableArray alloc] init];
		
		// Initialize the mutable array for timer windows
		stopwatchWindows = [[NSMutableArray alloc] init];
		
		// Initialize the mutable array for alarm editor windows
		alarmEditorWindows = [[NSMutableArray alloc] init];
		
		// Register for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(alarmEditorWindowClosed:)
													 name:@"AlarmEditorWindowClosed"
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(alarmClosed:)
													 name:@"AlarmClosed"
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(timerClosed:)
													 name:@"TimerClosed"
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(stopwatchClosed:)
													 name:@"StopwatchClosed"
												   object:nil];
		
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
															selector:@selector(screensaverDidStop:)
																name:@"com.apple.screensaver.didstop"
															  object:nil];
		
		// Initialize lock
		lock = [[NSLock alloc] init];
		
		initialized = YES;
	}
}

/**
 Called (via our application delegate) when the application is terminating.
 All cleanup tasks should go here.
**/
+ (void)deinitialize
{
	int i;
	
	// Close all open Alarm Editor Windows
	// NOTE: This is a HACK.  Not a solution.
	// TODO
	for(i = 0; i < [alarmEditorWindows count]; i++)
	{
		[[alarmEditorWindows objectAtIndex:i] release];
	}
	[alarmEditorWindows release];
	
	// Release all references to open alarm windows, so they may be properly dealloced on exit
	[alarmWindows release];
	
	// Release all references to open timer windows, so they may be properly dealloced on exit
	[timerWindows release];
	
	// Release all references to open stopwatch windows, so they may be properly dealloced on exit
	[stopwatchWindows release];
	
	// Deregiester for notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Alarm Editor Windows:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 This method takes care of opening the desired alarm editor.
 If an alarm editor for the given alarm index is already open, the window is brought to the front.
 If not, a new alarm editor for the alarm is created, and displayed for the user.
**/
+ (void)openAlarmEditorWithAlarmIndex:(int)alarmIndex
{
	Alarm *alarmRef = [AlarmScheduler alarmReferenceForIndex:alarmIndex];
	
	BOOL found = NO;
	int arrayIndex = 0;
	
	while(!found && (arrayIndex < [alarmEditorWindows count]))
	{
		// Note: We're doing an object compare, NOT an alarm compare
		// We want to make sure the references are the exact same object
		// Different alarms may have the same properties, and thus be "equal alarms"
		
		if([alarmRef isEqualTo:[[alarmEditorWindows objectAtIndex:arrayIndex] alarmReference]])
			found = YES;
		else
			arrayIndex++;
	}
	
	if(found)
	{
		// We found an open alarm editor for the given alarm
		// All we need to do is display it to the user
		[[[alarmEditorWindows objectAtIndex:arrayIndex] window] makeKeyAndOrderFront:self];
	}
	else
	{
		// Create EditorController, and display
		// EditorController releases itself upon window close
		EditorController *temp = [[EditorController alloc] initWithIndex:alarmIndex];
		[temp showWindow:self];
		
		// We also add the new AlarmEdiotr to the array of alarm editor windows
		// This allows us to open only one alarm editor window per alarm
		[alarmEditorWindows addObject:temp];
	}
}

+ (void)openAlarmEditorForNewAlarm
{
	// Create EditorController, and display
	// EditorController releases itself upon window close
	EditorController *temp = [[EditorController alloc] init];
	[temp showWindow:self];
	
	// We also add the new AlarmEditor to the array of alarm editor windows
	// We do this so we can properly close all open alarm editors during shut down
	[alarmEditorWindows addObject:temp];
}

/**
 Called when notifications of "AlarmEditorWindowClosed" are posted.
 This class keeps references to all open alarm editor windows,
 because it doesn't want to open two editors for the same alarm.
**/
+ (void)alarmEditorWindowClosed:(NSNotification *)notification
{
	[alarmEditorWindows removeObject:[notification object]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Alarm Windows:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 This method takes care of opening a new alarm window.
 The alarm window will play the alarm for the lastAlarm in the AlarmScheduler.
 This method will also manage a reference to the open alarm window,
 and handle removing the reference when the alarm is stopped.
**/
+ (void)openAlarmWindow
{
	// Create AlarmController, and display
	// AlarmController releases itself upon window close
	AlarmController *temp = [[AlarmController alloc] init];
	[temp showWindow:self];
	
	// We also add the new AlarmController to the array of alarm windows
	// This allows us to query all the alarm windows when the computer wants to go to sleep
	[alarmWindows addObject:temp];
	
	// Start listening to the Apple Remote if needed
	if([Prefs supportAppleRemote] && [[AppleRemote sharedRemote] isRemoteAvailable])
	{
		[[AppleRemote sharedRemote] startListening];
		[[AppleRemote sharedRemote] setDelegate:self];
	}
}

/**
 Returns a list of references to all open AlarmControllers.
**/
+ (NSArray *)alarmWindows
{
	return alarmWindows;
}

/**
 Delegate method for the apple remote.
 Forwards this method call to each active alarm window.
**/
+ (void)appleRemoteButton:(AppleRemoteCookieIdentifier)buttonIdentifier pressedDown:(BOOL)pressedDown
{
	int i;
	for(i = 0; i < [alarmWindows count]; i++)
	{
		[[alarmWindows objectAtIndex:i] appleRemoteButton:buttonIdentifier pressedDown:pressedDown];
	}
}

/**
 Called when notifications of "AlarmStopped" are posted.
 This class keeps references to all open active alarm windows,
 so that they may be queried for information prior to the machine going to sleep.
**/
+ (void)alarmClosed:(NSNotification *)notification
{
	// Remove the alarmWindow from the list of alarm windows
	[alarmWindows removeObject:[notification object]];
	
	// If we don't have any alarm windows open, we can stop listening to the apple remote
	if([alarmWindows count] == 0)
	{
		[[AppleRemote sharedRemote] stopListening];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Timer Windows:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 This method takes care of opening a new timer window.
 This method will also manage a reference to the open window,
 and handle removing the reference when the window is closed.
**/
+ (void)openTimerWindow
{
	// Create TimerController, and display
	// TimerController releases itself upon window close
	TimerController *temp = [[TimerController alloc] init];
	[temp showWindow:self];
	
	// We also add the new TimerController to the array of timer windows
	// This allows us to query all the timer windows when the computer wants to go to sleep
	// Which allows us to wake the computer when a timer is supposed to go off
	[timerWindows addObject:temp];
}

/**
 Returns a list of references to all open TimerControllers.
**/
+ (NSArray *)timerWindows
{
	return timerWindows;
}

/**
 Called when notifications of "TimerClosed" are posted.
 This class keeps references to all open timer windows,
 so that they may be queried for information prior to the machine going to sleep.
**/
+ (void)timerClosed:(NSNotification *)notification
{
	// Remove the timerWindow from the list of timer windows
	[timerWindows removeObject:[notification object]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Stopwatch Windows:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 This method takes care of opening a new stopwatch window.
 This method will also manage a reference to the open window,
 and handle removing the reference when the window is closed.
**/
+ (void)openStopwatchWindow
{
	// Create StopwatchController, and display
	// StopwatchController releases itself upon window close
	StopwatchController *temp = [[StopwatchController alloc] init];
	[temp showWindow:self];
	
	// We also add the new StopwatchController to the array of stopwatch windows
	// This allows us to query all the stopwatch windows when the computer wants to go to sleep
	// Which allows us to prevent sleep with active open stopwatch windows
	[stopwatchWindows addObject:temp];
}

/**
 Returns a list of references to all open StopwatchControllers.
**/
+ (NSArray *)stopwatchWindows
{
	return stopwatchWindows;
}

/**
 Called when notifications of "StopwatchClosed" are posted.
 This class keeps references to all open stopwatch windows,
 so that they may be queried for information prior to the machine going to sleep.
**/
+ (void)stopwatchClosed:(NSNotification *)notification
{
	// Remove the stopwatchWindow from the list of stopwatch windows
	[stopwatchWindows removeObject:[notification object]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Sleep Management:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Special thanks to Andy for this code, which was graciously posted on his website.
 Made a few minor tweaks, and gave them back to him
**/
+ (BOOL)runningOnBattery
{
    BOOL mBatteryPower = NO;
	CFTypeRef powerSourcesInfo = IOPSCopyPowerSourcesInfo();
    NSArray *powerSources = (NSArray *)IOPSCopyPowerSourcesList(powerSourcesInfo);
    NSEnumerator *enumerator = [powerSources objectEnumerator];
    CFTypeRef sourceRef;
	
    while((sourceRef = [enumerator nextObject]) && !mBatteryPower)
    {
        NSDictionary *sourceData = (NSDictionary *)IOPSGetPowerSourceDescription(powerSourcesInfo, sourceRef);
		NSString *powerSourceStateKey = [NSString stringWithCString:kIOPSPowerSourceStateKey];
		NSString *batteryPowerValue = [NSString stringWithCString:kIOPSBatteryPowerValue];
		
        if([[sourceData objectForKey:powerSourceStateKey] isEqualToString:batteryPowerValue])
        {
			// We’re running on battery power
			mBatteryPower = YES;
        }
    }
	
	// Release resources
	CFRelease(powerSourcesInfo);
	[powerSources release];
	
    return mBatteryPower;
}

+ (BOOL)canSystemSleep
{
	if([self runningOnBattery] && [Prefs wakeFromSleep])
	{
		// The computer is running on battery power, and the app is properly configured to wake it from sleep
		// Thus, we shouldn't prevent sleep or the battery may die
		// And sleeping is fine since we can wake it up at the proper time
		return YES;
	}
	
	int i;
	
	// Loop through all the alarm windows, and see if any of them need to prevent sleep
	for(i = 0; i < [alarmWindows count]; i++)
	{
		if(![[alarmWindows objectAtIndex:i] canSystemSleep])
		{
			return NO;
		}
	}
	
	// Loop through all the timer windows, and see if any of them need to prevent sleep
	for(i = 0; i < [timerWindows count]; i++)
	{
		if(![[timerWindows objectAtIndex:i] canSystemSleep])
		{
			return NO;
		}
	}
	
	// Loop through all the stopwatch windows, and see if any of them need to prevent sleep
	for(i = 0; i < [stopwatchWindows count]; i++)
	{
		if(![[stopwatchWindows objectAtIndex:i] canSystemSleep])
		{
			return NO;
		}
	}
	
	return YES;
}

/**
 Called prior to the system going to sleep.
 Since there may be open windows that require the system to wake at a certain time,
 this method loops through all open windows, and calculates the earliest date at which the system should wake up.
 The earliest date is returned.
 If no windows require a system wake, nil is returned.
**/
+ (NSCalendarDate *)systemWillSleep
{
	int i;
	NSCalendarDate *wakeDate = nil;
	
	// Loop through all Alarms
	// If an alarm is snoozing, the system needs to wake up when the snooze duration is over
	
	for(i = 0; i < [alarmWindows count]; i++)
	{
		// Get the alarm's desired startTime
		NSCalendarDate *temp = [[alarmWindows objectAtIndex:i] systemWillSleep];
		
		if(temp != nil)
		{
			// Compare this with the existing wake date
			// We want the wake date to be the closest time to now
			if(wakeDate == nil)
				wakeDate = temp;
			else
				wakeDate = (NSCalendarDate*)[wakeDate earlierDate:temp];
		}
	}
	
	// Loop through all Timers
	// If a timer is active, the system needs to wake up when the timer is set to go off
	
	for(i = 0; i < [timerWindows count]; i++)
	{
		// Get the time at which the timer should go off
		NSCalendarDate *temp = [[timerWindows objectAtIndex:i] systemWillSleep];
		
		// If a timer isn't active, temp will be nil
		if(temp != nil)
		{
			// Compare this with the existing wake date
			// We want the wake date to be the closest time to now
			if(wakeDate == nil)
				wakeDate = temp;
			else
				wakeDate = (NSCalendarDate*)[wakeDate earlierDate:temp];
		}
	}
	
	// Loop through all Stopwatches
	// Stopwatches generally don't have to wake the system from sleep, but they need to prepare for it
	
	for(i = 0; i < [stopwatchWindows count]; i++)
	{
		// Get the time at which the timer should go off
		NSCalendarDate *temp = [[stopwatchWindows objectAtIndex:i] systemWillSleep];
		
		// If a timer isn't active, temp will be nil
		if(temp != nil)
		{
			// Compare this with the existing wake date
			// We want the wake date to be the closest time to now
			if(wakeDate == nil)
				wakeDate = temp;
			else
				wakeDate = (NSCalendarDate*)[wakeDate earlierDate:temp];
		}
	}
	
	return wakeDate;
}

/**
 Called after the system wakes from sleep.
 Notifies all open windows that the system has returned from sleeping.
 This allows open windows to recover (or make proper adjustments) after sleeping.
**/
+ (void)systemDidWake
{
	int i;
	
	// Loop through all Alarms
	for(i = 0; i < [alarmWindows count]; i++)
	{
		[[alarmWindows objectAtIndex:i] systemDidWake];
	}
	
	// Loop through all Timers
	for(i = 0; i < [timerWindows count]; i++)
	{
		[[timerWindows objectAtIndex:i] systemDidWake];
	}
	
	// Loop through all Stopwatches
	for(i = 0; i < [stopwatchWindows count]; i++)
	{
		[[stopwatchWindows objectAtIndex:i] systemDidWake];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Screensaver Notifications:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (void)screensaverDidStop:(NSNotification *)notification
{
	if([alarmWindows count] > 0)
	{
		// We need to know if any of the alarms are active
		// We only want to force the alarm window to the front if it's active
		
		int i;
		for(i = 0; i < [alarmWindows count]; i++)
		{
			AlarmController *currentAlarm = [alarmWindows objectAtIndex:i];
			
			if([currentAlarm alarmStatus] == STATUS_ACTIVE)
			{
				[NSApp activateIgnoringOtherApps:YES];
				[currentAlarm showWindow:self];
				
				return;
			}	
		}
	}
}

@end
