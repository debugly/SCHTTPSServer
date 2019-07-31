//
//  AppDelegate.m
//  SCHTTPServer
//
//  Created by Matt Reach on 2019/7/26.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
//    NSString *derPath = [[NSBundle mainBundle] pathForResource:@"localhost.gengtaotjut.com" ofType:@"der"];
//    NSData *data = [NSData dataWithContentsOfFile:derPath];
//    SecCertificateRef der = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)data);
//    if (der != NULL) {
//        NSLog(@"读取Der成功");
//        SecIdentityRef serverIdentityRef;
//        SecIdentityCreateWithCertificate(NULL, der, &serverIdentityRef);
//        if (serverIdentityRef != NULL) {
//            NSLog(@"创建SecIdentity成功");
//        }
//    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
