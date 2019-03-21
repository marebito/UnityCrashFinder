//
//  UnityLogServer.m
//  UnityCrashFinder
//
//  Created by Yuri Boyka on 2019/3/20.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import "UnityLogServer.h"
#import "SystemLogMessage.h"
#import "SystemLogManager.h"
#import "InteractionLogger.h"
#import "IPUtil.h"
#import <GCDWebServers/GCDWebServers.h>

#define kMinRefreshDelay 500  // In milliseconds

@interface UnityLogServer ()
@property(nonatomic, strong) GCDWebServer *webServer;
@property(nonatomic, assign) NSUInteger serverPort;
@property(nonatomic, copy) NSString *serverAddr;
@end

@implementation UnityLogServer

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static UnityLogServer *shared;
    dispatch_once(&onceToken, ^{
        shared = [UnityLogServer new];
    });
    return shared;
}

- (NSUInteger)serverPort
{
    if (_serverPort == 0)
    {
        _serverPort = kUnityWebServerPort;
    }
    return _serverPort;
}

- (GCDWebServer *)webServer
{
    if (!_webServer)
    {
        _webServer = [[GCDWebServer alloc] init];
        __weak __typeof__(self) weakSelf = self;
        // Add a handler to respond to GET requests on any URL
        [_webServer addDefaultHandlerForMethod:@"GET"
                                  requestClass:[GCDWebServerRequest class]
                                  processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                      return [weakSelf loadUnityLogResponseBody:request];
                                  }];
    }
    return _webServer;
}

- (void)startServer
{
    // Use convenience method that runs server on port 8080
    // until SIGINT (Ctrl-C in Terminal) or SIGTERM is received
    [self startServerWithPort:self.serverPort];
}

