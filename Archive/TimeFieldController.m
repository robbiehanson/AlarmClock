#import "TimeFieldController.h"
#import "AlarmFormats.h"
#import "CalendarAdditions.h"

@implementation TimeFieldController

/* Default constructor
 * Sets self as formatter for textField
 * Sets up the format of the textField based on NSTimeFormatString
**/
- (id)initWithTextField:(id)textField
{
	if(self = [super init])
	{
		// Setup references
		timeField = textField;
		
		// Register for delegation and fomatting
		[timeField setFormatter:self];
		
//		// Extract the user's current locale
//		// This must be used when formatting output, or the system default (root) locale is used
//		currentLocale = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] retain];
		
		// Fetch the correct timeFormat, based on the user's preferences
		timeFormat = [[AlarmFormats timeFormat] retain];
		NSLog(@"Setting timeFormat: %@", timeFormat);
		
//		// 10.4
//		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
//		amSymbol = [[dateFormatter AMSymbol] retain];
//		pmSymbol = [[dateFormatter PMSymbol] retain];			
//		NSLog(@"Found AM, PM symbols: %@, %@", amSymbol, pmSymbol);
		
//		// 10.3
//		NSArray *AMPMdesignations = [[NSUserDefaults standardUserDefaults] arrayForKey:NSAMPMDesignation];
//		amSymbol = [[AMPMdesignations objectAtIndex:0] retain];
//		pmSymbol = [[AMPMdesignations objectAtIndex:1] retain];
//		NSLog(@"Found AM, PM symbols: %@, %@", amSymbol, pmSymbol);		

		amSymbol = @"AM";
		pmSymbol = @"PM";
		
		// Set the length for each range
		// We are forcing these to be standard regardless of localization
		s1Range.length = 1;
		s2Range.length = 1;
		hRange.length  = 2;
		mRange.length  = 2;
		aRange.length  = 2;
		
		// Look for the position of the various formatting elements
		NSRange HSearch = [timeFormat rangeOfString:@"%H"];
//		NSRange hSearch = [timeFormat rangeOfString:@"%I"];
//		NSRange aSearch = [timeFormat rangeOfString:@"%p"];
		
		// Setup ranges based on timeFormat
		if(HSearch.length > 0)
		{
			isMilitary = YES;
			hRange.location  = 0;
			s1Range.location = 2;
			mRange.location  = 3;
			s2Range.location = 500;
			aRange.location  = 600;
		}
		else
		{
			isMilitary = NO;
			
//			if(hSearch.location < aSearch.location)
//			{
				hRange.location  = 0;
				s1Range.location = 2;
				mRange.location  = 3;
				s2Range.location = 5;
				aRange.location  = 6;
//			}
//			else
//			{
//				aRange.location  = 0;
//				s1Range.location = 2;
//				hRange.location  = 3;
//				s2Range.location = 5;
//				mRange.location  = 6;
//			}
		}
	}
	return self;
}


