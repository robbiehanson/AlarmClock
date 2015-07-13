#import <Foundation/Foundation.h>
@class Alarm;

@interface AlarmScheduler : NSObject

+ (void)initialize;
+ (void)deinitialize;

// Saving alarm info to user defaults
+ (void)savePrefs;

// Getting alarms
+ (Alarm *)alarmReferenceForIndex:(int)index;
+ (Alarm *)alarmCloneForIndex:(int)index;

// Changing alarms
+ (void)setAlarm:(Alarm *)clone forReference:(Alarm *)reference;
+ (void)addAlarm:(Alarm *)newAlarm;
+ (void)removeAlarm:(Alarm *)deletedAlarm;

// Updating alarms
+ (void)updateAllAlarms;

// Getting number of alarms
+ (int)numberOfAlarms;

// Getting info about next and last alarm
+ (Alarm *)lastAlarmClone;
+ (NSCalendarDate *)nextAlarmDate;

// Querying for sounding alarms
+ (int)alarmStatus:(NSCalendarDate *)now;

@end