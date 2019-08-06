//
//  HTTPJSONResponse.h
//  SCHTTPServer
//
//  Created by Matt Reach on 2019/8/1.
//
// application/json;charset=UTF-8

#import "HTTPDataResponse.h"

@interface HTTPJSONResponse : HTTPDataResponse

- (id)initWithJSON:(id)json;

@end
