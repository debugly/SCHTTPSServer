//
//  HTTPJSONPResponse.h
//  SCHTTPServer
//
//  Created by Matt Reach on 2019/8/6.
//
// Suport JSONP callback;
// application/javascript; charset=utf-8

#import "HTTPDataResponse.h"

@interface HTTPJSONPResponse : HTTPDataResponse

- (id)initWithJSON:(id)json callback:(NSString *)callback;

@end
