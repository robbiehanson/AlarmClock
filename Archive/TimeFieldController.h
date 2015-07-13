#import <Cocoa/Cocoa.h>


@interface TimeFieldController : NSFormatter
{
	// Reference to textField
	NSTextField *timeField;
	
	// Formatting information
//	NSDictionary *currentLocale;
	NSString *timeFormat;
	NSString *amSymbol;
	NSString *pmSymbol;
	BOOL isMilitary;
	NSRange s1Range;
	NSRange s2Range;
	NSRange hRange;
	NSRange mRange;
	NSRange aRange;
}

- (id)initWithTextField:(id )textField;

- (NSRange)incrementAtIndex:(int )index;
- (NSRange)decrementAtIndex:(int )index;

@end
