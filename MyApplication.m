#import "MyApplication.h"
#import "RoundedController.h"
#import "WindowManager.h"


@implementation MyApplication

- (void)snooze:(NSScriptCommand *)command
{
	NSLog(@"snooze called via applescript!");
	
	NSArray *alarmWindows = [WindowManager alarmWindows];
	
	int i;
	for(i = 0; i < [alarmWindows count]; i++)
	{
		[[alarmWindows objectAtIndex:i] leftButtonClicked];
	}
}

@end
