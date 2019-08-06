//
//  HTTPResponseMaker.h
//  SCHTTPServer
//
//  Created by Matt Reach on 2019/8/6.
//
// 工厂方法

#import "HTTPResponse.h"
#import "HTTPMessage.h"

@interface HTTPResponseMaker : NSObject

+ (id<HTTPResponse>)make:(id)payload req:(HTTPMessage *)req;

@end
