//
//  ViewController.m
//  SCHTTPServer
//
//  Created by Matt Reach on 2019/7/26.
//

#import "ViewController.h"
#import <SCHTTPServer/HTTPServer.h>
#import <SCHTTPServer/P12HTTPConnection.h>
#import <SCHTTPServer/HTTPLogger.h>

#import <WebKit/WebKit.h>
#import "TestHTTPConnection.h"

@interface ViewController ()

@property (strong) HTTPServer *httpServer;
@property (weak) IBOutlet WKWebView *wkWebView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    // Initalize our http server
    
    [[HTTPLogger sharedLogger] receiveLog:^(HTTP_LOG_Level level, NSString *log) {
       NSLog(@"%d %@",level,log);
    }];
    [[HTTPLogger sharedLogger] setLevel:HTTP_LOG_LEVEL_VERBOSE];
    [[HTTPLogger sharedLogger] setTraceOn:YES];
    
    self.httpServer = [[HTTPServer alloc] init];
#warning your PKCS#12 certificate
    NSString *p12Path = [[NSBundle mainBundle] pathForResource:@"localhost.gengtaotjut.com" ofType:@"p12"];
    [P12HTTPConnection pkcsPath:p12Path];
#warning PKCS#12 password
    NSString *pwdPath = [[NSBundle mainBundle] pathForResource:@"pwd" ofType:@"txt"];
    NSString *pwd = [[NSString alloc]initWithContentsOfFile:pwdPath encoding:NSUTF8StringEncoding error:nil];
    [P12HTTPConnection pkcsPassword:pwd];
    [P12HTTPConnection pkcsDesc:@"localhost.gengtaotjut.com"];
    
    [self.httpServer setConnectionClass:[P12HTTPConnection class]];
//    [self.httpServer setConnectionClass:[TestHTTPConnection class]];
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
    
    [self.httpServer setDocumentRoot:docRoot];
    [self.httpServer setPort:7981];
    NSError *error = nil;
    if([self.httpServer start:&error])
    {
//        NSURL *url = [NSURL URLWithString:@"https://localhost:7981"];
        NSURL *url = [NSURL URLWithString:@"https://localhost.gengtaotjut.com:7981"];
        
        NSURLRequest *req = [NSURLRequest requestWithURL:url];
        [self.wkWebView loadRequest:req];
    } else {
        NSLog(@"Error starting HTTP Server: %@", error);
    }
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
