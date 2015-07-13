//
//  MTCoreAudioDevice.h
//  MTCoreAudio.framework
//
//  Created by Michael Thornburgh on Sun Dec 16 2001.
//  Copyright (c) 2001 Michael Thornburgh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudio.h>


typedef enum MTCoreAudioDirection {
	kMTCoreAudioDevicePlaybackDirection,
	kMTCoreAudioDeviceRecordDirection
} MTCoreAudioDirection;

typedef struct _MTCoreAudioVolumeInfo {
	Boolean hasVolume;
	Boolean canSetVolume;
	Float32 theVolume;
	Boolean canMute;
	Boolean isMuted;
	Boolean canPlayThru;
	Boolean playThruIsSet;
} MTCoreAudioVolumeInfo;


@interface MTCoreAudioDevice : NSObject {
	AudioDeviceID myDevice;
}

- (MTCoreAudioDevice *) initWithDeviceID:(AudioDeviceID)theID;

+ (MTCoreAudioDevice *) deviceWithID:(AudioDeviceID)theID;
+ (MTCoreAudioDevice *) defaultOutputDevice;
+ (MTCoreAudioDevice *) defaultSystemOutputDevice;

- (Float32) volumeForChannel:(UInt32)theChannel forDirection:(MTCoreAudioDirection)theDirection;
- (void)    setVolume:(Float32)theVolume forChannel:(UInt32)theChannel forDirection:(MTCoreAudioDirection)theDirection;
- (void)    setMute:(BOOL)isMuted forChannel:(UInt32)theChannel forDirection:(MTCoreAudioDirection)theDirection;


@end
