#import "TimerController.h"
#import "Prefs.h"
#import "MTCoreAudioDevice.h"
#import <math.h>

#define WINDOW_KEY               @"TimerWindow"
#define ORIGINAL_WINDOW_KEY      @"TimerWindowOriginal"
#define RECENT_TIMERS_KEY        @"TimerRecent"
#define WINDOW_ON_TOP_KEY        @"TimerAlwaysOnTop"
#define USE_ALARM_VOLUME_KEY     @"TimerUsesAlarmVolume"

#define RECENT_NAME_KEY          @"Name"
#define RECENT_TIME_KEY          @"Time"


@interface TimerController (PrivateAPI)
- (void)start;
- (void)pause;
- (void)reset;
- (void)edit:(BOOL)isInitialSetup;
- (NSString *)formatTime:(float)timeInterval;
@end

@implementation TimerController

// INIT, DEALLOC
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Initializes object with proper nib
**/
- (id)init
{
	if(self = [super initWithWindowNibName:@"TimerWindow"])
	{
		// Initialize time tracking info
		isStarted = NO;
		elapsedTime = 0.0;
		
		// Default time is 15 minutes
		totalTime = 15 * 60;
		
		// Intialize movie
		NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
		NSString *filePath = [[thisBundle resourcePath] stringByAppendingPathComponent:@"defaultTimer.m4a"];
		movie = [[QTMovie alloc] initWithFile:filePath error:nil];
		
		// Initialize localized strings
		titleStr     = [NSLocalizedStringFromTable(@"Timer", @"TimerWindow", @"Initial title of timer") retain];
		totalTimeStr = [NSLocalizedStringFromTable(@"Total Time", @"TimerWindow", @"Status line in Timer") retain];
		startStr     = [NSLocalizedStringFromTable(@"Start", @"TimerWindow", @"Button in Timer") retain];
		pauseStr     = [NSLocalizedStringFromTable(@"Pause", @"TimerWindow", @"Button in Timer") retain];
		resetStr     = [NSLocalizedStringFromTable(@"Reset", @"TimerWindow", @"Button in Timer") retain];
		editStr      = [NSLocalizedStringFromTable(@"Edit",  @"TimerWindow", @"Button in Timer") retain];
		
		// Register for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(movieFinished:)
													 name:QTMovieDidEndNotification
												   object:nil];
	}
	return self;
}

/**
 * Called after laoding the nib file
 * Configures gui elements
**/
- (void)awakeFromNib
{
	// We want the time field to use 24 hour formatting
	// This is so we can use it as a normal time counter
	NSLocale *tempLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"fr"] autorelease];
	[timeField setLocale:tempLocale];
	
	// We also configure a minDate and maxDate
	// This makes it easy to set the timer duration, and allows us to limit the duration
	// We do it here instead of in interface builder, because we want the maxDate to include the 59 seconds
	NSCalendarDate *minDate, *maxDate;
	minDate = [NSCalendarDate dateWithYear:1982 month:5 day:20 hour:0 minute:0 second:0 timeZone:nil];
	maxDate = [NSCalendarDate dateWithYear:1982 month:5 day:20 hour:23 minute:59 second:59 timeZone:nil];
	
	[timeField setMinDate:minDate];
	[timeField setMaxDate:maxDate];
	
	// Set the useAlarmVolume variable to be the default in the user's preferences
	useAlarmVolume = [[NSUserDefaults standardUserDefaults] boolForKey:USE_ALARM_VOLUME_KEY];
	
	// Set the window to be 'always on top' if set in the user's preferences
	if([[[NSUserDefaults standardUserDefaults] objectForKey:WINDOW_ON_TOP_KEY] boolValue])
	{
		[[self window] setLevel:NSStatusWindowLevel];
	}
	
	// We're now going to check to see if the original window frame matches that in the nib file.
	// Because if it doesn't, then the saved frame won't have the appropriate aspect ratio.
	BOOL didResetWindowFrame = NO;
	
	NSString *originalFrameStr = [[NSUserDefaults standardUserDefaults] stringForKey:ORIGINAL_WINDOW_KEY];
	if(originalFrameStr == nil)
	{
		originalFrameStr = [[self window] stringWithSavedFrame];
		[[NSUserDefaults standardUserDefaults] setObject:originalFrameStr forKey:ORIGINAL_WINDOW_KEY];
	}
	else
	{
		NSRect originalFrame = NSRectFromString(originalFrameStr);
		NSRect nibFrame = [[self window] frame];
		
		if((originalFrame.size.width != nibFrame.size.width) || (originalFrame.size.height != nibFrame.size.height))
		{
			NSLog(@"Using new nib window frame size");
			
			// The size of the nib file has been changed
			// Honor the requested new size from the programmer, designer, or translator
			didResetWindowFrame = YES;
			
			// And update our stored original size
			originalFrameStr = [[self window] stringWithSavedFrame];
			[[NSUserDefaults standardUserDefaults] setObject:originalFrameStr forKey:ORIGINAL_WINDOW_KEY];
		}
	}
	
	if(!didResetWindowFrame)
	{
		// Set window size and position from saved information
		[[self window] setFrameUsingName:WINDOW_KEY force:YES];
	}
	
	// We also update the frame of the transparent view to match the window
	NSRect viewFrame = [[self window] frame];
	viewFrame.origin.x = 0;
	viewFrame.origin.y = 0;
	
	[transparentView setFrame:viewFrame];
	
	// Also, disable cascading windows
	[self setShouldCascadeWindows:NO];
}

