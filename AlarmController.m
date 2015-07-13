#import "AlarmController.h"
#import "Alarm.h"
#import "AlarmScheduler.h"
#import "Prefs.h"
#import "ITunesData.h"
#import "ITunesPlayer.h"
#import "MTCoreAudioDevice.h"
#import "AppleRemote.h"


// Declare private methods
@interface AlarmController (PrivateAPI)
- (void)parseITunesMusicLibrary;
- (void)setupPlayer;
- (void)playerPlay;
- (void)playerStop;
- (void)playerNextTrack;
- (void)playerPreviousTrack;
- (void)snooze;
- (void)stop;
- (void)setVolume:(float)percent;
- (void)runAppleScript:(NSObject *)obj;
@end


@implementation AlarmController

// INIT, DEALLOC
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* Initializes object with proper nib */
- (id)init
{
	if(self = [super initWithWindowNibName:@"AlarmWindow"])
	{
		// Get the alarm that is supposed to go off
		lastAlarm = [[AlarmScheduler lastAlarmClone] retain];
		
		// Get preferences
		anyKeyStops      = [Prefs anyKeyStops];
		isDigitalAudio   = [Prefs digitalAudio];
		easyWakeDuration = [Prefs easyWakeDuration] * 60;
		snoozeDuration   = [Prefs snoozeDuration] * 60;
		killDuration     = [Prefs killDuration] * 60;
		prefVolume       = [Prefs prefVolume];
		minVolume        = [Prefs minVolume];
		maxVolume        = [Prefs maxVolume];
		
		// Initialize time formatter
		timeFormatter = [[NSDateFormatter alloc] init];
		[timeFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[timeFormatter setDateStyle:NSDateFormatterNoStyle];
		[timeFormatter setTimeStyle:NSDateFormatterMediumStyle];
		
		// Intialize the alarm status variables
		alarmStatus = STATUS_ACTIVE;
		isDataReady = NO;
		isPlayerReady = NO;
		
		// Initialize status line variables
		statusOffset = 0;
		shouldDisplaySongInfo = YES;
		
		// Initialize localized strings
		anyKeyStopStr     = [NSLocalizedStringFromTable(@"Press Any key to stop", @"AlarmWindow", @"Status line above clock during alarm") retain];
		enterKeySnoozeStr = [NSLocalizedStringFromTable(@"Press Enter to snooze", @"AlarmWindow", @"Status line above clock during alarm") retain];
		anyKeySnoozeStr   = [NSLocalizedStringFromTable(@"Press Any key to snooze", @"AlarmWindow", @"Status line above clock during alarm") retain];
		enterKeyStopStr   = [NSLocalizedStringFromTable(@"Press Enter to stop", @"AlarmWindow", @"Status line above clock during alarm") retain];
		snoozingTilStr    = [NSLocalizedStringFromTable(@"Snoozing until", @"AlarmWindow", @"Status line above clock during snooze") retain];
		alarmStartStr     = [NSLocalizedStringFromTable(@"Starting alarm...", @"AlarmWindow", @"Status line above clock when first starting alarm") retain];
		alarmKillStr      = [NSLocalizedStringFromTable(@"Alarm terminated!", @"AlarmWindow", @"Status line above clock after alarm is stopped") retain];
		snoozeStr         = [NSLocalizedStringFromTable(@"Snooze", @"AlarmWindow", @"Button below clock") retain];
		stopStr           = [NSLocalizedStringFromTable(@"Stop", @"AlarmWindow", @"Button below clock") retain];
		timeStr           = [[timeFormatter stringFromDate:[NSDate date]] retain];
		
		// Initialize core audio device for changing system volume
		outputDevice = [[MTCoreAudioDevice defaultOutputDevice] retain];
		
		// Store the initial system volume
		// These get restored after the alarm is stopped
		initialLeftVolume  = [outputDevice volumeForChannel:1 forDirection:kMTCoreAudioDevicePlaybackDirection];
		initialRightVolume = [outputDevice volumeForChannel:2 forDirection:kMTCoreAudioDevicePlaybackDirection];
		
		// Configure the volume
		// The setVolume method automatically takes care of unmuting the volume
		if([lastAlarm usesEasyWake])
			[self setVolume:minVolume];
		else
			[self setVolume:prefVolume];
		
		// Initialize lock
		lock = [[NSLock alloc] init];
	}
	return self;
}


/**
 Called after laoding the nib file
 Configures gui elements
**/
- (void)awakeFromNib
{
	// Record the starting time
	startTime = [[lastAlarm time] retain];
	
	// Start the timer
	timer = [[NSTimer scheduledTimerWithTimeInterval:0.5
											  target:self
											selector:@selector(updateAndCheck:)
											userInfo:nil
											 repeats:YES] retain];
	
	// Initially set it's time
	[roundedView setNeedsDisplay:YES];
	
	// Center the window
	// Don't forget to turn of cascading, or the windows will continually cascade
	[self setShouldCascadeWindows:NO];
	[[self window] center];
}

- (void)dealloc
{
	NSLog(@"Destroying %@", self);
	
	// Release last alarm
	[lastAlarm release];
	
	// Release timer
	[timer release];
	
	// Release iTunes Data and Player, and core audio device
	[data release];
	[player release];
	[outputDevice release];
	
	// Release startTime
	[startTime release];
	
	// Release formatter used to display current time
	[timeFormatter release];
	
	// Release lock
	[lock release];
	
	// Release localized strings
	[anyKeyStopStr release];
	[enterKeySnoozeStr release];
	[anyKeySnoozeStr release];
	[enterKeyStopStr release];
	[snoozingTilStr release];
	[alarmStartStr release];
	[alarmKillStr release];
	[snoozeStr release];
	[stopStr release];
	[timeStr release];
	
	// Move up the inheritance chain
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Window Delegate Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Sent after the window owned by the receiver has been loaded.
**/
- (void)windowDidLoad
{
	// Start parsing iTunes Music Library in background thread
	[NSThread detachNewThreadSelector:@selector(parseThread:) toTarget:self withObject:nil];
	
	// Turn off the screen saver
	[NSThread detachNewThreadSelector:@selector(runAppleScript:) toTarget:self withObject:nil];
	
	// Note that Cocoa's thread management system retains the target during the execution of the detached thread
	// When the thread terminates, the target gets released
	// Thus, since self will be retained, dealloc won't be called until these threads are completed
	
	// Bring application, and window to the front
	[[self window] makeKeyAndOrderFront:self];
	[NSApp activateIgnoringOtherApps:YES];
}

/**
 Called when the window is about to close.
 In this case, it's after the user has stopped the alarm, and the window has faded out.
**/
- (void)windowWillClose:(NSNotification *)aNotification
{
	// Stop the timer
	// It would still be running if the user quit the app with this window still open
	[timer invalidate];
	
	// Post notification for stopped alarm
	// This informs the WindowManager to remove the alarm from it's list of active alarm windows
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AlarmClosed" object:self];
	
	// Release self
	[self autorelease];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Parsing iTunes and Playing Alarm
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Background thread function to parse iTunes library.
 This method is run in a separate thread, allowing the GUI to remain responsive.
**/
- (void)parseThread:(NSObject *)obj
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self parseITunesMusicLibrary];
    [pool release];
}

/**
 Parses the iTunes data into memory.
 
 Invokes the proper procedures to parse the iTunes music library into memory.
 After this is complete, the alarm informations is validated with the fresh iTunes information.
 
 This method is muli-thread safe (the method first requests a lock).
**/
- (void)parseITunesMusicLibrary
{
	[lock lock];
	
	// Parse iTunes data if needed
	if(!isDataReady)
	{
		NSLog(@"Parsing iTunes Music Library...");
		NSDate *start = [NSDate date];
		
		// Parse the iTunes Music Library
		data = [[ITunesData alloc] init];
		
		// The stored trackID may have changed
		// Check this, and update the alarm if needed
		int correctTrackID = [data validateTrackID:[lastAlarm trackID]
							 withPersistentTrackID:[lastAlarm persistentTrackID]];
		
		if(correctTrackID != [lastAlarm trackID])
		{
			[lastAlarm setTrackID:correctTrackID withPersistentTrackID:[lastAlarm persistentTrackID]];
		}
		
		// The stored playlistID may have changed
		// Check this, and update the alarm if needed
		int correctPlaylistID = [data validatePlaylistID:[lastAlarm playlistID]
								withPersistentPlaylistID:[lastAlarm persistentPlaylistID]];
		
		if(correctPlaylistID != [lastAlarm playlistID])
		{
			[lastAlarm setPlaylistID:correctPlaylistID withPersistentPlaylistID:[lastAlarm persistentPlaylistID]];
		}
		
		NSDate *end = [NSDate date];
		NSLog(@"Done parsing (time: %f seconds)", [end timeIntervalSinceDate:start]);
		
		// Update the data status
		// This lets the other methods know it's now safe to initialize the player
		isDataReady = YES;
	}
	
	[lock unlock];
}

/**
 This method initializes and configures the ITunesPlayer.
 Because the ITunesPlayer initializes a QTMovie, and QTMovie objects must be initialized in the main thread,
 the player must also be initialized in the main thread.
 
 This method should be called after the data is ready.
 
 This method is muli-thread safe (the method first requests a lock).
**/
- (void)setupPlayer
{
	// We can't do anything if we don't have the ITunesData yet
	if(!isDataReady) return;
	
	[lock lock];
	
	if(!isPlayerReady)
	{
		// Initialize ITunesPlayer
		player = [[ITunesPlayer alloc] initWithITunesData:data];
		
		// Configure self as delegate - we will implement iTunesPlayerChangedSong method
		[player setDelegate:self];
	
		// Set the alarm
		if([lastAlarm isPlaylist])
		{
			// Using a playlist
			NSLog(@"Setting alarm with playlistID: %i", [lastAlarm playlistID]);
			[player setPlaylistWithPlaylistID:[lastAlarm playlistID] usesShuffle:[lastAlarm usesShuffle]];
		}
		else if([lastAlarm isTrack])
		{
			// Using a single track
			NSLog(@"Setting alarm with trackID: %i", [lastAlarm trackID]);
			[player setTrackWithTrackID:[lastAlarm trackID]];
		}
		else
		{
			// No alarm file set, use default alarm file
			NSLog(@"Setting alarm with defaultAlarmFile");
			[player setFileWithPath:[Alarm defaultAlarmFile]];
		}
		
		// Update the player status
		// This lets the other methods know it's now safe to interact with the player
		isPlayerReady = YES;
	}
	
	[lock unlock];
}

/**
 This method starts the player, and verifies it's playing properly.
 If anything goes wrong, it reverts to the default alarm file.
**/
- (void)playerPlay
{
	if(isDataReady && isPlayerReady)
	{
		// Start the alarm
		[player play];
		
		// Check to make sure the alarm is playing
		// If it's not, then play the default alarm file
		if(![player isPlaying])
		{
			NSLog(@"Alarm failed to play! Reverting to defaultAlarmFile!");
			
			[player setFileWithPath:[Alarm defaultAlarmFile]];
			[player play];
		}
	}
}

/**
 This method stops the player from playing.
**/
- (void)playerStop
{
	if(isDataReady && isPlayerReady)
	{
		[player stop];
	}
}

/**
 This method moves the player to the next track
**/
- (void)playerNextTrack
{
	if(isDataReady && isPlayerReady)
	{
		if([player isPlaylist])
		{
			// Move to the next track
			[player nextTrack];
			
			// Force the display of song info
			statusOffset = (int)[[NSDate date] timeIntervalSinceDate:startTime];
			shouldDisplaySongInfo = YES;
		}
	}
}

/**
 This method moves the player to the previous track
**/
- (void)playerPreviousTrack
{
	if(isDataReady && isPlayerReady)
	{
		if([player isPlaylist])
		{
			// Move to the previous track
			[player previousTrack];
			
			// Force the display of song info
			statusOffset = (int)[[NSDate date] timeIntervalSinceDate:startTime];
			shouldDisplaySongInfo = YES;
		}
	}
}

/**
 Called by ITunesPlayer when the song changes.
 This lets us know we should force the display of song info
**/
- (void)iTunesPlayerChangedSong
{
	NSLog(@"iTunesPlayerChangedSong");
	
	statusOffset = (int)[[NSDate date] timeIntervalSinceDate:startTime];
	shouldDisplaySongInfo = YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Correspondence Info Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)shouldDisplayPlusMinusButtons
{
	if(alarmStatus == STATUS_SNOOZING)
	{
		return YES;
	}
	else if(alarmStatus == STATUS_ACTIVE)
	{
		return [player isPlaylist];
	}
	else
	{
		return NO;
	}
}

- (NSString *)statusLine1
{
	if(alarmStatus == STATUS_ACTIVE)
	{
		if([[NSDate date] timeIntervalSinceDate:startTime] < 3.0)
		{
			// Less than 3 seconds have elapsed since the alarm became active
			// At this point we're still ignoring keyboard input, so we display the starting message
			return alarmStartStr;
		}
		else if(!isPlayerReady)
		{
			// At least 3 seconds have elapsed since the alarm became active
			// But the player isn't ready yet, so instead of displaying empty strings
			// we're going to simply force display of the keyboard information
			if(anyKeyStops)
				return anyKeyStopStr;
			else
				return anyKeySnoozeStr;
		}
		else
		{
			// We either need to display the song info or the keyboard info
			// We switch back and forth between the 2 every 10 seconds
			// We also allow the user to manually switch between the 2 views
			if(shouldDisplaySongInfo)
			{
				return [[player currentTrack] objectForKey:@"Name"];
			}
			else
			{
				if(anyKeyStops)
					return anyKeyStopStr;
				else
					return anyKeySnoozeStr;
			}
		}
	}
	else if(alarmStatus == STATUS_SNOOZING)
	{
		return snoozingTilStr;
	}
	else
	{
		return alarmKillStr;
	}
}

- (NSString *)statusLine2
{
	if(alarmStatus == STATUS_ACTIVE)
	{
		if([[NSDate date] timeIntervalSinceDate:startTime] < 3.0)
		{
			// Less than 3 seconds have elapsed since the alarm became active
			// At this point we're still ignoring keyboard input, so we display the starting message
			return @"";
		}
		else if(!isPlayerReady)
		{
			// At least 3 seconds have elapsed since the alarm became active
			// But the player isn't ready yet, so instead of displaying empty strings
			// we're going to simply force display of the keyboard information
			if(anyKeyStops)
				return enterKeySnoozeStr;
			else
				return enterKeyStopStr;
		}
		else
		{
			// We either need to display the song info or the keyboard info
			// We switch back and forth between the 2 every 10 seconds
			// We also allow the user to manually switch between the 2 views
			if(shouldDisplaySongInfo)
			{
				return [[player currentTrack] objectForKey:@"Artist"];
			}
			else
			{
				if(anyKeyStops)
					return enterKeySnoozeStr;
				else
					return enterKeyStopStr;
			}
		}
	}
	else if(alarmStatus == STATUS_SNOOZING)
	{
		return [timeFormatter stringFromDate:startTime];
	}
	else
	{
		return @"";
	}
}

/**
 Returns the string to be displayed in the button traditionally used for increasing the snooze duration.
**/
- (NSString *)plusButtonStr
{
	if(alarmStatus == STATUS_ACTIVE)
		return @">";
	else if(alarmStatus == STATUS_SNOOZING)
		return @"+";
	else
		return @"";
}

/**
 Returns the string to be displayed in the button traditionally used for decreasing the snooze duration.
**/
- (NSString *)minusButtonStr
{
	if(alarmStatus == STATUS_ACTIVE)
		return @"<";
	else if(alarmStatus == STATUS_SNOOZING)
		return @"-";
	else
		return @"";
}

- (NSString *)timeStr
{
	// Wondering why we're using a timeStr, and not just formatting the current date every time this method is called?
	// It's because:
	// We don't want to update the time after the alarm is terminated!!!
	// If we format the current time right here, the time gets updated after the alarm is terminated,
	// while the user is interacting with the Alarm Window UI.  Which looks really odd!
	return timeStr;
}

- (NSString *)leftButtonStr
{
	return snoozeStr;
}

- (NSString *)rightButtonStr
{
	return stopStr;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Correspondence Action Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)statusLineClicked
{
	// We want to switch between displaying song info and keyboard info
	statusOffset = (int)[[NSDate date] timeIntervalSinceDate:startTime];
	shouldDisplaySongInfo = !shouldDisplaySongInfo;
}

/**
 Plus button clicked by user.
 We increase the snooze duration by 1 minute.
**/
- (void)plusButtonClicked
{
	if(alarmStatus == STATUS_SNOOZING)
	{
		NSCalendarDate *newStartTime;
		
		if([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
			newStartTime = [startTime dateByAddingYears:0 months:0 days:0 hours:0 minutes:5 seconds:0];
		else
			newStartTime = [startTime dateByAddingYears:0 months:0 days:0 hours:0 minutes:1 seconds:0];
	
		[startTime release];
		startTime = [newStartTime retain];
	
		NSLog(@"Increasing Snooze: %@", startTime);
	}
	else if(alarmStatus == STATUS_ACTIVE)
	{
		[self playerNextTrack];
	}
}

/**
 Minus button clicked by user.
 We decrease the snooze duration by 1 minute. (If this won't make the alarm immediately go off)
**/
- (void)minusButtonClicked
{
	if(alarmStatus == STATUS_SNOOZING)
	{
		NSCalendarDate *newStartTime;
		
		if([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
			newStartTime = [startTime dateByAddingYears:0 months:0 days:0 hours:0 minutes:-5 seconds:0];
		else
			newStartTime = [startTime dateByAddingYears:0 months:0 days:0 hours:0 minutes:-1 seconds:0];
	
		if([newStartTime timeIntervalSinceNow] > 0)
		{
			[startTime release];
			startTime = [newStartTime retain];
			
			NSLog(@"Decreasing Snooze: %@", startTime);
		}
	}
	else if(alarmStatus == STATUS_ACTIVE)
	{
		[self playerPreviousTrack];
	}
}

/**
 Snooze button clicked by user
**/
- (void)leftButtonClicked
{
	[self snooze];
}

/**
 Stop button clicked by user
**/
- (void)rightButtonClicked
{
	[self stop];
}

/**
 Called to determine if the system should be allowed to sleep.
 This is fine if the alarm is terminated or stopped.
 Otherwise, we would prefer that it didn't.
**/
- (BOOL)canSystemSleep
{
	return ((alarmStatus == STATUS_TERMINATED) || (alarmStatus == STATUS_STOPPED));
}

/**
 Called prior to the system going to sleep.
 We need to return the time at which this alarm will stop snoozing.
**/
- (NSCalendarDate *)systemWillSleep
{
	// Call snooze method
	// If the alarm is active, this will obviously snooze it
	// Otherwise it will have absolutely no effect.
	[self snooze];
	
	// Now, if the alarm was active, it's now snoozing
	// And if it was snoozing, well then it's still snoozing now isn't it
	if(alarmStatus == STATUS_SNOOZING)
		return [[startTime copy] autorelease];
	else
		return nil;
}

/**
 Called after the system has woken from sleep.
**/
- (void)systemDidWake
{
	// We don't actually have anything to do here.
	// The timer is still active, and will take care of setting off the alarm if needed.
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark General Correspondence
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (int)alarmStatus
{
	return alarmStatus;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Action Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)snooze
{
	if(alarmStatus == STATUS_ACTIVE)
	{
		// Update the alarm status
		alarmStatus = STATUS_SNOOZING;
		
		// Stop playing the music
		[self playerStop];
		
		// Automatically go to the next song (is using a playlist)
		[self playerNextTrack];
		
		// Reset the snooze time
		NSCalendarDate *now = [NSCalendarDate calendarDate];
		[startTime release];
		startTime = [[now dateByAddingYears:0 months:0 days:0 hours:0 minutes:0 seconds:snoozeDuration] retain];
		
		NSLog(@"Snoozing til: %@", startTime);
		
		// Set window so it can be put in the background
		[[self window] setLevel: NSNormalWindowLevel];
		
		// Reset the volume if using easy wake
		// This way you don't hear "You've Got Mail" really loud while you're snoozing
		if([lastAlarm usesEasyWake])
		{
			[self setVolume:minVolume];
		}
	}
}

- (void)stop
{
	if(alarmStatus != STATUS_STOPPED)
	{
		NSLog(@"Stopping alarm...");
		
		// Update the alarm status
		alarmStatus = STATUS_STOPPED;
		
		// Stop playing the music
		[self playerStop];
		
		// Stop the timer
		[timer invalidate];
		
		// Start a timer to fade out the window
		// After the fade is complete, the window will automatically be closed
		[NSTimer scheduledTimerWithTimeInterval:0.05
										 target:roundedView
									   selector:@selector(fade:)
									   userInfo:nil
										repeats:NO];
		
		// Return the system volume to it's original level (before the alarm went off)
		[outputDevice setVolume:initialLeftVolume forChannel:1 forDirection:kMTCoreAudioDevicePlaybackDirection];
		[outputDevice setVolume:initialRightVolume forChannel:2 forDirection:kMTCoreAudioDevicePlaybackDirection];
	}
}

// Timer Events
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)updateAndCheck:(NSTimer *)aTimer
{
	// Get the current time
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	
	// Update the timeStr
	[timeStr release];
	timeStr = [[timeFormatter stringFromDate:now] retain];
	
	// Update the shouldDisplaySongInfo variable (if needed)
	int elapsedTime = (int)[now timeIntervalSinceDate:startTime];
	int statusTime = elapsedTime - statusOffset;
	if(statusTime >= 10)
	{
		statusOffset = elapsedTime;
		shouldDisplaySongInfo = !shouldDisplaySongInfo;
	}
	
	// Setup the player if needed
	if(isDataReady && !isPlayerReady)
	{
		[self setupPlayer];
		if(alarmStatus == STATUS_ACTIVE)
		{
			[self playerPlay];
		}
	}
	
	if(alarmStatus == STATUS_ACTIVE)
	{
		// Set the volume to the proper level
		if([lastAlarm usesEasyWake])
		{
			// typedef double NSTimeInterval: Always in seconds; yields submillisecond precision...
			NSTimeInterval elapsed = [now timeIntervalSinceDate:startTime];
			
			float scale = (float)elapsed / (float)easyWakeDuration;
			if(scale > 1.0)
			{
				// We have to make sure the scale doesn't get bigger than 100%
				// If it does, the volume may end up higher than maxVolume
				scale = 1.0;
			}
			
			float diff = maxVolume - minVolume;
			float percent = minVolume + (diff * scale);
			
			[self setVolume:percent];
		}
		else
		{
			[self setVolume:prefVolume];
		}
		
		// Check to see if the alarm has expired
		if([now timeIntervalSinceDate:startTime] >= killDuration)
		{
			NSLog(@"Killing alarm due to inactivity");
			
			// Update alarm status
			alarmStatus = STATUS_TERMINATED;
			
			// Stop playing the music
			[self playerStop];
			
			// Stop the timer
			[timer invalidate];
			
			// Set window so it can be put in the background
			[[self window] setLevel:NSNormalWindowLevel];
		}
	}
	else
	{
		// Check to see if the alarm is done sleeping
		if([startTime timeIntervalSinceDate:now] <= 0)
		{
			// Update the alarm status
			alarmStatus = STATUS_ACTIVE;
			
			// Reset the start time
			[startTime release];
			startTime = [now retain];
			
			// Reset status line variables
			statusOffset = 0;
			shouldDisplaySongInfo = YES;
			
			// Reset the volume
			// The setVolume method automatically takes care of unmuting the volume
			if([lastAlarm usesEasyWake])
				[self setVolume:minVolume];
			else
				[self setVolume:prefVolume];
			
			// Start the music up again
			[self playerPlay];
			
			// Turn off screensaver
			[NSThread detachNewThreadSelector:@selector(runAppleScript:) toTarget:self withObject:nil];
			
			// Set window above all other windows
			[[self window] setLevel: NSStatusWindowLevel];
			
			// Bring application, and window to the front
			[[self window] makeKeyAndOrderFront:self];
			[NSApp activateIgnoringOtherApps:YES];
		}
	}
	
	[roundedView setNeedsDisplay:YES];
}

// KEYBOARD AND REMOTE EVENTS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Invoked when a key on the keyboard is pressed.
**/
- (void)keyDown:(NSEvent *)event
{
	unsigned short keyCode = [event keyCode];
	
	if(alarmStatus == STATUS_ACTIVE)
	{
		// Ignore keyboard events for the first 3 seconds
		if([[NSDate date] timeIntervalSinceDate:startTime] >= 3.0)
		{
			// If they hit the Return or Enter keys
			if((keyCode == 36) || (keyCode == 76) || (keyCode == 52))
			{
				if(anyKeyStops)
					[self snooze];
				else
					[self stop];
			}
			else if(keyCode == 123)
			{
				if([player isPlaylist])
				{
					[self minusButtonClicked];
					[roundedView setNeedsDisplay:YES];
				}
			}
			else if(keyCode == 124)
			{
				if([player isPlaylist])
				{
					[self plusButtonClicked];
					[roundedView setNeedsDisplay:YES];
				}
			}
			else
			{
				if(anyKeyStops)
					[self stop];
				else
					[self snooze];
			}
		}
	}
	else if(alarmStatus == STATUS_SNOOZING)
	{
		if(([event keyCode] == 69) || ([event keyCode] == 24))
		{
			// The user hit the plus button
			[self plusButtonClicked];
			[roundedView setNeedsDisplay:YES];
		}
		else if(([event keyCode] == 78) || ([event keyCode] == 27))
		{
			// The user hit the minus button
			[self minusButtonClicked];
			[roundedView setNeedsDisplay:YES];
		}
	}
}


/**
 Invoked when a button on the remote is pressed.
 Note: The WindowManager takes care of invoking this method for all active AlarmControllers.
**/
- (void)appleRemoteButton:(AppleRemoteCookieIdentifier)buttonIdentifier pressedDown:(BOOL)pressedDown 
{
	if(alarmStatus == STATUS_ACTIVE)
	{
		// Ignore events for the first 3 seconds
		if([[NSDate date] timeIntervalSinceDate:startTime] >= 3.0)
		{
			if(!pressedDown && (buttonIdentifier == kRemoteButtonPlay))
			{
				[self snooze];
			}
			if(!pressedDown && (buttonIdentifier == kRemoteButtonRight))
			{
				// Go to the next song (if using a playlist)
				[self playerNextTrack];
			}
			else if(!pressedDown && (buttonIdentifier == kRemoteButtonLeft))
			{
				// Go to the previous song (if using a playlist)
				[self playerPreviousTrack];
			}
		}
	}
}

// Helper methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setVolume:(float)percent
{
	float alteredPercent;
	
	// Some users use the application for reminders (like at work and such)
	// Therefore, setting the volume to 0% is just fine
	if(percent < 0.00)
		alteredPercent = 0.00;
	else if(percent > 1.00)
		alteredPercent = 1.00;
	else
		alteredPercent = percent;
	
	if(isDigitalAudio)
	{
		// It's impossible (as far as I know) to systematically control the output volume
		// when using digital audio. You can't even do it within system preferences.
		// So instead, we'll do the next best thing.
		// Control the output of our ITunesPlayer
		[player setVolume:percent];
	}
	else
	{
		// Make sure the volume is unmuted
		if(alteredPercent > 0.00)
		{
			[outputDevice setMute:NO forChannel:0 forDirection:kMTCoreAudioDevicePlaybackDirection];
		}
		
		// Set volume for left and right speakers, respectively
		[outputDevice setVolume:alteredPercent forChannel:1 forDirection:kMTCoreAudioDevicePlaybackDirection];
		[outputDevice setVolume:alteredPercent forChannel:2 forDirection:kMTCoreAudioDevicePlaybackDirection];
	}
}

/**
 Run AppleScript to take care of certain things otherwise un-accomplishable via Cocoa.
 These include things such as turning off the screensaver if running.
 
 However, running AppleScript is rather time consuming (especially on intel Macs for some reason).
 So running them in a background thread is ideal.
 However, according to the documentation, NSAppleScript should only be run from the main thread.
 So instead, we do it via NSTask and the osascript command.
**/
- (void)runAppleScript:(NSObject *)obj
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	/* Execute the following AppleScript command:
	
	try
	  tell application "System Events"
	    set the process_flag to (exists process "ScreenSaverEngine")
	  end tell
	  if the process_flag is true then
	    ignoring application responses
	      tell application "ScreenSaverEngine"
	        quit
	      end tell
	    end ignoring
	  end if
	end try
	
	*/
	
	NSMutableArray *args = [NSMutableArray arrayWithCapacity:24];
	
	// Pause iTunes
//	[args addObject:@"-e"]; [args addObject:@"try"];
//	[args addObject:@"-e"]; [args addObject:@"tell application \"System Events\"\n"];
//	[args addObject:@"-e"]; [args addObject:@"if exists process \"iTunes\" then\n"];
//	[args addObject:@"-e"]; [args addObject:@"tell application \"iTunes\"\n"];
//	[args addObject:@"-e"]; [args addObject:@"pause\n"];
//	[args addObject:@"-e"]; [args addObject:@"end tell\n"];
//	[args addObject:@"-e"]; [args addObject:@"end if\n"];
//	[args addObject:@"-e"]; [args addObject:@"end tell"];
//	[args addObject:@"-e"]; [args addObject:@"end try"];

	// Disable screen saver
	[args addObject:@"-e"]; [args addObject:@"try"];
	[args addObject:@"-e"]; [args addObject:@"tell application \"System Events\""];
	[args addObject:@"-e"]; [args addObject:@"set the process_flag to (exists process \"ScreenSaverEngine\")"];
	[args addObject:@"-e"]; [args addObject:@"end tell"];
	[args addObject:@"-e"]; [args addObject:@"if the process_flag is true then"];
	[args addObject:@"-e"]; [args addObject:@"ignoring application responses"];
	[args addObject:@"-e"]; [args addObject:@"tell application \"ScreenSaverEngine\""];
	[args addObject:@"-e"]; [args addObject:@"quit"];
	[args addObject:@"-e"]; [args addObject:@"end tell"];
	[args addObject:@"-e"]; [args addObject:@"end ignoring"];
	[args addObject:@"-e"]; [args addObject:@"end if"];
	[args addObject:@"-e"]; [args addObject:@"end try"];
	
	// Create task
	NSTask *task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:@"/usr/bin/osascript"];
	[task setArguments:args];
	
	// Launch task
	[task launch];
	
	// Wait for task to finish
	// I refuse to use [task waitUntilExit]
	// It's caused one too many headaches for me
	do {
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
	} while([task isRunning]);
	
	// Bring application to the front
	[NSApp activateIgnoringOtherApps:YES];
	
	[pool release];
}



@end