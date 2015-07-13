#import <Cocoa/Cocoa.h>

@interface CalendarView : NSView
{
	NSCalendarDate *date;
	NSImage *image;
	NSMutableDictionary *attributes;
	
	int firstDayOfWeek;
	NSArray *weekdays;
}
- (void)setCalendarDate:(NSCalendarDate *)date withValidDay:(BOOL)flag;
- (NSCalendarDate *)calendarDate;

@end