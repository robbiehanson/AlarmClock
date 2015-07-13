#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@interface QTMoviePlayer : NSObject
{
	// The current movie this object is playing
	QTMovie *movie;
	
	// Set to true when initialized with multiple URLs
	BOOL isPlaylist;
	
	// Array containing NSURLs, each pointing to a media file
	NSArray *movieURLs;
	
	// The current index in the movieFiles array that is being played
	int movieURLsIndex;
}

- (id)initWithURL:(NSURL *)URL;
- (id)initWithFile:(NSString *)file;

- (id)initWithURLs:(NSArray *)URLs;

- (BOOL)isPlaying;
- (void)play;
- (void)stop;

@end
