/* MenuController */

#import <Cocoa/Cocoa.h>
@class iTunesData;

@interface MenuController : NSObject
{
	// The status item to go in the status bar
	NSStatusItem *statusItem;
	
	// Interface Builder outlets
    IBOutlet NSMenu *menu;
    IBOutlet id prefsWindow;
}
- (IBAction)about:(id)sender;
- (IBAction)addAlarm:(id)sender;
- (IBAction)editAlarm:(id)sender;
- (IBAction)openNewStopwatch:(id)sender;
- (IBAction)openNewTimer:(id)sender;
- (IBAction)preferences:(id)sender;
- (IBAction)quit:(id)sender;
@end
