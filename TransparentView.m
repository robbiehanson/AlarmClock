#import "TransparentView.h"
#import "TransparentController.h"

@implementation TransparentView

// INIT, DEALLOC
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Standard init method for NSView.
 This method handles configuring the styles for the various elements, and sets up the NSRect variables.
**/
- (id)initWithFrame:(NSRect)frameRect
{
	if(self = [super initWithFrame:frameRect])
	{
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
		
		// Setup title attributes
		NSFont *titleFont = [NSFont titleBarFontOfSize:0];
		NSColor *titleColor = [NSColor whiteColor];
		
		NSMutableDictionary *titleAttrTemp = [NSMutableDictionary dictionaryWithCapacity:4];
		[titleAttrTemp setObject:titleFont forKey:NSFontAttributeName];
		[titleAttrTemp setObject:titleColor forKey:NSForegroundColorAttributeName];
		[titleAttrTemp setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
		
		titleAttributes = [titleAttrTemp copy];
		
		// Setup status attributes
		NSFont *statusFont = [NSFont labelFontOfSize:[NSFont systemFontSize]+2];
		NSColor *statusColor = [NSColor whiteColor];
		
		NSMutableDictionary *statusAttrTemp = [NSMutableDictionary dictionaryWithCapacity:4];
		[statusAttrTemp setObject:statusFont forKey:NSFontAttributeName];
		[statusAttrTemp setObject:textShadow forKey:NSShadowAttributeName];
		[statusAttrTemp setObject:statusColor forKey:NSForegroundColorAttributeName];
		[statusAttrTemp setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
		
		statusAttributes = [statusAttrTemp copy];
		
		// Setup clock attributes
		NSFont *clockFont = [NSFont userFixedPitchFontOfSize:50.0];
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
		
		int titleBarHeight = 22;
		
		titleBarRect.origin.x = 0;
		titleBarRect.origin.y = frameRect.size.height - titleBarHeight;
		titleBarRect.size.width = frameRect.size.width;
		titleBarRect.size.height = titleBarHeight;
		
		closeRect.origin.x = 0 + 4;
		closeRect.origin.y = titleBarRect.origin.y + 4;
		closeRect.size.width = 13;
		closeRect.size.height = 13;
		
		minimizeRect.origin.x = closeRect.origin.x + closeRect.size.width + 4;
		minimizeRect.origin.y = titleBarRect.origin.y + 4;
		minimizeRect.size.width = 13;
		minimizeRect.size.height = 13;
		
		titleRect.origin.x = titleBarRect.origin.x + 35;
		titleRect.origin.y = titleBarRect.origin.y + 2;
		titleRect.size.width = titleBarRect.size.width - 70;
		titleRect.size.height = 18;
		
		resizeRect.origin.x = frameRect.size.width - 15;
		resizeRect.origin.y = 0;
		resizeRect.size.width = 15;
		resizeRect.size.height = 15;
		
		contentRect.origin.x = 0;
		contentRect.origin.y = 0;
		contentRect.size.width = frameRect.size.width;
		contentRect.size.height = frameRect.size.height - titleBarHeight;
		
		/*
		 We now setup the viewRect
		 This sets up the drawable portion of the window
		 Effectively giving the window a nice padding between content and edges
		 */
		viewRect.origin.x = frameRect.origin.x + 12;
		viewRect.origin.y = frameRect.origin.y + 15;
		viewRect.size.width = frameRect.size.width - 24;
		viewRect.size.height = frameRect.size.height - 30;
		
		// Don't forget - Coordinate system => 0,0 => Lower lefthand corner
		
		float buttonSpace = 14.0;
		float buttonWidth = ((viewRect.size.width - buttonSpace) / 2.0);
		
		leftButtonRect.origin.x = viewRect.origin.x;
		leftButtonRect.origin.y = viewRect.origin.y;
		leftButtonRect.size.width  = buttonWidth;
		leftButtonRect.size.height = [buttonFont pointSize] + 8;
		
		rightButtonRect.origin.x = leftButtonRect.origin.x + leftButtonRect.size.width + buttonSpace;
		rightButtonRect.origin.y = viewRect.origin.y;
		rightButtonRect.size.width = buttonWidth;
		rightButtonRect.size.height = [buttonFont pointSize] + 8;
		
		clockRect.origin.x = viewRect.origin.x;
		clockRect.origin.y = leftButtonRect.origin.y + leftButtonRect.size.height + 20;
		clockRect.size.width  = viewRect.size.width;
		clockRect.size.height = [clockFont pointSize] + 15;
		
		statusLine2Rect.origin.x = viewRect.origin.x + 25;
		statusLine2Rect.origin.y = clockRect.origin.y + clockRect.size.height + 15;
		statusLine2Rect.size.width  = viewRect.size.width - 50;
		statusLine2Rect.size.height = [statusFont pointSize] + 8;
		
		leftModifierRect.origin.x = viewRect.origin.x;
		leftModifierRect.origin.y = statusLine2Rect.origin.y + 2;
		leftModifierRect.size.width  = [statusFont pointSize] + 4;
		leftModifierRect.size.height = [statusFont pointSize] + 4;
		
		rightModifierRect.origin.x = viewRect.origin.x + viewRect.size.width - ([statusFont pointSize] + 4);
		rightModifierRect.origin.y = statusLine2Rect.origin.y + 2;
		rightModifierRect.size.width  = [statusFont pointSize] + 4;
		rightModifierRect.size.height = [statusFont pointSize] + 4;
		
		statusLine1Rect.origin.x = viewRect.origin.x + 25;
		statusLine1Rect.origin.y = statusLine2Rect.origin.y + statusLine2Rect.size.height + 5;
		statusLine1Rect.size.width  = viewRect.size.width - 50;
		statusLine1Rect.size.height = [statusFont pointSize] + 4;
		
		// Store the original bounds
		originalViewBounds = [self bounds];
		
		// Configure minimum size of window and view
		NSRect originalViewFrame = [self frame];
		
		minSize.width = 160;
		minSize.height = 160 * (originalViewFrame.size.height / originalViewFrame.size.width);
	}
	return self;
}

/**
 Don't forget to tidy up!
**/
-(void) dealloc
{
	//NSLog(@"Destroying %@", self);
	[titleAttributes release];
	[statusAttributes release];
	[clockAttributes release];
	[buttonAttributes release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Overridden NSView Methods:
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

- (void)setFrame:(NSRect)newViewFrame
{
	[super setFrame:newViewFrame];
	[super setBounds:originalViewBounds];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Window Delegate Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Called when the window is about to display a sheet.
 We alter the standard sheet position, since we're drawing our own title bar within the view.
 We want the sheet to be displayed within our title bar instead of within the invisible window title bar.
 
 Note: We are not actually the delegate for the window. The call is forwarded from the TransparentController.
**/
- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect
{
	NSRect viewFrame = [self frame];
	NSRect viewBounds = [self bounds];
	
	float scale = viewFrame.size.height / viewBounds.size.height;
	
	NSRect result;
	result.origin.x = rect.origin.x;
	result.origin.y = (titleBarRect.origin.y * scale) + 1;
	result.size.width = rect.size.width;
	result.size.height = 0;
	
    return result;
}

/**
 * Called when the window becomes the key window.
 * That is, the window the user is currently using.
 * 
 * Note: We are not actually the delegate for the window. The call is forwarded from the TransparentController.
**/
- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	// We need to change the color of the title bar to reflect this change
	[self setNeedsDisplay:YES];
}

/**
 * Called when the window ceases to be the key window.
 * That is, the window is no longer the window the user is currently using.
 * 
 * Note: We are not actually the delegate for the window. The call is forwarded from the TransparenController.
**/
- (void)windowDidResignKey:(NSNotification *)aNotification
{
	// We need to change the color of the title bar to reflect this change
	[self setNeedsDisplay:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Drawing Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Helper method to fill rects with specified radius', colors and highlight state.
 This method handles the underlying bezier path methods and drawing.
**/
- (void)fillRect:(NSRect)rect topRadius:(float)tRad bottomRadius:(float)bRad color:(NSColor *)bgColor highlight:(BOOL)highlight
{
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
                                      radius:bRad];
    
    // Right edge and top-right curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) 
                                     toPoint:NSMakePoint(midX, maxY) 
                                      radius:tRad];
    
    // Top edge and top-left curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) 
                                     toPoint:NSMakePoint(minX, midY) 
                                      radius:tRad];
    
    // Left edge and bottom-left curve
    [bgPath appendBezierPathWithArcFromPoint:rect.origin 
                                     toPoint:NSMakePoint(midX, minY) 
                                      radius:bRad];
    [bgPath closePath];
    
    [bgColor set];
    [bgPath fill];
	
	if(highlight)
	{
		[[NSColor whiteColor] set];
		[bgPath setLineWidth:2.0];
		[bgPath stroke];
	}
}

/**
 Helper method to draw background for buttons (and clock).
 Fills all buttons with standard background color.
**/
- (void)fillRoundedRect:(NSRect)rect usingRadius:(float)radius andRollover:(BOOL)rollover andClick:(BOOL)click
{
	NSColor *bgColor;
	
	if(click)
		bgColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.2025];
	else
		bgColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.5];
	
	[self fillRect:rect topRadius:radius bottomRadius:radius color:bgColor highlight:rollover];
}

/**
 Draws the outline of the window, as well as the title bar, close button, and scaling triangle.
**/
- (void)drawWindow
{
	// Fill the titleBar
	NSColor *titleBarColor;
	if([NSApp isActive])
		titleBarColor = [NSColor colorWithCalibratedWhite:0.25 alpha:0.75];
	else
		titleBarColor = [NSColor colorWithCalibratedWhite:0.15 alpha:0.75];
	
	[self fillRect:titleBarRect topRadius:8.0 bottomRadius:0.0 color:titleBarColor highlight:NO];
	
	// Fill the rest of the window
	NSColor *contentColor = [NSColor colorWithCalibratedWhite:0.1 alpha:0.75];
	[self fillRect:contentRect topRadius:0.0 bottomRadius:0.0 color:contentColor highlight:NO];
	
	// Fill the close button
	if([transparentController shouldDisplayCloseButton])
	{
		if(isPressedClose)
			[self fillRect:closeRect topRadius:6.5 bottomRadius:6.5 color:[NSColor clearColor] highlight:isRolloverClose];
		else
			[self fillRect:closeRect topRadius:6.5 bottomRadius:6.5 color:titleBarColor highlight:isRolloverClose];
	
		// Draw the X in the close button
		NSPoint bottomLeft;
		bottomLeft.x = closeRect.origin.x + 3;
		bottomLeft.y = closeRect.origin.y + 3;
		
		NSPoint topLeft;
		topLeft.x = closeRect.origin.x + 3;
		topLeft.y = closeRect.origin.y + closeRect.size.height - 3;
		
		NSPoint bottomRight;
		bottomRight.x = closeRect.origin.x + closeRect.size.width - 3;
		bottomRight.y = closeRect.origin.y + 3;
		
		NSPoint topRight;
		topRight.x = closeRect.origin.x + closeRect.size.width - 3;
		topRight.y = closeRect.origin.y + closeRect.size.height - 3;
		
		NSBezierPath *path1 = [NSBezierPath bezierPath];
		[path1 moveToPoint:bottomLeft];
		[path1 lineToPoint:topRight];
		
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.95] set];
		[path1 setLineWidth:1.0];
		[path1 stroke];
		
		[path1 moveToPoint:topLeft];
		[path1 lineToPoint:bottomRight];
		
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.95] set];
		[path1 setLineWidth:1.0];
		[path1 stroke];
	}
	
	// Fill the minimize button
	if([transparentController shouldDisplayMinimizeButton])
	{
		if(isPressedMinimize)
			[self fillRect:minimizeRect topRadius:6.5 bottomRadius:6.5 color:[NSColor clearColor] highlight:isRolloverMinimize];
		else
			[self fillRect:minimizeRect topRadius:6.5 bottomRadius:6.5 color:titleBarColor highlight:isRolloverMinimize];
		
		// Draw the - in the close button
		NSPoint left;
		left.x = minimizeRect.origin.x + 3;
		left.y = minimizeRect.origin.y + 7;
		
		NSPoint right;
		right.x = minimizeRect.origin.x + minimizeRect.size.width - 3;
		right.y = minimizeRect.origin.y + 7;
		
		NSBezierPath *path1 = [NSBezierPath bezierPath];
		[path1 moveToPoint:left];
		[path1 lineToPoint:right];
		
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.95] set];
		[path1 setLineWidth:1.75];
		[path1 stroke];
	}
	
	// Draw window title
	[[transparentController title] drawInRect:titleRect withAttributes:titleAttributes];
	
	// Draw line at the bottom of the title bar
	NSPoint tLeft;
	tLeft.x = titleBarRect.origin.x;
	tLeft.y = titleBarRect.origin.y;
	
	NSPoint tRight;
	tRight.x = titleBarRect.origin.x + titleBarRect.size.width;
	tRight.y = titleBarRect.origin.y;
	
	NSBezierPath *path2 = [NSBezierPath bezierPath];
	[path2 setLineWidth:0.5];
	[[NSColor blackColor] set];
	
	[path2 moveToPoint:tLeft];
	[path2 lineToPoint:tRight];
	[path2 stroke];
	
	// Draw window scale lines in bottom right corner
	NSPoint line1Bottom;
	line1Bottom.x = contentRect.origin.x + contentRect.size.width - 3;
	line1Bottom.y = contentRect.origin.y + 1;
	
	NSPoint line2Bottom;
	line2Bottom.x = contentRect.origin.x + contentRect.size.width - 7;
	line2Bottom.y = contentRect.origin.y + 1;
	
	NSPoint line3Bottom;
	line3Bottom.x = contentRect.origin.x + contentRect.size.width - 11;
	line3Bottom.y = contentRect.origin.y + 1;
	
	NSPoint line1Top;
	line1Top.x = contentRect.origin.x + contentRect.size.width - 1;
	line1Top.y = contentRect.origin.y + 3;
	
	NSPoint line2Top;
	line2Top.x = contentRect.origin.x + contentRect.size.width - 1;
	line2Top.y = contentRect.origin.y + 7;
	
	NSPoint line3Top;
	line3Top.x = contentRect.origin.x + contentRect.size.width - 1;
	line3Top.y = contentRect.origin.y + 11;
	
	NSBezierPath *path3 = [NSBezierPath bezierPath];
	[path3 setLineWidth:1.0];
	[[NSColor whiteColor] set];
	
	[path3 moveToPoint:line1Bottom];
	[path3 lineToPoint:line1Top];
	[path3 stroke];
	
	[path3 moveToPoint:line2Bottom];
	[path3 lineToPoint:line2Top];
	[path3 stroke];
	
	[path3 moveToPoint:line3Bottom];
	[path3 lineToPoint:line3Top];
	[path3 stroke];
}

