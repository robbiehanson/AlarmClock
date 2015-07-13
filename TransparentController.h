/**
 Protocol to define the methods that will be invoke by TransparentView.
**/

@protocol TransparentController

// Correspondence Info Methods
- (BOOL)shouldDisplayCloseButton;
- (BOOL)shouldDisplayMinimizeButton;
- (BOOL)shouldDisplayModifierButtons;

- (NSString *)title;
- (NSString *)statusLine1;
- (NSString *)statusLine2;
- (NSString *)rightModifierStr;
- (NSString *)leftModifierStr;
- (NSString *)timeStr;
- (NSString *)leftButtonStr;
- (NSString *)rightButtonStr;

// Correspondence Action Methods
- (void)statusLineClicked;
- (void)leftModifierClicked;
- (void)rightModifierClicked;
- (void)leftButtonClicked;
- (void)rightButtonClicked;

- (BOOL)canSystemSleep;
- (NSCalendarDate *)systemWillSleep;
- (void)systemDidWake;

@end
