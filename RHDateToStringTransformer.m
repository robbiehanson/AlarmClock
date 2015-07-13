#import "RHDateToStringTransformer.h"


@implementation RHDateToStringTransformer

// CLASS METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (Class)transformedValueClass;
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation;
{
    return NO;   
}

// TRANSFORMING WORK
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)transformedValue:(id)value;
{
	if(![value isKindOfClass:[NSDate class]])
		return nil;
	
	NSCalendarDate *date;
	if([value isKindOfClass:[NSCalendarDate class]])
		date = value;
	else
		date = [value dateWithCalendarFormat:nil timeZone:nil];
	
	int today = [[NSCalendarDate calendarDate] dayOfCommonEra];
	int dateDay = [date dayOfCommonEra];
	
	
	if(dateDay == today)
	{
		// NSUserDefaults Constant: NSThisDayDesignations:
		// Key for an array of strings that specify what this day is called.
		// The default is an array containing two strings, "today" and "now".
		NSArray *todayDesignations;
		
		todayDesignations = [[NSUserDefaults standardUserDefaults] stringArrayForKey:NSThisDayDesignations];
		NSString *todayStr = [[todayDesignations objectAtIndex:0] capitalizedString];
		
		NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
		[df setFormatterBehavior:NSDateFormatterBehavior10_4];
		[df setDateStyle:NSDateFormatterNoStyle];
		[df setTimeStyle:NSDateFormatterShortStyle];
		
		return [NSString stringWithFormat:@"%@ %@", todayStr, [df stringFromDate:date]]; 
	}
	else if(dateDay == (today-1))
	{
		// NSUserDefaults Constant: NSPriorDayDesignations:
		// Key for an array of strings that denote the day before today.
		// The default is an array that contains a single string, "yesterday".
		NSArray *yesterdayDesignations;
		
		yesterdayDesignations = [[NSUserDefaults standardUserDefaults] stringArrayForKey:NSPriorDayDesignations];
		NSString *yesterdayStr = [[yesterdayDesignations objectAtIndex:0] capitalizedString];
		
		NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
		[df setFormatterBehavior:NSDateFormatterBehavior10_4];
		[df setDateStyle:NSDateFormatterNoStyle];
		[df setTimeStyle:NSDateFormatterShortStyle];
		
		return [NSString stringWithFormat:@"%@ %@", yesterdayStr, [df stringFromDate:date]]; 
	}
	else
	{
		NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
		[df setFormatterBehavior:NSDateFormatterBehavior10_4];
		[df setDateStyle:NSDateFormatterMediumStyle];
		[df setTimeStyle:NSDateFormatterShortStyle];
		
		return [df stringFromDate:date];
	}
}

@end
