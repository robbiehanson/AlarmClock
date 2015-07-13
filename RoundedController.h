/**
 Protocol to define the methods that will be invoke by TransparentView.
**/

@protocol RoundedController

// Correspondence Info Methods
- (BOOL)shouldDisplayPlusMinusButtons;

- (NSString *)statusLine1;
- (NSString *)statusLine2;
- (NSString *)plusButtonStr;
- (NSString *)minusButtonStr;
- (NSString *)timeStr;
- (NSString *)leftButtonStr;
- (NSString *)rightButtonStr;

	// Correspondence Action Methods
- (void)statusLineClicked;
- (void)plusButtonClicked;
- (void)minusButtonClicked;
- (void)leftButtonClicked;
- (void)rightButtonClicked;

- (BOOL)canSystemSleep;
- (NSCalendarDate *)systemWillSleep;
- (void)systemDidWake;

@end