//
//  HTTPJSONResponse.h
//  SCHTTPServer
//
//  Created by Matt Reach on 2019/8/1.
//

#import "HTTPDataResponse.h"

@interface HTTPJSONResponse : HTTPDataResponse

- (id)initWithJSON:(id)json status:(int)status;

@end
