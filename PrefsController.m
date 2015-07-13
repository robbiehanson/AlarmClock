#import "PrefsController.h"
#import "Prefs.h"
#import "AlarmTasks.h"
#import "AppleRemote.h"

#import <Sparkle/Sparkle.h>

@interface PrefsController (PrivateAPI)
- (BOOL)isLoginItem;
- (void)switchViews:(NSToolbarItem *)item;
- (void)addLoginItem;
- (void)deleteLoginItem;
@end

@implementation PrefsController

- (void)awakeFromNib
{
	// Initialize items dictionary
	// This will hold all the toolbar items
	items = [[NSMutableDictionary alloc] init];
    
	// Create all toolbar items and add them to our items dictionary
	
    NSToolbarItem *item1 = [[[NSToolbarItem alloc] initWithItemIdentifier:@"General"] autorelease];
    [item1 setLabel:NSLocalizedString(@"General", @"Preference Pane Option")];
    [item1 setImage:[NSImage imageNamed:@"General.png"]];
    [item1 setTarget:self];
    [item1 setAction:@selector(switchViews:)];
	
	NSToolbarItem *item2 = [[[NSToolbarItem alloc] initWithItemIdentifier:@"Easy Wake"] autorelease];
    [item2 setLabel:NSLocalizedString(@"Easy Wake", @"Preference Pane Option")];
    [item2 setImage:[NSImage imageNamed:@"Sound.png"]];
    [item2 setTarget:self];
    [item2 setAction:@selector(switchViews:)];
	
	NSToolbarItem *item3 = [[[NSToolbarItem alloc] initWithItemIdentifier:@"Advanced"] autorelease];
    [item3 setLabel:NSLocalizedString(@"Advanced", @"Preference Pane Option")];
    [item3 setImage:[NSImage imageNamed:@"Advanced.png"]];
    [item3 setTarget:self];
    [item3 setAction:@selector(switchViews:)];
	
	NSToolbarItem *item4 = [[[NSToolbarItem alloc] initWithItemIdentifier:@"Software Update"] autorelease];
    [item4 setLabel:NSLocalizedString(@"Software Update", @"Preference Pane Option")];
    [item4 setImage:[NSImage imageNamed:@"SoftwareUpdate.png"]];
    [item4 setTarget:self];
    [item4 setAction:@selector(switchViews:)];
	
    [items setObject:item1 forKey:[item1 itemIdentifier]];
	[items setObject:item2 forKey:[item2 itemIdentifier]];
	[items setObject:item3 forKey:[item3 itemIdentifier]];
	[items setObject:item4 forKey:[item4 itemIdentifier]];
	
    // Any other items you want to add, do so here.
    // After you are done, just do all the toolbar stuff.
	
    toolbar = [[[NSToolbar alloc] initWithIdentifier:@"PreferencePanes"] autorelease];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    
	[window setToolbar:toolbar];
	[window setShowsToolbarButton:NO];
	
	// Now setup all the controls
	
	// Alarms
	[coloredIconsButton setState:([Prefs useColoredIcons] ? NSOnState : NSOffState)];
	
	[prefVolumeSlider setIntValue:([Prefs prefVolume] * 100)];
	[self setPrefVolume:prefVolumeSlider];
	
	[snoozeDurationSlider setIntValue:[Prefs snoozeDuration]];
	[self setSnoozeDuration:snoozeDurationSlider];
	
	[killDurationSlider setIntValue:[Prefs killDuration]];
	[self setKillDuration:killDurationSlider];
	
	// Easy wake
	[easyWakeDefaultButton setState:([Prefs useEasyWakeByDefault] ? NSOnState : NSOffState)];
	
	[minVolumeSlider setIntValue:([Prefs minVolume] * 100)];
	[self setMinVolume:minVolumeSlider];
	
	[maxVolumeSlider setIntValue:([Prefs maxVolume] * 100)];
	[self setMaxVolume:maxVolumeSlider];
	
	[easyWakeDurationSlider setIntValue:[Prefs easyWakeDuration]];
	[self setEasyWakeDuration:easyWakeDurationSlider];
	
	// Advanced
	[wakeFromSleepButton setState:([Prefs wakeFromSleep] ? NSOnState: NSOffState)];
	[deauthenticateButton setEnabled:[Prefs wakeFromSleep]];
	
	[keyboardType selectCellAtRow:([Prefs anyKeyStops] ? 0 : 1) column:0];
	
	[appleRemoteButton setState:([Prefs supportAppleRemote] ? NSOnState : NSOffState)];
	[appleRemoteButton setEnabled:[[AppleRemote sharedRemote] isRemoteAvailable]];
	
	[loginButton setState:([Prefs launchAtLogin] ? NSOnState: NSOffState)];
	
	// Software Update
	int updateInterval = [[NSUserDefaults standardUserDefaults] integerForKey:SUScheduledCheckIntervalKey];
	[checkForUpdatesButton setState:(updateInterval > 0) ? NSOnState : NSOffState];
	
	if(updateInterval == 0) {
		// Select default item "Weekly"
		[updateIntervalPopup setEnabled:NO];
		[updateIntervalPopup selectItemAtIndex:1];
	}
	else if(updateInterval == 86400) {
		[updateIntervalPopup selectItemAtIndex:0];
	}
	else if(updateInterval == 604800) {
		[updateIntervalPopup selectItemAtIndex:1];
	}
	else if(updateInterval == 2592000) {
		[updateIntervalPopup selectItemAtIndex:2];
	}
	else {
		// The updateInterval has been corrupted - reset to zero
		updateInterval = 0;
		[[NSUserDefaults standardUserDefaults] setInteger:updateInterval forKey:SUScheduledCheckIntervalKey];
		[updateIntervalPopup setEnabled:NO];
		[updateIntervalPopup selectItemAtIndex:1];
	}
	
	// Switch to the default view
	[self switchViews:nil];
	
	// Don't center the window til after we've switched the view, or else it will center that small window stub
	[window center];
	
	// Check that wake from sleep is possible if "wake from sleep" option is selected
	if([Prefs wakeFromSleep] && ![AlarmTasks isAuthenticated])
	{
		// Preferences do not match system!  Bring to users attention
		
		// Deslect the wake from sleep option
		[wakeFromSleepButton setState:NSOffState];
		// Disable deauthenticate button and change preference
		[self toggleWakeFromSleep:wakeFromSleepButton];
		
		// Display the prefs window
		[window makeKeyAndOrderFront:nil];
		
		// Bring application to the front
		[NSApp activateIgnoringOtherApps:YES];
		
		// Display the information window
		NSString *title = NSLocalizedString(@"Reauthentication Required", @"Dialog Title");
		NSString *message = NSLocalizedString(@"Internal components of the application have changed. Reauthentication is required to wake the computer from sleep.", @"Dialog Message");
		NSString *okButton = NSLocalizedString(@"OK", @"Dialog Button");
		NSBeginAlertSheet(title, okButton, nil, nil, window, self, NULL, NULL, nil, message);
		
		// Also, this means that the user is upgrading their app
		// So turn off isFirstRun because they don't need the welcome message
		[Prefs setIsFirstRun:NO];
	}
	
	// Check that loginButton state matches loginItem
	if([self isLoginItem])
	{
		if(![Prefs launchAtLogin])
		{
			// User manually added login item
			// Check box, but do not set preference
			[loginButton setState:NSOnState];
		}
	}
	else
	{
		if([Prefs launchAtLogin])
		{
			// User manually removed login item
			// Preferences do not match system!  Bring to users attention
			
			// Deselect login button
			[loginButton setState:NSOffState];
			// Change preference
			[self toggleLogin:loginButton];
			
			// Display the prefs window
			[window makeKeyAndOrderFront:nil];
			
			// Bring application to the front
			[NSApp activateIgnoringOtherApps:YES];
		}
	}
}

