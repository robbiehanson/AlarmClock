#import "StopwatchController.h"

#define WINDOW_KEY           @"StopwatchWindow"
#define ORIGINAL_WINDOW_KEY  @"StopwatchWindowOriginal"
#define WINDOW_ON_TOP_KEY    @"StopwatchAlwaysOnTop"

@interface StopwatchController (PrivateAPI)
- (void)start;
- (void)pause;
- (void)lapSplit;
- (void)reset;
- (void)openConfigPanel;
- (NSString *)formatTime:(float)timeInterval;
@end

@implementation StopwatchController

// INIT, DEALLOC
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Initializes object with proper nib
**/
- (id)init
{
	if(self = [super initWithWindowNibName:@"StopwatchWindow"])
	{
		// Initialize time tracking info
		isStarted = NO;
		lapElapsedTime = 0.0;
		splitElapsedTime = 0.0;
		
		// Initialize lap/split info
		isLapMode = YES;
		lapSplitIndex = 0;
		laps = [[NSMutableArray alloc] init];
		splits = [[NSMutableArray alloc] init];
		
		// Initialize time formatter
		timeFormatter = [[NSDateFormatter alloc] init];
		[timeFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[timeFormatter setDateStyle:NSDateFormatterNoStyle];
		[timeFormatter setTimeStyle:NSDateFormatterMediumStyle];
		
		// Initialize localized strings
		titleStr     = [NSLocalizedStringFromTable(@"Stopwatch",  @"StopwatchWindow", @"Window title") retain];
		readyStr     = [NSLocalizedStringFromTable(@"Ready",      @"StopwatchWindow", @"Status line - displays before starting") retain];
		startedAtStr = [NSLocalizedStringFromTable(@"Started At", @"StopwatchWindow", @"Status line - displays when started") retain];
		lapXStr      = [NSLocalizedStringFromTable(@"Lap %i",     @"StopwatchWindow", @"Status line - displays lap mode info") retain];
		splitXStr    = [NSLocalizedStringFromTable(@"Split %i",   @"StopwatchWindow", @"Status line - displays split mode info") retain];
		startStr     = [NSLocalizedStringFromTable(@"Start",      @"StopwatchWindow", @"Button Title") retain];
		pauseStr     = [NSLocalizedStringFromTable(@"Pause",      @"StopwatchWindow", @"Button Title") retain];
		resetStr     = [NSLocalizedStringFromTable(@"Reset",      @"StopwatchWindow", @"Button Title") retain];
		lapSplitStr  = [NSLocalizedStringFromTable(@"Lap/Split",  @"StopwatchWindow", @"Button Title") retain];
	}
	return self;
}

/**
 Called after laoding the nib file
 Configures gui elements
**/
- (void)awakeFromNib
{
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
	NSLog(@"Destroying %@", self);
	
	// Release timer
	[timer release];
	
	// Release start date
	[startDate release];
	
	// Release lap/split info stuff
	[laps release];
	[splits release];
	[timeFormatter release];
	
	// Release localized and stored strings
	[titleStr release];
	[readyStr release];
	[startedAtStr release];
	[lapXStr release];
	[splitXStr release];
	[startStr release];
	[pauseStr release];
	[resetStr release];
	[lapSplitStr release];
	
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
	// Now we display the config panel as a sheet
	[self openConfigPanel];
	
	// Big Important Note:
	// Make sure the stopwatch window is set to "visible at launch time",
	// or else the sheet won't be properly attached to the window
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"StopwatchClosed" object:self];
	
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
	// Only display the buttons when we have laps to loop through
	return ([laps count] > 1);
}

- (NSString *)title
{
	return titleStr;
}

- (NSString *)statusLine1
{
	if(![timer isValid] && splitElapsedTime == 0)
	{
		// The stopwatch hasn't been started yet
		return readyStr;
	}
	
	if(lapSplitIndex == 0)
	{
		// First index is always start time
		return startedAtStr;
	}
	
	if(isLapMode)
		return [NSString stringWithFormat:lapXStr, lapSplitIndex];
	else
		return [NSString stringWithFormat:splitXStr, lapSplitIndex];
}

- (NSString *)statusLine2
{
	if(![timer isValid] && splitElapsedTime == 0)
	{
		// The stopwatch hasn't been started yet
		return @"";
	}
	
	if(isLapMode)
		return [laps objectAtIndex:lapSplitIndex];
	else
		return [splits objectAtIndex:lapSplitIndex];
}

- (NSString *)leftModifierStr
{
	return @"<";
}

- (NSString *)rightModifierStr
{
	return @">";
}

