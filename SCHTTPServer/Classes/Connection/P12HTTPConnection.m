//
//  P12HTTPConnection.m
//  SCHTTPServerDemo
//
//  Created by Matt Reach on 2019/7/30.
//

#import "P12HTTPConnection.h"
#import <SCHTTPServer/HTTPLogger.h>

static NSString *p12Pwd  = nil;
static NSString *p12Path = nil;
static NSString *p12Desc = nil;

@implementation P12HTTPConnection

+ (void)pkcsPassword:(NSString *)pwd
{
    NSAssert([pwd length] > 0, @"P12 密码长度必须大于0！");
    p12Pwd = pwd;
}

+ (void)pkcsPath:(NSString *)path
{
    NSAssert([[NSFileManager defaultManager]fileExistsAtPath:path], @"P12 证书不存在！");
    p12Path = path;
}

+ (void)pkcsDesc:(NSString *)descriptor
{
    NSAssert([descriptor length] > 0, @"P12 证书描述必须大于0！");
    p12Desc = descriptor;
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

static void deleteKeychain(NSString *keychainPath){
    NSError *error = NULL;
    if (![[NSFileManager defaultManager] removeItemAtPath:keychainPath error:&error]) {
        HTTPLogError(@"Failed to delete existing test keychain: %@", error);
    }
}

static bool defaultAccess(SecAccessRef * __nonnull CF_RETURNS_RETAINED accessRef)
{
    int rc = 0;
    CFMutableArrayRef trustedApplications = NULL;
    /* build a list of trusted applications */
    trustedApplications = CFArrayCreateMutable(kCFAllocatorDefault,
                                               0, &kCFTypeArrayCallBacks);
    SecTrustedApplicationRef myself = NULL;
    /* add the calling program */
    
    rc = SecTrustedApplicationCreateFromPath(NULL, &myself);
    if ( rc != errSecSuccess ) {
        HTTPLogError(@"SecTrustedApplication Failed!");
    } else {
        CFArrayAppendValue(trustedApplications, myself);
    }
    
//    /* add keychain access */
//    rc = SecTrustedApplicationCreateFromPath("/Applications/Utilities/Keychain Access.app",
//                                             &KeychainAccess);
//    if ( rc ) {
//        msg = "SecTrustedApplicationCreateFromPath(Keychain Access.app)";
//        goto cleanup;
//    }
//    CFArrayAppendValue(trustedApplications, KeychainAccess);
    
    /* create the access from the list */
    
    rc = SecAccessCreate((__bridge CFStringRef)p12Desc, (CFArrayRef)trustedApplications, accessRef);
    if ( rc != errSecSuccess ) {
        HTTPLogError(@"SecAccessCreate failed");
    }
    return rc == errSecSuccess;
}

static bool createNewKeychain(NSString *keychainPath,SecKeychainRef * keychain){
    SecAccessRef accessRef = NULL;
    const char *cPath = [keychainPath cStringUsingEncoding:NSUTF8StringEncoding];
    if (defaultAccess(&accessRef)) {
        int pwdLength = 6;
        void *pwd = malloc(pwdLength + 1);
        memset(pwd, 0, pwdLength + 1);
        for (int i = 0; i < pwdLength; i ++) {
            //[32,126] = 32 + [0,94]
            int j = 32 + arc4random() % 95;
            char *dest = (char *)pwd;
            *dest = j;
            dest ++;
        }
        OSStatus result = SecKeychainCreate(cPath, pwdLength, pwd, NO, accessRef, keychain);
        if (NULL != pwd) {
            free(pwd);
            pwd = NULL;
        }
        if (result == errSecSuccess) {
            HTTPLogInfo(@"SecKeychainCreate succeed!");
        } else {
            HTTPLogError(@"SecKeychainCreate failed:(%d)", result);
        }
        return result == errSecSuccess;
    }
    return false;
}

static bool openExistKeychain(NSString *keychainPath,SecKeychainRef * keychain){
    if ([[NSFileManager defaultManager] fileExistsAtPath:keychainPath]) {
        const char *cPath = [keychainPath cStringUsingEncoding:NSUTF8StringEncoding];
        if (errSecSuccess == SecKeychainOpen(cPath, keychain)) {
            HTTPLogInfo(@"Use Exist Keychain: %@", keychainPath);
            return true;
        } else {
            HTTPLogInfo(@"Can't Open Old Keychain, so delete it: %@", keychainPath);
            deleteKeychain(keychainPath);
            return false;
        }
    } else {
        return false;
    }
}

static void removeKeychainIfAccessBad(NSString *keychainPath)
{
    //1、these method are not implemented! can't check current process can access the old keychain!
    //OSStatus result = SecKeychainCopyAccess(privateKeychain, &accessRef2);
    //OSStatus result = SecKeychainSetAccess(keychain, accessRef);
    
    //2、I want to use sc_lastTrustPath record the application path, if the path not equal current runing process then remove the old keychain, because current runing process can't access the old keychain before user confirm access alert! However I failed ,even the application bundle path equal,but still can' access before user confirm access alert!
        
//    NSString *lastTrustPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"sc_lastTrustPath"];
//    NSString *currentTrustPath = [[NSBundle mainBundle] bundlePath];
//    if (lastTrustPath && ![lastTrustPath isEqualToString:currentTrustPath]) {
//        HTTPLogInfo(@"remove old keychain!");
//        deleteKeychain(keychainPath);
//        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sc_lastTrustPath"];
//    }
    //so delete it!
    if ([[NSFileManager defaultManager] fileExistsAtPath:keychainPath]) {
        deleteKeychain(keychainPath);
        HTTPLogInfo(@"Removed old keychain file");
    }
}

//static void updateLastTrustPath()
//{
//    NSString *currentTrustPath = [[NSBundle mainBundle] bundlePath];
//    [[NSUserDefaults standardUserDefaults] setObject:currentTrustPath forKey:@"sc_lastTrustPath"];
//}

static SecKeychainRef privateKeyChain()
{
    //static
    SecKeychainRef privateKeychain = NULL;
    if (!privateKeychain) {
        
        NSString *keychainPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"SCKeychain"];
        
        removeKeychainIfAccessBad(keychainPath);
        
        if (!openExistKeychain(keychainPath, &privateKeychain)) {
            createNewKeychain(keychainPath, &privateKeychain);
        }
    }
    return privateKeychain;
}

