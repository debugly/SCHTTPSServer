#import "HTTPServer.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "HTTPConnection.h"
#import "HTTPLogger.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

@interface HTTPServer ()
{
    void *IsOnServerQueueKey;
    void *IsOnConnectionQueueKey;
}

// Underlying asynchronous TCP/IP socket
@property GCDAsyncSocket * asyncSocket;

// Dispatch queues
@property dispatch_queue_t serverQueue;
@property dispatch_queue_t connectionQueue;

// HTTP server configuration
@property Class connectionClass;
@property NSString *interface;
@property uint16_t port;

// NSNetService and related variables
@property NSNetService *netService;
@property NSString *domain;
@property NSString *type;
@property NSString *name;
@property (nonatomic) NSString *publishedName;
@property NSDictionary *txtRecordDictionary;

// Connection management
@property NSMutableArray *connections;
@property NSLock *connectionsLock;

@property (nonatomic,getter=isRunning) BOOL running;

@end

@interface HTTPServer (PrivateAPI)

- (void)unpublishBonjour;
- (void)publishBonjour;

+ (void)startBonjourThreadIfNeeded;
+ (void)performBonjourBlock:(dispatch_block_t)block;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation HTTPServer

@synthesize connectionClass = _connectionClass;
@synthesize port = _port;
@synthesize domain = _domain;
@synthesize name = _name;
@synthesize interface = _interface;
@synthesize type = _type;

/**
 * Standard Constructor.
 * Instantiates an HTTP server, but does not start it.
**/
- (id)init
{
	if ((self = [super init]))
	{
		HTTPLogTrace();
		// Setup underlying dispatch queues
		_serverQueue = dispatch_queue_create("HTTPServer", NULL);
		_connectionQueue = dispatch_queue_create("HTTPConnection", NULL);
		
		IsOnServerQueueKey = &IsOnServerQueueKey;
		IsOnConnectionQueueKey = &IsOnConnectionQueueKey;
		
		void *nonNullUnusedPointer = (__bridge void *)self; // Whatever, just not null
		
		dispatch_queue_set_specific(_serverQueue, IsOnServerQueueKey, nonNullUnusedPointer, NULL);
		dispatch_queue_set_specific(_connectionQueue, IsOnConnectionQueueKey, nonNullUnusedPointer, NULL);
		
		// Initialize underlying GCD based tcp socket
		_asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:(id)self delegateQueue:_serverQueue];
		
		// Use default connection class of HTTPConnection
		_connectionClass = [HTTPConnection self];
		
		// By default bind on all available interfaces, en1, wifi etc
		_interface = nil;
		
		// Use a default port of 0
		// This will allow the kernel to automatically pick an open port for us
		_port = 0;
		
		// Configure default values for bonjour service
		
		// Bonjour domain. Use the local domain by default
		_domain = @"local.";
		
		// If using an empty string ("") for the service name when registering,
		// the system will automatically use the "Computer Name".
		// Passing in an empty string will also handle name conflicts
		// by automatically appending a digit to the end of the name.
		_name = @"";
		
		// Initialize arrays to hold all the HTTP and webSocket connections
		_connections = [[NSMutableArray alloc] init];
		_connectionsLock = [[NSLock alloc] init];
		
		// Register for notifications of closed connections
		[[NSNotificationCenter defaultCenter] addObserver:self
		                                         selector:@selector(connectionDidDie:)
		                                             name:HTTPConnectionDidDieNotification
		                                           object:nil];
		
		_running = NO;
	}
	return self;
}