/**
 Don't forget to tidy up when we're done!
**/
- (void)dealloc
{
	//NSLog(@"Destroying %@", self);
	
	// Release timer
	[timer release];
	
	// Release startDate
	[startDate release];
	
	// Release movie
	[movie release];
	
	// Release stored and localized strings
	[titleStr release];
	[totalTimeStr release];
	[startStr release];
	[pauseStr release];
	[resetStr release];
	[editStr release];
	
	// Release miniWindow stuff
	[miniWindowTimer invalidate];
	[miniWindowTimer release];
	[bmpImageRep release];
	[miniWindowImage release];
	
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
	[super windowDidLoad];
	
	// Force the display to draw
	// This probably isn't needed, but we do it just to be safe
	[transparentView display];
	
	// Set title and time to be the last configuration used
	NSArray *recent = [[NSUserDefaults standardUserDefaults] arrayForKey:RECENT_TIMERS_KEY];
	if([recent count] > 0)
	{
		NSDictionary *mostRecent = [recent objectAtIndex:0];
		
		[titleStr release];
		titleStr = [[mostRecent objectForKey:RECENT_NAME_KEY] copy];
		totalTime = [[mostRecent objectForKey:RECENT_TIME_KEY] floatValue];
	}
	
	// Now we call edit, which opens up the config sheet
	[self edit:YES];
}

/**
 Called when the window becomes the key window.
 That is, the window the user is currently using.
**/
- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	[transparentView windowDidBecomeKey:aNotification];
}

/**
 Called when the window ceases to be the key window.
 That is, the window is no longer the window the user is currently using.
**/
- (void)windowDidResignKey:(NSNotification *)aNotification
{
	[transparentView windowDidResignKey:aNotification];
}

/**
 Called when the window is about to display a sheet.
 We alter the standard sheet position, since we're drawing our own title bar within the view.
 We want the sheet to be displayed within our title bar instead of within the invisible window title bar.
 
 Since this class isn't in charge of drawing the window, or the title bar, we don't actually know where it is,
 or how big it is.  We forward the call to a class that does know.
**/
- (NSRect)window:(NSWindow *)theWindow willPositionSheet:(NSWindow *)theSheet usingRect:(NSRect)theRect
{
	return [transparentView window:theWindow willPositionSheet:theSheet usingRect:theRect];
}

/**
 Called automatically when the window moves.
 This is called when the user is dragging the window around.
 Note that it is not called when the user is resizing the window, even though the window is also technically moving.
 Guess the Cocoa guys realized there's no need to call both during a resize.  Good call!
**/
- (void)windowDidMove:(NSNotification *)aNotification
{
	[[self window] saveFrameUsingName:WINDOW_KEY];
}

/**
 Called automatically when the window resizes.
 This is called while the user is resizing the window.
**/
- (void)windowDidResize:(NSNotification *)aNotification
{
	[[self window] saveFrameUsingName:WINDOW_KEY];
}

