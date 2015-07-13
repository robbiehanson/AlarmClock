#import "AlarmTasks.h"
#import "Prefs.h"
#import "AlarmScheduler.h"
#import "WindowManager.h"
#import "CalendarAdditions.h"

#import <mach/mach_port.h>
#import <mach/mach_interface.h>
#import <mach/mach_init.h>

#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/ps/IOPSKeys.h>
#import <IOKit/IOMessage.h>

#import <Security/Authorization.h>
#import <unistd.h>

// Callback function to be invoked by the OS for power notifications
void callback(void * x,io_service_t y,natural_t messageType,void * messageArgument);

// Reference to the Root Power Domain IOService
io_connect_t root_port;

// Notification port allocated by IORegisterForSystemPower
IONotificationPortRef notifyPortRef;

// Notifier object, created when registering for power notifications, and used to deregister later
io_object_t notifierObject;


// Declare private methods
@interface AlarmTasks (PrivateAPI)
+ (BOOL)md5Check:(NSString *)path;
+ (void)runHelperToolWithArg:(int)arg;
+ (void)startTimers;
+ (void)initialCheckForAlarm:(NSTimer *)aTimer;
+ (void)checkForAlarm:(NSTimer *)aTimer;
+ (void)updateMenuItemsAtDayChange:(NSTimer *)aTimer;
@end


@implementation AlarmTasks

// CLASS VARIABLES
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Timer used to check for alarms every minute
static NSTimer *timer;

// Timer used to update the menu items when the day changes
static NSTimer *dayTimer;

// The time to schedule the computer to wake from sleep
static NSCalendarDate *wakeDate;

// INTIALIZATION, DEINITIALIZATION
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Initializes everything needed for the AlarmTasks class.
 This includes registering for system power notifications, as well as starting a timer to check for alarms.
 
 Note that this method is automatically called (courtesy of Cocoa) before the first method of this class is called.
 However, it is directly called by the MenuController during the startup of the application.
 This is because this class is in charge of checking for alarms to go off, and must be started immediately.
 Since it's called directly, we use a static variable to prevent multiple calls to this method.
 (One directly at startup, and the other indirectly via Cocoa the first time a method within it is called)
**/
+ (void)initialize
{
	static BOOL initialized = NO;
	if(!initialized)
	{
		NSLog(@"Initializing AlarmTasks...");
		
		NSLog(@"Registering for system power notifications...");
		
		// Register for system power notifications
		root_port = IORegisterForSystemPower(0, &notifyPortRef, callback, &notifierObject);
		if(root_port == (int)NULL)
		{
			NSLog(@"IORegisterForSystemPower failed!");
		}
		
		CFRunLoopAddSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notifyPortRef), kCFRunLoopDefaultMode);
		
		// Start the timer
		[self startTimers];
		
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
	// Stop and release the timers
	[timer release];
	[timer invalidate];
	[dayTimer release];
	[dayTimer invalidate];
	
	// Release next alarm date
	[wakeDate release];
	
	NSLog(@"Unregistering for system power notifications...");
	
	// Deregister for system power notifications
	
	// Remove the sleep notification port from the application runloop
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notifyPortRef), kCFRunLoopCommonModes);
	
    // Deregister for system sleep notifications
    IODeregisterForSystemPower(&notifierObject);
	
    // IORegisterForSystemPower implicitly opens the Root Power Domain IOService, so we close it here
    IOServiceClose(root_port);
	
    // destroy the notification port allocated by IORegisterForSystemPower
    IONotificationPortDestroy(notifyPortRef);
}

// POWER MANAGEMENT CALLBACK
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Called by the System whenever a power event occurs.
 Code courtesy Apple. (Wayne Flansburg)
