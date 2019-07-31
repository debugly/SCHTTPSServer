//
//  P12HTTPConnection.h
//  SCHTTPServer
//
//  Created by Matt Reach on 2019/7/30.
//
// Support PKCS#12 Certificate.

#import <Foundation/Foundation.h>
#import "HTTPConnection.h"

@interface P12HTTPConnection : HTTPConnection

/**
 设置 P12 证书密码；在导出 P12 证书时必须设置秘密！否则将会报错：
 errSecPassphraseRequired = -25260, //Passphrase is required for import/export.
 */
+ (void)pkcsPassword:(NSString *)pwd;

/**
 设置 P12 证书路径；
 */
+ (void)pkcsPath:(NSString *)path;

@end
