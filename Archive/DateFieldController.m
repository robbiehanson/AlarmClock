#import "DateFieldController.h"
#import "AlarmFormats.h"
#import "CalendarAdditions.h"

@implementation DateFieldController

BOOL isDayFirst = NO;

/* Default constructor
 * Sets self as formatter for textField
 * Sets up the format of the textField based on NSTimeFormatString
**/
- (id)initWithTextField:(id)textField
{
	if(self = [super init])
	{		
		// Setup references
		dateField = textField;
		
		// Register for delegation and fomatting
		[dateField setFormatter:self];
		
		// Fetch the correct timeFormat, based on the user's preferences
		dateFormat = [[AlarmFormats dateFormat] retain];
		NSLog(@"Setting dateFormat: %@", dateFormat);
		
		// Set the length for each range
		// We are forcing these to be standard regardless of localization
		s1Range.length = 1;
		s2Range.length = 1;
		dRange.length  = 2;
		mRange.length  = 2;
		yRange.length  = 4;
		
		// Look for the position of the various formatting elements
		NSRange dSearch = [dateFormat rangeOfString:@"%d"];
		NSRange mSearch = [dateFormat rangeOfString:@"%m"];
		NSRange ySearch = [dateFormat rangeOfString:@"%Y"];
		
		// Setup ranges based on timeFormat
		if((dSearch.location < mSearch.location) && (dSearch.location < ySearch.location))
		{
			if(mSearch.location < ySearch.location)
			{
				// Day, Month, Year (Most of the world)
				dRange.location  = 0;
				s1Range.location = 2;
				mRange.location  = 3;
				s2Range.location = 5;
				yRange.location  = 6;
			}
			else
			{
				// Day, Year, Month (Probably never used)
				dRange.location  = 0;
				s1Range.location = 2;
				yRange.location  = 3;
				s2Range.location = 7;
				mRange.location  = 8;
			}
		}
		else if((mSearch.location < dSearch.location) && (mSearch.location < ySearch.location))
		{
			if(dSearch.location < ySearch.location)
			{
				// Month, Day, Year (Standard US)
				mRange.location  = 0;
				s1Range.location = 2;
				dRange.location  = 3;
				s2Range.location = 5;
				yRange.location  = 6;
			}
			else
			{
				// Month, Year, Day (Probably never used)
				mRange.location  = 0;
				s1Range.location = 2;
				yRange.location  = 3;
				s2Range.location = 7;
				dRange.location  = 8;
			}
		}
		else
		{
			if(mSearch.location < dSearch.location)
			{
				// Year, Month, Day (A few countries)
				yRange.location  = 0;
				s1Range.location = 4;
				mRange.location  = 5;
				s2Range.location = 7;
				dRange.location  = 8;
			}
			else
			{
				// Year, Day, Month (Standard China, Japan, Korea, Taiwan, ...)
				yRange.location  = 0;
				s1Range.location = 4;
				dRange.location  = 5;
				s2Range.location = 7;
				mRange.location  = 8;
			}
		}
	}
	return self;
}


/* Deconstructor
** Be a tidy programmer
**/
-(void) dealloc
{
	// Do not release dateField, it is only a reference
	[dateFormat release];
	[super dealloc];
}


/* Simple utility to convert char to int
** I'm sure there's a C function that will do this,
** but C is confusing, complicated and ugly.
** And this method works just fine.
**/
- (int)charToInt:(char) c
{
	if(c == '0') return 0;
	if(c == '1') return 1;
	if(c == '2') return 2;
	if(c == '3') return 3;
	if(c == '4') return 4;
	if(c == '5') return 5;
	if(c == '6') return 6;
	if(c == '7') return 7;
	if(c == '8') return 8;
	if(c == '9') return 9;
	return -1;
}


/* Formats the given number into a proper string for display in the date field.
 * Basically, this class just converts the integer into a number, and pads with a 0
 * if less than 10.
 * This functionallity exists in NSNumberFormatter as of 10.4, but I'm trying to keep 10.3 compatibility...
 * for the time being.
 */
- (NSString *)formatDayMonth:(int)num
{
	if(num < 10)
		return [NSString stringWithFormat:@"0%i", num];
	else
		return [NSString stringWithFormat:@"%i", num];
}