**/
void callback(void * x, io_service_t y, natural_t messageType, void * messageArgument)
{
    switch(messageType)
	{
		case kIOMessageSystemWillSleep:
			// Handle demand sleep, such as:
			// A. Running out of batteries
			// B. Closing the lid of a laptop
			// C. Selecting sleep from the Apple menu
			NSLog(@"kIOMessageSystemWillSleep");
			[AlarmTasks prepareForSleep];
			IOAllowPowerChange(root_port, (long)messageArgument);
			break;
		case kIOMessageCanSystemSleep:
			// In this case, the computer has been idle for several minutes
			// and will sleep soon so you must either allow or cancel
			// this notification. Important: if you don’t respond, there will
			// be a 30-second timeout before the computer sleeps.
			if([WindowManager canSystemSleep])
			{
				NSLog(@"kIOMessageCanSystemSleep -> Allow");
				IOAllowPowerChange(root_port, (long)messageArgument);
			}
			else
			{
				NSLog(@"kIOMessageCanSystemSleep -> Cancel");
				IOCancelPowerChange(root_port, (long)messageArgument);
			}
			break;
		case kIOMessageSystemHasPoweredOn:
			NSLog(@"kIOMessageSystemHasPoweredOn");
			[AlarmTasks wakeFromSleep];
			break;
	}
}

// AUTHENTICATION METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Checks to see if the user is authenticated.
 That is, if the helper tool has the sticky bit set and the user is set to root.
**/
+ (BOOL)isAuthenticated
{
	// Get the path of the helper program
	NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [thisBundle pathForResource:@"helper" ofType:nil];
	
	// Check the attributes of the helper tool
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDictionary *attr = [fm fileAttributesAtPath:path traverseLink:NO];
	
	BOOL needsRepair = NO;
	NSNumber *permissions;
	NSString *owner;
	
	if(owner = [attr objectForKey:NSFileOwnerAccountName])
	{
		if(![owner isEqualToString:@"root"])
		{
			needsRepair = YES;
		}
	}
	if(permissions = [attr objectForKey:NSFilePosixPermissions])
	{
		if([permissions intValue] != 2541) //-rwsr-xr-x
		{
			needsRepair = YES;
		}
	}
	
	return !needsRepair;
}

/**
 Performs authentication.
 The helper tool that adds items to the IOPMQueue must be run as root.
 To achieve this we set the file's owner to root, and then set its setuid bit.
 The user needs to authenticate once to do this.
**/
+ (BOOL)authenticate
{	
	// Return immediately if the file doesn't need repair
	if([self isAuthenticated]) return YES;
	
	// Get the path of the helper program
	NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [thisBundle pathForResource:@"helper" ofType:nil];
	
	// Check to make sure it's our file (with md5 checksum)
	if(![self md5Check:path])
	{
		NSString *title = NSLocalizedString(@"Security Warning", @"Dialog Title");
		NSString *message = NSLocalizedString(@"Internal components of the program have been tampered with.\nPlease reinstall the application.", @"Dialog Message");
		NSString *okButton = NSLocalizedString(@"OK", @"Dialog Button");
        NSRunCriticalAlertPanel(title, message, okButton, nil, nil);
		
		return NO;
	}
	
	// Create AuthorizationReference
	AuthorizationRef authorizationRef;
	AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
	
	// Create path and args for CHOWN
	char *chown = "/usr/sbin/chown";
	char *chownArgs[] = {"root", (char*)[path UTF8String], NULL};
	
	// Create path and args for CHMOD
	char *chmod = "/bin/chmod";
	char *chmodArgs[] = {"4755", (char*)[path UTF8String], NULL};
	
	int result1 = AuthorizationExecuteWithPrivileges(authorizationRef, chown, kAuthorizationFlagDefaults, chownArgs, NULL);
	int result2 = AuthorizationExecuteWithPrivileges(authorizationRef, chmod, kAuthorizationFlagDefaults, chmodArgs, NULL);
	
	// Free AuthorizationReferences
	AuthorizationFree(authorizationRef, kAuthorizationFlagDefaults);
	
	return ((result1 == errAuthorizationSuccess) && (result2 == errAuthorizationSuccess));
}

