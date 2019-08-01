//
//  MRKeychain.m
//  SCHTTPServerDemo
//
//  Created by Matt Reach on 2019/7/31.
//

#import "MRKeychain.h"

@implementation MRKeychain

+ (NSArray *)SelfCertificateExist
{
    NSMutableDictionary* query = [NSMutableDictionary dictionary];
    
    [query setObject:(id)kSecClassIdentity forKey:(id)kSecClass];
    [query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
    [query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    [query setObject:(id)kSecMatchLimitAll forKey:(id)kSecMatchLimit];
    [query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnRef];
    [query setObject:@"SecureHTTPServer" forKey:(id)kSecAttrLabel];
    
    CFTypeRef stuff = NULL;
    OSStatus err = SecItemCopyMatching((CFDictionaryRef)query, &stuff);
    
    NSMutableArray *result = nil;
    
    if (err == errSecItemNotFound) {
        
    } else if (err == noErr){
        result = [NSMutableArray arrayWithCapacity:1];
        CFIndex count = CFArrayGetCount(stuff);
        for (int i = 0; i < count; i ++) {
            CFDictionaryRef dataTypeRef = CFArrayGetValueAtIndex(stuff, i);
            NSDictionary *dict = (__bridge NSDictionary *)dataTypeRef;
            CFStringRef clazz = CFDictionaryGetValue(dataTypeRef, kSecClass);
            if (kCFCompareEqualTo == CFStringCompare(kSecClassCertificate, clazz, 0)) {
                //NSLog(@"%@",dict);
                CFStringRef label = CFDictionaryGetValue(dataTypeRef, kSecAttrLabel);
                //NSLog(@"label:%@",label);
                if (kCFCompareEqualTo == CFStringCompare(CFSTR("SecureHTTPServer"), label, 0)) {
                    id cert = (id)dict[(__bridge id)kSecValueRef];
                    [result addObject:cert];
                    //                SecIdentity
                    //                * The certRefs argument is a CFArray containing SecCertificateRefs,
                    //                * except for certRefs[0], which is a SecIdentityRef.
                    
                    //                NSData *data = (id)dict[(__bridge id)kSecValueData];
                    //                NSLog(@"%@",data);//[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]
                    //
                    //                SecCertificateRef certificate = (__bridge SecCertificateRef)cert;
                    //                NSString *name =  CFBridgingRelease(SecCertificateCopySubjectSummary(certificate));
                    //                NSLog(@"%@",name);
                    //                SecKeyRef publicKey = NULL;
                    //                SecCertificateCopyPublicKey(certificate, &publicKey);
                    //
                    //                SecTrustRef trustRef = NULL;
                    //                SecPolicyRef policy = SecPolicyCreateBasicX509();
                    //                SecCertificateRef certificates[1];
                    //                SecTrustCreateWithCertificates((CFTypeRef)certificates, policy, &trustRef);
                    //                // 获得公钥对象
                    //                SecTrustCopyPublicKey(trustRef);
                }
            }
        }
    }
    
    if (stuff != NULL) {
        CFRelease(stuff);
        stuff = NULL;
    }
    return [result copy];
}

/**
 * Creates (if necessary) and returns a temporary directory for the application.
 *
 * A general temporary directory is provided for each user by the OS.
 * This prevents conflicts between the same application running on multiple user accounts.
 * We take this a step further by putting everything inside another subfolder, identified by our application name.
 **/
+ (NSString *)applicationTemporaryDirectory
{
    NSString *userTempDir = NSTemporaryDirectory();
    NSString *appTempDir = [userTempDir stringByAppendingPathComponent:@"SecureHTTPServer"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:appTempDir] == NO)
    {
        [fileManager createDirectoryAtPath:appTempDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return appTempDir;
}

/**
 * Simple utility class to convert a SecExternalFormat into a string suitable for printing/logging.
 **/
+ (NSString *)stringForSecExternalFormat:(SecExternalFormat)extFormat
{
    switch(extFormat)
    {
        case kSecFormatUnknown              : return @"kSecFormatUnknown";
            
            /* Asymmetric Key Formats */
        case kSecFormatOpenSSL              : return @"kSecFormatOpenSSL";
        case kSecFormatSSH                  : return @"kSecFormatSSH - Not Supported";
        case kSecFormatBSAFE                : return @"kSecFormatBSAFE";
            
            /* Symmetric Key Formats */
        case kSecFormatRawKey               : return @"kSecFormatRawKey";
            
            /* Formats for wrapped symmetric and private keys */
        case kSecFormatWrappedPKCS8         : return @"kSecFormatWrappedPKCS8";
        case kSecFormatWrappedOpenSSL       : return @"kSecFormatWrappedOpenSSL";
        case kSecFormatWrappedSSH           : return @"kSecFormatWrappedSSH - Not Supported";
        case kSecFormatWrappedLSH           : return @"kSecFormatWrappedLSH - Not Supported";
            
            /* Formats for certificates */
        case kSecFormatX509Cert             : return @"kSecFormatX509Cert";
            
            /* Aggregate Types */
        case kSecFormatPEMSequence          : return @"kSecFormatPEMSequence";
        case kSecFormatPKCS7                : return @"kSecFormatPKCS7";
        case kSecFormatPKCS12               : return @"kSecFormatPKCS12";
        case kSecFormatNetscapeCertSequence : return @"kSecFormatNetscapeCertSequence";
            
        default                             : return @"Unknown";
    }
}

/**
 * Simple utility class to convert a SecExternalItemType into a string suitable for printing/logging.
 **/
+ (NSString *)stringForSecExternalItemType:(SecExternalItemType)itemType
{
    switch(itemType)
    {
        case kSecItemTypeUnknown     : return @"kSecItemTypeUnknown";
            
        case kSecItemTypePrivateKey  : return @"kSecItemTypePrivateKey";
        case kSecItemTypePublicKey   : return @"kSecItemTypePublicKey";
        case kSecItemTypeSessionKey  : return @"kSecItemTypeSessionKey";
        case kSecItemTypeCertificate : return @"kSecItemTypeCertificate";
        case kSecItemTypeAggregate   : return @"kSecItemTypeAggregate";
            
        default                      : return @"Unknown";
    }
}

+ (void)createNewIdentity
{
    // Declare any Carbon variables we may create
    // We do this here so it's easier to compare to the bottom of this method where we release them all
    SecKeychainRef keychain = NULL;
    CFArrayRef outItems = NULL;
    
    // Configure the paths where we'll create all of our identity files
    NSString *basePath = [self applicationTemporaryDirectory];
    
    NSString *privateKeyPath  = [basePath stringByAppendingPathComponent:@"private.pem"];
    NSString *reqConfPath     = [basePath stringByAppendingPathComponent:@"req.conf"];
    NSString *certificatePath = [basePath stringByAppendingPathComponent:@"certificate.crt"];
    NSString *certWrapperPath = [basePath stringByAppendingPathComponent:@"certificate.p12"];
    
    // You can generate your own private key by running the following command in the terminal:
    // openssl genrsa -out private.pem 1024
    //
    // Where 1024 is the size of the private key.
    // You may used a bigger number.
    // It is probably a good recommendation to use at least 1024...
    
    NSArray *privateKeyArgs = [NSArray arrayWithObjects:@"genrsa", @"-out", privateKeyPath, @"1024", nil];
    
    NSTask *genPrivateKeyTask = [[NSTask alloc] init];
    
    [genPrivateKeyTask setLaunchPath:@"/usr/bin/openssl"];
    [genPrivateKeyTask setArguments:privateKeyArgs];
    [genPrivateKeyTask launch];
    
    // Don't use waitUntilExit - I've had too many problems with it in the past
    do {
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    } while([genPrivateKeyTask isRunning]);
    
    // Now we want to create a configuration file for our certificate
    // This is an optional step, but we do it so people who are browsing their keychain
    // know exactly where the certificate came from, and don't delete it.
    
    NSMutableString *mStr = [NSMutableString stringWithCapacity:500];
    [mStr appendFormat:@"%@\n", @"[ req ]"];
    [mStr appendFormat:@"%@\n", @"distinguished_name  = req_distinguished_name"];
    [mStr appendFormat:@"%@\n", @"prompt              = no"];
    [mStr appendFormat:@"%@\n", @""];
    [mStr appendFormat:@"%@\n", @"[ req_distinguished_name ]"];
    [mStr appendFormat:@"%@\n", @"C                   = US"];
    [mStr appendFormat:@"%@\n", @"ST                  = Missouri"];
    [mStr appendFormat:@"%@\n", @"L                   = Springfield"];
    [mStr appendFormat:@"%@\n", @"O                   = Deusty Designs, LLC"];
    [mStr appendFormat:@"%@\n", @"OU                  = Open Source"];
    [mStr appendFormat:@"%@\n", @"CN                  = SecureHTTPServer"];
    [mStr appendFormat:@"%@\n", @"emailAddress        = robbiehanson@deusty.com"];
    
    [mStr writeToFile:reqConfPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    
    // You can generate your own certificate by running the following command in the terminal:
    // openssl req -new -x509 -key private.pem -out certificate.crt -text -days 365 -batch
    //
    // You can optionally create a configuration file, and pass an extra command to use it:
    // -config req.conf
    
    NSArray *certificateArgs = [NSArray arrayWithObjects:@"req", @"-new", @"-x509",
                                @"-key", privateKeyPath,
                                @"-config", reqConfPath,
                                @"-out", certificatePath,
                                @"-text", @"-days", @"365", @"-batch", nil];
    
    NSTask *genCertificateTask = [[NSTask alloc] init];
    
    [genCertificateTask setLaunchPath:@"/usr/bin/openssl"];
    [genCertificateTask setArguments:certificateArgs];
    [genCertificateTask launch];
    
    // Don't use waitUntilExit - I've had too many problems with it in the past
    do {
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    } while([genCertificateTask isRunning]);
    
    // Mac OS X has problems importing private keys, so we wrap everything in PKCS#12 format
    // You can create a p12 wrapper by running the following command in the terminal:
    // openssl pkcs12 -export -in certificate.crt -inkey private.pem
    //   -passout pass:password -out certificate.p12 -name "Open Source"
    
    NSArray *certWrapperArgs = [NSArray arrayWithObjects:@"pkcs12", @"-export", @"-export",
                                @"-in", certificatePath,
                                @"-inkey", privateKeyPath,
                                @"-passout", @"pass:password",
                                @"-out", certWrapperPath,
                                @"-name", @"SecureHTTPServer", nil];
    
    NSTask *genCertWrapperTask = [[NSTask alloc] init];
    
    [genCertWrapperTask setLaunchPath:@"/usr/bin/openssl"];
    [genCertWrapperTask setArguments:certWrapperArgs];
    [genCertWrapperTask launch];
    
    // Don't use waitUntilExit - I've had too many problems with it in the past
    do {
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    } while([genCertWrapperTask isRunning]);
    
    // At this point we've created all the identity files that we need
    // Our next step is to import the identity into the keychain
    // We can do this by using the SecKeychainItemImport() method.
    // But of course this method is "Frozen in Carbonite"...
    // So it's going to take us 100 lines of code to build up the parameters needed to make the method call
    NSData *certData = [NSData dataWithContentsOfFile:certWrapperPath];
    
    /* SecKeyImportExportFlags - typedef uint32_t
     * Defines values for the flags field of the import/export parameters.
     *
     * enum
     * {
     *    kSecKeyImportOnlyOne        = 0x00000001,
     *    kSecKeySecurePassphrase     = 0x00000002,
     *    kSecKeyNoAccessControl      = 0x00000004
     * };
     *
     * kSecKeyImportOnlyOne
     *     Prevents the importing of more than one private key by the SecKeychainItemImport function.
     *     If the importKeychain parameter is NULL, this bit is ignored. Otherwise, if this bit is set and there is
     *     more than one key in the incoming external representation,
     *     no items are imported to the specified keychain and the error errSecMultipleKeys is returned.
     * kSecKeySecurePassphrase
     *     When set, the password for import or export is obtained by user prompt. Otherwise, you must provide the
     *     password in the passphrase field of the SecKeyImportExportParameters structure.
     *     A user-supplied password is preferred, because it avoids having the cleartext password appear in the
     *     application’s address space at any time.
     * kSecKeyNoAccessControl
     *     When set, imported private keys have no access object attached to them. In the absence of both this bit and
     *     the accessRef field in SecKeyImportExportParameters, imported private keys are given default access controls
     **/
    
    SecKeyImportExportFlags importFlags = kSecKeyImportOnlyOne;
    
    /* SecKeyImportExportParameters - typedef struct
     *
     * FOR IMPORT AND EXPORT:
     * uint32_t version
     *     The version of this structure; the current value is SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION.
     * SecKeyImportExportFlags flags
     *     A set of flag bits, defined in "Keychain Item Import/Export Parameter Flags".
     * CFTypeRef passphrase
     *     A password, used for kSecFormatPKCS12 and kSecFormatWrapped formats only...
     *     IE - kSecFormatWrappedOpenSSL, kSecFormatWrappedSSH, or kSecFormatWrappedPKCS8
     * CFStringRef alertTitle
     *     Title of secure password alert panel.
     *     When importing or exporting a key, if you set the kSecKeySecurePassphrase flag bit,
     *     you can optionally use this field to specify a string for the password panel’s title bar.
     * CFStringRef alertPrompt
     *     Prompt in secure password alert panel.
     *     When importing or exporting a key, if you set the kSecKeySecurePassphrase flag bit,
     *     you can optionally use this field to specify a string for the prompt that appears in the password panel.
     *
     * FOR IMPORT ONLY:
     * SecAccessRef accessRef
     *     Specifies the initial access controls of imported private keys.
     *     If more than one private key is being imported, all private keys get the same initial access controls.
     *     If this field is NULL when private keys are being imported, then the access object for the keychain item
     *     for an imported private key depends on the kSecKeyNoAccessControl bit in the flags parameter.
     *     If this bit is 0 (or keyParams is NULL), the default access control is used.
     *     If this bit is 1, no access object is attached to the keychain item for imported private keys.
     * CSSM_KEYUSE keyUsage
     *     A word of bits constituting the low-level use flags for imported keys as defined in cssmtype.h.
     *     If this field is 0 or keyParams is NULL, the default value is CSSM_KEYUSE_ANY.
     * CSSM_KEYATTR_FLAGS keyAttributes
     *     The following are valid values for these flags:
     *     CSSM_KEYATTR_PERMANENT, CSSM_KEYATTR_SENSITIVE, and CSSM_KEYATTR_EXTRACTABLE.
     *     The default value is CSSM_KEYATTR_SENSITIVE | CSSM_KEYATTR_EXTRACTABLE
     *     The CSSM_KEYATTR_SENSITIVE bit indicates that the key can only be extracted in wrapped form.
     *     Important: If you do not set the CSSM_KEYATTR_EXTRACTABLE bit,
     *     you cannot extract the imported key from the keychain in any form, including in wrapped form.
     **/
    
    SecItemImportExportKeyParameters importParameters;
    importParameters.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
    importParameters.flags = importFlags;
    importParameters.passphrase = CFSTR("password");
    importParameters.accessRef = NULL;
    
    NSArray *keyAttrs = [[NSArray alloc] initWithObjects: (id) kSecAttrIsPermanent,kSecAttrIsSensitive, nil];
    importParameters.keyAttributes = (__bridge_retained CFArrayRef) keyAttrs;
    NSArray *keyUsage = [[NSArray alloc] initWithObjects: (id) kSecAttrCanVerify, nil];
    importParameters.keyUsage = (__bridge_retained CFArrayRef) keyUsage;
    //kSecAttrIsExtractable
    importParameters.keyAttributes = (__bridge CFArrayRef) @[ @(CSSM_KEYATTR_EXTRACTABLE) ];
    importParameters.keyUsage = NULL;
    //    kSecAttrCanEncrypt
    //    importParameters.keyUsage = CSSM_KEYUSE_ANY;
    
    /* SecKeychainItemImport - Imports one or more certificates, keys, or identities and adds them to a keychain.
     *
     * Parameters:
     * CFDataRef importedData
     *     The external representation of the items to import.
     * CFStringRef fileNameOrExtension
     *     The name or extension of the file from which the external representation was obtained.
     *     Pass NULL if you don’t know the name or extension.
     * SecExternalFormat *inputFormat
     *     On input, points to the format of the external representation.
     *     Pass kSecFormatUnknown if you do not know the exact format.
     *     On output, points to the format that the function has determined the external representation to be in.
     *     Pass NULL if you don’t know the format and don’t want the format returned to you.
     * SecExternalItemType *itemType
     *     On input, points to the item type of the item or items contained in the external representation.
     *     Pass kSecItemTypeUnknown if you do not know the item type.
     *     On output, points to the item type that the function has determined the external representation to contain.
     *     Pass NULL if you don’t know the item type and don’t want the type returned to you.
     * SecItemImportExportFlags flags
     *     Unused; pass in 0.
     * const SecKeyImportExportParameters *keyParams
     *     A pointer to a structure containing a set of input parameters for the function.
     *     If no key items are being imported, these parameters are optional
     *     and you can set the keyParams parameter to NULL.
     * SecKeychainRef importKeychain
     *     A keychain object indicating the keychain to which the key or certificate should be imported.
     *     If you pass NULL, the item is not imported.
     *     Use the SecKeychainCopyDefault function to get a reference to the default keychain.
     *     If the kSecKeyImportOnlyOne bit is set and there is more than one key in the
     *     incoming external representation, no items are imported to the specified keychain and the
     *     error errSecMultiplePrivKeys is returned.
     * CFArrayRef *outItems
     *     On output, points to an array of SecKeychainItemRef objects for the imported items.
     *     You must provide a valid pointer to a CFArrayRef object to receive this information.
     *     If you pass NULL for this parameter, the function does not return the imported items.
     *     Release this object by calling the CFRelease function when you no longer need it.
     **/
    
    SecExternalFormat inputFormat = kSecFormatPKCS12;
    SecExternalItemType itemType = kSecItemTypeCertificate;
    
    SecKeychainCopyDefault(&keychain);
    
    OSStatus err = 0;
    err = SecItemImport((__bridge CFDataRef)certData,  // CFDataRef importedData
                        NULL,                          // CFStringRef fileNameOrExtension
                        &inputFormat,                  // SecExternalFormat *inputFormat
                        &itemType,                     // SecExternalItemType *itemType
                        0,                             // SecItemImportExportFlags flags (Unused)
                        &importParameters,             // const SecKeyImportExportParameters *keyParams
                        keychain,                      // SecKeychainRef importKeychain
                        &outItems);                    // CFArrayRef *outItems
    
    NSLog(@"OSStatus: %i", err);
    if (errSecParam == err) {
        
    }
    NSLog(@"SecExternalFormat: %@", [self stringForSecExternalFormat:inputFormat]);
    NSLog(@"SecExternalItemType: %@", [self stringForSecExternalItemType:itemType]);
    
    NSLog(@"outItems: %@", (__bridge NSArray *)outItems);
    
    // Don't forget to delete the temporary files
    [[NSFileManager defaultManager] removeItemAtPath:privateKeyPath  error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:reqConfPath     error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:certificatePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:certWrapperPath error:nil];
    
    // Don't forget to release anything we may have created
    if(keychain)   CFRelease(keychain);
    if(outItems)   CFRelease(outItems);
}

@end
