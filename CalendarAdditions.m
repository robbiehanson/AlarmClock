#import "CalendarAdditions.h"

@implementation NSCalendarDate (CalendarAdditions)

// FOR COMPARING DATES
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Returns whether or not the current calendarDate is earlier then the given calendarDate.
 Note: If they represent the same date in time, this method returns false.
 Note: Doesn't take into effect the timeZone representation. Just the internal NSDate absolute time.
**/
- (BOOL)isEarlierDate:(NSCalendarDate *)anotherDate
{
	return [self timeIntervalSinceDate:anotherDate] < 0;
}

/**
 Returns whether or not the current calendarDate is later then the given calendarDate.
 Note: If they represent the same date in time, this method returns false.
 Note: Doesn't take into effect the timeZone representation. Just the internal NSDate absolute time.
**/
- (BOOL)isLaterDate:(NSCalendarDate *)anotherDate
{
	return [self timeIntervalSinceDate:anotherDate] > 0;
}

// FOR EXTRACTING PRECISION DATE COMPONENTS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Returns an NSTimeInterval within the minute.
 This can be used to determine both the number of seconds, and milliseconds, of the time within the current minute.
 IE - if the time is 5:42:36.238 AM, this method would return 36.238.
 
 typedef double NSTimeInterval: Always in seconds; yields submillisecond precision...
**/
- (NSTimeInterval)intervalOfMinute
{
	double totalWithMillis = [self timeIntervalSinceReferenceDate] + [[self timeZone] secondsFromGMT];
	int totalWithoutMillis = (int)totalWithMillis;
	
	double sec = totalWithoutMillis % 60;
	double mil = totalWithMillis - totalWithoutMillis;
	
	NSTimeInterval result = sec + mil;
	//NSLog(@"intervalOfMinute: %f", result);
	
	return result;
}

/**
 Returns an NSTimeInterval within the day.
 This can be used to determine both the number of seconds, and milliseconds, of the time within the current day.
 IE - if the time is 12:01:02.003 AM, this method would return 62.003.
 
 typedef double NSTimeInterval: Always in seconds; yields submillisecond precision...
 **/
- (NSTimeInterval)intervalOfDay
{
	double totalWithMillis = [self timeIntervalSinceReferenceDate] + [[self timeZone] secondsFromGMT];
	int totalWithoutMillis = (int)totalWithMillis;
	
	double sec = totalWithoutMillis % 86400;
	double mil = totalWithMillis - totalWithoutMillis;
	
	NSTimeInterval result = sec + mil;
	//NSLog(@"intervalOfDay: %f", result);
	
	return result;
}

// FOR LAYING OUT CALENDARS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Returns whether or not this calendarDate is in a leap year.
**/
- (BOOL)isLeapYear
{
	// LEAP YEAR FORMULA
	// 1. If the year is evenly divisible by 4, go to step 2. Otherwise, go to  step 5.
	// 2. If the year is evenly divisible by 100, go to step 3. Otherwise, go to  step 4.
	// 3. If the year is evenly divisible by 400, go to step 4. Otherwise, go to  step 5.
	// 4. The year is a leap year (it has 366 days).
	// 5. The year is not a leap year (it has 365 days).
	
	int currentYear = [self yearOfCommonEra];
	
	if(currentYear % 4 == 0)
	{
		if(currentYear % 100 == 0)
		{
			if(currentYear % 400 == 0)
				return YES;
		}
		else
			return YES;
	}
	
	return NO;
}

/**
 Returns the number of days in the current month for this calendarDate.
**/
- (int)daysInMonth
{
	switch([self monthOfYear])
	{
		case 2 : return [self isLeapYear] ? 29 : 28;
		case 4 : return 30;
		case 6 : return 30;
		case 9 : return 30;
		case 11: return 30;
		default: return 31;
	}
}

/**
 Returns the weekday of the first day of the month for this calendarDate.
**/
- (int)startingWeekdayOfMonth
{
	int dayDiff = -1 * ([self dayOfMonth] - 1);
	
	NSCalendarDate *startingDay = [self dateByAddingYears:0 months:0 days:dayDiff hours:0 minutes:0 seconds:0];
	
	return [startingDay dayOfWeek];
}

// FOR ALTERING DATES
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Rolls the current time by the specified amount.
 Rolling means that if the time overflows for one field, it loops, and doesn't affect the other fields.
 IE - if the time was 4:55, and you rolled the time 6 minutes, it would now be 4:01
**/
- (NSCalendarDate *)dateByRollingYears:(int)year months:(int)month days:(int)day hours:(int)hour minutes:(int)minute seconds:(int)second
{
	// Make the common case fast.
	// Common case:  only one variable is being rolled.
	
	// Roll seconds (always 60)
	int diffSec = 0;
	if(second != 0)
	{
		diffSec = (([self secondOfMinute] + (second % 60) + 60) % 60) - [self secondOfMinute];
	}
	
	// Roll minutes (always 60)
	int diffMin = 0;
	if(minute != 0)
	{
		diffMin = (([self minuteOfHour] + (minute % 60) + 60) % 60) - [self minuteOfHour];
	}
	
	// Roll hours (always 24)
	int diffHour = 0;
	if(hour != 0)
	{
		diffHour = (([self hourOfDay] + (hour % 24) + 24) % 24) - [self hourOfDay];
	}
	
	// Roll days (variable, starts @ 1)
	int diffDay = 0;
	if(day != 0)
	{
		int d = [self daysInMonth];
		diffDay = ((([self dayOfMonth] - 1) + (day % d) + d) % d) - [self dayOfMonth] + 1;
	}
	
	// Roll months (always 12, starts @ 1)
	int diffMonth = 0;
	if(month != 0)
	{
		diffMonth = ((([self monthOfYear] - 1) + (month % 12) + 12) % 12) - [self monthOfYear] + 1;
	}
	
	return [self dateByAddingYears:year months:diffMonth days:diffDay hours:diffHour minutes:diffMin seconds:diffSec];
}

/**
 Returns a calendar date with the same local time as this one, for the new time zone.
 That is, if the local time for this date is 10:00AM, the local time for the new date will be 10:00AM in it's time zone.
**/
- (NSCalendarDate *)dateBySwitchingToTimeZone:(NSTimeZone *)newTimeZone
{
	NSCalendarDate *result = [NSCalendarDate dateWithYear:[self yearOfCommonEra]
													month:[self monthOfYear]
													  day:[self dayOfMonth]
													 hour:[self hourOfDay]
												   minute:[self minuteOfHour]
												   second:[self secondOfMinute]
												 timeZone:newTimeZone];
	
	return result;
}

@end
