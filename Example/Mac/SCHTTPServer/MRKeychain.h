//
//  MRKeychain.h
//  SCHTTPServerDemo
//
//  Created by Matt Reach on 2019/7/31.
//

#import <Foundation/Foundation.h>

@interface MRKeychain : NSObject

+ (NSArray *)SelfCertificateExist;
+ (void)createNewIdentity;

@end
