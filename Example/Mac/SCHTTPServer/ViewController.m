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
#import <SCHTTPServer/HTTPResponseMaker.h>
#import <SCHTTPServer/HTTPMessage.h>
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
    
    [P12HTTPConnection registerHandler:^id<HTTPResponse>(HTTPMessage *req) {
        NSData *body = [req body];
        NSString *bodyStr = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
        NSLog(@"Post Body:%@",bodyStr);
        return [HTTPResponseMaker make:@{@"post":@(200)} req:req];
    } forPath:@"/test" method:@"POST"];
    //https://localhost.gengtaotjut.com:7981/test?cma=a
    [P12HTTPConnection registerHandler:^id<HTTPResponse>(HTTPMessage *req) {
        return [HTTPResponseMaker make:@{@"get":@(201)} req:req];;
    } forPath:@"/test" method:@"GET"];
    
    NSDate *date = [NSDate date];
    [P12HTTPConnection registerHandler:^id<HTTPResponse>(HTTPMessage *req) {
        int interval = (int)[[NSDate date] timeIntervalSinceDate:date];
        return [HTTPResponseMaker make:@{@"run time":@(interval)} req:req];
    } forPath:@"/" method:@"GET"];
    
    self.httpServer = [[HTTPServer alloc] init];
#warning your PKCS#12 certificate
    NSString *p12Path = [[NSBundle mainBundle] pathForResource:@"localhost.gengtaotjut.com" ofType:@"p12"];
    [P12HTTPConnection pkcsPath:p12Path];
#warning PKCS#12 password
    NSString *pwdPath = [[NSBundle mainBundle] pathForResource:@"pwd" ofType:@"txt"];
    NSString *pwd = [[NSString alloc]initWithContentsOfFile:pwdPath encoding:NSUTF8StringEncoding error:nil];
    [P12HTTPConnection pkcsPassword:pwd];
    
    [self.httpServer setConnectionClass:[P12HTTPConnection class]];
//    [self.httpServer setConnectionClass:[TestHTTPConnection class]];
    
    [self.httpServer setPort:7777];
    NSError *error = nil;
    if([self.httpServer start:&error])
    {
//        NSURL *url = [NSURL URLWithString:@"https://localhost:7777"];
        NSURL *url = [NSURL URLWithString:@"https://localhost.gengtaotjut.com:7777"];
        
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