/**
 * Standard Deconstructor.
 * Stops the server, and clients, and releases any resources connected with this instance.
**/
- (void)dealloc
{
	HTTPLogTrace();
	
	// Remove notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	// Stop the server if it's running
	[self stop];
	
	// Release all instance variables
	
	#if !OS_OBJECT_USE_OBJC
	dispatch_release(_serverQueue);
	dispatch_release(_connectionQueue);
	#endif
	
	[_asyncSocket setDelegate:nil delegateQueue:NULL];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Server Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * The connection class is the class that will be used to handle connections.
 * That is, when a new connection is created, an instance of this class will be intialized.
 * The default connection class is HTTPConnection.
 * If you use a different connection class, it is assumed that the class extends HTTPConnection
**/
- (Class)connectionClass
{
	__block Class result;
	
	dispatch_sync(_serverQueue, ^{
        result = self->_connectionClass;
	});
	
	return result;
}

- (void)setConnectionClass:(Class)value
{
	HTTPLogTrace();
	
	dispatch_sync(_serverQueue, ^{
        self->_connectionClass = value;
	});
}

/**
 * What interface to bind the listening socket to.
**/
- (NSString *)interface
{
	__block NSString *result;
	
	dispatch_sync(_serverQueue, ^{
        result = self->_interface;
	});
	
	return result;
}

- (void)setInterface:(NSString *)value
{
	NSString *valueCopy = [value copy];
	
	dispatch_sync(_serverQueue, ^{
        self->_interface = valueCopy;
	});
	
}

/**
 * The port to listen for connections on.
 * By default this port is initially set to zero, which allows the kernel to pick an available port for us.
 * After the HTTP server has started, the port being used may be obtained by this method.
**/
- (uint16_t)port
{
	__block uint16_t result;
	
	dispatch_sync(_serverQueue, ^{
        result = self->_port;
	});
	
    return result;
}

- (uint16_t)listeningPort
{
	__block uint16_t result;
	
	dispatch_sync(_serverQueue, ^{
		if (self.isRunning)
			result = [self.asyncSocket localPort];
		else
			result = 0;
	});
	
	return result;
}

- (void)setPort:(uint16_t)value
{
	HTTPLogTrace();
	
	dispatch_sync(_serverQueue, ^{
        self->_port = value;
	});
}

/**
 * Domain on which to broadcast this service via Bonjour.
 * The default domain is @"local".
**/
- (NSString *)domain
{
	__block NSString *result;
	
	dispatch_sync(_serverQueue, ^{
        result = self->_domain;
	});
	
    return result;
}

- (void)setDomain:(NSString *)value
{
	HTTPLogTrace();
	
	NSString *valueCopy = [value copy];
	
	dispatch_sync(_serverQueue, ^{
        self->_domain = valueCopy;
	});
	
}

/**
 * The name to use for this service via Bonjour.
 * The default name is an empty string,
 * which should result in the published name being the host name of the computer.
**/
- (NSString *)name
{
	__block NSString *result;
	
	dispatch_sync(_serverQueue, ^{
        result = self->_name;
	});
	
	return result;
}

- (NSString *)publishedName
{
	__block NSString *result;
	
	dispatch_sync(_serverQueue, ^{
		
		if (self.netService == nil)
		{
			result = nil;
		}
		else
		{
			
			dispatch_block_t bonjourBlock = ^{
				result = [[self.netService name] copy];
			};
			
			[[self class] performBonjourBlock:bonjourBlock];
		}
	});
	
	return result;
}

- (void)setName:(NSString *)value
{
	NSString *valueCopy = [value copy];
	
	dispatch_sync(_serverQueue, ^{
        self->_name = valueCopy;
	});
	
}

/**
 * The type of service to publish via Bonjour.
 * No type is set by default, and one must be set in order for the service to be published.
**/
- (NSString *)type
{
	__block NSString *result;
	
	dispatch_sync(_serverQueue, ^{
        result = self->_type;
	});
	
	return result;
}

- (void)setType:(NSString *)value
{
	NSString *valueCopy = [value copy];
	
	dispatch_sync(_serverQueue, ^{
        self->_type = valueCopy;
	});
	
}

/**
 * The extra data to use for this service via Bonjour.
**/
- (NSDictionary *)TXTRecordDictionary
{
	__block NSDictionary *result;
	
	dispatch_sync(_serverQueue, ^{
        result = self->_txtRecordDictionary;
	});
	
	return result;
}

- (void)setTXTRecordDictionary:(NSDictionary *)value
{
	HTTPLogTrace();
	
	NSDictionary *valueCopy = [value copy];
	
	dispatch_sync(_serverQueue, ^{
	
		self.txtRecordDictionary = valueCopy;
		
		// Update the txtRecord of the netService if it has already been published
		if (self.netService)
		{
			NSNetService *theNetService = self.netService;
			NSData *txtRecordData = nil;
			if (self.txtRecordDictionary)
				txtRecordData = [NSNetService dataFromTXTRecordDictionary:self.txtRecordDictionary];
			
			dispatch_block_t bonjourBlock = ^{
				[theNetService setTXTRecordData:txtRecordData];
			};
			
			[[self class] performBonjourBlock:bonjourBlock];
		}
	});
	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Server Control
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)start:(NSError **)errPtr
{
	HTTPLogTrace();
	
	__block BOOL success = YES;
	__block NSError *err = nil;
	
    NSString *inInterface = _interface;
    uint16_t port = _port;
	dispatch_sync(_serverQueue, ^{ @autoreleasepool {
		
        success = [self.asyncSocket acceptOnInterface:inInterface port:port error:&err];
		if (success)
		{
			HTTPLogInfo(@"Started HTTP server on port %hu", [self.asyncSocket localPort]);
			
			self.running = YES;
			[self publishBonjour];
		}
		else
		{
            HTTPLogError(@"Failed to start HTTP Server: %@", err);
		}
	}});
	
	if (errPtr)
		*errPtr = err;
	
	return success;
}

- (void)stop
{
	[self stop:NO];
}

- (void)stop:(BOOL)keepExistingConnections
{
	HTTPLogTrace();
	
	dispatch_sync(_serverQueue, ^{ @autoreleasepool {
		
		// First stop publishing the service via bonjour
		[self unpublishBonjour];
		
		// Stop listening / accepting incoming connections
		[self.asyncSocket disconnect];
		self.running = NO;
		
		if (!keepExistingConnections)
		{
			// Stop all HTTP connections the server owns
			[self.connectionsLock lock];
			for (HTTPConnection *connection in self.connections)
			{
				[connection stop];
			}
			[self.connections removeAllObjects];
			[self.connectionsLock unlock];
		}
	}});
}

- (BOOL)isRunning
{
	__block BOOL result;
	
	dispatch_sync(_serverQueue, ^{
        result = self->_running;
	});
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Server Status
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the number of http client connections that are currently connected to the server.
**/
- (NSUInteger)numberOfHTTPConnections
{
	NSUInteger result = 0;
	
	[self.connectionsLock lock];
	result = [self.connections count];
	[self.connectionsLock unlock];
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Incoming Connections
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (HTTPConfig *)config
{
	// Override me if you want to provide a custom config to the new connection.
	// 
	// Generally this involves overriding the HTTPConfig class to include any custom settings,
	// and then having this method return an instance of 'MyHTTPConfig'.
	
	// Note: Think you can make the server faster by putting each connection on its own queue?
	// Then benchmark it before and after and discover for yourself the shocking truth!
	// 
	// Try the apache benchmark tool (already installed on your Mac):
	// $  ab -n 1000 -c 1 http://localhost:<port>/some_path.html
	
	return [[HTTPConfig alloc] initWithServer:self queue:self.connectionQueue];
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
	HTTPConnection *newConnection = (HTTPConnection *)[[_connectionClass alloc] initWithAsyncSocket:newSocket
	                                                                                 configuration:[self config]];
	[self.connectionsLock lock];
	[self.connections addObject:newConnection];
	[self.connectionsLock unlock];
	
	[newConnection start];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Bonjour
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)publishBonjour
{
	HTTPLogTrace();
	
	NSAssert(dispatch_get_specific(IsOnServerQueueKey) != NULL, @"Must be on serverQueue");
	
	if (_type)
	{
		self.netService = [[NSNetService alloc] initWithDomain:_domain type:_type name:_name port:[self.asyncSocket localPort]];
		[self.netService setDelegate:self];
		
		NSNetService *theNetService = self.netService;
		NSData *txtRecordData = nil;
		if (_txtRecordDictionary)
			txtRecordData = [NSNetService dataFromTXTRecordDictionary:_txtRecordDictionary];
		
		dispatch_block_t bonjourBlock = ^{
			
			[theNetService removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
			[theNetService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
			[theNetService publish];
			
			// Do not set the txtRecordDictionary prior to publishing!!!
			// This will cause the OS to crash!!!
			if (txtRecordData)
			{
				[theNetService setTXTRecordData:txtRecordData];
			}
		};
		
		[[self class] startBonjourThreadIfNeeded];
		[[self class] performBonjourBlock:bonjourBlock];
	}
}

- (void)unpublishBonjour
{
	HTTPLogTrace();
	
	NSAssert(dispatch_get_specific(IsOnServerQueueKey) != NULL, @"Must be on serverQueue");
	
	if (self.netService)
	{
		NSNetService *theNetService = self.netService;
		
		dispatch_block_t bonjourBlock = ^{
			
			[theNetService stop];
		};
		
		[[self class] performBonjourBlock:bonjourBlock];
		
		self.netService = nil;
	}
}

/**
 * Republishes the service via bonjour if the server is running.
 * If the service was not previously published, this method will publish it (if the server is running).
**/
- (void)republishBonjour
{
	HTTPLogTrace();
	
	dispatch_async(_serverQueue, ^{
		
		[self unpublishBonjour];
		[self publishBonjour];
	});
}

/**
 * Called when our bonjour service has been successfully published.
 * This method does nothing but output a log message telling us about the published service.
**/
- (void)netServiceDidPublish:(NSNetService *)ns
{
	// Override me to do something here...
	// 
	// Note: This method is invoked on our bonjour thread.
	
	HTTPLogInfo(@"Bonjour Service Published: domain(%@) type(%@) name(%@)", [ns domain], [ns type], [ns name]);
}

/**
 * Called if our bonjour service failed to publish itself.
 * This method does nothing but output a log message telling us about the published service.
**/
- (void)netService:(NSNetService *)ns didNotPublish:(NSDictionary *)errorDict
{
	// Override me to do something here...
	// 
	// Note: This method in invoked on our bonjour thread.
	
	HTTPLogWarn(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@",
	                                         [ns domain], [ns type], [ns name], errorDict);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Notifications
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method is automatically called when a notification of type HTTPConnectionDidDieNotification is posted.
 * It allows us to remove the connection from our array.
**/
- (void)connectionDidDie:(NSNotification *)notification
{
	// Note: This method is called on the connection queue that posted the notification
	
	[self.connectionsLock lock];
	
	HTTPLogTrace();
	[self.connections removeObject:[notification object]];
	
	[self.connectionsLock unlock];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Bonjour Thread
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * NSNetService is runloop based, so it requires a thread with a runloop.
 * This gives us two options:
 * 
 * - Use the main thread
 * - Setup our own dedicated thread
 * 
 * Since we have various blocks of code that need to synchronously access the netservice objects,
 * using the main thread becomes troublesome and a potential for deadlock.
**/

static NSThread *bonjourThread;

+ (void)startBonjourThreadIfNeeded
{
	HTTPLogTrace();
	
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		
        HTTPLogVerbose(@"Starting bonjour thread...");
		
		bonjourThread = [[NSThread alloc] initWithTarget:self
		                                        selector:@selector(bonjourThread)
		                                          object:nil];
		[bonjourThread start];
	});
}

+ (void)bonjourThread
{
	@autoreleasepool {
	
        HTTPLogVerbose(@"BonjourThread: Started");
		
		// We can't run the run loop unless it has an associated input source or a timer.
		// So we'll just create a timer that will never fire - unless the server runs for 10,000 years.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
		[NSTimer scheduledTimerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow]
		                                 target:self
		                               selector:@selector(donothingatall:)
		                               userInfo:nil
		                                repeats:YES];
#pragma clang diagnostic pop

		[[NSRunLoop currentRunLoop] run];
		
        HTTPLogVerbose(@"BonjourThread: Aborted");
	
	}
}

+ (void)executeBonjourBlock:(dispatch_block_t)block
{
	HTTPLogTrace();
	
	NSAssert([NSThread currentThread] == bonjourThread, @"Executed on incorrect thread");
	
	block();
}

+ (void)performBonjourBlock:(dispatch_block_t)block
{
	HTTPLogTrace();
	
	[self performSelector:@selector(executeBonjourBlock:)
	             onThread:bonjourThread
	           withObject:block
	        waitUntilDone:YES];
}

@end
