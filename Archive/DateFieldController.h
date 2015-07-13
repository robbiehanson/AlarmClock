#import <Cocoa/Cocoa.h>


@interface DateFieldController : NSFormatter
{
	// Reference to textField
	NSTextField *dateField;
	
	// Formatting information
	NSString *dateFormat;
	NSRange s1Range;
	NSRange s2Range;
	NSRange dRange;
	NSRange mRange;
	NSRange yRange;
}

- (id)initWithTextField:(id )textField;

- (NSRange)incrementAtIndex:(int )index;
- (NSRange)decrementAtIndex:(int )index;

@end