//
//  AppleRemote.m
//  AppleRemote
//
//  Created by Martin Kahr on 11.03.06.
//  Copyright 2006 martinkahr.com. All rights reserved.
//

#import "AppleRemote.h"

static void QueueCallbackFunction(void* target, IOReturn result, void* refcon, void* sender);

@interface AppleRemote (PrivateMethods) 
- (IOHIDQueueInterface**) queue;
- (IOHIDDeviceInterface**) hidDeviceInterface;
- (void) handleEvent: (IOHIDEventStruct) event; 
@end

@interface AppleRemote (IOKitMethods) 
- (io_object_t)findAppleRemoteDevice;
- (IOHIDDeviceInterface**)createInterfaceForDevice:(io_object_t)hidDevice;
- (BOOL) initializeCookies;
- (BOOL) openDevice;
@end


@implementation AppleRemote

// CLASS VARIABLES
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Provides a single shared instance of the apple remote
// This is helpful as multiple classes may want to access the remote,
// yet only one instance of this class may open the remote exclusively
static AppleRemote *sharedInstance = nil;

// CLASS METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (AppleRemote *)sharedRemote 
{
	if(sharedInstance == nil)
	{
		sharedInstance = [[AppleRemote alloc] init];
	}
	return sharedInstance;
}

// INIT, DEALLOC
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Creates a new instance of the apple remote.
 Exclusive mode is turned on by default.
**/
- (id)init 
{
	if(self = [super init])
	{
		openInExclusiveMode = YES;
		queue = NULL;
		hidDeviceInterface = NULL;
		cookies = NULL;
	}
	return self;
}

- (void)dealloc 
{
	[self stopListening];
	[super dealloc];
}

// PUBLIC API
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Returns whether or not an apple remote is available on this machine.
 The remote is determined to be available if a matching device is found after searching IO Services.
**/
- (BOOL)isRemoteAvailable 
{	
	io_object_t hidDevice = [self findAppleRemoteDevice];
	if (hidDevice != 0)
	{
		IOObjectRelease(hidDevice);
		return YES;
	}
	else
	{
		return NO;		
	}
}

/**
 Standard delegate method.
 Returns the current delegate for this instance.
**/
- (id)delegate
{
	return delegate;
}

/**
 Standard setDelegate method.
 Registers the given object as this instance's delegate.
**/
- (void)setDelegate:(id)newDelegate 
{
	delegate = newDelegate;
}

/**
 Returns whether this instance is set to listen to the remote in exclusive mode.
 This is set to true by default when a new instance is created.
**/
- (BOOL)isOpenInExclusiveMode
{
	return openInExclusiveMode;
}

/**
 Sets whether or not to listen to the remote exclusively.
 If the instance is already listening, it must be stopped and started again for any changes to take effect.
**/
- (void)setOpenInExclusiveMode:(BOOL)value 
{
	openInExclusiveMode = value;
}

/**
 Returns whether this instance is currently listening to the Apple Remote or not.
**/
- (BOOL)isListeningToRemote 
{
	return ((hidDeviceInterface != NULL) && (cookies != NULL) && (queue != NULL));
}

/**
 Begins listening to the Apple Remote.
**/
- (void)startListening 
{
	// First make sure we're not already listening
	// If we are, we can just ignore this method call, and immediately return
	if([self isListeningToRemote]) return;
	
	// Get a reference to the apple remote device
	io_object_t hidDevice = [self findAppleRemoteDevice];
	if(hidDevice == 0) return;
	
	if([self createInterfaceForDevice:hidDevice] == NULL)
	{
		[self stopListening];
		IOObjectRelease(hidDevice);
		return;
	}
	
	if([self initializeCookies] == NO)
	{
		[self stopListening];
		IOObjectRelease(hidDevice);
		return;
	}

	if([self openDevice]==NO)
	{
		[self stopListening];
		IOObjectRelease(hidDevice);
		return;
	}
	
	IOObjectRelease(hidDevice);
}

/**
 Stops listening to the device, and releases all objects associated with listening.
**/
- (void)stopListening
{
	if (queue != NULL) {
		(*queue)->stop(queue);		
		
		//dispose of queue
		(*queue)->dispose(queue);		
		
		//release the queue we allocated
		(*queue)->Release(queue);	
		
		queue = NULL;
	}
	
	if (cookies != NULL) {
		free(cookies);
		cookies = NULL;
	}
	
	if (hidDeviceInterface != NULL) {
		//close the device
		(*hidDeviceInterface)->close(hidDeviceInterface);
		
		//release the interface	
		(*hidDeviceInterface)->Release(hidDeviceInterface);
		
		hidDeviceInterface = NULL;		
	}	
}

// PRIVATE METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IOHIDQueueInterface**) queue
{
	return queue;
}

- (IOHIDDeviceInterface**) hidDeviceInterface
{
	return hidDeviceInterface;
}

- (void)handleEvent:(IOHIDEventStruct)event 
{
	AppleRemoteCookieIdentifier remoteId = -1;
	
	int i=0;
	for(i=0; i<NUMBER_OF_APPLE_REMOTE_ACTIONS; i++) {
		if (cookies[i] == event.elementCookie) {
			remoteId = i;
			break;
		}
	}
	if(delegate)
	{
		[delegate appleRemoteButton:remoteId pressedDown:(event.value == 1)];
	}
}

