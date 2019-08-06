//
//  HTTPResponseMaker.m
//  SCHTTPServer
//
//  Created by Matt Reach on 2019/8/6.
//

#import "HTTPResponseMaker.h"
#import "HTTPJSONPResponse.h"
#import "HTTPJSONResponse.h"

@implementation HTTPResponseMaker

+ (NSDictionary *)queryMapWithString:(NSString *)queryStr
{
    NSMutableDictionary *map = [[NSMutableDictionary alloc]init];
    if (queryStr && queryStr.length > 1) {
        NSArray *items = [queryStr componentsSeparatedByString:@"&"];
        for (NSString *item in items) {
            NSArray *keyValue = [item componentsSeparatedByString:@"="];
            
            NSString *key = [keyValue firstObject];
            NSString *value = [keyValue lastObject];
            //URL解码
            NSString *v = [value stringByRemovingPercentEncoding];
            while ([v rangeOfString:@"%"].location != NSNotFound) {
                v = [v stringByRemovingPercentEncoding];
            }
            [map setObject:v forKey:key];
        }
    }
    return [map copy];
}

+ (id<HTTPResponse>)make:(id)payload req:(HTTPMessage *)req
{
    NSString *queryString = [[req url] query];
    NSDictionary *queryMap = [self queryMapWithString:queryString];
    NSString *callback = [queryMap objectForKey:@"jsonp"];
    if (callback) {
        return [[HTTPJSONPResponse alloc] initWithJSON:payload callback:callback];
    } else {
        if ([payload isKindOfClass:[NSData class]]) {
            return [[HTTPDataResponse alloc] initWithData:payload];
        } else if ([payload isKindOfClass:[NSDictionary class]] || [payload isKindOfClass:[NSArray class]]){
            return [[HTTPJSONResponse alloc] initWithJSON:payload];
        } else {
            NSAssert(NO, @"can't make HTTPResponse!");
            return nil;
        }
    }
}

@end