/**
 Performs de-authentication.
 This returns the helper tool to standard permissions. (removes root owner, and sticky bit)
**/
+ (BOOL)deauthenticate
{
	// Get the path of the helper program
	NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [thisBundle pathForResource:@"helper" ofType:nil];
	
	// Create AuthorizationReference
	AuthorizationRef authorizationRef;
	AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
	
	// Create path and args for CHOWN
	char *chown = "/usr/sbin/chown";
	char *chownArgs[] = {getlogin(), (char*)[path UTF8String], NULL};
	
	// Create path and args for CHMOD
	char *chmod = "/bin/chmod";
	char *chmodArgs[] = {"0755", (char*)[path UTF8String], NULL};
	
	int result1 = AuthorizationExecuteWithPrivileges(authorizationRef, chown, kAuthorizationFlagDefaults, chownArgs, NULL);
	int result2 = AuthorizationExecuteWithPrivileges(authorizationRef, chmod, kAuthorizationFlagDefaults, chmodArgs, NULL);
	
	// Free AuthorizationReferences
	AuthorizationFree(authorizationRef, kAuthorizationFlagDefaults);
	
	return ((result1 == errAuthorizationSuccess) && (result2 == errAuthorizationSuccess));
}

/**
 It is possible for someone to replace the helper tool with a program that does considerable harm,
 since it is run with extra privledges.
 In order to prevent this from occuring, we refuse to authenticate if the helper tool isn't specifically ours.
 Perform an md5 checksum to be safe.
**/
+ (BOOL)md5Check:(NSString *)path
{
	NSArray *args = [NSArray arrayWithObject:path];
	
	NSTask *md5 = [[NSTask alloc] init];
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *readHandle = [pipe fileHandleForReading];
	
	[md5 setLaunchPath:@"/sbin/md5"];
	[md5 setArguments:args];
    [md5 setStandardOutput:pipe]; 
    [md5 launch];
	
	// Don't use waitUntilExit - It has problems
	// [md5 waitUntilExit];
	
	do {
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
	} while([md5 isRunning]);
	
	NSString *output = [[NSString alloc] initWithData:[readHandle readDataToEndOfFile] encoding:nil];
	// NSLog(@"md5Check: %@", output);
	
	[output autorelease];
    [md5 autorelease];
	
	// I once read on CocoaDev:
	// Be aware that someone could hack your app's executable... 
	// (@"" constant strings are stored as plain text in the executable.)
	// Using a C string would solve this.
	// 
	// I'm not sure if this is completely true or not, but it's worth doing since it's so easy to do.
	// Thus we use the stringWithUFT8String: method below for critical secret strings.
	// 
	// Update: A simple hex dump of an application file in TextWrangler reveals
	// @"" constant strings, but not C strings, so the CocoaDev poster seems somewhat credible.
	
	// Deployment1 = The helper version inside the alarm clock application
	// Deployment2 = The helper version when it's compiled by itself
	//
	// They're different because the helper is stripped when it's copied into the alarm clock resources
	
	NSString *deployment1 = [NSString stringWithUTF8String:"316826cbb9cdfb6b2eaba043e6f1ba6c\n"];
	NSString *deployment2 = [NSString stringWithUTF8String:"92f0b318b507f377bc559458c075935a\n"];
	
	NSString *development = [NSString stringWithUTF8String:"b48e7cc52e3d4d280533cc848801e2d4\n"];
	
	// Deployment build
	if([output hasSuffix:deployment1] || [output hasSuffix:deployment2])
		return YES;
	// Development build
	if([output hasSuffix:development])
		return YES;
	
	return NO;
}

// HANDLING SLEEP METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Prepares the program to go to sleep.
 That is, if it needs to wake the computer from sleep at some time then the event is scheduled in the IOPMQueue
**/
+ (void)prepareForSleep
{
	// We need to figure out when we have to wake up
	// Thus, we need to figure out when the next alarm is
	
	// Release the previous wakeDate
	[wakeDate release];
	
	// We get the time of the next scheduled alarm
	wakeDate = [AlarmScheduler nextAlarmDate];
	
	// What if an open alarm is currently snoozing, or a timer is active, etc...
	// So we also get the earliest date an open window may need to wake up
	NSCalendarDate *nextWindowDate = [WindowManager systemWillSleep];
	
	if(nextWindowDate != nil)
	{
		if(wakeDate == nil)
			wakeDate = nextWindowDate;
		else
			wakeDate = (NSCalendarDate*)[wakeDate earlierDate:nextWindowDate];
	}
	
	// Don't forget to retain the wakeDate - we need to reference it after we wake from sleep
	[wakeDate retain];
	
	// Now that we know the wakeDate, we can configure the system to wakeup at that time
	[self runHelperToolWithArg:1];
	
	// Stop the timers
	[timer invalidate];
	[dayTimer invalidate];
}