- (void)windowDidMiniaturize:(NSNotification *)aNotification
{
	if([timer isValid])
	{
		miniWindowTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0
															target:self
														  selector:@selector(updateMiniWindow:)
														  userInfo:nil
														   repeats:YES] retain];
	}
}

- (void)windowDidDeminiaturize:(NSNotification *)aNotification
{
	[miniWindowTimer invalidate];
	[miniWindowTimer release];
	miniWindowTimer = nil;
}

/**
 Called when the window is about to close.
**/
- (void)windowWillClose:(NSNotification *)aNotification
{
	// Stop the timer
	[timer invalidate];
	
	// Post notification for closed timer
	// This informs the WindowManager to remove the timer from it's list of open timer windows
	[[NSNotificationCenter defaultCenter] postNotificationName:@"TimerClosed" object:self];
	
	// Release self
	[self autorelease];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Correspondence Info Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)shouldDisplayCloseButton
{
	return YES;
}

- (BOOL)shouldDisplayMinimizeButton
{
	return YES;
}

- (BOOL)shouldDisplayModifierButtons
{
	return YES;
}

- (NSString *)title
{
	return titleStr;
}

- (NSString *)statusLine1
{
	return totalTimeStr;
}

- (NSString *)statusLine2
{
	return [self formatTime:totalTime];
}

- (NSString *)leftModifierStr
{
	return @"-";
}

- (NSString *)rightModifierStr
{
	return @"+";
}

- (NSString *)timeStr
{
	if([timer isValid])
	{
		float timeLeft = totalTime - (elapsedTime + [[NSDate date] timeIntervalSinceDate:startDate]);
		return [self formatTime:timeLeft];
	}
	else
	{
		float timeLeft = totalTime - elapsedTime;
		return [self formatTime:timeLeft];
	}
}

- (NSString *)leftButtonStr
{
	if([timer isValid])
		return pauseStr;
	else
		return startStr;
}

- (NSString *)rightButtonStr
{
	if([timer isValid])
		return resetStr;
	else
		return editStr;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Correspondence Action Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)statusLineClicked
{
	// This is ignored.  Nothing to do here for now.
}

