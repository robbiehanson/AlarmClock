#import <Cocoa/Cocoa.h>

#define LIBRARY_PERSISTENTID          @"Library Persistent ID"
#define MUSIC_FOLDER                  @"Music Folder"

#define TRACK_ID                      @"Track ID"
#define TRACK_PERSISTENTID            @"Persistent ID"
#define TRACK_LOCATION                @"Location"
#define TRACK_TOTALTIME               @"Total Time"
#define TRACK_NAME                    @"Name"
#define TRACK_ARTIST                  @"Artist"
#define TRACK_ALBUM                   @"Album"
#define TRACK_TRACKNUMBER             @"Track Number"
#define TRACK_TRACKCOUNT              @"Track Count"
#define TRACK_ISPROTECTED             @"Protected"

#define PLAYLIST_ID                   @"Playlist ID"
#define PLAYLIST_PERSISTENTID         @"Playlist Persistent ID"
#define PLAYLIST_NAME                 @"Name"
#define PLAYLIST_ITEMS                @"Playlist Items"

#define PLAYLIST_PARENT_PERSISTENTID  @"Parent Persistent ID"

#define PLAYLIST_TYPE_MASTER          @"Master"
#define PLAYLIST_TYPE_MUSIC           @"Music"
#define PLAYLIST_TYPE_MOVIES          @"Movies"
#define PLAYLIST_TYPE_TVSHOWS         @"TV Shows"
#define PLAYLIST_TYPE_PODCASTS        @"Podcasts"
#define PLAYLIST_TYPE_VIDEOS          @"Videos"
#define PLAYLIST_TYPE_AUDIOBOOKS      @"Audiobooks"
#define PLAYLIST_TYPE_PURCHASED       @"Purchased Music"
#define PLAYLIST_TYPE_PARTYSHUFFLE    @"Party Shuffle"
#define PLAYLIST_TYPE_FOLDER          @"Folder"
#define PLAYLIST_TYPE_SMART           @"Smart Info"


@interface ITunesData : NSObject
{
	// Dictionary with contents of music library xml file
	NSDictionary *library;
}

- (id)init;

- (NSArray *)playlists;

- (int)playlistIndexForID:(int)playlistID;

- (NSDictionary *)playlistForID:(int)playlistID;
- (NSDictionary *)playlistForIndex:(int)playlistIndex;

- (NSDictionary *)trackForID:(int)trackID;

- (int)trackIndexForID:(int)trackID;
- (int)trackIndexForID:(int)trackID withPlaylistID:(int)playlistID;
- (int)trackIndexForID:(int)trackID withPlaylistIndex:(int)playlistIndex;

- (int)validateTrackID:(int)trackID withPersistentTrackID:(NSString *)persistentTrackID;
- (int)validatePlaylistID:(int)playlistID withPersistentPlaylistID:(NSString *)persistentPlaylistID;

@end