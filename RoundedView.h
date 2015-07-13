/* RoundedView */

#import <Cocoa/Cocoa.h>

@interface RoundedView : NSView
{
	// Attributes used for drawing window contents
	NSDictionary *statusAttributes;
	NSDictionary *modifierAttributes;
	NSDictionary *clockAttributes;
	NSDictionary *buttonAttributes;

	// Stored frames and locations (for dragging and resizing)
	// NSRect and NSPoint are simple structs
	NSSize minSize;
	NSRect originalViewBounds;
	NSRect initialWindowFrame;
	NSPoint initialLocationInWindow;
	NSPoint initialLocationInScreen;
	
	// Transparency percentage of window
	float alpha;
	
	// Coordinates of frame, clock, buttons, etc (NSRect is a simple struct)
	NSRect viewRect;
	NSRect statusLine1Rect;
	NSRect statusLine2Rect;
	NSRect clockRect;
	NSRect plusRect;
	NSRect minusRect;
	NSRect leftRect;
	NSRect rightRect;
	
	// Plus button
	BOOL isRolloverPlus;
	BOOL isPressedPlus;
	BOOL wasPressedPlus;
	// Minus button
	BOOL isRolloverMinus;
	BOOL isPressedMinus;
	BOOL wasPressedMinus;
	// Left button
	BOOL isRolloverLeft;
	BOOL isPressedLeft;
	BOOL wasPressedLeft;
	// Right button
	BOOL isRolloverRight;
	BOOL isPressedRight;
	BOOL wasPressedRight;
	// Window
	BOOL isPressedWindow;
	
    IBOutlet id roundedController;
}

@end