#import "RoundedView.h"
#import "AlarmController.h"

@implementation RoundedView

- (id)initWithFrame:(NSRect)frameRect
{
	if(self = [super initWithFrame:frameRect])
	{
		// Setup color attributes for window and strings
		alpha = 0.45;
		
		// Setup alignment of strings
		NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
		[paragraphStyle setAlignment:NSCenterTextAlignment];
		[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
		
		// Setup shadow for strings
		NSShadow *textShadow = [[[NSShadow alloc] init] autorelease];
		NSSize shadowSize = {0.0f, -1.5f};
		[textShadow setShadowOffset:shadowSize];
		[textShadow setShadowBlurRadius:3.5f];
		[textShadow setShadowColor:[NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.0f alpha:0.92]];
		
		// Setup status attributes
		NSFont *statusFont = [NSFont labelFontOfSize:[NSFont systemFontSize]+2];
		NSColor *statusColor = [NSColor whiteColor];
		
		NSMutableDictionary *statusAttrTemp = [NSMutableDictionary dictionaryWithCapacity:4];
		[statusAttrTemp setObject:statusFont forKey:NSFontAttributeName];
		[statusAttrTemp setObject:textShadow forKey:NSShadowAttributeName];
		[statusAttrTemp setObject:statusColor forKey:NSForegroundColorAttributeName];
		[statusAttrTemp setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
		
		statusAttributes = [statusAttrTemp copy];
		
		// Setup modifier attributes
		NSFont *modifierFont = [NSFont fontWithName:@"Arial" size:[NSFont systemFontSize]+2];
		if(!modifierFont)
		{
			NSLog(@"Arial font is missing from system");
			modifierFont = [NSFont labelFontOfSize:[NSFont systemFontSize]+2];
		}
		NSColor *modifierColor = [NSColor whiteColor];
		
		NSMutableDictionary *modifierAttrTemp = [NSMutableDictionary dictionaryWithCapacity:4];
		[modifierAttrTemp setObject:modifierFont forKey:NSFontAttributeName];
		[modifierAttrTemp setObject:textShadow forKey:NSShadowAttributeName];
		[modifierAttrTemp setObject:modifierColor forKey:NSForegroundColorAttributeName];
		[modifierAttrTemp setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
		
		modifierAttributes = [modifierAttrTemp copy];
		
		// Setup clock attributes
		NSFont *clockFont = [NSFont userFixedPitchFontOfSize:38.0];
		NSColor *clockColor = [NSColor whiteColor];
		
		NSMutableDictionary *clockAttrTemp = [NSMutableDictionary dictionaryWithCapacity:3];
		[clockAttrTemp setObject:clockFont forKey:NSFontAttributeName];
		[clockAttrTemp setObject:clockColor forKey:NSForegroundColorAttributeName];
		[clockAttrTemp setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
		
		clockAttributes = [clockAttrTemp copy];
		
		// Setup button attributes
		NSFont *buttonFont = [NSFont labelFontOfSize:[NSFont systemFontSize]+2];
		NSColor *buttonColor = [NSColor whiteColor];
		
		NSMutableDictionary *buttonAttrTemp = [NSMutableDictionary dictionaryWithCapacity:4];
		[buttonAttrTemp setObject:buttonFont forKey:NSFontAttributeName];
		[buttonAttrTemp setObject:textShadow forKey:NSShadowAttributeName];
		[buttonAttrTemp setObject:buttonColor forKey:NSForegroundColorAttributeName];
		[buttonAttrTemp setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
		
		buttonAttributes = [buttonAttrTemp copy];
		
		// Setup Rects
		
		viewRect.origin.x = frameRect.origin.x + 23;
		viewRect.origin.y = frameRect.origin.y + 29;
		viewRect.size.width = frameRect.size.width - 46;
		viewRect.size.height = frameRect.size.height - 58;
		
		// Don't forget - Coordinate system => 0,0 => Lower lefthand corner
		
		float buttonSpace = 14.0;
		float buttonWidth = ((viewRect.size.width - buttonSpace) / 2.0);
		
		leftRect.origin.x = viewRect.origin.x;
		leftRect.origin.y = viewRect.origin.y;
		leftRect.size.width  = buttonWidth;
		leftRect.size.height = [statusFont pointSize] + 8;
		
		rightRect.origin.x = leftRect.origin.x + leftRect.size.width + buttonSpace;
		rightRect.origin.y = viewRect.origin.y;
		rightRect.size.width  = buttonWidth;
		rightRect.size.height = [statusFont pointSize] + 8;
		
		clockRect.origin.x = viewRect.origin.x;
		clockRect.origin.y = leftRect.origin.y + leftRect.size.height + 20;
		clockRect.size.width  = viewRect.size.width;
		clockRect.size.height = [clockFont pointSize] + 15;
		
		statusLine2Rect.origin.x = viewRect.origin.x + 25;
		statusLine2Rect.origin.y = clockRect.origin.y + clockRect.size.height + 20;
		statusLine2Rect.size.width  = viewRect.size.width - 50;
		statusLine2Rect.size.height = [statusFont pointSize] + 8;
		
		minusRect.origin.x = viewRect.origin.x;
		minusRect.origin.y = statusLine2Rect.origin.y + 2;
		minusRect.size.width  = [statusFont pointSize] + 4;
		minusRect.size.height = [statusFont pointSize] + 4;
		
		plusRect.origin.x = viewRect.origin.x + viewRect.size.width - ([statusFont pointSize] + 4);
		plusRect.origin.y = statusLine2Rect.origin.y + 2;
		plusRect.size.width  = [statusFont pointSize] + 4;
		plusRect.size.height = [statusFont pointSize] + 4;
		
		statusLine1Rect.origin.x = viewRect.origin.x;
		statusLine1Rect.origin.y = statusLine2Rect.origin.y + statusLine2Rect.size.height + 5;
		statusLine1Rect.size.width  = viewRect.size.width;
		statusLine1Rect.size.height = [statusFont pointSize] + 8;
		
		// Store the original bounds
		originalViewBounds = [self bounds];
		
		// Configure minimum size of window and view
		NSRect originalViewFrame = [self frame];
		
		minSize.width = 160;
		minSize.height = 160 * (originalViewFrame.size.height / originalViewFrame.size.width);
	}
	return self;
}

- (void)dealloc
{
	// NSLog(@"Destroying %@", self);
	[statusAttributes release];
	[modifierAttributes release];
	[clockAttributes release];
	[buttonAttributes release];
	[super dealloc];
}
// OVERRIDEN NSVIEW METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 We want to respond to click-through.
 That is, we want to be notified of the first click on this view, when the window is not key.
 This is similar behavior to other windows on OS X.
**/
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

// DRAWING METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)fillRoundedRect:(NSRect)rect withRadius:(float)radius andRollover:(BOOL)rollover andClick:(BOOL)click
{
	NSColor *bgColor = [NSColor colorWithCalibratedWhite:0.0 alpha:alpha];
	
	int minX = NSMinX(rect);
	int midX = NSMidX(rect);
    int maxX = NSMaxX(rect);
    int minY = NSMinY(rect);
    int midY = NSMidY(rect);
    int maxY = NSMaxY(rect);
    
    NSBezierPath *bgPath = [NSBezierPath bezierPath];
    
    // Bottom edge and bottom-right curve
    [bgPath moveToPoint:NSMakePoint(midX, minY)];
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) 
                                     toPoint:NSMakePoint(maxX, midY) 
                                      radius:radius];
    
    // Right edge and top-right curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) 
                                     toPoint:NSMakePoint(midX, maxY) 
                                      radius:radius];
    
    // Top edge and top-left curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) 
                                     toPoint:NSMakePoint(minX, midY) 
                                      radius:radius];
    
    // Left edge and bottom-left curve
    [bgPath appendBezierPathWithArcFromPoint:rect.origin 
                                     toPoint:NSMakePoint(midX, minY) 
                                      radius:radius];
    [bgPath closePath];
    
    [bgColor set];
    [bgPath fill];
	
	if(click)
	{
		[bgPath fill];
	}
	if(rollover)
	{
		[[NSColor whiteColor] set];
		[bgPath setLineWidth:2.0];
		[bgPath stroke];
	}
}

- (void)drawRect:(NSRect)rect
{
	// Draw background window
	[self fillRoundedRect:rect withRadius:25.0 andRollover:NO andClick:NO];
	
	// Status line 1
	[[roundedController statusLine1] drawInRect:statusLine1Rect withAttributes:statusAttributes];
	
	// Status line 2
	[[roundedController statusLine2] drawInRect:statusLine2Rect withAttributes:statusAttributes];
	
	if([roundedController shouldDisplayPlusMinusButtons])
	{
		// Plus button
		[self fillRoundedRect:plusRect withRadius:3.0 andRollover:isRolloverPlus andClick:isPressedPlus];
		[[roundedController plusButtonStr] drawInRect:plusRect withAttributes:modifierAttributes];
		
		// Minus button
		[self fillRoundedRect:minusRect withRadius:3.0 andRollover:isRolloverMinus andClick:isPressedMinus];
		[[roundedController minusButtonStr] drawInRect:minusRect withAttributes:modifierAttributes];
	}
	
	// Clock display
	[self fillRoundedRect:clockRect withRadius:15.0 andRollover:NO andClick:NO];
	[[roundedController timeStr] drawInRect:clockRect withAttributes:clockAttributes];
	
	// Left button
	[self fillRoundedRect:leftRect withRadius:12.0 andRollover:isRolloverLeft andClick:isPressedLeft];
	[[roundedController leftButtonStr] drawInRect:leftRect withAttributes:buttonAttributes];
	
	// Right button
	[self fillRoundedRect:rightRect withRadius:12.0 andRollover:isRolloverRight andClick:isPressedRight];
	[[roundedController rightButtonStr] drawInRect:rightRect withAttributes:buttonAttributes];
}

// MOUSE MOVEMENT AND ACTION
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Receives mouse movement events, forwarded from the window.
 If the mouse moves inside any of the active buttons, those buttons are highlighted.
 
 Note that we don't terminate early if we find movement in or out of a button rect.
 It's possible to have overlapping buttons, or buttons right next to each other.
 Thus in one mouse movement, there could theoretically be multiple updates.
 Therefore we check each rect for mouse activity.
**/
- (void)mouseMoved:(NSEvent *)event
{
	// Convert the window coordinates to our scaled coordinate system for this view
	NSPoint mousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
	
	// Plus, Minus buttons
	BOOL newIsRolloverPlus = [self mouse:mousePoint inRect:plusRect];
	BOOL newIsRolloverMinus = [self mouse:mousePoint inRect:minusRect];
	
	if([roundedController shouldDisplayPlusMinusButtons])
	{
		if((newIsRolloverPlus != isRolloverPlus) || (newIsRolloverMinus != isRolloverMinus))
		{
			isRolloverPlus = newIsRolloverPlus;
			isRolloverMinus = newIsRolloverMinus;
			[self setNeedsDisplay:YES];
		}
	}
	
	// Left, Right buttons
	BOOL newIsRolloverLeft = [self mouse:mousePoint inRect:leftRect];
	BOOL newIsRolloverRight = [self mouse:mousePoint inRect:rightRect];
	
	if((newIsRolloverLeft != isRolloverLeft) || (newIsRolloverRight != isRolloverRight))
	{
		isRolloverLeft = newIsRolloverLeft;
		isRolloverRight = newIsRolloverRight;
		[self setNeedsDisplay:YES];
	}
}

/**
 Called when the user presses the left mouse button down.
 We check to see if the mouse down event was in any of the active buttons.
 If it was, this click is noted, and the button changes appearance to reflect the click.
 If the mouse wasn't pressed on any buttons, then we allow the user to move the window,
 and make the necessary preparations.
**/
- (void)mouseDown:(NSEvent *)event
{
	// Convert the window coordinates to our scaled coordinate system for this view
	NSPoint mouseLocationInWindow = [event locationInWindow];
	NSPoint mouseLocationInView   = [self convertPoint:mouseLocationInWindow fromView:nil];
	
	if([self mouse:mouseLocationInView inRect:statusLine1Rect] || [self mouse:mouseLocationInView inRect:statusLine2Rect])
	{
		// Status Line 1 or 2
		// These fire on mouse down
		[roundedController statusLineClicked];
		[self setNeedsDisplay:YES];
	}
	
	if([roundedController shouldDisplayPlusMinusButtons] && [self mouse:mouseLocationInView inRect:plusRect])
	{
		// Plus button
		wasPressedPlus = isPressedPlus = YES;
		[self setNeedsDisplay:YES];
	}
	else if([roundedController shouldDisplayPlusMinusButtons] && [self mouse:mouseLocationInView inRect:minusRect])
	{
		// Decrease button
		wasPressedMinus = isPressedMinus = YES;
		[self setNeedsDisplay:YES];
	}
	else if([self mouse:mouseLocationInView inRect:leftRect])
	{
		// Left button
		wasPressedLeft = isPressedLeft = YES;
		[self setNeedsDisplay:YES];
	}
	else if([self mouse:mouseLocationInView inRect:rightRect])
	{
		// Rigth button
		wasPressedRight = isPressedRight = YES;
		[self setNeedsDisplay:YES];
	}
	else
	{
		// Click anywhere else in window
		isPressedWindow = YES;
		
		// Store initial frame and location
		initialWindowFrame = [[self window] frame];
		initialLocationInWindow = [event locationInWindow];
		initialLocationInScreen = [[self window] convertBaseToScreen:initialLocationInWindow];
	}
}

/**
 Constantly called while the user drags the mouse around the screen.
 If the user is moving the window around, or resizing the window, we quickly react and immediately return.
 Otherwise, we check to see if the mouse is moving over buttons.
 Remember, buttons only light up (during drag) if they were originally clicked on.
 Otherwise mouse movement during a drag is ignored for buttons.
**/
- (void)mouseDragged:(NSEvent *)event
{
	if(isPressedWindow)
	{
		NSPoint currentLocation;
		NSPoint newOrigin;
		NSRect  screenFrame = [[NSScreen mainScreen] frame];
		NSRect  windowFrame = [[self window] frame];
		
		currentLocation = [[self window] convertBaseToScreen:[event locationInWindow]];
		newOrigin.x = currentLocation.x - initialLocationInWindow.x;
		newOrigin.y = currentLocation.y - initialLocationInWindow.y;
		
		if((newOrigin.y + windowFrame.size.height) > (NSMaxY(screenFrame) - [NSMenuView menuBarHeight]))
		{
			// Prevent dragging into the menu bar area
			newOrigin.y = NSMaxY(screenFrame) - windowFrame.size.height - [NSMenuView menuBarHeight];
		}
		
		[[self window] setFrameOrigin:newOrigin];
		
		return;
	}
	
	// Convert the window coordinates to our scaled coordinate system for this view
	NSPoint mousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
	
	// Plus, Minus buttons - Ignored if not currently active
	BOOL newIsPressedPlus = [self mouse:mousePoint inRect:plusRect];
	BOOL newIsPressedMinus = [self mouse:mousePoint inRect:minusRect];
	
	if([roundedController shouldDisplayPlusMinusButtons])
	{
		if((newIsPressedPlus != isPressedPlus) || (newIsPressedMinus != isPressedMinus))
		{
			isRolloverPlus = isPressedPlus = wasPressedPlus && newIsPressedPlus;
			isRolloverMinus = isPressedMinus = wasPressedMinus && newIsPressedMinus;
			[self setNeedsDisplay:YES];
		}
	}
	
	// Left, Right buttons
	BOOL newIsPressedLeft = [self mouse:mousePoint inRect:leftRect];
	BOOL newIsPressedRight = [self mouse:mousePoint inRect:rightRect];
	
	if((newIsPressedLeft != isPressedLeft) || (newIsPressedRight != isPressedRight))
	{
		isRolloverLeft = isPressedLeft = wasPressedLeft && newIsPressedLeft;
		isRolloverRight = isPressedRight = wasPressedRight && newIsPressedRight;
		[self setNeedsDisplay:YES];
	}
}

/**
 Called when the user releases the mouse from it's pressed down state.
 If the user pressed down and released on the same button, then that button fires.
 Otherwise, the event is ignored, just as it would be under normal circumstances.
**/
- (void)mouseUp:(NSEvent *)event
{
	// Convert the window coordinates to our scaled coordinate system for this view
	NSPoint mousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
	
	if(isPressedPlus && [roundedController shouldDisplayPlusMinusButtons])
	{
		// Plus Button
		wasPressedPlus = isPressedPlus = NO;
		if([self mouse:mousePoint inRect:plusRect])
		{
			[roundedController plusButtonClicked];
			[self setNeedsDisplay:YES];
		}
	}
	else if(isPressedMinus && [roundedController shouldDisplayPlusMinusButtons])
	{
		// Minus Button
		wasPressedMinus = isPressedMinus = NO;
		if([self mouse:mousePoint inRect:minusRect])
		{
			[roundedController minusButtonClicked];
			[self setNeedsDisplay:YES];
		}
	}
	else if(isPressedLeft)
	{
		// Left Button
		wasPressedLeft = isPressedLeft = NO;
		if([self mouse:mousePoint inRect:leftRect])
		{
			[roundedController leftButtonClicked];
			[self setNeedsDisplay:YES];
		}
	}
	else if(isPressedRight)
	{
		// Right Button
		wasPressedRight = isPressedRight = NO;
		if([self mouse:mousePoint inRect:rightRect])
		{
			[roundedController rightButtonClicked];
			[self setNeedsDisplay:YES];
		}
	}
	else
	{
		isPressedWindow = NO;
	}
}

// WINDOW CLOSING FADE
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)fade:(NSTimer *)aTimer
{
	alpha -= 0.05;
	
	if(alpha > 0.0)
	{
		[self setNeedsDisplay:YES];
		[NSTimer scheduledTimerWithTimeInterval:0.05
										 target:self
									   selector:@selector(fade:)
									   userInfo:nil
										repeats:NO];
	}
	else
	{
		[[self window] close];
	}
}

@end
