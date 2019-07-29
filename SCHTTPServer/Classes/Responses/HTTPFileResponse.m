#import "HTTPFileResponse.h"
#import "HTTPConnection.h"
#import "HTTPLogging.h"

#import <unistd.h>
#import <fcntl.h>

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#define NULL_FD  -1


@implementation HTTPFileResponse

- (id)initWithFilePath:(NSString *)fpath forConnection:(HTTPConnection *)parent
{
	if((self = [super init]))
	{
		HTTPLogTrace();
		
		connection = parent; // Parents retain children, children do NOT retain parents
		
		fileFD = NULL_FD;
		filePath = [[fpath copy] stringByResolvingSymlinksInPath];
		if (filePath == nil)
		{
            HTTPLogWarn(@"%s: Init failed - Nil filePath", __FILE__);
			
			return nil;
		}
		
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
		if (fileAttributes == nil)
		{
            HTTPLogWarn(@"%s: Init failed - Unable to get file attributes. filePath: %@", __FILE__, filePath);
			
			return nil;
		}
		
		fileLength = (UInt64)[[fileAttributes objectForKey:NSFileSize] unsignedLongLongValue];
		fileOffset = 0;
		
		aborted = NO;
		
		// We don't bother opening the file here.
		// If this is a HEAD request we only need to know the fileLength.
	}
	return self;
}

- (void)abort
{
	HTTPLogTrace();
	
	[connection responseDidAbort:self];
	aborted = YES;
}

- (BOOL)openFile
{
	HTTPLogTrace();
	
	fileFD = open([filePath UTF8String], O_RDONLY);
	if (fileFD == NULL_FD)
	{
        HTTPLogError(@"%s[%p]: Unable to open file. filePath: %@", __FILE__, self, filePath);
		
		[self abort];
		return NO;
	}
	
    HTTPLogVerbose(@"%s[%p]: Open fd[%i] -> %@", __FILE__, self, fileFD, filePath);
	
	return YES;
}

- (BOOL)openFileIfNeeded
{
	if (aborted)
	{
		// The file operation has been aborted.
		// This could be because we failed to open the file,
		// or the reading process failed.
		return NO;
	}
	
	if (fileFD != NULL_FD)
	{
		// File has already been opened.
		return YES;
	}
	
	return [self openFile];
}

- (UInt64)contentLength
{
	HTTPLogTrace();
	
	return fileLength;
}

- (UInt64)offset
{
	HTTPLogTrace();
	
	return fileOffset;
}

- (void)setOffset:(UInt64)offset
{
    HTTPLogTrace2(@"%s[%p]: setOffset:%llu", __FILE__, self, offset);
	
	if (![self openFileIfNeeded])
	{
		// File opening failed,
		// or response has been aborted due to another error.
		return;
	}
	
	fileOffset = offset;
	
	off_t result = lseek(fileFD, (off_t)offset, SEEK_SET);
	if (result == -1)
	{
        HTTPLogError(@"%s[%p]: lseek failed - errno(%i) filePath(%@)", __FILE__, self, errno, filePath);
		
		[self abort];
	}
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
	HTTPLogTrace2(@"%s[%p]: readDataOfLength:%lu", __FILE__, self, (unsigned long)length);
	
	if (![self openFileIfNeeded])
	{
		// File opening failed,
		// or response has been aborted due to another error.
		return nil;
	}
	
	// Determine how much data we should read.
	// 
	// It is OK if we ask to read more bytes than exist in the file.
	// It is NOT OK to over-allocate the buffer.
	
	UInt64 bytesLeftInFile = fileLength - fileOffset;
	
	NSUInteger bytesToRead = (NSUInteger)MIN(length, bytesLeftInFile);
	
	// Make sure buffer is big enough for read request.
	// Do not over-allocate.
	
	if (buffer == NULL || bufferSize < bytesToRead)
	{
		bufferSize = bytesToRead;
		buffer = reallocf(buffer, (size_t)bufferSize);
		
		if (buffer == NULL)
		{
            HTTPLogError(@"%s[%p]: Unable to allocate buffer", __FILE__, self);
			
			[self abort];
			return nil;
		}
	}
	
	// Perform the read
	
	HTTPLogVerbose(@"%s[%p]: Attempting to read %lu bytes from file", __FILE__, self, (unsigned long)bytesToRead);
	
	ssize_t result = read(fileFD, buffer, bytesToRead);
	
	// Check the results
	
	if (result < 0)
	{
		HTTPLogError(@"%s: Error(%i) reading file(%@)", __FILE__, errno, filePath);
		
		[self abort];
		return nil;
	}
	else if (result == 0)
	{
		HTTPLogError(@"%s: Read EOF on file(%@)", __FILE__, filePath);
		
		[self abort];
		return nil;
	}
	else // (result > 0)
	{
		HTTPLogVerbose(@"%s[%p]: Read %ld bytes from file", __FILE__, self, (long)result);
		
		fileOffset += result;
		
		return [NSData dataWithBytes:buffer length:result];
	}
}

- (BOOL)isDone
{
	BOOL result = (fileOffset == fileLength);
	
    HTTPLogTrace2(@"%s[%p]: isDone - %@", __FILE__, self, (result ? @"YES" : @"NO"));
	
	return result;
}

- (NSString *)filePath
{
	return filePath;
}

- (void)dealloc
{
	HTTPLogTrace();
	
	if (fileFD != NULL_FD)
	{
        HTTPLogVerbose(@"%s[%p]: Close fd[%i]", __FILE__, self, fileFD);
		
		close(fileFD);
	}
	
	if (buffer)
		free(buffer);
	
}

@end
