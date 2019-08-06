//
//  HTTPJSONResponse.m
//  SCHTTPServer
//
//  Created by Matt Reach on 2019/8/1.
//

#import "HTTPJSONResponse.h"
#import "HTTPLogger.h"

@implementation HTTPJSONResponse

- (instancetype)initWithJSON:(id)json
{
    NSError *error = nil;
    id data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        HTTPLogError(@"Can't serial json to data:%@",json);
    }
    
    HTTPJSONResponse *resp = [self initWithData:data];
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithCapacity:3];
    NSDictionary *superHeaders = resp.httpHeaders ? resp.httpHeaders : @{};
    
    [headers addEntriesFromDictionary:superHeaders];
    [headers setObject:@"application/json;charset=UTF-8" forKey:@"Content-Type"];
    self.httpHeaders = [headers copy];
    return resp;
}

@end
