#import "ITunesTable.h"


// Declare private methods
@interface ITunesTable (PrivateAPI)

// Private Methods
- (void)resetPlaylist;

// Search Cache
- (BOOL)searchCache:(NSString *)criteria;
- (void)addToCache:(NSString *)criteria array:(NSArray *)result;
- (void)clearCache;

@end

@implementation ITunesTable

/*!
 Standard init routine.
 Sets the current playlist to the entire iTunes library, and initializes the internal search cache.
*/
- (id)init
{
	if(self = [super init])
	{
		// Set current table to be entire library
		[self setPlaylist:0];
		
		// Initialize search cache
		cache = [[NSMutableArray alloc] initWithCapacity:20];
		strCache = [[NSMutableArray alloc] initWithCapacity:20];
	}
	return self;
}


/*!
 Deallocates all memory associated with this instance.
*/
- (void)dealloc
{
	// NSLog(@"Destroying %@", self);
	[table release];
	[cache release];
	[strCache release];
	[super dealloc];
}


/*!
 @abstract   Returns table that is currently being displayed.
 @discussion
 
 The table represents the table that is currently being displayed.
 It may be a subset of the entire library, such as a playlist,
 or even a subset of the playlist, such as when the user is searching for something.
 When writing the table display code, use this method to access the displayable rows.
*/
- (NSArray *)table
{
	return table;
}


/*!
 Sets the table to be the indicated playlist.
 
 The displayable table is reset to contain all track in the specified playlist.
 The search cache is also cleared so incorrect cache hits to not occur.
 
 @param  index - Index (in array) of playlist to use.
 @result Table now contains all tracks in specified playlist.
*/
- (void)setPlaylist:(int)index
{
	// Store playlist index
	playlistIndex = index;
	
	// Setup current table to be the entire playlist
	[self resetPlaylist];
	
	// Clear the search cache
	// This is so that repeat searches in different playlists don't result in incorrect cache hits
	[self clearCache];
}


/*!
 Resets the table to be the entire current playlist.
 
 @result Table now contains all tracks in current playlist.
*/
- (void)resetPlaylist
{
	NSMutableArray *temp = [NSMutableArray array];
	
	NSArray *tracks = [[self playlistForIndex:playlistIndex] objectForKey:PLAYLIST_ITEMS];
	int i;
	for(i=0; i<[tracks count]; i++)
	{
		NSNumber *trackID = [[tracks objectAtIndex:i] objectForKey:TRACK_ID];
		[temp addObject:trackID];
	}
	
	[table release];
	table = [temp retain];
}


/*!
 @abstract   Sets the table to be the indicated playlist.
 @discussion
 
 The displayable table is reset to contain all track in the specified playlist.
 The search cache is also cleared so incorrect cache hits to not occur.
 
 @param  index - Index (in array) of playlist to use.
 @result Table now contains all tracks in specified playlist.
*/
- (void)setSearchCriteria:(NSString *)searchStr
{
	// If the user has cleared the search field, restore viewable table to entire playlist
	if([searchStr isEqualToString:@""])
	{
		[self setPlaylist:playlistIndex];
		return;
	}
	
	// Search cache
	if([self searchCache:searchStr])
	{
		// A Cache Hit occured
		// The cache method already took care of updating the table
		return;
	}
	
	// Reset the table to the entire playlist for searching
	[self resetPlaylist];
	
	// Seperate searchStr by its components - IE: ["John", "Mayer", "Wonderland"]
	NSArray *temp = [searchStr componentsSeparatedByString:@" "];
	
	// For some bizarre reason, temp contains empty strings...get rid of that shit!
	NSMutableArray *components = [NSMutableArray arrayWithArray:temp];
	[components removeObject:@""];
	
	// Perform search for each component, narrowing results each time
	int i, j;
	for(i=0; i<[components count]; i++)
	{
		NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
		
		NSString *str = [components objectAtIndex:i];
		
		NSMutableArray *array = [NSMutableArray array];
		
		for(j=0; j<[table count]; j++)
		{
			int index = [[table objectAtIndex:j] intValue];
			
			NSDictionary *track = [self trackForID:index];
			NSString *name   = [track objectForKey:TRACK_NAME];
			NSString *artist = [track objectForKey:TRACK_ARTIST];
			NSString *album  = [track objectForKey:TRACK_ALBUM];
			
			if((name != nil) && ([name rangeOfString:str options:NSCaseInsensitiveSearch].location != NSNotFound))
			{
				[array addObject:[NSNumber numberWithInt:index]];
			}
			else if((artist != nil) && ([artist rangeOfString:str options:NSCaseInsensitiveSearch].location != NSNotFound))
			{
				[array addObject:[NSNumber numberWithInt:index]];
			}
			else if((album != nil) && ([album rangeOfString:str options:NSCaseInsensitiveSearch].location != NSNotFound))
			{
				[array addObject:[NSNumber numberWithInt:index]];
			}
		}
		
		// Save current table and continue searching and narrowing results
		[table release];
		table = [array retain];
		
		[innerPool release];
	}
	
	[self addToCache:searchStr array:table];
}

// CACHE
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)searchCache:(NSString *)criteria
{	
	int i;
	for(i=0; i<[strCache count]; i++)
	{
		if([criteria caseInsensitiveCompare:[strCache objectAtIndex:i]] == NSOrderedSame)
		{
			[table release];
			table = [[cache objectAtIndex:i] retain];
			return YES;
		}
	}
	
	return NO;
}

- (void)addToCache:(NSString *)criteria array:(NSArray *)result
{
	[strCache insertObject:criteria atIndex:0];
	[cache insertObject:result atIndex:0];
	
	if([strCache count] > 20)
	{
		[strCache removeObjectAtIndex:20];
		[cache removeObjectAtIndex:20];
	}
}

- (void)clearCache
{
	[strCache removeAllObjects];
	[cache removeAllObjects];
}

@end