- (NSString *)timeStr
{
	if([timer isValid])
	{
		float totalTime = splitElapsedTime + [[NSDate date] timeIntervalSinceDate:startDate];
		return [self formatTime:totalTime];
	}
	else
	{
		return [self formatTime:splitElapsedTime];
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
		return lapSplitStr;
	else
		return resetStr;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Correspondence Action Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Status Line 1 or 2 clicked
**/
- (void)statusLineClicked
{
	// Switch between lap mode and split mode
	isLapMode = !isLapMode;
}

/**
 Minus button clicked - go to the previous lap/split in the list
**/
- (void)leftModifierClicked
{
	lapSplitIndex--;
	if(lapSplitIndex < 0)
	{
		lapSplitIndex = [laps count] - 1;
	}
}

/**
 Plus button clicked - go to next lap/split in the list
**/
- (void)rightModifierClicked
{
	lapSplitIndex = (lapSplitIndex + 1) % [laps count];
}

/**
 Pause or Start button was clicked
**/
- (void)leftButtonClicked
{
	if([timer isValid])
		[self pause];
	else
		[self start];
}

/**
 Reset or Lap/Split button was clicked
**/
- (void)rightButtonClicked
{
	if([timer isValid])
		[self lapSplit];
	else
		[self reset];
}

- (BOOL)canSystemSleep
{
	// The only reason to prevent sleep is if the stopwatch is active
	if([timer isValid])
		return NO;
	else
		return YES;
}

/**
 Called prior to the system going to sleep.
 We don't actually need to wake the computer at any time, so we return nil.
 However, we may need to prepare for sleep.
**/
- (NSCalendarDate *)systemWillSleep
{
	// Nothing to do here
	// Total time is calculated using the elapsed times, and the startDate
	// If the timer is currently firing, it will continue to fire after sleep
	
	// We don't actually need to wake the computer at any time, so return nil
	return nil;
}

/**
 Called after the system wakes from sleep.
 We update the elapsed time to keep the stopwatch accurate.
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
		// Store the start time into the lap/split arrays		
		[laps removeAllObjects];
		[splits removeAllObjects];
		
		[laps addObject:[timeFormatter stringFromDate:startDate]];
		[splits addObject:[timeFormatter stringFromDate:startDate]];
		
		// Set status as started
		isStarted = YES;
	}
}

- (void)pause
{
	// Update elapsed times
	NSDate *now = [NSDate date];
	lapElapsedTime += [now timeIntervalSinceDate:startDate];
	splitElapsedTime += [now timeIntervalSinceDate:startDate];
	
	// Stop the timer
	[timer invalidate];
}

- (void)lapSplit
{
	// Update elapsed times
	NSDate *now = [NSDate date];
	lapElapsedTime += [now timeIntervalSinceDate:startDate];
	splitElapsedTime += [now timeIntervalSinceDate:startDate];
	
	// Store new start time
	[startDate release];
	startDate = [now retain];
	
	// Add the current times to the arrays
	[laps addObject:[self formatTime:lapElapsedTime]];
	[splits addObject:[self formatTime:splitElapsedTime]];
	
	// Set the lapSplitIndex to be the time that was just added
	// This will force the new time to be displayed
	lapSplitIndex = [laps count] - 1;
	
	// Reset the lap time
	// Remember: laps always start over from zero... but don't forget about those leftover milliseconds
	lapElapsedTime = splitElapsedTime - (int)splitElapsedTime;
}

- (void)reset
{	
	// Set status as unstarted
	isStarted = NO;
	
	// Reset the elapsed time
	lapElapsedTime = 0.0;
	splitElapsedTime = 0.0;
	
	// Clear the list of laps and splits, and reset lapSplitIndex
	[laps removeAllObjects];
	[splits removeAllObjects];
	lapSplitIndex = 0;

	// Stop the timer
	[timer invalidate];
	
	// And open up the config panel, so the user is able to set a new name for the stopwatch window if they want
	[self openConfigPanel];
}

- (void)openConfigPanel
{
	// Setup config panel
	[nameField setStringValue:titleStr];
	[nameField selectText:self];
	
	[alwaysOnTopButton setState:([[self window] level] == NSStatusWindowLevel) ? NSOnState: NSOffState];
	
	// Present the config sheet
	[NSApp beginSheet:configPanel modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:NULL];
}

- (IBAction)closeConfigPanel:(id)sender
{
	// Close the configPanel and end the sheet
	[configPanel orderOut:self];
	[NSApp endSheet:configPanel];
	
	// Store the new name
	[titleStr release];
	titleStr = [[nameField stringValue] retain];
	
	// Update title of actual window to match what we'll display
	[[self window] setTitle:titleStr];
	[[self window] setMiniwindowTitle:titleStr];
	
	// Update window to match "always on top preference"
	BOOL alwaysOnTop = [alwaysOnTopButton state] == NSOnState;
	if(alwaysOnTop)
		[[self window] setLevel:NSStatusWindowLevel];
	else
		[[self window] setLevel:NSNormalWindowLevel];
	
	// Store always on top preference
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:alwaysOnTop] forKey:WINDOW_ON_TOP_KEY];
	
	// Start the stopwatch
	[self start];
	
	// And update the view
	[transparentView setNeedsDisplay:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Events:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)updateAndCheck:(NSTimer *)aTimer
{
	// Notify NSView that it needs to redraw itself
	[transparentView setNeedsDisplay:YES];
}

/**
 Invoked when a key on the keyboard is pressed.
**/
- (void)keyDown:(NSEvent *)event
{
	//NSLog(@"keyDown: %hu", [event keyCode]);
	
	if([event keyCode] == 49) /* Space Bar */
	{
		if([timer isValid])
			[self pause];
		else
			[self start];
		
		[transparentView setNeedsDisplay:YES];
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
	int totalSeconds = (int)timeInterval;
	
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
