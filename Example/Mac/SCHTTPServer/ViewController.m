//
//  ViewController.m
//  SCHTTPServer
//
//  Created by Matt Reach on 2019/7/26.
//

#import "ViewController.h"
#import <SCHTTPServer/HTTPServer.h>
#import "MyHTTPConnection.h"

@implementation ViewController
{
    HTTPServer *httpServer;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    // Initalize our http server
    httpServer = [[HTTPServer alloc] init];
    [httpServer setConnectionClass:[MyHTTPConnection class]];
    // Serve files from the standard Sites folder
    NSString *docRoot = [@"~/Sites" stringByExpandingTildeInPath];
    NSLog(@"Setting document root: %@", docRoot);
    
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