/**
 Removes the scheduled event from the IOPMQueue.
 Additionally NSTimers do not seem to be on schedule after the computer wakes from sleep.
 Thus, this method is used to stop the timer, check for an alarm manually,
 and then start the timer again (thus resyncing it)
**/
+ (void)wakeFromSleep
{
	// Remove the 'wakeFromSleep' event from the IOPMQueue
	[self runHelperToolWithArg:0];
	
	if([Prefs wakeFromSleep])
	{
		// Check for an alarm
		[self checkForAlarm:nil];
	}
	else
	{
		// Update all the alarms, so we don't have 50 go off at once
		// Which is entirely possible since we're not configured to wake the system from sleep
		// Because the computer may have slept through a dozen alarms
		[AlarmScheduler updateAllAlarms];
	}
	
	// Inform all open windows that we've woken from sleep
	[WindowManager systemDidWake];
	
	// Start the timer again
	[self startTimers];
	
	// Post notification for changed alarm
	// This will prompt the MenuController to update it's menu
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AlarmChanged" object:self];
}


/**
 Invokes the helper tool
 If arg is 1 - an IOPM event will be added
 If arg is 0 - an IOPM event will be deleted
**/
+ (void)runHelperToolWithArg:(int)arg
{
	// wakeDate is nil if no alarm is scheduled
	if(wakeDate == nil)
	{
		NSLog(@"Nothing to wake up for...");
		return;
	}
	
	if(![Prefs wakeFromSleep])
	{
		NSLog(@"Not configured to wake computer from sleep...");
		return;
	}
	
	// Setup the argument list
	NSMutableArray *args = [NSMutableArray arrayWithCapacity:2];
	
	// Argument 0: PM event type
	[args addObject:[NSString stringWithFormat:@"%i",arg]];
	
	// Argument 1: Time of event, measured as number of seconds since reference date
	if(arg == 1)
	{
		// We are adding an IOPM event: figure out the the time to use
		double secondsTilAlarm = [wakeDate timeIntervalSinceNow];
		if(secondsTilAlarm > 60)
		{
			// We have at least 60 seconds til alarm is set to go off
			NSString *targetStr = [NSString stringWithFormat:@"%f", [wakeDate timeIntervalSinceReferenceDate]];
			[args addObject:targetStr];
		}
		else
		{
			// We barely have any time til the alarm goes off
			// We don't want to set the alarm at its normal time, as it may not wake the computer in time
			// Some computers can take up to 30 seconds to go to sleep...
			// And after they go to sleep, they may ignore wake requests within only a few seconds
			
			// To be safe, we want to make sure the wake time is at least 60 seconds from now
			// We also try to get this as close as possible to the alarm time
			double secondsTilWake = 60.0 - secondsTilAlarm;
			
			[wakeDate autorelease];
			wakeDate = [[wakeDate dateByAddingYears:0
											 months:0
											   days:0
											  hours:0
											minutes:0
											seconds:secondsTilWake] retain];
			
			NSString *targetStr = [NSString stringWithFormat:@"%f", [wakeDate timeIntervalSinceReferenceDate]];
			[args addObject:targetStr];
		}
	}
	else
	{
		// We are deleting an IOPM event: use the wakeDate that was previously set
		NSString *targetStr = [NSString stringWithFormat:@"%f", [wakeDate timeIntervalSinceReferenceDate]];
		[args addObject:targetStr];
	}
	
	// Get the path of the helper program
	NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [thisBundle pathForResource:@"helper" ofType:nil];
	
	NSTask *task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:path];
	[task setArguments:args];
	[task launch];
	
	// Previously, the following code was used
	// [task waitUntilExit];
	
	// This is pretty standard textbook procedure, but caused a problem.
	// The above call would crash, if both prepareForSleep and wakeFromSleep were called at the same time
	// But wait! How could they both be running at the same time? They must be in different threads right??
	// The answer, mysteriously, seems to be NO.
	// According to the documentation for [task waitUntilExit]:
	//   This method first checks to see if the receiver is still running using isRunning.
	//   Then it polls the current run loop using NSDefaultRunLoopMode until the task completes.
	// So possibly, it sets up some kind of crazy callback scheme, which was apparently crashing the app.
	// Well, what I really need is for the thread to sleep until the task is done
	// So I just wrote my own simple implementation of waitUntilExit, which simply checks and sleeps
	// And ironically, it seems to be faster!
	
	do {
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
	} while([task isRunning]);
}

