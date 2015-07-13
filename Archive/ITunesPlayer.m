/*!
 The ITunesPlayer class provides functionallity for playing anything in the iTunes library.
 It can play tracks (whether they be files, radio streams, or podcasts) and it can also play entire playlists.
 
 @author Robbie Hanson
*/

#import "ITunesPlayer.h"
#import "ITunesData.h"


// Declare private methods
@interface ITunesPlayer (PrivateAPI)
- (void)setTrack:(int)trackID repeats:(BOOL)repeats;
- (void)setPlayerStatus:(int)newStatus;
@end

@implementation ITunesPlayer

/*!
 Creates a new ITunesPlayer with it's own ITunesData.
*/
- (id)init
{
	if(self = [super init])
	{
		// Create new iTunesData for internal use
		iTunesData = [[ITunesData alloc] init];
		
		// Register for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(movieFinished:)
													 name:QTMovieDidEndNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(movieRateChanged:)
													 name:QTMovieRateDidChangeNotification
												   object:nil];
	}
	return self;
}

/*!
 Creates a new ITunesPlayer which references the given ITunesData.
*/
- (id)initWithITunesData:(ITunesData *)dataReference
{
	if(self = [super init])
	{
		// Retain reference to existing iTunesData
		iTunesData = [dataReference retain];
		
		// Register for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(movieFinished:)
													 name:QTMovieDidEndNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(movieRateChanged:)
													 name:QTMovieRateDidChangeNotification
												   object:nil];
	}
	return self;
}

/*!
 Don't forget to tidy up afterwards!
 */
- (void)dealloc
{
	NSLog(@"Destroying %@", self);
	
	// Remove notification observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	// Remove any objects we created
	[iTunesData release];
	[movie release];
	[currentSongName release];
	[currentArtistName release];
	
	// Move up the inheritance chain
	[super dealloc];
}

// GETTER METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*!
 Returns a reference to the iTunesData being used by this player.
 
 The player can be initialized with existing iTunesData, or it can create it's own.
 In the case that it creates it's own, this is a convenience method to return a reference to the data.
 This way, the data can be used if needed outside this class.
*/
- (ITunesData *)iTunesData
{
	return iTunesData;
}

// CONFIGURATION METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*!
 Sets the player to play ths specified file.
 
 If the player is currently playing a song, the player is stopped.
 The player is automatically properly configured to play the track,
 whether it be an audio stream, pls URL, or audio file.
 
 @param file  String that points to a file on the local filesystem.
*/
- (void)setFile:(NSString *)filepath
{
	// Stop and release the movie if needed
	[movie release];
	movie = nil;
	
	NSURL *url = [NSURL fileURLWithPath:filepath];
	
	movie = [[QTMovie alloc] initWithURL:url error:nil];
	if(movie != nil)
	{
		[movie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieLoopsAttribute];
		[self setPlayerStatus:ITunesPlayerStatus_READY];
	}
	
	isPlaylist = NO;
}

- (void)setTrack:(int)trackID asPartOfPlaylist:(BOOL)partOfPlaylist
{
	// Store playlist setting
	// This will be used later when playing the track to conditionally set looping
	isPlaylist = partOfPlaylist;
	
	// Get the specified track from the iTunesData
	NSDictionary *track = [iTunesData trackForID:trackID];
	
	NSLog(@"Setting track: \n%@", track);
	
	if(track == nil)
	{
		[self setPlayerStatus:ITunesPlayerStatus_STOPPED];
	}
	else
	{
		// Update currentSongName and currentArtistName
		[currentSongName release];
		[currentArtistName release];
		
		currentSongName = [[track objectForKey:@"Name"] retain];
		currentArtistName = [[track objectForKey:@"Artist"] retain];
		
		// Figure out what type it is
		NSString *trackType = [track objectForKey:@"Track Type"];
		
		if([trackType isEqualToString:@"URL"])
		{
			NSLog(@"Track Type: URL");
			
			NSURL *url = [NSURL URLWithString:[track objectForKey:@"Location"]];
			urlHandle = [url URLHandleUsingCache:YES];
			[urlHandle addClient:self];
			[urlHandle loadInBackground];
		}
		else
		{
			NSLog(@"Track Type: File");
			
			// Assume the location points to a standard audio file
			NSURL *url = [NSURL URLWithString:[track objectForKey:@"Location"]];
			
			movie = [[QTMovie alloc] initWithURL:url error:nil];
			if(movie != nil)
			{
				[self setPlayerStatus:ITunesPlayerStatus_READY];
			}
			else
			{
				[self setPlayerStatus:ITunesPlayerStatus_STOPPED];
			}
		}
	}
}

