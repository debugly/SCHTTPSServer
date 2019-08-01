/**
 * In order to provide flexible logging, this project provide log receiver interface.
 *
 * Here's what you need to know concerning how logging is setup for CocoaHTTPServer:
 * 
 * There are 4 log levels:
 * - Error
 * - Warning
 * - Info
 * - Verbose
 * 
 * In addition to this, there is a Trace flag that can be enabled.
 * When tracing is enabled, it spits out the methods that are being called.
 * 
 * Please note that tracing is separate from the log levels.
 * For example, one could set the log level to warning, and enable tracing.
 * 
 * All logging is asynchronous, except errors.
 * To use logging within your own custom files, follow the steps below.
 * 
 * Step 1:
 * Import this header in your implementation file:
 * 
 * #import "HTTPLogger.h"
 * 
 * Step 2:
 * Define your logging level in your implementation file:
 * 
 * // Log levels: off, error, warn, info, verbose
 * static const int httpLogLevel = HTTP_LOG_LEVEL_VERBOSE;
 * 
 * If you wish to enable tracing, you could do something like this:
 * 
 * // Debug levels: off, error, warn, info, verbose
 * static const int httpLogLevel = HTTP_LOG_LEVEL_INFO | HTTP_LOG_FLAG_TRACE;
 * 
 * Step 3:
 * Replace your NSLog statements with HTTPLog statements according to the severity of the message.
 * 
 * NSLog(@"Fatal error, no dohickey found!"); -> HTTPLogError(@"Fatal error, no dohickey found!");
 * 
 * HTTPLog works exactly the same as NSLog.
 * This means you can pass it multiple variables just like NSLog.
**/


// Define logging context for every log message coming from the HTTP server.
// The logging context can be extracted from the DDLogMessage from within the logging framework,
// which gives loggers, formatters, and filters the ability to optionally process them differently.

// Configure log levels.

typedef NS_ENUM(int, HTTP_LOG_FLAG) {
    HTTP_LOG_FLAG_ERROR   = (1 << 0), // 0...00001
    HTTP_LOG_FLAG_WARN    = (1 << 1), // 0...00010
    HTTP_LOG_FLAG_INFO    = (1 << 2), // 0...00100
    HTTP_LOG_FLAG_VERBOSE = (1 << 3), // 0...01000
    HTTP_LOG_FLAG_TRACE   = (1 << 4), // 0...10000
};

typedef NS_OPTIONS(int, HTTP_LOG_Level) {
    HTTP_LOG_LEVEL_OFF     = 0                                             , // 0...00000
    HTTP_LOG_LEVEL_ERROR   = (HTTP_LOG_LEVEL_OFF   | HTTP_LOG_FLAG_ERROR)  , // 0...00001
    HTTP_LOG_LEVEL_WARN    = (HTTP_LOG_LEVEL_ERROR | HTTP_LOG_FLAG_WARN)   , // 0...00011
    HTTP_LOG_LEVEL_INFO    = (HTTP_LOG_LEVEL_WARN  | HTTP_LOG_FLAG_INFO)   , // 0...00111
    HTTP_LOG_LEVEL_VERBOSE = (HTTP_LOG_LEVEL_INFO  | HTTP_LOG_FLAG_VERBOSE), // 0...01111
};

#define HTTP_LOG_LEVEL_TRACE (HTTP_LOG_LEVEL_VERBOSE | HTTP_LOG_FLAG_TRACE)

typedef void(^HTTPLogggerReceiver)(HTTP_LOG_Level level,NSString* log);

@interface HTTPLogger : NSObject

+ (instancetype)sharedLogger;

//default is HTTP_LOG_FLAG_ERROR;
@property(assign) HTTP_LOG_Level level;
//print trace log? default is off;
@property(assign) BOOL traceOn;

- (void)writeLog:(HTTP_LOG_Level)level file:(const char*)sourceFile function:(const char*)functionName lineNumber:(int)lineNumber format:(NSString*)format,...;
- (void)receiveLog:(HTTPLogggerReceiver)reveiver;

@end

#define LOG_OBJC_MAYBE(level,fmt,...)  do { \
    [[HTTPLogger sharedLogger] writeLog:level file:__FILE__ function:(char *)__FUNCTION__ lineNumber:__LINE__ format:(fmt),##__VA_ARGS__]; \
    } while (0)

// Define logging primitives.

#define HTTPLogError(fmt,...)    LOG_OBJC_MAYBE(HTTP_LOG_LEVEL_ERROR, fmt, ##__VA_ARGS__)
#define HTTPLogWarn(fmt,...)     LOG_OBJC_MAYBE(HTTP_LOG_LEVEL_WARN, fmt, ##__VA_ARGS__)
#define HTTPLogInfo(fmt,...)     LOG_OBJC_MAYBE(HTTP_LOG_LEVEL_INFO, fmt, ##__VA_ARGS__)
#define HTTPLogVerbose(fmt,...)  LOG_OBJC_MAYBE(HTTP_LOG_LEVEL_VERBOSE, fmt, ##__VA_ARGS__)
#define HTTPLogTrace()  LOG_OBJC_MAYBE(HTTP_LOG_LEVEL_TRACE, @"")
#define HTTPLogTrace2(fmt,...)   LOG_OBJC_MAYBE(HTTP_LOG_LEVEL_TRACE, fmt, ##__VA_ARGS__)

