#import <Cocoa/Cocoa.h>


@interface WindowManager : NSObject

+ (void)initialize;
+ (void)deinitialize;

+ (void)openAlarmEditorWithAlarmIndex:(int)alarmIndex;
+ (void)openAlarmEditorForNewAlarm;

+ (void)openAlarmWindow;
+ (NSArray *)alarmWindows;

+ (void)openTimerWindow;
+ (NSArray *)timerWindows;

+ (void)openStopwatchWindow;
+ (NSArray *)stopwatchWindows;

+ (BOOL)canSystemSleep;
+ (NSCalendarDate *)systemWillSleep;
+ (void)systemDidWake;

@end