/*!
 Configures the player to play the specified track within iTunes.
 
 If the player is currently playing a song, the player is stopped, without delegate notification.
 The player is automatically properly configured to play the track,
 whether it be an audio stream, pls URL, or audio file.
 The delegate is in charge of calling play when the player is ready.
 
 @param trackID  ID of the track in the iTunes library.
*/
- (void)setTrack:(int)trackID
{	
	// Stop and release the movie if needed
	[movie release];
	
	// Set the track
	[self setTrack:trackID asPartOfPlaylist:NO];
}

/*!
 Configures the player to play the specified playlist within iTunes.
 
 If the player is currently playing a song, the player is stopped, without delegate notification.
 The player is configured to play the each track in the playlist in order.
 Each track is automatically properly configured, whether it be an audio stream, pls URL, or audio file.
 The delegate is in charge of calling play when the player is ready.
 The delegate must properly call play for each song in the playlist.
 
 @param playlistID  ID of the playlist in the iTunes library.
 */
- (void)setPlaylist:(int)playlistID;
{
	// Stop and release the movie if needed
	[movie release];
	
	// Store playlist information for later
	currentPlaylistID = playlistID;
	currentPlaylistIndex = 0;
	
	// Get playlist
	NSDictionary *playlistDict = [iTunesData playlistForID:currentPlaylistID];
	NSArray *playlistArray = [playlistDict objectForKey:@"Playlist Items"];
	
	if([playlistArray count] > 0)
	{
		// Set with first track in playlist
		NSDictionary *dict = [playlistArray objectAtIndex:currentPlaylistIndex];
		NSString *trackID = [dict objectForKey:@"Track ID"];
		[self setTrack:[trackID intValue] asPartOfPlaylist:YES];
	}
	else
	{
		// The playlist is empty
		[self setPlayerStatus:ITunesPlayerStatus_STOPPED];
	}
}

// PLAYER STATUS METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)isPlaying
{
	return playerStatus != ITunesPlayerStatus_STOPPED;
}

- (int)playerStatus
{
	return playerStatus;
}

- (void)setPlayerStatus:(int)newStatus
{
	playerStatus = newStatus;
	
	if([delegate respondsToSelector:@selector(iTunesPlayer:hasNewStatus:)])
	{
		[delegate iTunesPlayer:self hasNewStatus:playerStatus];
	}
}

// PLAYER CONTROL METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*!
 Plays/Resumes the player.
 
 If the track or playlist has not been set, this method has no effect.
 If a track or playlist has been set, and a series of play/stop methods have been invoked, the player starts playing
 where it left off (unpauses).
*/
- (void)play
{
	[movie play];
	if(!isPlaylist)
	{
		[movie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieLoopsAttribute];
	}
}


/*!
 Stops/Pauses the player from playing.
 
 If the track or playlist has not been set, or the movie is not playing,
 this method has no effect.
*/
- (void)stop
{
	[movie stop];
}

- (void)abort
{
	[urlHandle cancelLoadInBackground];
}

// DELEGATE CONTROL
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)delegate
{
    return delegate;
}

- (void)setDelegate:(id)newDelegate
{
    delegate = newDelegate;
}

// BACKGROUND URL LOADING METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)URLHandleResourceDidBeginLoading:(NSURLHandle *)sender
{
	// Sent by sender when the URL handle begins loading resource data.
	NSLog(@"URLHandleResourceDidBeginLoading");
	
	[self setPlayerStatus:ITunesPlayerStatus_LOADING];
}

- (void)URLHandleResourceDidCancelLoading:(NSURLHandle *)sender
{
	// Sent by sender when the URL handle has canceled loading resource data in response to a programmatic request.
	NSLog(@"URLHandleResourceDidCancelLoading");
	
	[self setPlayerStatus:ITunesPlayerStatus_STOPPED];
}

- (void)URLHandleResourceDidFinishLoading:(NSURLHandle *)sender
{
	// Sent by sender when the URL handle finishes loading resource data.
	NSLog(@"URLHandleResourceDidFinishLoading");
	
	[self setPlayerStatus:ITunesPlayerStatus_READY];
}

- (void)URLHandle:(NSURLHandle *)sender resourceDataDidBecomeAvailable:(NSData *)newBytes
{
	// Sent by sender periodically when newBytes resource data becomes available from the URL handle.
	NSLog(@"URLHandle:resourceDataDidBecomeAvailable:");
}

- (void)URLHandle:(NSURLHandle *)sender resourceDidFailLoadingWithReason:(NSString *)reason
{
	// Sent by sender when the URL handle fails to load resource data for some reason other than being canceled.
	NSLog(@"URLHandle:resourceDidFailLoadingWithReason:");
	
	[self setPlayerStatus:ITunesPlayerStatus_STOPPED];
}

