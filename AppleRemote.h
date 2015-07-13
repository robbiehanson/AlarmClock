//
//  AppleRemote.h
//  AppleRemote
//
//  Created by Martin Kahr on 11.03.06.
//  Copyright 2006 martinkahr.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <mach/mach.h>
#import <mach/mach_error.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/hid/IOHIDLib.h>
#import <IOKit/hid/IOHIDKeys.h>

#define AppleRemoteDeviceName "AppleIRController"
#define NUMBER_OF_APPLE_REMOTE_ACTIONS 9
enum AppleRemoteCookieIdentifier
{
	kRemoteButtonVolume_Plus=0,
	kRemoteButtonVolume_Minus,
	kRemoteButtonMenu,
	kRemoteButtonPlay,
	kRemoteButtonRight,	
	kRemoteButtonLeft,	
	kRemoteButtonRight_Hold,	
	kRemoteButtonLeft_Hold,
	kRemoteButtonPlay_Sleep	
};
typedef enum AppleRemoteCookieIdentifier AppleRemoteCookieIdentifier;

/**
 Encapsulates usage of the apple remote control.
 The class is not thread safe.
**/
@interface AppleRemote : NSObject
{
	IOHIDDeviceInterface** hidDeviceInterface;
	IOHIDQueueInterface**  queue;
	IOHIDElementCookie*    cookies;		

	BOOL openInExclusiveMode;

	id delegate;
}

+ (AppleRemote *)sharedRemote;

- (BOOL)isRemoteAvailable;

- (BOOL)isOpenInExclusiveMode;
- (void)setOpenInExclusiveMode:(BOOL)value;

- (void)setDelegate:(id)delegate;
- (id)delegate;

- (BOOL)isListeningToRemote;

- (void)startListening;
- (void)stopListening;

@end

/**
 Method definitions for the delegate of the AppleRemote class
**/
@interface NSObject(AppleRemoteDelegate)
- (void)appleRemoteButton:(AppleRemoteCookieIdentifier)buttonIdentifier pressedDown:(BOOL)pressedDown;
@end
