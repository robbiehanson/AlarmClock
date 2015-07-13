/* EditorController */

#import <Cocoa/Cocoa.h>
@class Alarm;
@class ITunesTable;
@class ITunesPlayer;

@interface EditorController : NSWindowController
{
	// Alarm reference and alarm copy
	Alarm *alarmReference;
	Alarm *alarm;
	
	// iTunes Data reference
	ITunesTable *data;
	
	// For previewing songs with quicktime
	NSImage *playImage;
	NSImage *stopImage;
	ITunesPlayer *player;
	
	// Lock for threads
	NSLock *lock;
	
	// For displaying the correct track/playlist
	BOOL hasSelectedTrackOrPlaylist;
	
    IBOutlet id calMonths;
    IBOutlet id calPanel;
    IBOutlet id calView;
    IBOutlet id calYears;
    IBOutlet id dateButton;
    IBOutlet id dateField;
    IBOutlet id deleteButton;
    IBOutlet id easyWakeButton;
    IBOutlet id playlists;
    IBOutlet id previewButton;
    IBOutlet id repeatSchedule;
    IBOutlet id repeatType;
    IBOutlet id searchField;
    IBOutlet id searchLabel;
    IBOutlet id shuffleButton;
    IBOutlet id songLabel;
    IBOutlet id statusButton;
    IBOutlet id sunMoonImage;
    IBOutlet id table;
    IBOutlet id tabView;
    IBOutlet id timeField;
}
- (IBAction)cancel:(id)sender;
- (IBAction)changeCal:(id)sender;
- (IBAction)closeCalPanel:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)preview:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)selectDate:(id)sender;
- (IBAction)switchSource:(id)sender;
- (IBAction)toggleDateTime:(id)sender;
- (IBAction)toggleEasyWake:(id)sender;
- (IBAction)toggleShuffle:(id)sender;
- (IBAction)toggleStatus:(id)sender;

- (id)init;
- (id)initWithIndex:(int)index;

- (Alarm *)alarmReference;

@end
