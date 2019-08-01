#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "HTTPConnection.h"
#import "HTTPServer.h"
#import "P12HTTPConnection.h"
#import "HTTPLogger.h"

FOUNDATION_EXPORT double SCHTTPServerVersionNumber;
FOUNDATION_EXPORT const unsigned char SCHTTPServerVersionString[];

