/* TransparentView */

#import <Cocoa/Cocoa.h>

@interface TransparentView : NSView
{
	// Drawing attributes for buttons and clock
	NSDictionary *titleAttributes;
	NSDictionary *statusAttributes;
	NSDictionary *clockAttributes;
	NSDictionary *buttonAttributes;
	
	// Stored frames and locations (for dragging and resizing)
	// NSRect and NSPoint are simple structs
	NSSize minSize;
	NSRect originalViewBounds;
	NSRect initialWindowFrame;
	NSPoint initialLocationInWindow;
	NSPoint initialLocationInScreen;
	
	// Coordinates of frame, clock, buttons, etc (NSRect is a simple struct)
	NSRect titleBarRect;
	NSRect closeRect;
	NSRect minimizeRect;
	NSRect titleRect;
	NSRect resizeRect;
	NSRect contentRect;
	NSRect viewRect;
	NSRect statusLine1Rect;
	NSRect statusLine2Rect;
	NSRect clockRect;
	NSRect bigClockRect;
	NSRect leftModifierRect;
	NSRect rightModifierRect;
	NSRect leftButtonRect;
	NSRect rightButtonRect;
	
	// Close button
	BOOL isRolloverClose;
	BOOL isPressedClose;
	BOOL wasPressedClose;
	// Minimize button
	BOOL isRolloverMinimize;
	BOOL isPressedMinimize;
	BOOL wasPressedMinimize;
	// Left modifier
	BOOL isRolloverMinus;
	BOOL isPressedMinus;
	BOOL wasPressedMinus;
	// Plus button
	BOOL isRolloverPlus;
	BOOL isPressedPlus;
	BOOL wasPressedPlus;
	// Left button
	BOOL isRolloverLeft;
	BOOL isPressedLeft;
	BOOL wasPressedLeft;
	// Right button
	BOOL isRolloverRight;
	BOOL isPressedRight;
	BOOL wasPressedRight;
	// Resize control
	BOOL isPressedResize;
	// Window
	BOOL isPressedWindow;
	
    IBOutlet id transparentController;
}
@end
