#import "ITunesData.h"
#import "Prefs.h"
#import "RHAliasHandler.h"

// Declare private API
@interface ITunesData (PrivateAPI)
- (NSString *)locateITunesMusicLibrary;
@end

@implementation ITunesData

// INIT, DEALLOC
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)init
{
	if(self = [super init])
	{
		// Get path of iTunes Music Library file
		
		// First we check the preferences to see if an override exists
		NSString *xmlPath = [Prefs xmlPath];
		
		// If an override doesn't exist, we search for the location of the file
		if([xmlPath isEqualToString:@""])
		{
			xmlPath = [self locateITunesMusicLibrary];
			NSLog(@"Found iTunes library: %@", xmlPath);
		}
		else
		{
			NSLog(@"Using configured XMLPath: %@", xmlPath);
		}
		
		// Load iTunes Music Library xml/plist file
		library = [[NSDictionary alloc] initWithContentsOfFile:xmlPath];
	}
	return self;
}

- (void)dealloc
{
	NSLog(@"Destroying %@", self);
	[library release];
	[super dealloc];
}

// SEARCHING FOR ITUNES MUSIC LIBRARY
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Searches for the location of the "iTunes Music Library.xml" file.
 In order to do this, it follows the same search pattern that iTunes follows.
 Most of the logic behind this search is based on the information from here:
 http://www.indyjt.com/blog/?p=51
*/
- (NSString *)locateITunesMusicLibrary
{
	NSString *xmlPath1 = [@"~/Music/iTunes/iTunes Music Library.xml" stringByExpandingTildeInPath];
	NSString *xmlPath2 = [@"~/Documents/iTunes/iTunes Music Library.xml" stringByExpandingTildeInPath];
	NSArray *locations = [NSArray arrayWithObjects:xmlPath1, xmlPath2, nil];
	
	int i;
	BOOL found = NO;
	NSString *xmlPath = nil;
	for(i = 0; i < [locations count] && !found; i++)
	{
		xmlPath = [RHAliasHandler resolvePath:[locations objectAtIndex:i]];
				
		found = [[NSFileManager defaultManager] fileExistsAtPath:xmlPath];
	}
	
	if(found)
		return xmlPath;
	else
		return nil;
}

// DATA EXTRACTION
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Returns array of playlist dictionaries.
 
 Returns an array, which may be accessed like any other array (objectAtIndex, count, etc...)
 Each object in the array is an NSDictionary, which contains info for that particular playlist.
 Each playlist dictionary contains the following keys (among others):
 Name - Name of playlist
 Playlist ID - Unique ID number of playlist, which should be used as name and index in array may change over time.
 Playlist Items - Array of dictionaries, each containing a track ID number.
**/
- (NSArray *)playlists
{
	return [library objectForKey:@"Playlists"];
}

/**
 Returns the array index of the playlist with the given playlist ID.
 
 Although playlists are stored in an array, and referenced via their array index, this index is obviously not permanent.
 That is, the playlist index may be different upon a different parse of the iTunes library.
 The playlist ID is thus often used to identify a particular playlist.
 This method returns the index in the playlists array which may be used to access it.
 If the playlistID is not found, -1 is returned.
**/
- (int)playlistIndexForID:(int)playlistID
{
	NSArray *playlists = [self playlists];
	
	int index = 0;
	BOOL found = NO;
	while(!found && (index < [playlists count]))
	{
		NSDictionary *playlist = [playlists objectAtIndex:index];
		
		if([[playlist objectForKey:PLAYLIST_ID] intValue] == playlistID)
			found = YES;
		else
			index++;
	}
	
	if(found)
		return index;
	else
		return -1;
}

/**
Returns the playlist that has the given playlist ID.
 
 Searches all playlists for the one with the given ID.
 When this is found, it is returned.
 Otherwise, nil is returned.
 
 @param playlistID - The ID of the desired playlist in the XML database.
 **/
- (NSDictionary *)playlistForID:(int)playlistID
{
	int playlistIndex = [self playlistIndexForID:playlistID];
	if(playlistIndex >= 0)
		return [self playlistForIndex:playlistIndex];
	else
		return nil;
}

