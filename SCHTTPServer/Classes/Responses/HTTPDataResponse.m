#import "HTTPDataResponse.h"
#import "HTTPLogging.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


@implementation HTTPDataResponse

- (id)initWithData:(NSData *)dataParam
{
	if((self = [super init]))
	{
		HTTPLogTrace();
		
		offset = 0;
		data = dataParam;
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
	
    HTTPLogTrace2(@"%s[%p]: contentLength - %llu", __FILE__, self, result);
	
	return result;
}

- (UInt64)offset
{
	HTTPLogTrace();
	
	return offset;
}

- (void)setOffset:(UInt64)offsetParam
{
    HTTPLogTrace2(@"%s[%p]: setOffset:%lu", __FILE__, self, (unsigned long)offset);
	
	offset = (NSUInteger)offsetParam;
}

- (NSData *)readDataOfLength:(NSUInteger)lengthParameter
{
    HTTPLogTrace2(@"%s[%p]: readDataOfLength:%lu", __FILE__, self, (unsigned long)lengthParameter);
	
	NSUInteger remaining = [data length] - offset;
	NSUInteger length = lengthParameter < remaining ? lengthParameter : remaining;
	
	void *bytes = (void *)([data bytes] + offset);
	
	offset += length;
	
	return [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:NO];
}

- (BOOL)isDone
{
	BOOL result = (offset == [data length]);
	
    HTTPLogTrace2(@"%s[%p]: isDone - %@", __FILE__, self, (result ? @"YES" : @"NO"));
	
	return result;
}

@end