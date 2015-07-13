#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
@class ITunesData;

const int ITunesPlayerStatus_STOPPED = 0;
const int ITunesPlayerStatus_LOADING = 1;
const int ITunesPlayerStatus_READY   = 2;
const int ITunesPlayerStatus_PLAYING = 3;

@interface ITunesPlayer : NSObject <NSURLHandleClient>
{
	// iTunesData reference
	ITunesData *iTunesData;
	
	// The current movie this object is playing
	QTMovie *movie;
	
	// Status. Using constants above.
	int playerStatus;
	
	// Playlist Information
	BOOL isPlaylist;
	int  currentPlaylistID;
	int  currentPlaylistIndex;
	
	// Current song information
	NSString *currentSongName;
	NSString *currentArtistName;
	
	// URL background loading system
	NSURLHandle *urlHandle;
	
	// Our delegate class
	id delegate;
}

- (id)init;
- (id)initWithITunesData:(ITunesData *)dataReference;

- (ITunesData *)iTunesData;

- (void)setFile:(NSString *)file;
- (void)setTrack:(int)trackID;
- (void)setPlaylist:(int)playlistID;

- (int)playerStatus;
- (BOOL)isPlaying;

- (void)play;
- (void)stop;
- (void)abort;

- (NSString *)currentSongName;
- (NSString *)currentArtistName;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

@end

@interface NSObject (ITunesPlayerDelegate)

- (void)iTunesPlayer:(ITunesPlayer *)player hasNewStatus:(int)status;

@end
