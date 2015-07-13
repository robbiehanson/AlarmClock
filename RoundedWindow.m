#import "RoundedWindow.h"

@implementation RoundedWindow

/**
 We override the standard init method to return a transparent window, with no title bar.
 Instead, we are going to rely on the timer view to handle all the drawing.
**/
- (id)initWithContentRect:(NSRect)contentRect 
                styleMask:(unsigned int)aStyle 
                  backing:(NSBackingStoreType)bufferingType 
                    defer:(BOOL)flag
{
    if (self = [super initWithContentRect:contentRect 
								styleMask:NSBorderlessWindowMask
								  backing:NSBackingStoreBuffered
									defer:NO])
	{
		// Use this level to make it above all other applications
        [self setLevel: NSStatusWindowLevel];
		
		// Use this level to let the user put it in the background
		//[self setLevel: NSNormalWindowLevel];
		
        [self setBackgroundColor:[NSColor clearColor]];
        [self setAlphaValue:1.0];
        [self setOpaque:NO];
        [self setHasShadow:YES];
		
		// Disable movableByWindowBackground
		// If this is enabled, the window is movable via clicks on our buttons
		// We will implement window moving within the view itself
		[self setMovableByWindowBackground:NO];
		
		// Listen for mouse movement
		// We need to forward these events to our custom view
		[self setAcceptsMouseMovedEvents:YES];
    }
    return self;
}

/**
 Don't forget to tidy up when we're done!
 We don't actually create any variables, but it's good practice to do this anyways.
**/
-(void) dealloc
{
	// NSLog(@"Destroying %@", self);
	[super dealloc];
}

/**
 We want to be able to become the key window, so we override this method to enforce this.
 The default implementation returns YES if the window has a title bar or resize control.
 The transparentView implements a title bar and resize control, so this is still standard OS X policy.
**/
- (BOOL)canBecomeKeyWindow
{
    return YES;
}

/**
 We want to listen to mouse movement events.
 However, we don't actually have anything to do with them.
 Our transparentView needs them, so we forward them to the timerView.
**/
- (void)mouseMoved:(NSEvent *)theEvent
{
	[roundedView mouseMoved:theEvent];
}

@end