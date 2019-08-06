#import "HTTPDataResponse.h"
#import "HTTPLogger.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

@implementation HTTPDataResponse
{
    NSUInteger offset;
    NSData *data;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithCapacity:3];
        [headers setObject:@"text/html;charset=UTF-8" forKey:@"Content-Type"];
        [headers setObject:@"SCHTTPServer" forKey:@"Server"];
        self.httpHeaders = [headers copy];
    }
    return self;
}

- (id)initWithData:(NSData *)dataParam
{
	if((self = [self init]))
	{
		HTTPLogTrace();
		offset = 0;
		data = dataParam;
        self.status = 200;
	}
	return self;
}

- (void)dealloc
{
	HTTPLogTrace();
}

- (UInt64)contentLength
{
	UInt64 result = (UInt64)[data length];

    HTTPLogTrace2(@"[%p]: contentLength - %llu", self, result);
	
	return result;
}

- (UInt64)offset
{
	HTTPLogTrace();
	
	return offset;
}

- (void)setOffset:(UInt64)offsetParam
{
    HTTPLogTrace2(@"[%p]: setOffset:%lu", self, (unsigned long)offset);
	
	offset = (NSUInteger)offsetParam;
}

- (NSData *)readDataOfLength:(NSUInteger)lengthParameter
{
    HTTPLogTrace2(@"[%p]: readDataOfLength:%lu", self, (unsigned long)lengthParameter);
	
	NSUInteger remaining = [data length] - offset;
	NSUInteger length = lengthParameter < remaining ? lengthParameter : remaining;
	
	void *bytes = (void *)([data bytes] + offset);
	
	offset += length;
	
	return [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:NO];
}

- (BOOL)isDone
{
	BOOL result = (offset == [data length]);
	
    HTTPLogTrace2(@"[%p]: isDone - %@", self, (result ? @"YES" : @"NO"));
	
	return result;
}

@end
