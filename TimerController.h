/* TimerController */

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

#import "TransparentController.h"

@interface TimerController : NSWindowController <TransparentController>
{
	// Timer
	NSTimer *timer;
	
	// For tracking time
	BOOL isStarted;
	float totalTime;
	float elapsedTime;
	NSDate *startDate;
	
	// Options
	BOOL useAlarmVolume;
	
	// Movie for playing sound
	QTMovie *movie;
	
	// Initial system volumes
	// This is the volume the system was at before the alarm went off
	// We store this, so that after the alarm is stopped, we can restore the system volume for the user
	float initialLeftVolume;
	float initialRightVolume;
	
	// Stored and Localized strings
	NSString *titleStr;
	NSString *totalTimeStr;
	NSString *startStr;
	NSString *pauseStr;
	NSString *resetStr;
	NSString *editStr;
	
	// Timer for updating window when minituarized
	NSTimer *miniWindowTimer;
	NSBitmapImageRep *bmpImageRep;
	NSImage *miniWindowImage;
	
    IBOutlet id alwaysOnTopButton;
    IBOutlet id configPanel;
    IBOutlet id nameField;
    IBOutlet id timeField;
    IBOutlet id transparentView;
    IBOutlet id useAlarmVolumeButton;
}
- (IBAction)closeConfigPanel:(id)sender;
- (IBAction)nameDidChange:(id)sender;
@end