- (void)drawRect:(NSRect)rect
{
	// Draw background window
	[self drawWindow];
	
	// Status line 1
	[[transparentController statusLine1] drawInRect:statusLine1Rect withAttributes:statusAttributes];
	
	// Status line 2
	[[transparentController statusLine2] drawInRect:statusLine2Rect withAttributes:statusAttributes];
	
	if([transparentController shouldDisplayModifierButtons])
	{
		// Left modifier
		[self fillRoundedRect:leftModifierRect usingRadius:3.0 andRollover:isRolloverMinus andClick:isPressedMinus];
		[[transparentController leftModifierStr] drawInRect:leftModifierRect withAttributes:buttonAttributes];
		
		// Right modifier
		[self fillRoundedRect:rightModifierRect usingRadius:3.0 andRollover:isRolloverPlus andClick:isPressedPlus];
		[[transparentController rightModifierStr] drawInRect:rightModifierRect withAttributes:buttonAttributes];
	}
	
	// Clock display
	[self fillRoundedRect:clockRect usingRadius:15.0 andRollover:NO andClick:NO];
	[[transparentController timeStr] drawInRect:clockRect withAttributes:clockAttributes];
	
	// Left button
	[self fillRoundedRect:leftButtonRect usingRadius:12.0 andRollover:isRolloverLeft andClick:isPressedLeft];
	[[transparentController leftButtonStr] drawInRect:leftButtonRect withAttributes:buttonAttributes];
	
	// Right button
	[self fillRoundedRect:rightButtonRect usingRadius:12.0 andRollover:isRolloverRight andClick:isPressedRight];
	[[transparentController rightButtonStr] drawInRect:rightButtonRect withAttributes:buttonAttributes];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Mouse Movement and Action:
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
	
	// Close button
	BOOL newIsRolloverClose = [self mouse:mousePoint inRect:closeRect];
	
	if([transparentController shouldDisplayCloseButton])
	{
		if(newIsRolloverClose != isRolloverClose)
		{
			isRolloverClose = newIsRolloverClose;
			[self setNeedsDisplay:YES];
		}
	}
	
	// Minimize button
	BOOL newIsRolloverMinimize = [self mouse:mousePoint inRect:minimizeRect];
	
	if([transparentController shouldDisplayMinimizeButton])
	{
		if(newIsRolloverMinimize != isRolloverMinimize)
		{
			isRolloverMinimize = newIsRolloverMinimize;
			[self setNeedsDisplay:YES];
		}
	}
	
	// Left, Right modifiers
	BOOL newIsRolloverMinus = [self mouse:mousePoint inRect:leftModifierRect];
	BOOL newIsRolloverPlus = [self mouse:mousePoint inRect:rightModifierRect];
	
	if([transparentController shouldDisplayModifierButtons])
	{
		if((newIsRolloverMinus != isRolloverMinus) || (newIsRolloverPlus != isRolloverPlus))
		{
			isRolloverMinus = newIsRolloverMinus;
			isRolloverPlus = newIsRolloverPlus;
			[self setNeedsDisplay:YES];
		}
	}
	
	// Left, Right buttons
	BOOL newIsRolloverLeft = [self mouse:mousePoint inRect:leftButtonRect];
	BOOL newIsRolloverRight = [self mouse:mousePoint inRect:rightButtonRect];
	
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
		[transparentController statusLineClicked];
		[self setNeedsDisplay:YES];
	}
	
	if([transparentController shouldDisplayCloseButton] && [self mouse:mouseLocationInView inRect:closeRect])
	{
		// Close button
		wasPressedClose = isPressedClose = YES;
		[self setNeedsDisplay:YES];
	}
	else if([transparentController shouldDisplayMinimizeButton] && [self mouse:mouseLocationInView inRect:minimizeRect])
	{
		// Minimize button
		wasPressedMinimize = isPressedMinimize = YES;
		[self setNeedsDisplay:YES];
	}
	else if([transparentController shouldDisplayModifierButtons] && [self mouse:mouseLocationInView inRect:rightModifierRect])
	{
		// Plus button
		wasPressedPlus = isPressedPlus = YES;
		[self setNeedsDisplay:YES];
	}
	else if([transparentController shouldDisplayModifierButtons] && [self mouse:mouseLocationInView inRect:leftModifierRect])
	{
		// Decrease button
		wasPressedMinus = isPressedMinus = YES;
		[self setNeedsDisplay:YES];
	}
	else if([self mouse:mouseLocationInView inRect:leftButtonRect])
	{
		// Left button
		wasPressedLeft = isPressedLeft = YES;
		[self setNeedsDisplay:YES];
	}
	else if([self mouse:mouseLocationInView inRect:rightButtonRect])
	{
		// Rigth button
		wasPressedRight = isPressedRight = YES;
		[self setNeedsDisplay:YES];
	}
	else if([self mouse:mouseLocationInView inRect:resizeRect])
	{
		// Resize control
		isPressedResize = YES;
		
		// Store mouse location
		initialWindowFrame = [[self window] frame];
		initialLocationInWindow = [event locationInWindow];
		initialLocationInScreen = [[self window] convertBaseToScreen:initialLocationInWindow];
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
	
	if(isPressedResize)
	{
		NSPoint currentScreenLocation = [[self window] convertBaseToScreen:[event locationInWindow]];
	
		float xDiff = currentScreenLocation.x - initialLocationInScreen.x;
		float yDiff = initialLocationInScreen.y - currentScreenLocation.y;
		
		float xRatio = (initialWindowFrame.size.width + xDiff) / initialWindowFrame.size.width;
		float yRatio = (initialWindowFrame.size.height + yDiff) / initialWindowFrame.size.height;
		
		float ratio = (xRatio < yRatio) ? xRatio : yRatio;
		
		NSSize newSize;
		newSize.width = initialWindowFrame.size.width * ratio;
		newSize.height = initialWindowFrame.size.height * ratio;
		
		// Enforce a minimum size
		if(newSize.width < minSize.width || newSize.height < minSize.height)
		{
			newSize.width = minSize.width;
			newSize.height = minSize.height;
		}
		
		NSRect newViewFrame;
		newViewFrame.origin.x = 0.0;
		newViewFrame.origin.y = 0.0;
		newViewFrame.size.width  = newSize.width;
		newViewFrame.size.height = newSize.height;
		
		[self setFrame:newViewFrame];
		
		// Note: Our frame is changed but our bounds stay the same thanks to our overriden setFrame method.
		
		NSRect newWindowFrame;
		newWindowFrame.origin.x = initialWindowFrame.origin.x;
		newWindowFrame.origin.y = initialWindowFrame.origin.y - (newSize.height - initialWindowFrame.size.height);
		newWindowFrame.size.width  = newSize.width;
		newWindowFrame.size.height = newSize.height;
		
		[[self window] setFrame:newWindowFrame display:YES];
		
		return;
	}
	
	// Convert the window coordinates to our scaled coordinate system for this view
	NSPoint mousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
	
	// Close button
	BOOL newIsPressedClose = [self mouse:mousePoint inRect:closeRect];
	
	if([transparentController shouldDisplayCloseButton])
	{
		if(newIsPressedClose != isPressedClose)
		{
			isRolloverClose = isPressedClose = wasPressedClose && newIsPressedClose;
			[self setNeedsDisplay:YES];
		}
	}
	
	// Minimize button
	BOOL newIsPressedMinimize = [self mouse:mousePoint inRect:minimizeRect];
	
	if([transparentController shouldDisplayMinimizeButton])
	{
		if(newIsPressedMinimize != isPressedMinimize)
		{
			isRolloverMinimize = isPressedMinimize = wasPressedMinimize && newIsPressedMinimize;
			[self setNeedsDisplay:YES];
		}
	}
	
	// Left, Right modifiers - Ignored if not currently active
	BOOL newIsPressedMinus = [self mouse:mousePoint inRect:leftModifierRect];
	BOOL newIsPressedPlus = [self mouse:mousePoint inRect:rightModifierRect];
	
	if([transparentController shouldDisplayModifierButtons])
	{
		if((newIsPressedPlus != isPressedPlus) || (newIsPressedMinus != isPressedMinus))
		{
			isRolloverMinus = isPressedMinus = wasPressedMinus && newIsPressedMinus;
			isRolloverPlus = isPressedPlus = wasPressedPlus && newIsPressedPlus;
			[self setNeedsDisplay:YES];
		}
	}
	
	// Left, Right buttons
	BOOL newIsPressedLeft = [self mouse:mousePoint inRect:leftButtonRect];
	BOOL newIsPressedRight = [self mouse:mousePoint inRect:rightButtonRect];
	
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
	
	if(isPressedClose && [transparentController shouldDisplayCloseButton])
	{
		// Close Button
		wasPressedClose = isPressedClose = NO;
		if([self mouse:mousePoint inRect:closeRect])
		{
			[[self window] close];
			[self setNeedsDisplay:YES];
		}
	}
	else if(isPressedMinimize && [transparentController shouldDisplayMinimizeButton])
	{
		// Minimize Button
		wasPressedMinimize = isPressedMinimize = NO;
		if([self mouse:mousePoint inRect:minimizeRect])
		{
			[[self window] miniaturize:self];
			[self setNeedsDisplay:YES];
		}
	}
	else if(isPressedMinus && [transparentController shouldDisplayModifierButtons])
	{
		// Left Modifier
		wasPressedMinus = isPressedMinus = NO;
		if([self mouse:mousePoint inRect:leftModifierRect])
		{
			[transparentController leftModifierClicked];
			[self setNeedsDisplay:YES];
		}
	}
	else if(isPressedPlus && [transparentController shouldDisplayModifierButtons])
	{
		// Right Modifier
		wasPressedPlus = isPressedPlus = NO;
		if([self mouse:mousePoint inRect:rightModifierRect])
		{
			[transparentController rightModifierClicked];
			[self setNeedsDisplay:YES];
		}
	}
	else if(isPressedLeft)
	{
		// Left Button
		wasPressedLeft = isPressedLeft = NO;
		if([self mouse:mousePoint inRect:leftButtonRect])
		{
			[transparentController leftButtonClicked];
			[self setNeedsDisplay:YES];
		}
	}
	else if(isPressedRight)
	{
		// Right Button
		wasPressedRight = isPressedRight = NO;
		if([self mouse:mousePoint inRect:rightButtonRect])
		{
			[transparentController rightButtonClicked];
			[self setNeedsDisplay:YES];
		}
	}
	else
	{
		isPressedResize = NO;
		isPressedWindow = NO;
	}
}

@end