//- (void)setupRadioStreamWithTrack:(NSDictionary *)track
//{	
//	BOOL repeats = NO;
//	
//	// We know have to figure out what kind of track this is.
//	// Is it a regular file, a pls file, an audio stream...
//	// We can look at the track's Kind to help determine this.
//	
//	NSString *trackKind = [track objectForKey:@"Kind"];
//	NSString *trackLocation = [track objectForKey:@"Location"];
//	
//	// Unfortuneately, iTunes has a bug where they don't properly sync radio stations in the XML file
//	// It will sometimes report the Kind as "MPEG audio stream", when it's actually "Playlist URL"
//	
//	NSString *kind;
//	if([trackKind isEqualToString:@"MPEG audio stream"])
//	{
//		if([trackLocation hasPrefix:@"http://pri.kts-af.net/redir/index.pls?"])
//		{
//			// iTunes is lying again
//			kind = @"Playlist URL";
//		}
//		else
//			kind = @"MPEG audio stream";
//	}
//	else
//	{
//		kind = trackKind;
//	}
//	
//	// Now that we know the proper kind, we can do our thing
//	
//	if([kind isEqualToString:@"MPEG audio stream"])
//	{
//		NSLog(@"Kind: MPEG audio stream");
//		
//		// The location is the URL of an audio stream
//		// The location may be valid as is, or the 'http' may need to be changed to 'icy'
//		NSString *location = [track objectForKey:@"Location"];
//		if([location hasPrefix:@"http"])
//		{
//			NSMutableString *temp = [[location mutableCopy] autorelease];
//			
//			NSRange range;
//			range.location = 0;
//			range.length = 4;
//			
//			[temp replaceCharactersInRange:range withString:@"icy"];
//			location = [[temp copy] autorelease];
//		}
//		NSURL *url = [NSURL URLWithString:location];
//		
//		movie = [[QTMovie alloc] initWithURL:url error:nil];
//		if(movie != nil && repeats)
//		{
//			[movie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieLoopsAttribute];
//		}
//	}
//	else if([kind isEqualToString:@"Playlist URL"])
//	{
//		NSLog(@"Kind: Playlist URL");
//		
//		// The location points to a pls playlist file
//		// QuickTime can play this, but must be told it's looking at a pls file
//		NSLog(@"Getting url");
//		NSURL *url = [NSURL URLWithString:[track objectForKey:@"Location"]];
//
//		NSLog(@"Getting data");
//		NSData *plsData = [NSData dataWithContentsOfURL:url];
//		
//		NSLog(@"Getting dataReference");
//		QTDataReference *dt = [QTDataReference dataReferenceWithReferenceToData:plsData name:@"stream.pls" MIMEType:nil];
//		
//		NSLog(@"Getting dataReference");
//		QTDataReference *dt = [QTDataReference dataReferenceWithReferenceToURL:url];
//		
//		NSLog(@"Initializing movie");
//		movie = [[QTMovie alloc] initWithDataReference:dt error:nil];
//		if(movie != nil && repeats)
//		{
//			NSLog(@"Setting movie attributes");
//			[movie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieLoopsAttribute];
//		}
//	}
//	else
//	{
//		NSLog(@"Kind: Audio File");
//		
//		// Assume the location points to a standard audio file
//		NSURL *url = [NSURL URLWithString:[track objectForKey:@"Location"]];
//		
//		movie = [[QTMovie alloc] initWithURL:url error:nil];
//		if(movie != nil && repeats)
//		{
//			[movie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieLoopsAttribute];
//		}
//	}
//	
//}


// DELEGATE METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*!
 Called when a song has finished playing.
 
 This method facilitates the playlist functionality.
 It switches the movie to the next song in the playlist and plays it.
*/
- (void)movieFinished:(NSNotification *)notification
{
	NSLog(@"movieFinished");
	
	// This method is called for every movie in the application finishing
	// Check to make sure the movie is the one we're looking for
	if(isPlaylist && (movie == [notification object]))
	{
		// Get playlist
		NSDictionary *playlistDict = [iTunesData playlistForID:currentPlaylistID];
		NSArray *playlistArray = [playlistDict objectForKey:@"Playlist Items"];
		
		// Move to the next item in the playlist, looping if needed
		currentPlaylistIndex = ++currentPlaylistIndex % [playlistArray count];
		NSLog(@"currentPlaylistIndex: %i", currentPlaylistIndex);
			
		NSDictionary *dict = [playlistArray objectAtIndex:currentPlaylistIndex];
		NSString *trackID = [dict objectForKey:@"Track ID"];
		[self setTrack:[trackID intValue] asPartOfPlaylist:YES];
	}
}

- (void)movieRateChanged:(NSNotification *)notification
{
	NSLog(@"Movie rate changed!");
	
	if([movie rate] == 0)
		[self setPlayerStatus:ITunesPlayerStatus_STOPPED];
	else
		[self setPlayerStatus:ITunesPlayerStatus_PLAYING];
}

@end
