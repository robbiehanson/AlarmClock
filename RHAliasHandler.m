#import "RHAliasHandler.h"


@implementation RHAliasHandler

/**
Detects whether the file at the given path is an alias.
 
 This is basically a Cocoa wrapper for FSIsAliasFile.
 This code was more of less copied from here:
 http://developer.apple.com/documentation/Cocoa/Conceptual/LowLevelFileMgmt/Tasks/ResolvingAliases.html
**/
+ (BOOL)isAliasFile:(NSString *)path
{
    BOOL isAlias = NO;
	
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)path, kCFURLPOSIXPathStyle, NO);
    if(url != NULL)
    {
		FSRef fileRef;
        if(CFURLGetFSRef(url, &fileRef))
        {
            Boolean aliasFlag;
            Boolean folderFlag;
            FSIsAliasFile(&fileRef, &aliasFlag, &folderFlag);
            if(aliasFlag)
                isAlias = YES;
        }
        CFRelease(url);
    }
    return isAlias;
}

/**
 Converts an alias path to the actual path of the file.
 
 Aliases are special files which store a pointer to an iNode.
 Thus, aliases always work, even when the original file is moved.
 Aliases are the default shortcut mechanism created by the Finder.
 
 This code was more of less copied from here:
 http://developer.apple.com/documentation/Cocoa/Conceptual/LowLevelFileMgmt/Tasks/ResolvingAliases.html
**/
+ (NSString *)resolveAlias:(NSString *)path
{
    NSString *resolvedPath = nil;
	
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)path, kCFURLPOSIXPathStyle, NO);
	
	if(url != NULL)
	{
		FSRef fileRef;
		if(CFURLGetFSRef(url, &fileRef))
		{
			Boolean targetIsFolder, wasAliased;
			if(FSResolveAliasFile(&fileRef, true, &targetIsFolder, &wasAliased) == noErr && wasAliased)
			{
				CFURLRef resolvedUrl = CFURLCreateFromFSRef(NULL, &fileRef);
				if (resolvedUrl != NULL)
				{
					resolvedPath = (NSString *)CFURLCopyFileSystemPath(resolvedUrl, kCFURLPOSIXPathStyle);
					CFRelease(resolvedUrl);
				}
			}
		}
		CFRelease(url);
	}
	
	return [resolvedPath autorelease];
}

/**
 This method resolves an entire path, resolving any aliases within the path.
 
 This was added after I received bug reports from users who moved their Music folder,
 and left an alias in the original location. Thus the path to the XML file was still
 "~/Music/iTunes/iTunes Music Library.xml", but the Music folder was an alias.
**/
+ (NSString *)resolvePath:(NSString *)path
{
	// Create a mutable string to incrementally store the resolved path in
    NSMutableString *resolvedPath = [NSMutableString stringWithCapacity:[path length]];
    
	// Extract all the components along the path
	// This includes all enclosing directories, and the final file
    NSArray *components = [path pathComponents];
	
	// Note: We are starting from 1 to ignore the first path component which is always "/"
	int i;
	BOOL failed = NO;
	for(i = 1; i < [components count] && !failed; i++)
	{
		// Get the path up to the current point
		// This includes everything we've resolved so far, and the current path component
        NSString *currentPath = [resolvedPath stringByAppendingPathComponent:[components objectAtIndex:i]];
		
        if([self isAliasFile:currentPath])
		{
            NSString *resolvedAliasPath = [self resolveAlias:currentPath];
			
			// resolvedAliasPath is nil if we were unable to resolve the alias
			// This would happen if the alias was bad. As in the original was deleted.
			if(resolvedAliasPath != nil)
			{
				// Replace entire string with resolved path from alias
				NSRange fullRange = NSMakeRange(0, [resolvedPath length]);
				[resolvedPath replaceCharactersInRange:fullRange withString:resolvedAliasPath];
			}
			else
			{
				failed = YES;
			}
		}
        else
		{
			[resolvedPath appendFormat:@"/%@", [components objectAtIndex:i]];
        }
		
		//NSLog(@"resolvedPath: %@", resolvedPath);
    }
	
	if(failed)
		return nil;
	else
		return resolvedPath;
}

@end
