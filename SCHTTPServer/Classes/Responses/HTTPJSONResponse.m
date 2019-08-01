//
//  HTTPJSONResponse.m
//  SCHTTPServer
//
//  Created by Matt Reach on 2019/8/1.
//

#import "HTTPJSONResponse.h"
#import "HTTPLogger.h"

@interface HTTPJSONResponse ()

@property (nonatomic) NSInteger status;

@end

@implementation HTTPJSONResponse

- (instancetype)initWithJSON:(id)json status:(int)status
{
    self.status = status;
    NSError *error = nil;
    id data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        HTTPLogError(@"Can't serial json to data:%@",json);
    }
    return [self initWithData:data];;
}

@end
