//
//  ViewController.m
//  SCHTTPServer
//
//  Created by Matt Reach on 2019/7/26.
//

#import "ViewController.h"
#import <SCHTTPServer/HTTPServer.h>
#import <SCHTTPServer/P12HTTPConnection.h>

@implementation ViewController
{
    HTTPServer *httpServer;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    // Initalize our http server
    httpServer = [[HTTPServer alloc] init];
#warning your PKCS#12 certificate
    NSString *p12Path = [[NSBundle mainBundle] pathForResource:@"localhost.gengtaotjut.com" ofType:@"p12"];
    [P12HTTPConnection pkcsPath:p12Path];
#warning PKCS#12 password
    [P12HTTPConnection pkcsPassword:@"123456"];
    
    [httpServer setConnectionClass:[P12HTTPConnection class]];
    // Serve files from the standard Sites folder
    NSString *docRoot = [@"~/Sites" stringByExpandingTildeInPath];
    NSLog(@"Setting document root: %@", docRoot);
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:docRoot isDirectory:&isDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:docRoot withIntermediateDirectories:YES attributes:nil error:NULL];
        NSString *fromPath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
        NSString *toPath = [docRoot stringByAppendingPathComponent:@"index.html"];
        [[NSFileManager defaultManager] copyItemAtPath:fromPath toPath:toPath error:NULL];
    }
    
    [httpServer setDocumentRoot:docRoot];
    [httpServer setPort:7981];
    NSError *error = nil;
    if(![httpServer start:&error])
    {
        NSLog(@"Error starting HTTP Server: %@", error);
    }
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
