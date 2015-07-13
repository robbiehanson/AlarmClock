#import <Cocoa/Cocoa.h>


@interface RHAliasHandler : NSObject

+ (BOOL)isAliasFile:(NSString *)path;
+ (NSString *)resolveAlias:(NSString *)path;
+ (NSString *)resolvePath:(NSString *)path;

@end
