//
//  UnityCrashFinder.m
//  UnityCrashFinder
//
//  Created by Yuri Boyka on 2019/3/20.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import "UnityLogServer.h"
#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import "InteractionLogger.h"
#ifdef UNITY_VERSION
#import "UnityAppController.h"

@interface UnityCrashFinder : UnityAppController
#else
@interface UnityCrashFinder : NSObject
#endif
@end

#ifdef __cplusplus
extern "C" {
#endif
int __StartUnityCrashFinderEngine(int port);
int __CSharpCrash(const char *crashLog, const char *stackTrace);
#ifdef __cplusplus
}
#endif

#ifdef UNITY_VERSION
IMPL_APP_CONTROLLER_SUBCLASS(UnityCrashFinder)
#endif

@implementation UnityCrashFinder
void UncaughtExceptionHandler(NSException *exception)
{
    NSString *name = [exception name];
    NSString *reason = [exception reason];
    NSArray *stackSymbols = [exception callStackSymbols];
    NSMutableString *iosCrashStackInfo = [NSMutableString new];
    [iosCrashStackInfo appendFormat:@"[iOS崩溃]: %@\n[名   称]: %@\n[堆栈信息]:\n%@\n", name, reason, stackSymbols];
    printf("%s", [iosCrashStackInfo cStringUsingEncoding:NSUTF8StringEncoding]);
}
#ifdef UNITY_VERSION

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [super application:application didFinishLaunchingWithOptions:launchOptions];
    NSString *logFilePath = [[LogPath(LogName) filePathURL].absoluteString substringFromIndex:7];
    if ([[NSFileManager defaultManager] fileExistsAtPath:logFilePath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:nil];
    }
    NSSetUncaughtExceptionHandler(&UncaughtExceptionHandler);
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    printf("[正在启动Unity日志服务器, 请稍后...]");
    [UnityCrashFinder start:kUnityWebServerPort];
    return YES;
}
#endif

+ (void)start:(NSUInteger)port { [[UnityLogServer sharedInstance] startServerWithPort:port]; }
@end

#ifdef __cplusplus
extern "C" {
#endif
int __CSharpWriteLog(const char *logMessage, const char *stackTrace, int type)
{
    NSString *logContent = [NSString stringWithCString:logMessage encoding:NSUTF8StringEncoding];
    if (type == 2 || type == 3)
    {
        WLog(logContent, LogName);
    }
    else
    {
        NSString *crashDetail = [NSString
                                 stringWithFormat:@"<span><b>&#9888[C#异常]：</span><div><font color=\"red\"></b><i>%@</i></font></div>",
                                 logContent];
        NSString *stackInfo = [[NSString stringWithFormat:@"<div><font color=\"red\">%s</font></div>", stackTrace]
                               stringByReplacingOccurrencesOfString:@"\n"
                               withString:@"<br>"];
        if (type == 4)
        {
            WLog(logContent, LogName);
            WSLog(stackInfo, LogName);
        }
        else
        {
            WSLog(@"<font color=\"aqua\">==========================================================</font>", LogName);
            WSLog(crashDetail, LogName);
            WSLog(@"<span><b>&#9888[C#堆栈]：</b></span>", LogName);
            WSLog(stackInfo, LogName);
            WSLog(@"<font color=\"aqua\">==========================================================</font>", LogName);
        }
   
    }
    return 0;
}
#ifdef __cplusplus
}

#endif
