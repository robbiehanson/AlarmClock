/* StopwatchController */

#import <Cocoa/Cocoa.h>

#import "TransparentController.h"

@interface StopwatchController : NSWindowController <TransparentController>
{
	// Timer
	NSTimer *timer;
	
	// For tracking time
	BOOL isStarted;
	float lapElapsedTime;
	float splitElapsedTime;
	NSDate *startDate;
	
	// For storing lap/split info
	BOOL isLapMode;
	int lapSplitIndex;
	NSMutableArray *laps;
	NSMutableArray *splits;
	NSDateFormatter *timeFormatter;
	
	// Localized and stored strings
	NSString *titleStr;
	NSString *readyStr;
	NSString *startedAtStr;
	NSString *lapXStr;
	NSString *splitXStr;
	NSString *startStr;
	NSString *pauseStr;
	NSString *resetStr;
	NSString *lapSplitStr;
	
	// Timer for updating window when minituarized
	NSTimer *miniWindowTimer;
	NSBitmapImageRep *bmpImageRep;
	NSImage *miniWindowImage;
	
    IBOutlet id alwaysOnTopButton;
    IBOutlet id configPanel;
    IBOutlet id nameField;
    IBOutlet id transparentView;
}
- (IBAction)closeConfigPanel:(id)sender;
@end
