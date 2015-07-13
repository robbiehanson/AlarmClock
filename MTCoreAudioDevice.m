//
//  MTCoreAudioDevice.m
//  MTCoreAudio.framework
//
//  Created by Michael Thornburgh on Sun Dec 16 2001.
//  Copyright (c) 2001 Michael Thornburgh. All rights reserved.
//

#import "MTCoreAudioDevice.h"

@implementation MTCoreAudioDevice

+ (MTCoreAudioDevice *) deviceWithID:(AudioDeviceID)theID
{
	return [[[[self class] alloc] initWithDeviceID:theID] autorelease];
}

+ (MTCoreAudioDevice *) _defaultDevice:(int)whichDevice
{
	OSStatus theStatus;
	UInt32 theSize;
	AudioDeviceID theID;
	
	theSize = sizeof(AudioDeviceID);
	
	theStatus = AudioHardwareGetProperty ( whichDevice, &theSize, &theID );
	if (theStatus == 0)
		return [[self class] deviceWithID:theID];
	return nil;
}

+ (MTCoreAudioDevice *) defaultOutputDevice
{
	return [[self class] _defaultDevice:kAudioHardwarePropertyDefaultOutputDevice];
}

+ (MTCoreAudioDevice *) defaultSystemOutputDevice
{
	return [[self class] _defaultDevice:kAudioHardwarePropertyDefaultSystemOutputDevice];
}

- (MTCoreAudioDevice *) initWithDeviceID:(AudioDeviceID)theID
{
	if(self = [super init])
	{
		myDevice = theID;
	}
	return self;
}

- (Float32) volumeForChannel:(UInt32)theChannel forDirection:(MTCoreAudioDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	Float32 theVolumeScalar;
	
	theSize = sizeof(Float32);
	theStatus = AudioDeviceGetProperty ( myDevice, theChannel, theDirection, kAudioDevicePropertyVolumeScalar, &theSize, &theVolumeScalar );
	if (theStatus == 0)
		return theVolumeScalar;
	else
		return 0.0;
}

- (void) setVolume:(Float32)theVolume forChannel:(UInt32)theChannel forDirection:(MTCoreAudioDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	
	theSize = sizeof(Float32);
	theStatus = AudioDeviceSetProperty ( myDevice, NULL, theChannel, theDirection, kAudioDevicePropertyVolumeScalar, theSize, &theVolume );
}

- (void) setMute:(BOOL)isMuted forChannel:(UInt32)theChannel forDirection:(MTCoreAudioDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 theMuteVal;
	
	theSize = sizeof(UInt32);
	if (isMuted) theMuteVal = 1; else theMuteVal = 0;
	theStatus = AudioDeviceSetProperty ( myDevice, NULL, theChannel, theDirection, kAudioDevicePropertyMute, theSize, &theMuteVal );
}

@end