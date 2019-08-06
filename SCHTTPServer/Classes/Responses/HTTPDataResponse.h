#import "HTTPResponse.h"

@interface HTTPDataResponse : NSObject <HTTPResponse>

//default is 200
@property (nonatomic) NSInteger status;
//Content-Type: text/html;charset=UTF-8
@property (nonatomic) NSDictionary *httpHeaders;

- (id)initWithData:(NSData *)data;

@end
