#import "QTMoviePlayer.h"

// Declare private methods
@interface QTMoviePlayer (PrivateAPI)
- (void)movieFinished:(NSNotification *)notification;
@end

@implementation QTMoviePlayer

/*!
 @abstract   Initializes player with a single URL
 @discussion
 
 This creates a player that plays a single URL that loops.
 */
- (id)initWithURL:(NSURL *)URL
{
	if(self = [super init])
	{
		// Register as a non-playlist
		isPlaylist = NO;
		
		// Create the movie
		if([QTMovie canInitWithURL:URL])
		{
			movie = [[QTMovie alloc] initWithURL:URL error:nil];
			[movie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieLoopsAttribute];
		}
	}
	return self;
}


/*!
 @abstract   Initializes player with a single file.
 @discussion
 
 This creates a player that plays a single file that loops.
 */
- (id)initWithFile:(NSString *)file
{
	NSURL *fileURL = [NSURL fileURLWithPath:file];
	return [self initWithURL:fileURL];
}


/*!
 @abstract   Allows multiple movies to be set, and played in order.
 @discussion
 
 This method allows the QTMovie to support playlists, basically.
 Each NSURL in the passed array, will be used (in turn) to create a QTMovie.
 All URLs are assumed to exist, and be readable.
 
 @param  URLs - Array of NSURLs, representing valid URLs that can be used to create QTMovies.
 @result When played, all specified movies will be played in order.
 */
- (id)initWithURLs:(NSArray *)URLs
{
	if(self = [super init])
	{
		// Register as a playlist
		isPlaylist = YES;
		
		// Store the list of movies in new array, and the movie index
		movieURLs = [URLs retain];
		movieURLsIndex = 0;
		
		int loopCount = 0;
		do
		{
			// Create the movie
			if([QTMovie canInitWithURL:[movieURLs objectAtIndex:movieURLsIndex]])
			{
				movie = [[QTMovie alloc] initWithURL:[movieURLs objectAtIndex:movieURLsIndex] error:nil];
			}
			
			// Set the movie to the next item in the playlist, looping if needed
			movieURLsIndex = ++movieURLsIndex % [movieURLs count];
			
			// Increment loopCount, we only want to iterate through the array once
			// We use a loopCount, because movieURLsIndex is always zero if movieURLs is nil
			loopCount++;
		}
		while((movie == nil) && (loopCount < [movieURLs count]));
		
		// Register for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(movieFinished:)
													 name:QTMovieDidEndNotification
												   object:nil];
	}
	return self;
}

/*!
 @abstract   Don't forget to clean up your mess.
 @discussion
 
 Releases all resources created by this class,
 before sending the dealloc message up the inheritance chain.
 */
-(void) dealloc
{
	// Remove self from all notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	// Release memory
	[movie release];
	[movieURLs release];
	[super dealloc];
}

/*!
 @abstract   Returns YES is the movie is currently playing
 @discussion
 
 Method correlates to NSMovie's isPlaying method.
 This helps to reduce code changes while migrating from NSMovie to QTMovie.
 */
- (BOOL)isPlaying
{
	if(movie == nil)
		return NO;
	else
		return !([movie rate] == 0);
}


- (void)play
{
	if(movie != nil)
	{
		[movie play];
	}
}

- (void)stop
{
	if(movie != nil)
	{
		[movie stop];
	}
}

/*!
 @abstract   Called when using a playlist, and the current song has finished playing
 @discussion
 
 This method facilitates the playlist functionality.
 It switches the movie to the next song in the playlist and plays it.
 */
- (void)movieFinished:(NSNotification *)notification
{
	if(movie == [notification object])
	{
		do
		{
			// Release the last movie
			[movie release];
			
			// Create the movie
			if([QTMovie canInitWithURL:[movieURLs objectAtIndex:movieURLsIndex]])
			{
				movie = [[QTMovie alloc] initWithURL:[movieURLs objectAtIndex:movieURLsIndex] error:nil];
				[movie play];
			}
			
			// Set the movie to the next item in the playlist, looping if needed
			movieURLsIndex = ++movieURLsIndex % [movieURLs count];
		}
		while(movie == nil);
	}
}

@end
