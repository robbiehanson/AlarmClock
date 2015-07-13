#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@class ITunesData;


@interface ITunesPlayer : NSObject
{
	// iTunesData reference
	ITunesData *iTunesData;
	
	// The current movie this object is playing
	QTMovie *movie;
	
	// Volume percentage at which to play movies
	float volumePercentage;
	
	// Current type (file, track, playlist), and information
	NSDictionary *currentTrack;
	int type;
	
	// Playlist Information
	BOOL shouldShuffle;
	int  playlistIndex;
	NSMutableArray *playlist;
	
	// Delegate
	id delegate;
}

- (id)initWithITunesData:(ITunesData *)dataReference;

- (void)setFileWithPath:(NSString *)file;
- (void)setTrackWithTrackID:(int)trackID;
- (void)setPlaylistWithPlaylistID:(int)playlistID usesShuffle:(BOOL)shuffleFlag;

- (BOOL)isPlaying;
- (BOOL)isFile;
- (BOOL)isTrack;
- (BOOL)isPlaylist;

- (void)play;
- (void)stop;

- (void)nextTrack;
- (void)previousTrack;

- (NSDictionary *)currentTrack;

- (void)setVolume:(float)volume;

- (void)setDelegate:(id)delegate;
- (id)delegate;

@end

/**
 Method definitions for the delegate of the ITunesPlayer class
**/
@interface NSObject (ITunesPlayerDelegate)
- (void)iTunesPlayerChangedSong;
@end