- (BOOL)isLoginItem
{
	/*  Execute the following AppleScript command:
	
	tell application "System Events"
		if "Alarm Clock" is in (name of every login item) then
			return yes
		else
			return no
		end if
	end tell
	*/
	
	NSMutableString *command = [NSMutableString string];
	[command appendString:@"tell application \"System Events\" \n"];
	[command appendString:@"if \"Alarm Clock\" is in (name of every login item) then \n"];
	[command appendString:@"return yes \n"];
	[command appendString:@"else \n"];
	[command appendString:@"return no \n"];
	[command appendString:@"end if \n"];
	[command appendString:@"end tell"];
	
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:command];
	NSAppleEventDescriptor *ae = [script executeAndReturnError:nil];
	
	[script autorelease];
	
	return [[ae stringValue] hasPrefix:@"yes"];
}

/**
 * This method is called everytime a toolbar item is clicked.
 * If item is nil, switch to the default toolbar item ("General")
**/
- (void)switchViews:(NSToolbarItem *)item
{
    NSString *sender;
    if(item == nil) {
		// Set the pane to the default view
		sender = @"Advanced";
		[toolbar setSelectedItemIdentifier:sender];
		// And set the item to be toolbar item for this view
		item = [items objectForKey:sender];
    }
	else {
        sender = [item itemIdentifier];
    }
	
    // Make a temp pointer.
    NSView *prefsView = nil;
	
    // Set the title to the name of the Preference Item.
    [window setTitle:[item label]];
	
    if([sender isEqualToString:@"General"]) {
		prefsView = generalView;
	}
	else if([sender isEqualToString:@"Easy Wake"]) {
		prefsView = easyWakeView;
	}
	else if([sender isEqualToString:@"Advanced"]) {
		prefsView = advancedView;
	}
	else if([sender isEqualToString:@"Software Update"]) {
		prefsView = softwareUpdateView;
	}
    
	// To stop flicker, we make a temp blank view.
	NSView *tempView = [[NSView alloc] initWithFrame:[[window contentView] frame]];
	[window setContentView:tempView];
	[tempView release];
    
	// Mojo to get the right frame for the new window.
	NSRect newFrame = [window frame];
	newFrame.size.height = [prefsView frame].size.height + ([window frame].size.height - [[window contentView] frame].size.height);
	newFrame.size.width = [prefsView frame].size.width;
	newFrame.origin.y += ([[window contentView] frame].size.height - [prefsView frame].size.height);
	
	// Set the frame to newFrame and animate it. (change animate:YES to animate:NO if you don't want this)
	[window setFrame:newFrame display:YES animate:YES];
	// Set the main content view to the new view we have picked through the if structure above.
	[window setContentView:prefsView];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Toolbar delegate methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return [items objectForKey:itemIdentifier];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)theToolbar
{
    return [self toolbarDefaultItemIdentifiers:theToolbar];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)theToolbar
{
    // Make sure we arrange the identifiers in the correct order
	return [NSArray arrayWithObjects:@"General", @"Easy Wake", @"Advanced", @"Software Update", nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    // Make all of them selectable. This puts that little grey outline thing around an item when you select it.
    return [items allKeys];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark General Options:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction)toggleColoredIcons:(id)sender
{
	[Prefs setUseColoredIcons:[sender state]];
	
	// Post notification for changed alarm
	// This is to allow the menu to properly change it's icon
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AlarmChanged" object:self];
}

- (IBAction)setPrefVolume:(id)sender
{
	NSString *format = NSLocalizedString(@"%i%%", @"Label in Preferences panel");
	
	[prefVolumeLabel setStringValue:[NSString stringWithFormat:format, [sender intValue]]];
	
	float value = [sender intValue] / 100.0;
	[Prefs setPrefVolume:value];
}

- (IBAction)setSnoozeDuration:(id)sender
{
	NSString *format = NSLocalizedString(@"%i minutes", @"Label in Preferences panel");
	
	[snoozeDurationLabel setStringValue:[NSString stringWithFormat:format, [sender intValue]]];
	[Prefs setSnoozeDuration:[sender intValue]];
}

- (IBAction)setKillDuration:(id)sender
{
	NSString *format = NSLocalizedString(@"%i minutes", @"Label in Preferences panel");
	
	[killDurationLabel setStringValue:[NSString stringWithFormat:format, [sender intValue]]];	
	[Prefs setKillDuration:[sender intValue]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Easy Wake Options:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction)toggleEasyWakeDefault:(id)sender
{
	[Prefs setUseEasyWakeByDefault:[sender state]];
}

- (IBAction)setMinVolume:(id)sender
{
	NSString *format = NSLocalizedString(@"%i%%", @"Label in Preferences panel");
	
	[minVolumeLabel setStringValue:[NSString stringWithFormat:format, [sender intValue]]];

	float value = [sender intValue] / 100.0;
	[Prefs setMinVolume:value];
	
	if([Prefs minVolume] > [Prefs maxVolume])
	{
		[maxVolumeSlider setIntValue:[sender intValue]];
		[self setMaxVolume:maxVolumeSlider];
	}
}

- (IBAction)setMaxVolume:(id)sender
{
	NSString *format = NSLocalizedString(@"%i%%", @"Label in Preferences panel");
	
	[maxVolumeLabel setStringValue:[NSString stringWithFormat:format, [sender intValue]]];	
	
	float value = [sender intValue] / 100.0;
	[Prefs setMaxVolume:value];
	
	if([Prefs maxVolume] < [Prefs minVolume])
	{
		[minVolumeSlider setIntValue:[sender intValue]];
		[self setMinVolume:minVolumeSlider];
	}
}

- (IBAction)setEasyWakeDuration:(id)sender
{
	NSString *format = NSLocalizedString(@"%i minutes", @"Label in Preferences panel");
	
	[easyWakeDurationLabel setStringValue:[NSString stringWithFormat:format, [sender intValue]]];
	[Prefs setEasyWakeDuration:[sender intValue]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Advanced Options:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction)toggleWakeFromSleep:(id)sender
{
	BOOL flag = [sender state];
	
	if(flag)
	{
		if([AlarmTasks authenticate])
		{
			[Prefs setWakeFromSleep:YES];
			[deauthenticateButton setEnabled:YES];
		}
		else
		{
			[sender setState:NO];
		}
	}
	else
	{
		[Prefs setWakeFromSleep:NO];
		[deauthenticateButton setEnabled:NO];
	}
	
	// For some reason, the authentication dialog doesn't return focus to our application
	// Bring application and window back to the front
	[NSApp activateIgnoringOtherApps:YES];
	[window makeKeyAndOrderFront:self];
	
	// Post notification for changed alarm
	// This lets the menu know to change it's icon, based on wake from sleep status
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AlarmChanged" object:self];
}

- (IBAction)deauthenticate:(id)sender
{
	if([AlarmTasks deauthenticate])
	{
		[Prefs setWakeFromSleep:NO];
		[wakeFromSleepButton setState:NSOffState];
		[deauthenticateButton setEnabled:NO];
	}
	
	// For some reason, the authentication dialog doesn't return focus to our application
	// Bring application back to the front
	[NSApp activateIgnoringOtherApps:YES];
	[window makeKeyAndOrderFront:self];
	
	// Post notification for changed alarm
	// This lets the menu know to change it's icon, based on wake from sleep status
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AlarmChanged" object:self];
}

- (IBAction)toggleKeyboard:(id)sender
{
	[Prefs setAnyKeyStops:([sender selectedRow] == 0)];
}

- (IBAction)toggleAppleRemote:(id)sender
{
	[Prefs setSupportAppleRemote:[sender state]];
}

- (IBAction)toggleLogin:(id)sender
{
	if([sender state])
	{
		[Prefs setLaunchAtLogin:YES];
		[self addLoginItem];
	}
	else
	{
		[Prefs setLaunchAtLogin:NO];
		[self deleteLoginItem];
	}
}

- (void)addLoginItem
{
	/* Execute the following AppleScript command:
	
	set app_path to path to me
	tell application "System Events"
		if "Alarm Clock" is not in (name of every login item) then
			make login item at end with properties {hidden:false, path:app_path}
		end if
	end tell
	*/
	
	NSMutableString *command = [NSMutableString string];
	[command appendString:@"set app_path to path to me \n"];
	[command appendString:@"tell application \"System Events\" \n"];
	[command appendString:@"if \"Alarm Clock\" is not in (name of every login item) then \n"];
	[command appendString:@"make login item at end with properties {hidden:false, path:app_path} \n"];
	[command appendString:@"end if \n"];
	[command appendString:@"end tell"];
	
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:command];
	[script executeAndReturnError:nil];
	[script release];
}

- (void)deleteLoginItem
{
	/* Execute the following AppleScript command:
	
	tell application "System Events"
		if "Script Editor" is in (name of every login item) then
			delete (every login item whose name is "Script Editor")
		end if
	end tell
	*/
	
	NSMutableString *command = [NSMutableString string];
	[command appendString:@"tell application \"System Events\" \n"];
	[command appendString:@"if \"Alarm Clock\" is in (name of every login item) then \n"];
	[command appendString:@"delete (every login item whose name is \"Alarm Clock\") \n"];
	[command appendString:@"end if \n"];
	[command appendString:@"end tell"];
	
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:command];
	[script executeAndReturnError:nil];
	[script release];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Software Update Options:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction)toggleCheckForUpdates:(id)sender
{
	if([sender state] == NSOffState)
	{
		[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:SUScheduledCheckIntervalKey];
		[updateIntervalPopup setEnabled:NO];
	}
	else
	{
		int updateInterval = [updateIntervalPopup selectedTag];
		[[NSUserDefaults standardUserDefaults] setInteger:updateInterval forKey:SUScheduledCheckIntervalKey];
		[updateIntervalPopup setEnabled:YES];
	}
}

- (IBAction)setUpdateInterval:(id)sender
{
	int updateInterval = [sender selectedTag];
	[[NSUserDefaults standardUserDefaults] setInteger:updateInterval forKey:SUScheduledCheckIntervalKey];
}

@end