/**
 Minus button clicked by user.
 We decrease the total time by 1 minute. (If this won't make the timer immediately go off)
**/
- (void)leftModifierClicked
{
	// We have to be careful when decreasing the totalTime, as this may immediately sound the alarm
	float timeLeft;
	
	if(!isStarted)
	{
		// The timer has finished, and the user is decreasing the time with the minus button
		// This means they want to use it again, so we reset the elapsedTime
		// This will have the effect of displaying the totalTime in the time field, just as if they clicked reset
		elapsedTime = 0.0;
		
		// So the timeLeft is simply the totalTime
		timeLeft = totalTime;
	}
	else if([timer isValid])
	{
		// The timer is active, so the timeLeft is calculated traditionally, using the startDate
		timeLeft = totalTime - (elapsedTime + [[NSDate date] timeIntervalSinceDate:startDate]);
	}
	else
	{
		// The timer is paused, so the timeLeft is calculated traditionally
		timeLeft = elapsedTime;
	}
	
	// Now we can decrease the time, but only if it doesn't put us below (or at) zero
	int amountToDecrease;
	if([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
		amountToDecrease = (60 * 5);
	else
		amountToDecrease = 60;
	
	if((timeLeft > amountToDecrease) && (totalTime > amountToDecrease))
	{
		totalTime -= amountToDecrease;
	}
}

/**
 Plus button clicked by user.
 We increase the total time by 1 minute.
**/
- (void)rightModifierClicked
{
	// We can always simply increase the total time
	if([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
		totalTime += (60 * 5);
	else
		totalTime += 60;
	
	// Remember: elapsedTime == totalTime, after the timer has finished
	// So if we blindly update only the totalTime at this point, there will be 1 minute left...
	if(!isStarted)
	{
		// The timer has finished, and the user is increasing the time with the plus button
		// This means they want to use it again, so we reset the elapsedTime
		// This will have the effect of displaying the totalTime in the time field, just as if they clicked reset
		elapsedTime = 0.0;
	}
}

/**
 Start or Pause button clicked by user
**/
- (void)leftButtonClicked
{
	if([timer isValid])
		[self pause];
	else
		[self start];
}

/**
 Reset or Edit button clicked by user
**/
- (void)rightButtonClicked
{
	if([timer isValid])
		[self reset];
	else
		[self edit:NO];
}

- (BOOL)canSystemSleep
{
	// The only reason to prevent sleep is if the timer is active
	if([timer isValid])
		return NO;
	else
		return YES;
}

/**
 Called prior to the system going to sleep.
 We need to return the time at which the timer will go off.
**/
- (NSCalendarDate *)systemWillSleep
{
	if([timer isValid])
	{
		float timeLeft = totalTime - (elapsedTime + [[NSDate date] timeIntervalSinceDate:startDate]);
		
		// Now return the time at which the timer should go off
		NSDate *temp = [NSDate dateWithTimeIntervalSinceNow:timeLeft];
		return [temp dateWithCalendarFormat:nil timeZone:nil];
	}
	else
	{
		return nil;
	}
}

/**
 Called after the system wakes from sleep.
 We update the elapsed time to keep the timer accurate.
**/
- (void)systemDidWake
{
	// Nothing to reset or recalculate here
	// It's all done on the fly
	// But we should immediately update the window
	
	// Notify NSView that it needs to redraw itself
	[transparentView setNeedsDisplay:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Action Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Starts the Timer.
**/
- (void)start
{
	// Store start time
	[startDate release];
	startDate = [[NSDate date] retain];
	
	// Start the timer
	[timer release];
	timer = [[NSTimer scheduledTimerWithTimeInterval:0.5
											  target:self
											selector:@selector(updateAndCheck:)
											userInfo:nil
											 repeats:YES] retain];
	
	// If starting for the first time, or after a reset (as in not unpausing)
	if(!isStarted)
	{
		// Reset the time
		elapsedTime = 0.0;
		
		// Set status as started
		isStarted = YES;
	}
}

/**
 Pauses the Timer.
**/
- (void)pause
{
	// Update elapsed time
	elapsedTime += [[NSDate date] timeIntervalSinceDate:startDate];
	
	// Stop the timer
	[timer invalidate];
}

/**
 Stops the timer, and resets the time.
**/
- (void)reset
{
	// Set status as unstarted
	isStarted = NO;
	
	// Reset the elapsed time
	elapsedTime = 0.0;
	
	// Stop the timer
	[timer invalidate];
}

/**
 Brings up the configuration sheet to allow editing of the timer properties.
**/
- (void)edit:(BOOL)isInitialSetup
{
	// Setup config panel
	NSArray *recent = [[NSUserDefaults standardUserDefaults] arrayForKey:RECENT_TIMERS_KEY];
	if(recent)
	{
		[nameField removeAllItems];
		
		int i;
		for(i = 0; i < [recent count]; i++)
		{
			NSDictionary *recentDict = [recent objectAtIndex:i];
			NSString *name = [recentDict objectForKey:RECENT_NAME_KEY];
			if(name) {
				[nameField addItemWithObjectValue:name];
			}
		}
	}
	
	// Set the proper first responder
	// It's important that we do this before setting the timeField, because if the nameField previously had focus,
	// then making the timeField the first responder would cause the nameField to fire, updating the timeField.
	// This is a problem if the user had modified the time using the plus/minus buttons.
	if(isInitialSetup)
		[nameField selectText:self];
	else
		[configPanel makeFirstResponder:timeField];
	
	[nameField setStringValue:titleStr];
	
	NSDate *currentDate = [[timeField minDate] addTimeInterval:totalTime];
	[timeField setDateValue:currentDate];
	
	[alwaysOnTopButton setState:([[self window] level] == NSStatusWindowLevel) ? NSOnState: NSOffState];
	
	[useAlarmVolumeButton setState:(useAlarmVolume) ? NSOnState : NSOffState];
	
	// Present the config sheet
	[NSApp beginSheet:configPanel modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:NULL];
}

/**
 Called when the name field is changed.
 That is, it's called immediately after a user selects a name from the drop down list, or
 when a user types in a name and navigates away from the name field.
**/
- (IBAction)nameDidChange:(id)sender
{
	// Look through the list of recent timers
	// If the user selected a name that's in the recent timers list, update the time to match
	
	NSArray *recent = [[NSUserDefaults standardUserDefaults] arrayForKey:RECENT_TIMERS_KEY];
	
	int i;
	BOOL done = NO;
	for(i = 0; i < [recent count] && !done; i++)
	{
		NSDictionary *dict = [recent objectAtIndex:i];
		NSString *name = [dict objectForKey:RECENT_NAME_KEY];
		
		if([[sender stringValue] isEqualToString:name])
		{
			float time = [[dict objectForKey:RECENT_TIME_KEY] floatValue];
			
			NSDate *currentDate = [[timeField minDate] addTimeInterval:time];
			[timeField setDateValue:currentDate];
			
			done = YES;
		}
	}
}

- (IBAction)closeConfigPanel:(id)sender
{
	// Close the configPanel and end the sheet
	[configPanel orderOut:self];
	[NSApp endSheet:configPanel];
	
	// Store the new name
	// NSComboBox works in a somewhat unintuitive manner
	// The stringValue is NOT the same as the objectValue of the selected item
	[titleStr release];
	if([nameField indexOfSelectedItem] >= 0)
		titleStr = [[nameField objectValueOfSelectedItem] retain];
	else
		titleStr = [[nameField stringValue] retain];
	
	// Update title of actual window to match what we'll display
	[[self window] setTitle:titleStr];
	[[self window] setMiniwindowTitle:titleStr];
	
	// Update the times
	totalTime = [[timeField dateValue] timeIntervalSinceDate:[timeField minDate]];
	elapsedTime = 0.0;
	
	// Store the entered name and time in the recent list
	NSMutableDictionary *recentEntry = [NSMutableDictionary dictionaryWithCapacity:2];
	[recentEntry setObject:titleStr forKey:RECENT_NAME_KEY];
	[recentEntry setObject:[NSNumber numberWithFloat:totalTime] forKey:RECENT_TIME_KEY];
	
	NSArray *recent = [[NSUserDefaults standardUserDefaults] arrayForKey:RECENT_TIMERS_KEY];
	if(recent == nil)
	{
		recent = [NSArray arrayWithObject:recentEntry];
		[[NSUserDefaults standardUserDefaults] setObject:recent forKey:RECENT_TIMERS_KEY];
	}
	else
	{
		NSMutableArray *mRecent = [[recent mutableCopy] autorelease];
		
		int i;
		for(i = [mRecent count]-1; i >= 0; i--)
		{
			NSDictionary *dict = [mRecent objectAtIndex:i];
			NSString *name = [dict objectForKey:RECENT_NAME_KEY];
			
			if([titleStr isEqualToString:name])
			{
				[mRecent removeObjectAtIndex:i];
			}
		}
		
		[mRecent insertObject:recentEntry atIndex:0];
		
		if([mRecent count] > 10)
		{
			[mRecent removeObjectsInRange:NSMakeRange(10, [mRecent count]-10)];
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:mRecent forKey:RECENT_TIMERS_KEY];
	}
	
	// Update window to match "always on top preference"
	BOOL alwaysOnTop = [alwaysOnTopButton state] == NSOnState;
	if(alwaysOnTop)
		[[self window] setLevel:NSStatusWindowLevel];
	else
		[[self window] setLevel:NSNormalWindowLevel];
	
	// Store always on top preference
	[[NSUserDefaults standardUserDefaults] setBool:alwaysOnTop forKey:WINDOW_ON_TOP_KEY];
	
	// Update useAlarmVolume preference
	useAlarmVolume = [useAlarmVolumeButton state] == NSOnState;
	
	// Store useAlarmVolume preference
	[[NSUserDefaults standardUserDefaults] setBool:useAlarmVolume forKey:USE_ALARM_VOLUME_KEY];
	
	// Start the timer
	[self start];
	
	// And update the view
	[transparentView setNeedsDisplay:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Events:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Methods called by timer
- (void)updateAndCheck:(NSTimer *)aTimer
{
	float timeLeft = totalTime - (elapsedTime + [[NSDate date] timeIntervalSinceDate:startDate]);
	
	// If we've counted all the way down to zero
	if(timeLeft <= 0.0)
	{
		NSLog(@"Timer is complete!");
		
		// Set the elapsed time to the total time
		// This ensures that the timer won't go below zero
		elapsedTime = totalTime;
		
		// Stop the timer
		[timer invalidate];
		
		// Set status as unstarted
		isStarted = NO;
		
		// If we're supposed to use the alarm volume, then we need to set that up...
		if(useAlarmVolume)
		{
			// Setup core audio device for changing system volume
			MTCoreAudioDevice *outputDevice = [MTCoreAudioDevice defaultOutputDevice];
			
			// Store the initial system volume
			// These get restored after the movie is stopped
			initialLeftVolume  = [outputDevice volumeForChannel:1 forDirection:kMTCoreAudioDevicePlaybackDirection];
			initialRightVolume = [outputDevice volumeForChannel:2 forDirection:kMTCoreAudioDevicePlaybackDirection];
			
			// Make sure the volume is unmuted
			[outputDevice setMute:NO forChannel:0 forDirection:kMTCoreAudioDevicePlaybackDirection];
			
			// Get preferred alarm volumn
			float preferredVolume = [Prefs prefVolume];
			
			// Set volume for left and right speakers, respectively
			[outputDevice setVolume:preferredVolume forChannel:1 forDirection:kMTCoreAudioDevicePlaybackDirection];
			[outputDevice setVolume:preferredVolume forChannel:2 forDirection:kMTCoreAudioDevicePlaybackDirection];
		}
		
		// Deminiaturize the timer window if needed
		if([[self window] isMiniaturized])
		{
			[[self window] deminiaturize:self];
		}
		
		// And finally, play our little tune
		[movie play];
	}
	
	// Notify NSView that it needs to redraw itself
	[transparentView setNeedsDisplay:YES];
}

/**
 Invoked when a key on the keyboard is pressed.
**/
- (void)keyDown:(NSEvent *)event
{
	//NSLog(@"keyDown: %hu", [event keyCode]);
	
	if([event keyCode] == 49)
	{
		if([timer isValid])
			[self pause];
		else
			[self start];
		
		[transparentView setNeedsDisplay:YES];
	}
}

- (void)movieFinished:(NSNotification *)notification
{
	// This method is called for every movie in the application finishing
	// Check to make sure the movie is the one we're looking for
	if(movie == [notification object])
	{
		// If we are using the alarm volume
		if(useAlarmVolume)
		{
			// Reset the volume to what it was before the timer went off
			MTCoreAudioDevice *outputDevice = [MTCoreAudioDevice defaultOutputDevice];
			
			[outputDevice setVolume:initialLeftVolume  forChannel:1 forDirection:kMTCoreAudioDevicePlaybackDirection];
			[outputDevice setVolume:initialRightVolume forChannel:2 forDirection:kMTCoreAudioDevicePlaybackDirection];
		}
	}
}

- (void)updateMiniWindow:(NSTimer *)aTimer
{
	if(bmpImageRep == nil)
	{
		bmpImageRep = [[transparentView bitmapImageRepForCachingDisplayInRect:[transparentView visibleRect]] retain];
	}
	[transparentView cacheDisplayInRect:[transparentView visibleRect] toBitmapImageRep:bmpImageRep];
	
	if(miniWindowImage == nil)
	{
		miniWindowImage = [[NSImage alloc] init];
		[miniWindowImage addRepresentation:bmpImageRep];
	}
	
	[[self window] setMiniwindowImage:miniWindowImage];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Helper Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *)formatTime:(float)timeInterval
{
	// We're about to truncate the milliseconds
	// However, we're counting down, so we need to not display 5 seconds left if there's 5.9 seconds left
	int totalSeconds = (int)(ceilf(timeInterval));
	
	int hours   = totalSeconds / 3600;
	int minutes = (totalSeconds % 3600) / 60;
	int seconds = totalSeconds % 60;
	
	NSString *hString, *mString, *sString;
	
	if(hours < 10)
		hString = [NSString stringWithFormat:@"0%i", hours];
	else
		hString = [NSString stringWithFormat:@"%i", hours];
	
	if(minutes < 10)
		mString = [NSString stringWithFormat:@"0%i", minutes];
	else
		mString = [NSString stringWithFormat:@"%i", minutes];
	
	if(seconds < 10)
		sString = [NSString stringWithFormat:@"0%i", seconds];
	else
		sString = [NSString stringWithFormat:@"%i", seconds];
	
	return [NSString stringWithFormat:@"%@:%@:%@", hString, mString, sString];
}

@end