/* Deconstructor
** Be a tidy programmer
**/
-(void) dealloc
{
	// Do not release timeField, it is only a reference
//	[currentLocale release];
	[timeFormat release];
	[amSymbol release];
	[pmSymbol release];
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
- (NSString *)formatHourMinute:(int)num
{
	if(num < 10)
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
    return [anObject descriptionWithCalendarFormat:timeFormat];
}

/* Returns the NSFormatter from a string
 * This is part of NSForamtter
**/
- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error
{
	if(obj)
		*obj = [NSCalendarDate dateWithString:string calendarFormat:timeFormat];
	
	if(*obj == nil)
	{
		if(error)
			*error = @"Invalid time string";
		return false;
	}
	else
		return true;
}

/* Called when the user trys to edit the text
 * This method enforces proper time format
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
		NSCalendarDate *test = [NSCalendarDate dateWithString:partialStr calendarFormat:timeFormat];
		
		if((test != nil) && ([partialStr length] == [originalStr length]))
			return YES;
		else
			return NO;
	}
	
	// Extract the character the user was attempting to insert
	unichar charInserted = [partialStr characterAtIndex:originalSelRange.location];
	
	// Are we inserting at a separator?
	// If so, we want to modify the ranges to skip over the separator
	if((originalSelRange.location == s1Range.location) || (originalSelRange.location == s2Range.location))
	{
		originalSelRange.location += 1;
		proposedSelRange.location += 1;
		(*proposedSelRangePtr).location += 1;
	}
	
	// Grab the current values
	int currentHour   = [[originalStr substringWithRange:hRange] intValue];
	int currentMinute = [[originalStr substringWithRange:mRange] intValue];
	NSString *currentSymbol;
	if(!isMilitary)
	{
		currentSymbol = [originalStr substringWithRange:aRange];
	}
	
	BOOL allowChange = NO;
	
	// Hours
	if(NSLocationInRange(originalSelRange.location, hRange))
	{
		allowChange = YES;
		
		// Convert charInserted to numInserted
		int numInserted = [self charToInt:charInserted];
		
		// Immediately ignore input if not a number
		if(numInserted < 0) return NO;
		
		// First character of hour
		if(originalSelRange.location == hRange.location)
		{
			if(isMilitary)
			{
				if(numInserted > 2)
				{
					currentHour = numInserted;
					
					// Shift caret to next field
					if(hRange.location < 3)
						(*proposedSelRangePtr).location += 2;
					else
						(*proposedSelRangePtr).location += 1;
				}
				else if((numInserted == 2) && ((currentHour % 10) > 3))
				{
					currentHour = 20;
				}
				else
				{
					currentHour = (numInserted * 10) + (currentHour % 10);
				}
			}
			else
			{
				if(numInserted > 1)
				{
					currentHour = numInserted;
					
					// Shift caret to next field
					if(hRange.location < 6)
						(*proposedSelRangePtr).location += 2;
					else
						(*proposedSelRangePtr).location += 1;
				}
				else if((numInserted == 1) && ((currentHour % 10) > 2))
				{
					currentHour = 10;
				}
				else
				{
					currentHour = (numInserted * 10) + (currentHour % 10);
				}
			}
		}
		// Second character of hour
		else
		{
			if(isMilitary)
			{
				if((currentHour >= 20) && (numInserted > 3)) return NO;
				
				currentHour = (currentHour / 10 * 10) + numInserted;
				
				// Shift caret to next field (if needed)
				if(hRange.location < 3)
					(*proposedSelRangePtr).location += 1;
			}
			else
			{
				if((currentHour >= 10) && (numInserted > 2)) return NO;
				
				currentHour = (currentHour / 10 * 10) + numInserted;
				
				// Shift caret to next field (if needed)
				if(hRange.location < 6)
					(*proposedSelRangePtr).location += 1;
			}
		}
	}
	// Minutes
	else if(NSLocationInRange(originalSelRange.location, mRange))
	{
		allowChange = YES;
		
		// Convert charInserted to numInserted
		int numInserted = [self charToInt:charInserted];
		
		// Immediately ignore input if not a number
		if(numInserted < 0) return NO;
		
		// First character of minute
		if(originalSelRange.location == mRange.location)
		{
			if(isMilitary)
			{
				if(numInserted > 5)
				{
					currentMinute = numInserted;
					
					// Shift caret to next field
					if(mRange.location < 3)
						(*proposedSelRangePtr).location += 2;
					else
						(*proposedSelRangePtr).location += 1;
				}
				else
				{
					currentMinute = (numInserted * 10) + (currentMinute % 10);
				}
			}
			else
			{
				if(numInserted > 5)
				{
					currentMinute = numInserted;
					
					// Shift caret to next field
					if(mRange.location < 6)
						(*proposedSelRangePtr).location += 2;
					else
						(*proposedSelRangePtr).location += 1;
				}
				else
				{
					currentMinute = (numInserted * 10) + (currentMinute % 10);
				}
			}
		}
		// Second character of minute
		else
		{
			if(isMilitary)
			{
				currentMinute = (currentMinute / 10 * 10) + numInserted;
				
				// Shift caret to next field (if needed)
				if(mRange.location < 3)
					(*proposedSelRangePtr).location += 1;
			}
			else
			{
				currentMinute = (currentMinute / 10 * 10) + numInserted;
				
				// Shift caret to next field (if needed)
				if(mRange.location < 6)
					(*proposedSelRangePtr).location += 1;
			}
		}
	}
	// AM,PM
	else if(NSLocationInRange(originalSelRange.location, aRange))
	{
		allowChange = YES;
		
		// This is a little complex...
		// Here is the situation and what I want to accomplish:
		// We don't know what the symbols are going to be in advance, but we want to support them whatever they are
		// We want to be smart about support - so if they type 'a' we should convert to 'A' if symbol is "AM"
		
		// Convert the symbols to uppercase (for comparison)
		NSString *AMSymbol = [amSymbol uppercaseString];
		NSString *PMSymbol = [pmSymbol uppercaseString];
		
		// Convert the charInserted to uppercase (for comparison)
		NSString *CHARInserted = [[NSString stringWithFormat:@"%C", charInserted] uppercaseString];
		
		// Extract the matching character within the symbols
		// That is, the character the user wishes to replace
		NSRange insertionRange;
		insertionRange.length = 1;
		insertionRange.location = originalSelRange.location - aRange.location;

		NSString *AMSubstring = [AMSymbol substringWithRange:insertionRange];
		NSString *PMSubstring = [PMSymbol substringWithRange:insertionRange];
		
		// If the user is replacing a character properly, we allow the replacement
		// Otherwise, we stop them
		if([CHARInserted isEqualToString:AMSubstring] && [CHARInserted isEqualToString:PMSubstring])
		{
			// This is like typing in the 'M' in PM
			// No need to actually change anything
		}
		else if([CHARInserted isEqualToString:AMSubstring])
		{
			// Switching to AM
			currentSymbol = amSymbol;
		}
		else if([CHARInserted isEqualToString:PMSubstring])
		{
			// Switching to PM
			currentSymbol = pmSymbol;
		}
		else
		{
			// Typing in something that doesn't make sense
			// Ignore input
			return NO;
		}
		
		// Shift caret to next field (if needed)
		if(aRange.location < 6)
		{
			if(proposedSelRange.location == aRange.location + aRange.length)
				(*proposedSelRangePtr).location += 1;
		}
	}
	
	if(allowChange)
	{
		NSMutableString *newTime = [[originalStr mutableCopy] autorelease];
		[newTime replaceCharactersInRange:hRange withString:[self formatHourMinute:currentHour]];
		[newTime replaceCharactersInRange:mRange withString:[self formatHourMinute:currentMinute]];
		if(!isMilitary)
		{
			[newTime replaceCharactersInRange:aRange withString:currentSymbol];
		}
		
		*partialStrPtr = newTime;
	}
	return NO;
}

/* Called from NSStepper action
 * The caret position should be passed in for index
**/
- (NSRange)incrementAtIndex:(int )index
{
	NSString *str = [timeField stringValue];
	NSCalendarDate *temp = [NSCalendarDate dateWithString:str calendarFormat:timeFormat];
	
	// Hours
	if(NSLocationInRange(index, hRange) || index == hRange.location + hRange.length)
	{
		temp = [temp dateByRollingYears:0 months:0 days:0 hours:1 minutes:0 seconds:0];
		[timeField setStringValue:[temp descriptionWithCalendarFormat:timeFormat]];
		return hRange;
	}
	// Minutes
	else if(NSLocationInRange(index, mRange) || index == mRange.location + mRange.length)
	{
		temp = [temp dateByRollingYears:0 months:0 days:0 hours:0 minutes:1 seconds:0];
		[timeField setStringValue:[temp descriptionWithCalendarFormat:timeFormat]];
		return mRange;
	}
	// AM,PM
	else
	{
		temp = [temp dateByRollingYears:0 months:0 days:0 hours:12 minutes:0 seconds:0];
		[timeField setStringValue:[temp descriptionWithCalendarFormat:timeFormat]];
		return aRange;
	}
}

/* Called from NSStepper action
 * The caret position should be passed in for index
**/
- (NSRange)decrementAtIndex:(int )index
{
	NSString *str = [timeField stringValue];
	NSCalendarDate *temp = [NSCalendarDate dateWithString:str calendarFormat:timeFormat];
	
	// Hours
	if(NSLocationInRange(index, hRange) || index == hRange.location + hRange.length)
	{
		temp = [temp dateByRollingYears:0 months:0 days:0 hours:-1 minutes:0 seconds:0];
		[timeField setStringValue:[temp descriptionWithCalendarFormat:timeFormat]];
		return hRange;
	}
	// Minutes
	else if(NSLocationInRange(index, mRange) || index == mRange.location + mRange.length)
	{
		temp = [temp dateByRollingYears:0 months:0 days:0 hours:0 minutes:-1 seconds:0];
		[timeField setStringValue:[temp descriptionWithCalendarFormat:timeFormat]];
		return mRange;
	}
	// AM,PM
	else
	{
		temp = [temp dateByRollingYears:0 months:0 days:0 hours:-12 minutes:0 seconds:0];
		[timeField setStringValue:[temp descriptionWithCalendarFormat:timeFormat]];
		return aRange;
	}
}

@end