- (NSString *)formatYear:(int)num
{
	if(num < 10)
		return [NSString stringWithFormat:@"000%i", num];
	else if(num < 100)
		return [NSString stringWithFormat:@"00%i", num];
	else if(num < 1000)
		return [NSString stringWithFormat:@"0%i", num];
	else
		return [NSString stringWithFormat:@"%i", num];
}


/* Returns the properly formatted string from an NSCalendarDate
 * This is part of the NSFormatter
**/
- (NSString *)stringForObjectValue:(id)anObject
{
    if (![anObject isKindOfClass:[NSCalendarDate class]]) {		
        return nil;
    }
    return [anObject descriptionWithCalendarFormat:dateFormat];
}

/* Returns the NSFormatter from a string
 * This is part of NSForamtter
**/
- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error
{
	if(obj)
		*obj = [NSCalendarDate dateWithString:string calendarFormat:dateFormat];
	
	if(*obj == nil)
	{
		if(error)
			*error = @"Invalid date string";
		return NO;
	}
	else
		return YES;
}

/* Called when the user trys to edit the text
 * This method enforces proper date format
**/
- (BOOL)isPartialStringValid:(NSString **)partialStrPtr
	   proposedSelectedRange:(NSRangePointer)proposedSelRangePtr
			  originalString:(NSString *)originalStr
	   originalSelectedRange:(NSRange)originalSelRange
			errorDescription:(NSString **)error
{
	NSString *partialStr = *partialStrPtr;
	NSRange proposedSelRange = *proposedSelRangePtr;
	
	// If the user is attempting to backspace
	if(originalSelRange.location == proposedSelRange.location)
	{
		// Attempting backspace.  Move caret instead.
		*partialStrPtr = [NSString stringWithString:originalStr];
		
		// Change caret position appropriately (if backspacing over separators)
		if((proposedSelRange.location == s1Range.location) || (proposedSelRange.location == s2Range.location))
			(*proposedSelRangePtr).location -= 1;
		
		return NO;
	}
	
	// If the user is attempting to replace a character range
	if(originalSelRange.length > 0)
	{
		// Attempting to replace character range...
		// Allow replacement only if valid
		NSCalendarDate *test = [NSCalendarDate dateWithString:partialStr calendarFormat:dateFormat];
		
		if((test != nil) && ([partialStr length] == [originalStr length]))
			return YES;
		else
			return NO;
	}
	
	
	int numInserted = [self charToInt:[partialStr characterAtIndex:originalSelRange.location]];
		
	// Immediately ignore input if not a number
	if(numInserted < 0) return NO;
	
	// Are we inserting at a separator?
	// If so, we want to modify the ranges to skip over the separator
	if((originalSelRange.location == s1Range.location) || (originalSelRange.location == s2Range.location))
	{
		originalSelRange.location += 1;
		(*proposedSelRangePtr).location += 1;
	}
	
	// Grab the current values
	int currentDay   = [[originalStr substringWithRange:dRange] intValue];
	int currentMonth = [[originalStr substringWithRange:mRange] intValue];
	int currentYear  = [[originalStr substringWithRange:yRange] intValue];
	
	BOOL allowChange = NO;
		
	// Days
	if(NSLocationInRange(originalSelRange.location, dRange))
	{
		allowChange = YES;
		
		// First character of day
		if(originalSelRange.location == dRange.location)
		{
			if(numInserted > 3)
			{
				currentDay = numInserted;
				
				// Shift caret to next field
				if(dRange.location < 8)
					(*proposedSelRangePtr).location += 2;
				else
					(*proposedSelRangePtr).location += 1;
			}
			else if(numInserted == 3 && ((currentDay % 10) > 1))
			{
				currentDay = 30;
			}
			else
			{
				currentDay = (numInserted * 10) + (currentDay % 10);
			}
		}
		// Second character of day
		else
		{
			if((currentDay >= 30) && (numInserted > 1)) return NO;
			
			currentDay = (currentDay / 10 * 10) + numInserted;
			
			// Shift caret to next field (if needed)
			if(dRange.location < 8)
				(*proposedSelRangePtr).location += 1;
		}
	}
	// Months
	else if(NSLocationInRange(originalSelRange.location, mRange))
	{
		allowChange = YES;
		
		// First character of month
		if(originalSelRange.location == mRange.location)
		{
			if(numInserted > 1)
			{
				currentMonth = numInserted;
				
				// Shift caret to next field
				if(mRange.location < 8)
					(*proposedSelRangePtr).location += 2;
				else
					(*proposedSelRangePtr).location += 1;
			}
			else if(numInserted == 1 && ((currentMonth % 10) > 2))
			{
				currentMonth = 10;
			}
			else
			{
				currentMonth = (numInserted * 10) + (currentMonth % 10);
			}
		}
		// Second character of month
		else
		{
			if((currentMonth >= 10) && (numInserted > 2)) return NO;
			
			currentMonth = (currentMonth / 10 * 10) + numInserted;
			
			// Shift caret to next field (if needed)
			if(mRange.location < 8)
				(*proposedSelRangePtr).location += 1;
		}

	}
	// Years
	else if(NSLocationInRange(originalSelRange.location, yRange))
	{
		allowChange = YES;
		
		int num1 = (currentYear / 1000);
		int num2 = (currentYear / 100) % 10;
		int num3 = (currentYear / 10) % 10;
		int num4 = (currentYear % 10);
		
		if(originalSelRange.location == yRange.location)
			num1 = numInserted;
		else if(originalSelRange.location == yRange.location + 1)
			num2 = numInserted;
		else if(originalSelRange.location == yRange.location + 2)
			num3 = numInserted;
		else
		{
			num4 = numInserted;
			
			// Shift caret to next field (if needed)
			if(yRange.location < 6)
			{
				(*proposedSelRangePtr).location += 1;
			}
		}
		
		currentYear = (num1 * 1000) + (num2 * 100) + (num3 * 10) + num4;
	}
	
	if(allowChange)
	{
		NSMutableString *newDate = [[originalStr mutableCopy] autorelease];
		[newDate replaceCharactersInRange:dRange withString:[self formatDayMonth:currentDay]];
		[newDate replaceCharactersInRange:mRange withString:[self formatDayMonth:currentMonth]];
		[newDate replaceCharactersInRange:yRange withString:[self formatYear:currentYear]];
		
		*partialStrPtr = newDate;
	}
	return NO;
}