// IOKIT METHODS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Searches, finds, and returns an IO reference to the Apple Remote Device.
**/
- (io_object_t)findAppleRemoteDevice 
{
	// Set up a matching dictionary to search the I/O Registry by class name for all HID class devices
	// We want to specifically search for the Apple Remote HID device
	CFMutableDictionaryRef hidMatchDictionary = IOServiceMatching(AppleRemoteDeviceName);
	
	// Note to Cocoa developers: CFMutableDictionaryRef = (NSMutableDictionary *)
	
	/*
	 IOServiceMatching Documentation:
	 
	 IOServiceMatching will create a matching dictionary that specifies any IOService object of a class,
	 or its subclasses.
	 
	 The matching dictionary created, is returned on success, or zero on failure.
	 The dictionary is commonly passed to IOServiceGetMatchingServices or IOServiceAddMatchingNotification
	 which will consume a reference, otherwise it should be released with CFRelease by the caller.
	*/
	
	// Create an empty IO_Iterator - We'll initialize this shortly
	io_iterator_t hidObjectIterator;
	
	/*
	 What the FUCK is an io_iterator_t?!?
	 
	 Functions in the IOKitLib communicate with in-kernel objects using the Mach port transport mechanism 
	 to cross the user-kernel boundary. The file IOTypes.h, located in the I/O Kit framework,
	 defines the objects you use with IOKitLib functions to communicate with such in-kernel entities 
	 as I/O Registry entries (objects of class IORegistryEntry) or iterators (objects of class IOIterator).
	 
	 Object definitions in IOTypes.h:
	 typedef mach_port_t io_object_t;
	 
	 typedef io_object_t io_connect_t;
	 typedef io_object_t io_iterator_t;
	 typedef io_object_t io_registry_entry_t;
	 typedef io_object_t io_service_t;
	 typedef io_object_t io_enumerator_t;
	 
	 Notice that they're all defined in the same way, specifically, as mach_port_t objects.
	 From the applicationÕs point of view, the transport mechanism is unimportant and what matters is the type
	 of object on the other side of the port. The fact that an io_iterator_t object, for example, encapsulates
	 the association of a Mach port with an in-kernel IOIterator object is not as important to the application
	 as the fact that an io_iterator_t object refers to an in-kernel object that knows how to
	 iterate over the I/O Registry.
	 
	 So basically, it's a reference to a mach-port, and on the other side of the port is an IOIterator.
	*/
	
	// Create the hidDevice
	// If all goes well, this will point to the apple remote device
	io_object_t	hidDevice = 0;
	
	// Now search I/O Registry for matching devices.
	IOReturn ioReturnValue = IOServiceGetMatchingServices(kIOMasterPortDefault, hidMatchDictionary, &hidObjectIterator);
	
	if((ioReturnValue == kIOReturnSuccess) && (hidObjectIterator != 0))
	{
		hidDevice = IOIteratorNext(hidObjectIterator);
	}
	
	// Release the iterator
	IOObjectRelease(hidObjectIterator);
	
	// Note: We don't have to release hidMatchDictionary because IOServiceGetMatchingServices consumes it 
	
	return hidDevice;
}

/**
 Amazing description goes here...
**/
- (IOHIDDeviceInterface**)createInterfaceForDevice:(io_object_t)hidDevice 
{
	io_name_t				className;
	IOCFPlugInInterface**   plugInInterface = NULL;
	HRESULT					plugInResult = S_OK;
	SInt32					score = 0;
	IOReturn				ioReturnValue = kIOReturnSuccess;
	
	hidDeviceInterface = NULL;
	
	ioReturnValue = IOObjectGetClass(hidDevice, className);
	
	if (ioReturnValue != kIOReturnSuccess) {
		NSLog(@"Error: Failed to get class name.");
		return NULL;
	}
	
	ioReturnValue = IOCreatePlugInInterfaceForService(hidDevice, kIOHIDDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &plugInInterface, &score);
	if (ioReturnValue == kIOReturnSuccess)
	{
		//Call a method of the intermediate plug-in to create the device interface
		plugInResult = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOHIDDeviceInterfaceID), (LPVOID) &hidDeviceInterface);
		
		if (plugInResult != S_OK) {
			NSLog(@"Error: Couldn't create HID class device interface");
		}
		// Release
		if (plugInInterface) (*plugInInterface)->Release(plugInInterface);
	}
	return hidDeviceInterface;
}

