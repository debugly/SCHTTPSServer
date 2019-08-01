#import "TestHTTPConnection.h"
#import <SCHTTPServer/HTTPLogger.h>
#import "MRKeychain.h"

@implementation TestHTTPConnection

/**
 * Overrides HTTPConnection's method
**/
- (BOOL)isSecureServer
{
	HTTPLogTrace();
	
	// Create an HTTPS server (all connections will be secured via SSL/TLS)
	return YES;
}

/**
 * Overrides HTTPConnection's method
 * 
 * This method is expected to returns an array appropriate for use in kCFStreamSSLCertificates SSL Settings.
 * It should be an array of SecCertificateRefs except for the first element in the array, which is a SecIdentityRef.
**/
- (NSArray *)sslIdentityAndCertificates
{
	HTTPLogTrace();
	
	NSArray *result = [MRKeychain SelfCertificateExist];
	if([result count] == 0)
	{
		[MRKeychain createNewIdentity];
		return [MRKeychain SelfCertificateExist];
	}
	return result;
}

@end