static OSStatus CopyIdentityFromPKCS12File(NSString *path,
                                           NSString *password,
                                           SecIdentityRef *out_cert_and_key)
{
    CFDataRef pkcs_data = NULL;
    NSData *data = [NSData dataWithContentsOfFile:path];
    pkcs_data = (__bridge CFDataRef)(data);
    
//    CFURLRef pkcs_url = CFURLCreateFromFileSystemRepresentation(NULL,
//                                                                (const UInt8 *)cPath, strlen(cPath), false);
//
//    if(CFURLCreateDataAndPropertiesFromResource(NULL, pkcs_url, &pkcs_data,
//                                                NULL, NULL, &status)) {
//
//
//    }
//    CFRelease(pkcs_url);
//    CFRelease(pkcs_data);
    SecKeychainRef privateKeychain = privateKeyChain();
    if (privateKeychain == NULL) {
        assert(0);
    }
    
    CFStringRef pwdRef    = (__bridge CFStringRef)(password);
    const void *cKeys[]   = {kSecImportExportPassphrase,kSecImportExportKeychain};
    const void *cValues[] = {pwdRef,privateKeychain};
    
    CFDictionaryRef options = CFDictionaryCreate(NULL, cKeys, cValues,
                                                 password ? 2L : 0L, NULL, NULL);
    
    CFArrayRef items = NULL;
    /* Here we go: */
    OSStatus status = SecPKCS12Import(pkcs_data, options, &items);
    if(status == errSecSuccess && items && CFArrayGetCount(items)) {
        CFDictionaryRef identity_and_trust = CFArrayGetValueAtIndex(items, 0L);
        const void *temp_identity = CFDictionaryGetValue(identity_and_trust,
                                                         kSecImportItemIdentity);
        
        /* Retain the identity; we don't care about any other data... */
        CFRetain(temp_identity);
        *out_cert_and_key = (SecIdentityRef)temp_identity;
    } else {
        HTTPLogError(@"SecPKCS12Import failed: %d", status);
    }
    
    if(items)
        CFRelease(items);
    CFRelease(options);
    
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
 v0.1.2 修改
 将 SecIdentityRef 做成静态的，不必每次都从keychain导一次；keychain做成非静态的；
 解决程序重启后仍旧出现弹出授权询问框问题；
 **/
- (NSArray *)sslIdentityAndCertificates
{
    HTTPLogTrace();
    static SecIdentityRef cert_and_key = NULL;
    
    if (!cert_and_key) {
        HTTPLogInfo(@"Create SecIdentityRef from PKCS12 file!");
        CopyIdentityFromPKCS12File(p12Path, p12Pwd, &cert_and_key);
        CFRetain(cert_and_key);
        
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
                    HTTPLogInfo(@"Client certificate: %s\n", cert_summary_c);
                }
                CFRelease(cert_summary);
                CFRelease(cert);
            }
        }
    }
    
    NSArray *result = cert_and_key != NULL ? @[(__bridge id)cert_and_key] : nil;
//    if (cert_and_key)
//        CFRelease(cert_and_key);
    
    return result;
}

@end