- (BOOL) initializeCookies 
{
	IOHIDDeviceInterface122** handle = (IOHIDDeviceInterface122**)hidDeviceInterface;
	IOHIDElementCookie		cookie;
	long					usage;
	long					usagePage;
	id						object;
	NSArray*				elements = nil;
	NSDictionary*			element;
	IOReturn success;
	
	if (!handle || !(*handle)) return NO;
	
	// Copy all elements, since we're grabbing most of the elements
	// for this device anyway, and thus, it's faster to iterate them
	// ourselves. When grabbing only one or two elements, a matching
	// dictionary should be passed in here instead of NULL.
	success = (*handle)->copyMatchingElements(handle, NULL, (CFArrayRef*)&elements);
	
	if (success == kIOReturnSuccess) {
		
		[elements autorelease];		
		
		cookies = calloc(NUMBER_OF_APPLE_REMOTE_ACTIONS, sizeof(IOHIDElementCookie)); 
		memset(cookies, 0, sizeof(IOHIDElementCookie) * NUMBER_OF_APPLE_REMOTE_ACTIONS);
		
		int i;
		for (i=0; i< [elements count]; i++) {
			element = [elements objectAtIndex:i];
			
			//Get cookie
			object = [element valueForKey: (NSString*)CFSTR(kIOHIDElementCookieKey) ];
			if (object == nil || ![object isKindOfClass:[NSNumber class]]) continue;
			if (object == 0 || CFGetTypeID(object) != CFNumberGetTypeID()) continue;
			cookie = (IOHIDElementCookie) [object longValue];
			
			//Get usage
			object = [element valueForKey: (NSString*)CFSTR(kIOHIDElementUsageKey) ];
			if (object == nil || ![object isKindOfClass:[NSNumber class]]) continue;			
			usage = [object longValue];
			
			//Get usage page
			object = [element valueForKey: (NSString*)CFSTR(kIOHIDElementUsagePageKey) ];
			if (object == nil || ![object isKindOfClass:[NSNumber class]]) continue;			
			usagePage = [object longValue];
			
			AppleRemoteCookieIdentifier cid = -1;
			switch(usage) {
				case 140:
					cid = kRemoteButtonVolume_Plus;
					break;
				case 141:
					cid = kRemoteButtonVolume_Minus;
					break;
				case 134:
					cid = kRemoteButtonMenu;
					break;
				case 137:
					cid = kRemoteButtonPlay;
					break;
				case 138:
					cid = kRemoteButtonRight;
					break;
				case 139:
					cid = kRemoteButtonLeft;
					break;
				case 179:
					cid = kRemoteButtonRight_Hold;
					break;
				case 180:
					cid = kRemoteButtonLeft_Hold;
					break;
				case 35:
					cid = kRemoteButtonPlay_Sleep;
					break;
				default:
					//NSLog(@"Usage %d will not be used", usage);
					break;
			}
			
			if (cid != -1) {
				if (cid < NUMBER_OF_APPLE_REMOTE_ACTIONS) {
					cookies[cid] = cookie;
				} else {
					NSLog(@"Invalid index %d for cookie. No slot to store the cookie.", cid);
				}
			}
			//NSLog(@"%d: usage = %d and page = %d", cookie, usage, usagePage);			
		}
	} else {
		return NO;
	}
	
	return YES;
}

- (BOOL) openDevice 
{
	HRESULT  result;
	
	IOHIDOptionsType openMode = kIOHIDOptionsTypeNone;
	if ([self isOpenInExclusiveMode]) openMode = kIOHIDOptionsTypeSeizeDevice;	
	IOReturn ioReturnValue = (*hidDeviceInterface)->open(hidDeviceInterface, openMode);	
	
	if (ioReturnValue == KERN_SUCCESS) {
		queue = (*hidDeviceInterface)->allocQueue(hidDeviceInterface);
		if (queue) {
			result = (*queue)->create(queue, 0,
									  8);	//depth: maximum number of elements in queue before oldest elements in queue begin to be lost.
			
			int i=0;
			for(i=0; i<NUMBER_OF_APPLE_REMOTE_ACTIONS; i++) {
				if (cookies[i] != 0) {
					(*queue)->addElement(queue, cookies[i], 0);
				}
			}
			
			// add callback for async events
			CFRunLoopSourceRef eventSource;
			ioReturnValue = (*queue)->createAsyncEventSource(queue, &eventSource);
			if (ioReturnValue == KERN_SUCCESS) {
				ioReturnValue = (*queue)->setEventCallout(queue,QueueCallbackFunction, self, NULL);
				if (ioReturnValue == KERN_SUCCESS) {
					CFRunLoopAddSource(CFRunLoopGetCurrent(), eventSource, kCFRunLoopDefaultMode);					
					//start data delivery to queue
					(*queue)->start(queue);	
					return YES;
				} else {
					NSLog(@"Error when setting event callout");
				}
			} else {
				NSLog(@"Error when creating async event source");
			}
		} else {
			NSLog(@"Error when opening device");
		}
	}
	return NO;				
}

@end

/**
 Callback method for the device queue
 Will be called for any event of any type (cookie) to which we subscribe
**/
static void QueueCallbackFunction(void* target, IOReturn result, void* refcon, void* sender)
{
	AppleRemote *remote = (AppleRemote *)target;
	
	IOHIDEventStruct event;	
	AbsoluteTime 	 zeroTime = {0,0};
	
	while (result == kIOReturnSuccess)
	{
		result = (*[remote queue])->getNextEvent([remote queue], &event, zeroTime, 0);		
		if ( result != kIOReturnSuccess )
			continue;
		
		[remote handleEvent: event];			
	}	
}