/* Called from NSStepper action
 * The caret position should be passed in for index
**/
- (NSRange)incrementAtIndex:(int )index
{
	NSString *str = [dateField stringValue];
	NSCalendarDate *temp = [NSCalendarDate dateWithString:str calendarFormat:dateFormat];
	
	// Days
	if(NSLocationInRange(index, dRange) || index == dRange.location + dRange.length)
	{
		temp = [temp dateByRollingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
		[dateField setStringValue:[temp descriptionWithCalendarFormat:dateFormat]];
		return dRange;
	}
	// Months
	else if(NSLocationInRange(index, mRange) || index == mRange.location + mRange.length)
	{
		temp = [temp dateByRollingYears:0 months:1 days:0 hours:0 minutes:0 seconds:0];
		[dateField setStringValue:[temp descriptionWithCalendarFormat:dateFormat]];
		return mRange;
	}
	// Years
	else
	{
		temp = [temp dateByRollingYears:1 months:0 days:0 hours:0 minutes:0 seconds:0];
		[dateField setStringValue:[temp descriptionWithCalendarFormat:dateFormat]];
		return yRange;
	}
}

/* Called from NSStepper action
 * The caret position should be passed in for index
**/
- (NSRange)decrementAtIndex:(int)index
{
	NSString *str = [dateField stringValue];
	NSCalendarDate *temp = [NSCalendarDate dateWithString:str calendarFormat:dateFormat];
	
	// Days
	if(NSLocationInRange(index, dRange) || index == dRange.location + dRange.length)
	{
		temp = [temp dateByRollingYears:0 months:0 days:-1 hours:0 minutes:0 seconds:0];
		[dateField setStringValue:[temp descriptionWithCalendarFormat:dateFormat]];
		return dRange;
	}
	// Months
	else if(NSLocationInRange(index, mRange) || index == mRange.location + mRange.length)
	{
		temp = [temp dateByRollingYears:0 months:-1 days:0 hours:0 minutes:0 seconds:0];
		[dateField setStringValue:[temp descriptionWithCalendarFormat:dateFormat]];
		return mRange;
	}
	// Years
	else
	{
		temp = [temp dateByRollingYears:-1 months:0 days:0 hours:0 minutes:0 seconds:0];
		[dateField setStringValue:[temp descriptionWithCalendarFormat:dateFormat]];
		return yRange;
	}
}

@end
