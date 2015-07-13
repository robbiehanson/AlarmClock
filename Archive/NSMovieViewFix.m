/* Had to create this class, because in the real NSMovieView
** setting the loopMode to NSQTMovieLoopingPlayback doesn't actually work!
** I'll happily delete this class as soon as that bug gets fixed!!
**/

#import "NSMovieViewFix.h"

// Declare private methods
@interface NSMovieViewFix (PrivateAPI)
- (void)didFinishPlaying;
@end

// Declare C-style methods
void QTFinishedPlayingProc(QTCallBack cb, long refCon);

@implementation NSMovieViewFix

- (id)init
{
	if(self = [super init])
	{
		EnterMovies();
    }
	return self;
}

-(void) dealloc
{
	[super dealloc];
}

- (void)start:(id)sender
{
	// Register for callback when finished playing
	callBack = NewCallBack(GetMovieTimeBase([[self movie] QTMovie]), callBackAtExtremes);
	
	CallMeWhen(callBack,					// Call back event, obtained from NewCallBack()
			   (*QTFinishedPlayingProc),	// Pointer to callback function, described in QTCallBackProc
			   (long)self,					// Optional reference to data, we use it so function can get QTMovie reference
			   triggerAtStop,				// Flag1 - call us when stopped
			   (int)NULL,					// Flag2 - not needed
			   (int)NULL);					// Time scale to call function on.  (Any if left null)
	
	// Actually start playing the movie
	[super start:sender];
}

- (void)didFinishPlaying
{	
	// Properly dispose of callback
	CancelCallBack(callBack);
	DisposeCallBack(callBack);
	
	if([self loopMode] == NSQTMovieLoopingPlayback)
	{
		// Restart movie from beginning
		[self gotoBeginning:nil];
		
		// Callback is only good once, reschedule another one
		callBack = NewCallBack(GetMovieTimeBase([[self movie] QTMovie]), callBackAtExtremes);
		
		CallMeWhen(callBack,					// Call back event, obtained from NewCallBack()
				   (*QTFinishedPlayingProc),	// Pointer to callback function, described in QTCallBackProc
				   (long)self,					// Optional reference to data, we use it so function can get NSMovieViewFix reference
				   triggerAtStop,				// Flag1 - call us when stopped
				   (int)NULL,					// Flag2 - not needed
				   (int)NULL);					// Time scale to call function on.  (Any if left null)
	}
}

void QTFinishedPlayingProc(QTCallBack cb, long refCon)
{	
	NSMovieViewFix *movie = (NSMovieViewFix*)refCon;
	[movie didFinishPlaying];
}

@end