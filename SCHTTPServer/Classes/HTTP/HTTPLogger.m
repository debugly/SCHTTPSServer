#import "HTTPLogger.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

@implementation HTTPLogger
{
    HTTPLogggerReceiver logReveiver;
}

+ (instancetype)sharedLogger
{
    static id logger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[self alloc] init];
    });
    return logger;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.level = HTTP_LOG_LEVEL_ERROR;
        self.traceOn = NO;
    }
    return self;
}

- (void)writeLog:(int)level file:(const char*)sourceFile function:(const char*)functionName lineNumber:(int)lineNumber format:(NSString*)format,...
{
    if (level == HTTP_LOG_LEVEL_TRACE) {
        if (!self.traceOn) {
            return;
        }
    } else {
        if (level > self.level) {
            return;
        }
    }
    
    va_list ap;
    va_start(ap,format);
    NSString *print = [[NSString alloc] initWithFormat: format arguments: ap];
    va_end(ap);
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM-dd HH:mm:ss"];
    NSString *dateString = [formatter stringFromDate:date];
    
    NSString *fileName = [[NSString stringWithUTF8String:sourceFile] lastPathComponent];
    NSString *msg = [NSString stringWithFormat:@"[%@] [%@ %s] %@", dateString, fileName, functionName, print];
    if (![msg hasSuffix:@"\n"]) {
        msg = [msg stringByAppendingString:@"\n"];
    }
    [self writeLog:level log:msg];
}

- (void)writeLog:(HTTP_LOG_Level)level log:(NSString*)log
{
    if (logReveiver) {
        logReveiver(level,log);
    }
}

- (void)receiveLog:(HTTPLogggerReceiver)reveiver
{
    logReveiver = reveiver;
}

@end
