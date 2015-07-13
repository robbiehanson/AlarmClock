#import <Foundation/Foundation.h>

@interface NSCalendarDate (CalendarAdditions)

// For comparing dates
- (BOOL)isEarlierDate:(NSCalendarDate *)anotherDate;
- (BOOL)isLaterDate:(NSCalendarDate *)anotherDate;

// For extracting precision date components
- (NSTimeInterval)intervalOfMinute;
- (NSTimeInterval)intervalOfDay;

// For laying out calendars
- (BOOL) isLeapYear;
- (int) daysInMonth;
- (int) startingWeekdayOfMonth;

// For altering dates
- (NSCalendarDate *)dateByRollingYears:(int)year months:(int)month days:(int)day hours:(int)hour minutes:(int)minute seconds:(int)second;
- (NSCalendarDate *)dateBySwitchingToTimeZone:(NSTimeZone *)newTimeZone;

@end
