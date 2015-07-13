#import <Cocoa/Cocoa.h>
#import "ITunesData.h"

@interface ITunesTable : ITunesData
{
	// Holds the indexes of the tracks currently being displayed
	NSArray *table;
	
	// Current playlist index
	int playlistIndex;
	
	// Search cache
	NSMutableArray *strCache;
	NSMutableArray *cache;
}

- (NSArray *)table;
- (void)setPlaylist:(int)index;
- (void)setSearchCriteria:(NSString *)searchStr;

@end
