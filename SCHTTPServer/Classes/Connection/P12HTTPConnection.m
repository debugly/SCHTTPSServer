//
//  P12HTTPConnection.m
//  SCHTTPServerDemo
//
//  Created by Matt Reach on 2019/7/30.
//

#import "P12HTTPConnection.h"
#import <SCHTTPServer/HTTPLogging.h>

@implementation P12HTTPConnection

static const char *p12_pwd  = NULL;
static const char *p12_path = NULL;

static void NSString2CharPoint(NSString *src,const char ** dest)
{
    if (NULL != dest && NULL != *dest) {
        free((void *)*dest);
        *dest = NULL;
    }
    if (!src) {
        *dest = NULL;
        return;
    }
    const char *c_src = [src UTF8String];
    size_t size  = strlen(c_src) + 1;
    char *buffer = malloc(size);
    memset(buffer, 0, size);
    memcpy(buffer, c_src, size - 1);
    *dest = buffer;
}

+ (void)pkcsPassword:(NSString *)pwd
{
    NSAssert([pwd length] > 0, @"P12 密码长度必须大于0！");
    NSString2CharPoint(pwd, &p12_pwd);
}

+ (void)pkcsPath:(NSString *)path
{
    NSAssert([[NSFileManager defaultManager]fileExistsAtPath:path], @"P12 证书不存在！");
    NSString2CharPoint(path, &p12_path);
}

/**
 * Overrides HTTPConnection's method
 **/
- (BOOL)isSecureServer
{
    HTTPLogTrace();

    // Create an HTTPS server (all connections will be secured via SSL/TLS)
    return YES;
}

static OSStatus CopyIdentityFromPKCS12File(const char *cPath,
                                           const char *cPassword,
                                           SecIdentityRef *out_cert_and_key)
{
    OSStatus status = errSecItemNotFound;
    CFURLRef pkcs_url = CFURLCreateFromFileSystemRepresentation(NULL,
                                                                (const UInt8 *)cPath, strlen(cPath), false);
    CFStringRef password = cPassword ? CFStringCreateWithCString(NULL,
                                                                 cPassword, kCFStringEncodingUTF8) : NULL;
    CFDataRef pkcs_data = NULL;
    
    /* We can import P12 files on iOS or OS X 10.7 or later: */
    /* These constants are documented as having first appeared in 10.6 but they
     raise linker errors when used on that cat for some reason. */
//    CFURLCopyResourcePropertiesForKeys(pkcs_url, <#CFArrayRef keys#>, <#CFErrorRef *error#>)
    if(CFURLCreateDataAndPropertiesFromResource(NULL, pkcs_url, &pkcs_data,
                                                NULL, NULL, &status)) {
        const void *cKeys[] = {kSecImportExportPassphrase};
        const void *cValues[] = {password};
        CFDictionaryRef options = CFDictionaryCreate(NULL, cKeys, cValues,
                                                     password ? 1L : 0L, NULL, NULL);
        CFArrayRef items = NULL;
        
        /* Here we go: */
        status = SecPKCS12Import(pkcs_data, options, &items);
        if(status == errSecSuccess && items && CFArrayGetCount(items)) {
            CFDictionaryRef identity_and_trust = CFArrayGetValueAtIndex(items, 0L);
            const void *temp_identity = CFDictionaryGetValue(identity_and_trust,
                                                             kSecImportItemIdentity);
            
            /* Retain the identity; we don't care about any other data... */
            CFRetain(temp_identity);
            *out_cert_and_key = (SecIdentityRef)temp_identity;
        }
        
        if(items)
            CFRelease(items);
        CFRelease(options);
        CFRelease(pkcs_data);
    }
    if(password)
        CFRelease(password);
    CFRelease(pkcs_url);
    return status;
}

/* Apple provides a myriad of ways of getting information about a certificate
 into a string. Some aren't available under iOS or newer cats. So here's
 a unified function for getting a string describing the certificate that
 ought to work in all cats starting with Leopard. */
CF_INLINE CFStringRef CopyCertSubject(SecCertificateRef cert)
{
    CFStringRef server_cert_summary = NULL;
    /* Lion & later: Get the long description if we can. */
    server_cert_summary = SecCertificateCopyLongDescription(NULL, cert, NULL);
    /* Snow Leopard: Get the certificate summary. */
    if(NULL == server_cert_summary)
        server_cert_summary = SecCertificateCopySubjectSummary(cert);
    /* Leopard is as far back as we go... */
    if(NULL == server_cert_summary)
        SecCertificateCopyCommonName(cert, &server_cert_summary);
    /* default is null ... */
    if(NULL == server_cert_summary)
        server_cert_summary = CFSTR("(null)");
    return server_cert_summary;
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
    SecIdentityRef cert_and_key = NULL;

    CopyIdentityFromPKCS12File(p12_path, p12_pwd, &cert_and_key);
    
    SecCertificateRef cert = NULL;
    
    /* If we found one, print it out: */
    OSStatus err = SecIdentityCopyCertificate(cert_and_key, &cert);
    if(err == noErr) {
        CFStringRef cert_summary = CopyCertSubject(cert);
        char cert_summary_c[128];
        
        if(cert_summary) {
            memset(cert_summary_c, 0, 128);
            if(CFStringGetCString(cert_summary,
                                  cert_summary_c,
                                  128,
                                  kCFStringEncodingUTF8)) {
                NSLog(@"Client certificate: %s\n", cert_summary_c);
            }
            CFRelease(cert_summary);
            CFRelease(cert);
        }
    }
    
//    CFTypeRef certs_c[1];
//    CFArrayRef certs;
//
//    certs_c[0] = cert_and_key;
//    certs = CFArrayCreate(NULL, (const void **)certs_c, 1L,
//                          &kCFTypeArrayCallBacks);
//    if(certs)
//        CFRelease(certs);
    
    NSArray *result = cert_and_key != NULL ? @[(__bridge id)cert_and_key] : nil;
    if (cert_and_key)
        CFRelease(cert_and_key);
    
    return result;
}


@end