- (void)startServerWithPort:(NSUInteger)port
{
    self.serverPort = port;
    [self.webServer startWithPort:port bonjourName:nil];
    self.serverAddr = _webServer.serverURL.absoluteString;
    printf("[Unity日志服务器启动完毕]: %s",
           [_webServer.serverURL.absoluteString cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)stopServer
{
    [_webServer stop];
    _webServer = nil;
}

- (GCDWebServerDataResponse *)createResponseBody:(GCDWebServerRequest *)request
{
    GCDWebServerDataResponse *response = nil;

    NSString *path = request.path;
    NSDictionary *query = request.query;
    // NSLog(@"path = %@,query = %@",path,query);
    NSMutableString *string;
    if ([path isEqualToString:@"/"])
    {
        string = [[NSMutableString alloc] init];
        [string appendString:@"<!DOCTYPE html><html lang=\"en\">"];
        [string appendString:@"<head><meta charset=\"utf-8\"></head>"];
        [string appendFormat:@"<title>%s[%i]</title>", getprogname(), getpid()];
        [string appendString:@"<style>\
         body {\n\
         margin: 0px;\n\
         font-family: Courier, monospace;\n\
         font-size: 0.8em;\n\
         }\n\
         table {\n\
         width: 100%;\n\
         border-collapse: collapse;\n\
         }\n\
         tr {\n\
         vertical-align: top;\n\
         }\n\
         tr:nth-child(odd) {\n\
         background-color: #eeeeee;\n\
         }\n\
         td {\n\
         padding: 2px 10px;\n\
         }\n\
         #footer {\n\
         text-align: center;\n\
         margin: 20px 0px;\n\
         color: darkgray;\n\
         }\n\
         .error {\n\
         color: red;\n\
         font-weight: bold;\n\
         }\n\
         </style>"];
        [string appendFormat:@"<script type=\"text/javascript\">\n\
         var refreshDelay = %i;\n\
         var footerElement = null;\n\
         function updateTimestamp() {\n\
         var now = new Date();\n\
         footerElement.innerHTML = \"Last updated on \" + now.toLocaleDateString() + \" \" + now.toLocaleTimeString();\n\
         }\n\
         function refresh() {\n\
         var timeElement = document.getElementById(\"maxTime\");\n\
         var maxTime = timeElement.getAttribute(\"data-value\");\n\
         timeElement.parentNode.removeChild(timeElement);\n\
         \n\
         var xmlhttp = new XMLHttpRequest();\n\
         xmlhttp.onreadystatechange = function() {\n\
         if (xmlhttp.readyState == 4) {\n\
         if (xmlhttp.status == 200) {\n\
         var contentElement = document.getElementById(\"content\");\n\
         contentElement.innerHTML = contentElement.innerHTML + xmlhttp.responseText;\n\
         updateTimestamp();\n\
         setTimeout(refresh, refreshDelay);\n\
         } else {\n\
         footerElement.innerHTML = \"<span class=\\\"error\\\">Connection failed! Reload page to try again.</span>\";\n\
         }\n\
         }\n\
         }\n\
         xmlhttp.open(\"GET\", \"/log?after=\" + maxTime, true);\n\
         xmlhttp.send();\n\
         }\n\
         window.onload = function() {\n\
         footerElement = document.getElementById(\"footer\");\n\
         updateTimestamp();\n\
         setTimeout(refresh, refreshDelay);\n\
         }\n\
         </script>",
                             kMinRefreshDelay];
        [string appendString:@"</head>"];
        [string appendString:@"<body>"];
        [string appendString:@"<table><tbody id=\"content\">"];
        [self _appendLogRecordsToString:string afterAbsoluteTime:0.0];

        [string appendString:@"</tbody></table>"];
        [string appendString:@"<div id=\"footer\"></div>"];
        [string appendString:@"</body>"];
        [string appendString:@"</html>"];
    }
    else if ([path isEqualToString:@"/log"] && query[@"after"])
    {
        string = [[NSMutableString alloc] init];
        double time = [query[@"after"] doubleValue];
        [self _appendLogRecordsToString:string afterAbsoluteTime:time];
    }
    else
    {
        string = [@" <html><body><p>无数据</p></body></html>" mutableCopy];
    }
    if (string == nil)
    {
        string = [@"" mutableCopy];
    }
    response = [GCDWebServerDataResponse responseWithHTML:string];
    return response;
}

- (void)_appendLogRecordsToString:(NSMutableString *)string afterAbsoluteTime:(double)time
{
    __block double maxTime = time;
    NSArray<SystemLogMessage *> *allMsg = [SystemLogManager allLogAfterTime:time];
    [allMsg enumerateObjectsUsingBlock:^(SystemLogMessage *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        const char *style = "color: dimgray;";
        NSString *formattedMessage = [self displayedTextForLogMessage:obj];
        [string appendFormat:@"<tr style=\"%s\">%@</tr>", style, formattedMessage];
        if (obj.timeInterval > maxTime)
        {
            maxTime = obj.timeInterval;
        }
    }];
    [string appendFormat:@"<tr id=\"maxTime\" data-value=\"%f\"></tr>", maxTime];
}

- (NSString *)displayedTextForLogMessage:(SystemLogMessage *)msg
{
    NSMutableString *string = [[NSMutableString alloc] init];
    [string appendFormat:@"<td>%@</td> <td>%@</td> <td>%@</td>", [SystemLogMessage logTimeStringFromDate:msg.date],
                         msg.sender, msg.messageText];
    return string;
}

- (GCDWebServerDataResponse *)loadUnityLogResponseBody:(GCDWebServerRequest *)request
{
    GCDWebServerDataResponse *response = nil;
    NSString *path = request.path;
    //    NSDictionary *query = request.query;
    // NSLog(@"path = %@,query = %@",path,query);
    NSMutableString *string;
    if ([path isEqualToString:@"/"])
    {
        string = [[NSMutableString alloc] init];
        [string appendString:@"<!DOCTYPE html><html lang=\"en\">"];
        [string appendString:@"<head><meta charset=\"utf-8\"></head>"];
        [string appendFormat:@"<title>%s[%i]</title>", getprogname(), getpid()];
        [string appendString:@"<style>\
         body {\n\
         margin: 0px;\n\
         font-family: Courier, monospace;\n\
         font-size: 0.8em;\n\
         }\n\
         table {\n\
         width: 100%;\n\
         border-collapse: collapse;\n\
         }\n\
         tr {\n\
         vertical-align: top;\n\
         }\n\
         tr:nth-child(odd) {\n\
         background-color: #eeeeee;\n\
         }\n\
         td {\n\
         padding: 2px 10px;\n\
         }\n\
         #footer {\n\
         text-align: center;\n\
         margin: 20px 0px;\n\
         color: darkgray;\n\
         }\n\
         .error {\n\
         color: red;\n\
         font-weight: bold;\n\
         }\n\
         </style>"];
        [string appendFormat:@"<script type=\"text/javascript\">\n\
         var refreshDelay = %i;\n\
         var footerElement = null;\n\
         function updateTimestamp() {\n\
         var now = new Date();\n\
         footerElement.innerHTML = \"Last updated on \" + now.toLocaleDateString() + \" \" + now.toLocaleTimeString();\n\
         }\n\
         function refresh() {\n\
         var timeElement = document.getElementById(\"maxTime\");\n\
         var maxTime = timeElement.getAttribute(\"data-value\");\n\
         timeElement.parentNode.removeChild(timeElement);\n\
         \n\
         var xmlhttp = new XMLHttpRequest();\n\
         xmlhttp.onreadystatechange = function() {\n\
         if (xmlhttp.readyState == 4) {\n\
         if (xmlhttp.status == 200) {\n\
         var contentElement = document.getElementById(\"content\");\n\
         contentElement.innerHTML = contentElement.innerHTML + xmlhttp.responseText;\n\
         updateTimestamp();\n\
         setTimeout(refresh, refreshDelay);\n\
         } else {\n\
         footerElement.innerHTML = \"<span class=\\\"error\\\">Connection failed! Reload page to try again.</span>\";\n\
         }\n\
         }\n\
         }\n\
         xmlhttp.open(\"GET\", \"http://localhost:8080\", true);\n\
         xmlhttp.send();\n\
         }\n\
         window.onload = function() {\n\
         footerElement = document.getElementById(\"footer\");\n\
         updateTimestamp();\n\
         setTimeout(refresh, refreshDelay);\n\
         }\n\
         </script>",
                             kMinRefreshDelay];
        [string appendString:@"</head>"];
        [string appendString:@"<body>"];
        [string appendString:@"<div id=\"content\">"];
        [self refreshLogPage:string];
        [string appendString:@"</div>"];
        [string appendString:@"<div id=\"footer\"></div>"];
        [string appendString:@"</body>"];
        [string appendString:@"</html>"];
    }
    if (string == nil)
    {
        string = [@"" mutableCopy];
    }
    response = [GCDWebServerDataResponse responseWithHTML:string];
    return response;
}

- (void)refreshLogPage:(NSMutableString *)content
{
    [content appendFormat:@"%@",
                          [NSString stringWithContentsOfURL:LogPath(LogName) encoding:NSUTF8StringEncoding error:nil]];
}

@end