// TIMER METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* Starts the timer
** An initial timer is started that will go off at the turn of the current minute
** After that, a timer will go off every 60 seconds (effectivly at the turn of every minute thereafter)
**/
+ (void)startTimers
{
	// Start the initial timer
	// It shouldn't go off til the seconds (and milliseconds) are zero
	double waitTime1 = 60.0 - [[NSCalendarDate calendarDate] intervalOfMinute];
	timer = [[NSTimer scheduledTimerWithTimeInterval:waitTime1
											  target:self
											selector:@selector(initialCheckForAlarm:)
											userInfo:nil
											 repeats:NO] retain];
	
	// Start a timer to update menu items when the current day changes
	// This is needed so that items with "Tomorrow" get properly updated to "Today"
	double waitTime2 = 86400.0 - [[NSCalendarDate calendarDate] intervalOfDay];
	dayTimer = [[NSTimer scheduledTimerWithTimeInterval:waitTime2
												 target:self
											   selector:@selector(updateMenuItemsAtDayChange:)
											   userInfo:nil
												repeats:NO] retain];
}


/**
 Called from the initial timer.  This timer does not repeat.
 It's interval was set based on the current time, so that it went off at zero seconds and zero milliseconds.
**/
+ (void)initialCheckForAlarm:(NSTimer *)aTimer
{
	// Start the regular timer
	[timer autorelease];
	timer = [[NSTimer scheduledTimerWithTimeInterval:60.0
											  target:self
											selector:@selector(checkForAlarm:)
											userInfo:nil
											 repeats:YES] retain];
	// Check for alarms
	[self checkForAlarm:nil];
}


/**
 Called from the regular timer every 60 seconds.
 It's job is to check for an alarm, and sound it if necessary.
**/
+ (void)checkForAlarm:(NSTimer *)aTimer
{
	// Immediately grab the time so we know exactly when this timer fired
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	
	// Timer Accuracy Check
	if([timer isValid] && ([now secondOfMinute] > 0))
	{
		// The timer is either firing early (second is probably 59) or it's firing late (second is probably 1)
		// The first is possible due to an OS bug (or timer API bug)
		// The second is possible due to heavy cpu usage
		// Realign the timer
		[timer invalidate];
		[timer autorelease];
		
		double waitTime = 60.0 - [now intervalOfMinute];
		timer = [[NSTimer scheduledTimerWithTimeInterval:waitTime
												  target:self
												selector:@selector(initialCheckForAlarm:)
												userInfo:nil
												 repeats:NO] retain];
	}
	
	// Check to see if an alarm should sound
	// Continously check in case more than one alarm is scheduled at the same time
	int alarmStatus;
	do
	{
		alarmStatus = [AlarmScheduler alarmStatus:now];
		
		if(alarmStatus > 0)
		{
			NSLog(@"AlarmTasks: Alarm should sound!");
			[WindowManager openAlarmWindow];
		}
		
	}while(alarmStatus >= 0);
}

+ (void)updateMenuItemsAtDayChange:(NSTimer *)aTimer
{
	[dayTimer autorelease];
	
	double waitTime = 86400.0 - [[NSCalendarDate calendarDate] intervalOfDay];
	dayTimer = [[NSTimer scheduledTimerWithTimeInterval:waitTime
												 target:self
											   selector:@selector(updateMenuItemsAtDayChange:)
											   userInfo:nil
												repeats:NO] retain];
	
	NSLog(@"Updating menu items at day change");
	
	// Post notification for changed alarm
	// This will prompt the MenuController to update it's menu
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AlarmChanged" object:self];
}

@end