/**
 Returns the playlist dictionary for the given index (in the array)
  
 Same as [[data playlists] objectAtIndex:playlistIndex]
 Here as a convenience method to make code look prettier and more understandable.
 
 @param playlistIndex - The index of the desired playlist, in the array of playlists.
*/
- (NSDictionary *)playlistForIndex:(int)playlistIndex
{
	return [[self playlists] objectAtIndex:playlistIndex];
}

/**
 Returns the dictionary for the given track index.
  
 Each track dictionary contains the following keys (among others):
 Name - Name of song (IE - Your Body is a Wonderland)
 Artist - Name of artist (IE - John Mayer)
 Album - Name of album track is from (IE - Room For Squares)
 Total Time - Number of milliseconds in song
 Location - File URL
 
 @param trackID - The ID of the desired track in the XML database.
**/
- (NSDictionary *)trackForID:(int)trackID
{
	return [[library objectForKey:@"Tracks"] objectForKey:[NSString stringWithFormat:@"%i",trackID]];
}

/**
 Returns the index of the track (in the main library) for the given track ID.
 
 Although tracks are stored in a dictionary, and accessed via a key (their track ID),
 an index may be needed when displaying the information in a table, and needing the position of the track.
 
 If the track is found in the library, the index of the track is returned.
 If it's not found, -1 is returned.
 
 @param trackID - The ID of the desired track in the XML database.
**/
- (int)trackIndexForID:(int)trackID
{
	// Note: The main library is always the first playlist
	return [self trackIndexForID:trackID withPlaylistIndex:0];
}

/**
 Returns the index of the track (in the given playlist) for the given track ID.
 
 Although tracks are stored in a dictionary, and accessed via a key (their track ID),
 an index may be needed when displaying the information in a table, and needing the position of the track.
 
 If the track is found in the given playlist, the index of the track is returned.
 If it's not found, -1 is returned.
 
 @param trackID - The ID of the desired track in the XML database.
 @param playlistID - The ID of the playlist that should be searched for the position of the given track.
**/
- (int)trackIndexForID:(int)trackID withPlaylistID:(int)playlistID
{
	// Convert the playlistID into it's playlistIndex
	int playlistIndex = [self playlistIndexForID:playlistID];
	
	// And lookup the trackIndex within the playlistIndex
	return [self trackIndexForID:trackID withPlaylistIndex:playlistIndex];
}

/**
 Returns the index of the track (in the given playlist) for the given track ID.
 
 Although tracks are stored in a dictionary, and accessed via a key (their track ID),
 an index may be needed when displaying the information in a table, and needing the position of the track.
 
 If the track is found in the given playlist, the index of the track is returned.
 If it's not found, -1 is returned.
 
 @param trackID - The ID of the desired track in the XML database.
 @param playlistIndex - The index of the playlist that should be searched for the position of the given track.
**/
- (int)trackIndexForID:(int)trackID withPlaylistIndex:(int)playlistIndex
{
	// First make sure the playlistIndex is valid
	if((playlistIndex < 0) || (playlistIndex >= [[self playlists] count]))
	{
		return -1;
	}
	
	NSArray *playlist = [[self playlistForIndex:playlistIndex] objectForKey:PLAYLIST_ITEMS];
	
	int index = 0;
	BOOL found = NO;
	while(!found && (index < [playlist count]))
	{
		NSString *trackRef = [[playlist objectAtIndex:index] objectForKey:TRACK_ID];
		
		if(trackID == [trackRef intValue])
			found = YES;
		else
			index++;
	}
	
	if(found)
		return index;
	else
		return -1;
}


