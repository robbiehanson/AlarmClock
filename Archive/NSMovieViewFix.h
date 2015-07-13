#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>

@interface NSMovieViewFix: NSMovieView
{
	QTCallBack callBack;
}

@end
