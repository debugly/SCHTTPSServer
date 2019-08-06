//
//  HTTPJSONPResponse.m
//  SCHTTPServer
//
//  Created by Matt Reach on 2019/8/6.
//

#import "HTTPJSONPResponse.h"

@implementation HTTPJSONPResponse

- (instancetype)initWithJSON:(id)json callback:(NSString *)callback
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
    NSData *payloadData = nil;
    if (jsonData) {
        NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSString *payloadStr = [NSString stringWithFormat:@"%@(%@);",callback,jsonStr];
        payloadData = [payloadStr dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    HTTPJSONPResponse *resp = [super initWithData:payloadData];
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithCapacity:3];
    NSDictionary *superHeaders = resp.httpHeaders ? resp.httpHeaders : @{};
    
    [headers addEntriesFromDictionary:superHeaders];
    [headers setObject:@"application/javascript;charset=UTF-8" forKey:@"Content-Type"];
    self.httpHeaders = [headers copy];
    return resp;
}

@end