// ID VALIDATION
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Returns the proper trackID for the given persistentID.
 
 Track ID's are not persistent across multiple creations of the "iTunes Music Library.xml" file from iTunes.
 Thus storing the trackID will not guarantee the same song will be played upon the next XML parse.
 Luckily apple provides a persistentID which may be used to lookup a song across multiple XML parses.
 However, the trackID is the key in which to lookup the song, so it is more or less necessary.
 
 This method provides a means with which to map a persistentID to it's corresponding trackID.
 The trackID which is assumed to be correct is passed along with it.
 This helps, because often times it is correct, and thus a search may be avoided.
 
 @param trackID - The old trackID that was used for the song with this persistentID.
 @param persistentTrackID - This is the persistentID for the song, which doesn't change between XML parses.
 
 @return The trackID that currently corresponds to the given persistentID, or -1 if the persistentID was not found.
**/
- (int)validateTrackID:(int)trackID withPersistentTrackID:(NSString *)persistentTrackID
{
	// Ignore the validation request if the persistentTrackID is nil (uninitialized)
	// This will happen for new alarms
	// It will also happen after upgrading to 2.2.1, where prior versions didn't support persistent ID's.
	if(persistentTrackID == nil)
	{
		return trackID;
	}
	
	// Get the track for the specified trackID
	NSDictionary *dict = [self trackForID:trackID];
	
	// Does the persistentID match the one given
	if((dict != nil) && [[dict objectForKey:TRACK_PERSISTENTID] isEqualToString:persistentTrackID])
	{
		// It's a match.! Just return the original trackID.
		return trackID;
	}
	
	// The trackID has changed!
	// Now we have to loop through the tracks, and find the one with the correct persistentID
	NSEnumerator *enumerator = [[library objectForKey:@"Tracks"] objectEnumerator];
	NSDictionary *currentTrack;
	BOOL found = NO;
		
	while(!found && (currentTrack = [enumerator nextObject]))
	{
		found = [[currentTrack objectForKey:TRACK_PERSISTENTID] isEqualToString:persistentTrackID];
	}
	
	if(found)
		return [[currentTrack objectForKey:TRACK_ID] intValue];
	else
		return -1;
}

/**
 Returns the proper playlistID for the given persistentID.
 
 Playlist ID's are not persistent across multiple creations of the "iTunes Music Library.xml" file from iTunes.
 Thus storing the playlistID will not guarantee the same playlist will be played upon the next XML parse.
 Luckily apple provides a persistentID which may be used to lookup a playlist across multiple XML parses.
 However, the playlistID is the key in which to lookup the playlist, so it is more or less necessary.
 
 This method provides a means with which to map a persistentID to it's corresponding playlistID.
 The playlistID which is assumed to be correct is passed along with it.
 This helps, because often times it is correct, and thus a search may be avoided.
 
 @param playlistID - The old playlistID that was used for the song with this persistentID.
 @param persistentPlaylistID - This is the persistentID for the playlist, which doesn't change between XML parses.
 
 @return The playlistID that currently corresponds to the given persistentID, or -1 if the persistentID was not found.
**/
- (int)validatePlaylistID:(int)playlistID withPersistentPlaylistID:(NSString *)persistentPlaylistID
{
	// Ignore the validation request if the persistentPlaylistID is nil (uninitialized)
	// This will happen for new alarms
	// It will also happen after upgrading to 2.2.1, where prior versions didn't support persistent ID's.
	if(persistentPlaylistID == nil)
	{
		return playlistID;
	}
	
	// Get the track for the specified trackID
	NSDictionary *dict = [self playlistForID:playlistID];
	
	// Does the persistentID match the one given
	if((dict != nil) && [[dict objectForKey:PLAYLIST_PERSISTENTID] isEqualToString:persistentPlaylistID])
	{
		// It's a match.! Just return the original trackID.
		return playlistID;
	}
	
	// The trackID has changed!
	// Now we have to loop through the tracks, and find the one with the correct persistentID
	NSEnumerator *enumerator = [[library objectForKey:@"Playlists"] objectEnumerator];
	NSDictionary *currentPlaylist;
	BOOL found = NO;
	
	while(!found && (currentPlaylist = [enumerator nextObject]))
	{
		found = [[currentPlaylist objectForKey:PLAYLIST_PERSISTENTID] isEqualToString:persistentPlaylistID];
	}
	
	if(found)
		return [[currentPlaylist objectForKey:PLAYLIST_ID] intValue];
	else
		return -1;
}

@end