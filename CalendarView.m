#import "CalendarView.h"
#import "CalendarAdditions.h"

@implementation CalendarView

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// INIT, DEALLOC
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(NSRect)frameRect
{
	if((self = [super initWithFrame:frameRect]) != nil)
	{
		// Initialize date
		date = [[NSCalendarDate alloc] init];
		
		// Setup image
		NSBundle *bundle  = [NSBundle bundleForClass:[self class]];
		NSString *imgPath = [bundle pathForImageResource:@"CalendarBack.tiff"];	
		image = [[NSImage alloc] initWithContentsOfFile:imgPath];
		
		// Setup display attributes
		NSFont *displayFont = [NSFont labelFontOfSize:[NSFont labelFontSize]];
		
		NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
		[paragraphStyle setAlignment:NSCenterTextAlignment];
		
		attributes = [[NSMutableDictionary alloc] initWithCapacity:2];
		[attributes setObject:displayFont    forKey:NSFontAttributeName];
		[attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
		
		// Determine what the first day of the week is based on the user's locale
		// Sunday = 1
		// Monday = 2
		// etc...
		// We subtract one because the internal code uses Sunday as 0
		// This makes it easier to do modulus arithmetic (i = ++i % 7)
		firstDayOfWeek = [[NSCalendar currentCalendar] firstWeekday] - 1;
		
		// Setup weekdays array, which contains the initials for the days of the week
		// The weekdays array is in the proper order for the current locale
		NSArray *shortWeekDays = [[NSUserDefaults standardUserDefaults] arrayForKey:NSShortWeekDayNameArray];
		
		NSMutableArray *weekdaysTemp = [NSMutableArray arrayWithCapacity:7];
		int i = firstDayOfWeek;
		while([weekdaysTemp count] < 7)
		{
			[weekdaysTemp addObject:[[shortWeekDays objectAtIndex:i] substringToIndex:1]];
			i = (i+1) % 7;
		}
		
		weekdays = [weekdaysTemp copy];
	}
	return self;
}

- (void)dealloc
{
	[date release];
	[image release];
	[attributes release];
	[weekdays release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// PUBLIC METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Changes the date displayed on the calendar.
 * 
 * Explanation of 'withValidDay' flag.
 * When changing from month to month, or year to year, it is generally desirable to keep the selected day the same.
 * For example, if you select May 20th, and then switch to April, you would expect the date to be April 20th.
 * However, this is not always possible, as there are not the same number of days in each month.
 * 
 * If you set the validDay flag to true, the calendar will switch to that exact day.
 * If you set the validDay flag to false, the calendar will attempt to keep the day the same, and if that's not possible
 * then it will use the given day passed in the newDate parameter.
**/
- (void)setCalendarDate:(NSCalendarDate *)newDate withValidDay:(BOOL)flag
{
	if(flag)
	{
		[date autorelease];
		date = [[NSCalendarDate alloc] initWithYear:[newDate yearOfCommonEra]
											  month:[newDate monthOfYear]
												day:[newDate dayOfMonth]
											   hour:0
											 minute:0
											 second:0
										   timeZone:[NSTimeZone defaultTimeZone]];
	}
	else
	{
		int day = ([date dayOfMonth] > [date daysInMonth]) ? [date daysInMonth] : [date dayOfMonth];
		
		[date autorelease];
		date = [[NSCalendarDate alloc] initWithYear:[newDate yearOfCommonEra]
											  month:[newDate monthOfYear]
												day:day
											   hour:0
											 minute:0
											 second:0
										   timeZone:[NSTimeZone defaultTimeZone]];
	}
	
	[self setNeedsDisplay:YES];
}

/**
 * Returns the date currently selected on the calendar.
 * The returned date is an autoreleased copy.
**/
- (NSCalendarDate *)calendarDate
{
	return [[date copy] autorelease];
}

/**
 * I find it easier to use a 'flipped' view for the particular drawing done in this class.
**/
- (BOOL)isFlipped
{
	return YES;
}

- (void)mouseDown:(NSEvent *)event
{
	NSPoint pt = [self convertPoint:[event locationInWindow] fromView:nil];
	
	int firstCell = 0 - [date startingWeekdayOfMonth] + 1 + firstDayOfWeek;
	int offset = (firstCell > 1) ? -7 : 0;
	
	int row, col;
	BOOL found = NO;
	BOOL different = NO;
	for(row=0; row<=5 && !found; row++)
	{
		for(col=0; col<7 && !found; col++)
		{
			int x =  5 + (col * 17);
			int y = 21 + (row * 14);
			
			if(pt.x >= x && pt.x <= x+17 && pt.y >= y && pt.y <=y+13)
			{
				int num = (row * 7) + col - [date startingWeekdayOfMonth] + 1 + firstDayOfWeek + offset;
				
				if(num > 0 && num <= [date daysInMonth])
				{
					if([date dayOfMonth] != num) different = YES;
					
					[date autorelease];
					date = [[NSCalendarDate dateWithYear:[date yearOfCommonEra]
												   month:[date monthOfYear] 
													 day:num 
													hour:0 
												  minute:0 
												  second:0 
												timeZone:[date timeZone]] retain];
					found = YES;
				}
			}
		}
	}
	
	if(found && different) [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)event
{
	// If the user drags the mouse across the calendar, we want the selected date to follow the mouse.
	// Thus we fire a mouseDown event while the user is dragging their mouse across the calendar.
	[self mouseDown:event];
}

- (void)drawRect:(NSRect)rect
{	
	// Draw background image
	NSPoint pt1;
	pt1.x = 0;
	pt1.y = 113;
	[image compositeToPoint:pt1 operation:NSCompositeSourceOver];
	
	NSRect displayRect;
	displayRect.size.width  = 17;
	displayRect.size.height = 13;
	
	// Draw table headers
	int i;
	for(i = 0; i < 7; i++)
	{
		displayRect.origin.x = 5 + (i * 17);
		displayRect.origin.y = 5;
		[[weekdays objectAtIndex:i] drawInRect:displayRect withAttributes:attributes];
	}
	
	// Draw days of the month
	int firstCell = 0 - [date startingWeekdayOfMonth] + 1 + firstDayOfWeek;
	int offset = (firstCell > 1) ? -7 : 0;
	
	int row, col;
	for(row = 0; row <= 5; row++)
	{
		for(col = 0; col < 7; col++)
		{
			int num = (row * 7) + col - [date startingWeekdayOfMonth] + 1 + firstDayOfWeek + offset;
			
			displayRect.origin.x =  5 + (col * 17);
			displayRect.origin.y = 21 + (row * 14);
			
			if(num > 0 && num <= [date daysInMonth])
			{
				if(num == [date dayOfMonth])
				{
					[[NSColor selectedTextBackgroundColor] set];
					[NSBezierPath fillRect:displayRect];
				}
				
				NSString *displayStr = [NSString stringWithFormat:@"%i",num];
				[displayStr drawInRect:displayRect withAttributes:attributes];
			}
		}
	}
}

@end