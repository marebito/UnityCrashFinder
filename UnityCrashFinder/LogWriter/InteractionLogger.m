//
//  InterfactionLogger.m
//  UnityCrashFinder
//
//  Created by Yuri Boyka on 2019/3/20.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import "InteractionLogger.h"
#import <UIKit/UIKit.h>
#import "UnityLogServer.h"

@interface InteractionLogger ()<NSStreamDelegate, UIDocumentInteractionControllerDelegate>
{
    dispatch_queue_t inputStreamQueue;  // 输入流队列
}
@property(nonatomic, strong) NSOutputStream *writeLogStream;                          // 写入日志流
@property(nonatomic, strong) UIDocumentInteractionController *interactionController;  // 文档交互控制器
@property(nonatomic, assign) BOOL exceptionFlag;                                      // 异常标识
@property(nonatomic, assign) BOOL exceptionStackFlag;                                 // 异常堆栈标识

@end

@implementation InteractionLogger

static InteractionLogger *interactionLogger = nil;

+ (InteractionLogger *)shareInteractionLogger
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        interactionLogger = [[InteractionLogger alloc] init];
    });
    return interactionLogger;
}

- (instancetype)init
{
    if (interactionLogger) return interactionLogger;
    if (self = [super init])
    {
        inputStreamQueue = dispatch_queue_create("com.godlike.iStreamQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)writeLog:(NSString *)logString withfileName:(NSString *)fileName detail:(BOOL)detail
{
    dispatch_async(inputStreamQueue, ^{
        if (self.exceptionFlag && self.exceptionStackFlag) return;
        if (self.writeLogStream == nil)
        {
            self.writeLogStream = [self creatStreamWithFileName:fileName];
        }
        BOOL isCrash = detail && ([logString rangeOfString:@"Exception"].location != NSNotFound ||
                                  [logString rangeOfString:@"Crash"].location != NSNotFound ||
                                  [logString rangeOfString:@"Assert"].location != NSNotFound);
        NSString *logMessage = logString;
        if (isCrash)
        {
            logMessage = [NSString stringWithFormat:@"&#9889<font color=\"red\"><b><i>%@</i></b></font>", logString];
        }
        NSData *data = [self getDataWithLogString:logMessage detail:detail];
        [self.writeLogStream write:[data bytes] maxLength:data.length];
        [self.writeLogStream close];
        [self.writeLogStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.writeLogStream = nil;
        if (isCrash)
        {
            if (self.exceptionFlag)
            {
                self.exceptionStackFlag = YES;
            }
            else
            {
                self.exceptionFlag = YES;
                NSString *exceptionDesc = [self descriptionForException:logString];
                if (!exceptionDesc)
                {
                    exceptionDesc = @"未知错误";
                }

                NSDictionary *infoPlist = [NSBundle mainBundle].infoDictionary;
                if (infoPlist[@"UIBackgroundModes"])
                {
                    UIAlertController *alertController =
                        [UIAlertController alertControllerWithTitle:@"C#脚本崩溃"
                                                            message:exceptionDesc
                                                     preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *okBtn =
                        [UIAlertAction actionWithTitle:@"查看日志"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *_Nonnull action) {
                                                   [[UIApplication sharedApplication]
                                                       openURL:[NSURL URLWithString:@"http://localhost:8080"]];
                                               }];
                    UIAlertAction *sendBtn = [UIAlertAction actionWithTitle:@"发送日志"
                                                                      style:UIAlertActionStyleDefault
                                                                    handler:^(UIAlertAction *_Nonnull action) {
                                                                        [self sendLogFile:LogName];
                                                                    }];
                    [alertController addAction:okBtn];
                    [alertController addAction:sendBtn];
                    [[UIApplication sharedApplication]
                            .keyWindow.rootViewController presentViewController:alertController
                                                                       animated:YES
                                                                     completion:nil];
                }
                else
                {
                    UIAlertController *alertController =
                        [UIAlertController alertControllerWithTitle:[UnityLogServer sharedInstance].serverAddr
                                                            message:exceptionDesc
                                                     preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *sendBtn = [UIAlertAction actionWithTitle:@"发送日志"
                                                                      style:UIAlertActionStyleDefault
                                                                    handler:^(UIAlertAction *_Nonnull action) {
                                                                        [self sendLogFile:LogName];
                                                                    }];
                    [alertController addAction:sendBtn];
                    [[UIApplication sharedApplication]
                            .keyWindow.rootViewController presentViewController:alertController
                                                                       animated:YES
                                                                     completion:nil];
                }
            }
        }
    });
}

- (void)writeLog:(NSString *)logString withfileName:(NSString *)fileName
{
    [self writeLog:logString withfileName:fileName detail:YES];
}

- (void)sendLogFile:(NSString *)fileName
{
    NSURL *fileurl = [self getPathWithFileName:fileName];

    if (!fileurl)
    {
        NSLog(@"日志文件不存在");
        return;
    }

    // 判断文件是否存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:[fileurl path]];
    if (!isExists)
    {
        return;
    }
    // 获取文件大小
    NSError *error = nil;
    CGFloat fileSize = [[fileManager attributesOfItemAtPath:[fileurl path] error:&error] fileSize] / 1024.0f;
    if (error)
    {
        NSLog(@"获取日志失败");
        return;
    }
    if (fileSize == 0)
    {
        NSLog(@"获取日志失败，文件不存在");
    }
    else
    {
        self.interactionController = [UIDocumentInteractionController interactionControllerWithURL:fileurl];
        self.interactionController.delegate = self;
        UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (vc.presentedViewController)
        {
            vc = vc.presentedViewController;
        }
        if (vc != nil)
        {
            [self.interactionController presentOptionsMenuFromRect:vc.view.bounds inView:vc.view animated:YES];
        }
    }
}

- (NSData *)getDataWithLogString:(NSString *)logString detail:(BOOL)detail
{
    NSString *logContent = [NSString new];
    if (logString.length == 0)
    {
        logContent = @"";
    }
    else
    {
        NSDate *date = [NSDate date];
        NSDateFormatter *forMatter = [[NSDateFormatter alloc] init];
        [forMatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSMutableString *dateStr = [NSMutableString stringWithString:[forMatter stringFromDate:date]];
        if (detail)
        {
            logContent =
                [logContent stringByAppendingFormat:@"<font color=\"blue\">%@</font> %@</br>", dateStr, logString];
        }
        else
        {
            logContent = [logContent stringByAppendingFormat:@"%@</br>", logString];
        }
    }
    NSData *data = [logContent dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}

/**
 创建 流写 实例

 @param fileName 类型名
 */
- (NSOutputStream *)creatStreamWithFileName:(NSString *)fileName
{
    NSURL *url = [self getPathWithFileName:fileName];
    NSOutputStream *outputStream = [[NSOutputStream alloc] initWithURL:url append:YES];
    outputStream.delegate = self;
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [outputStream open];
    return outputStream;
}

/**
 创建文件路径

 @param fileName 文件名称
 @return 路径
 */
- (NSURL *)getPathWithFileName:(NSString *)fileName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    BOOL isDir = TRUE;
    BOOL isDirExists = [fileManager fileExistsAtPath:cacheDir isDirectory:&isDir];

    if (!isDirExists)
    {
        NSError *err = nil;
        BOOL isCreateDirSuccess =
            [fileManager createDirectoryAtPath:cacheDir withIntermediateDirectories:NO attributes:nil error:&err];
        if (!isCreateDirSuccess)
        {
            NSLog(@"创建cache路径失败：%@", err.description);
            return nil;
        }
    }

    NSString *filePath = [[cacheDir stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"txt"];
    BOOL isFileExists = [fileManager fileExistsAtPath:filePath];
    if (isFileExists)
    {
        //存在
        NSError *err = nil;
        float fileSizeKB = [[fileManager attributesOfItemAtPath:filePath error:&err] fileSize] / 1024.0f;
        if (err)
        {
            NSLog(@"获取文件大小失败：%@", err.description);
        }
        if (fileSizeKB > 10240)
        {
            NSError *err = nil;
            BOOL isRmSuccess = [fileManager removeItemAtPath:filePath error:&err];
            if (!isRmSuccess)
            {
                NSLog(@"删除文件失败：%@", err.description);
            }
            BOOL isCreateFileSuccess = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
            if (!isCreateFileSuccess)
            {
                NSLog(@"创建文件失败：%@", err.description);
                return nil;
            }
        }
    }
    else
    {
        //不存在
        NSError *err = nil;
        BOOL isCreateFileSuccess = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
        if (!isCreateFileSuccess)
        {
            NSLog(@"创建文件失败：%@", err.description);
            return nil;
        }
    }
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    if (!fileURL)
    {
        NSLog(@"获取沙盒相对文件URL失败");
        return nil;
    }
    return fileURL;
}

- (NSString *)descriptionForException:(NSString *)exception
{
    NSString *desc = nil;
    if ([exception rangeOfString:@"AccessViolationException"].location != NSNotFound)
    {
        desc = @"试图读写受保护内存";
    }
    if ([exception rangeOfString:@"ArgumentException"].location != NSNotFound)
    {
        desc = @"向方法提供的其中一个参数无效";
    }
    if ([exception rangeOfString:@"KeyNotFoundException"].location != NSNotFound)
    {
        desc = @"指定用于访问集合中元素的键与集合中的任何键都不匹配";
    }
    if ([exception rangeOfString:@"IndexOutOfRangeException"].location != NSNotFound)
    {
        desc = @"访问数组，元素索引超出数组边界";
    }
    if ([exception rangeOfString:@"InvalidCastException"].location != NSNotFound)
    {
        desc = @"无效类型转换或显示转换";
    }
    if ([exception rangeOfString:@"InvalidOperationException"].location != NSNotFound)
    {
        desc = @"方法调用对于对象的当前状态无效";
    }
    if ([exception rangeOfString:@"InvalidProgramException"].location != NSNotFound)
    {
        desc = @"程序包含无效Microsoft中间语言（MSIL）或元数据("
               @"通常表示生成程序的编译器中有bug)";
    }
    if ([exception rangeOfString:@"IOException"].location != NSNotFound)
    {
        desc = @"发生I/O错误";
    }
    if ([exception rangeOfString:@"NotImplementedException"].location != NSNotFound)
    {
        desc = @"无法实现请求的方法或操作";
    }
    if ([exception rangeOfString:@"NullReferenceException"].location != NSNotFound)
    {
        desc = @"尝试对空对象引用进行操作";
    }
    if ([exception rangeOfString:@"OutOfMemoryException"].location != NSNotFound)
    {
        desc = @"没有足够的内存继续执行程序";
    }
    if ([exception rangeOfString:@"StackOverflowException"].location != NSNotFound)
    {
        desc = @"挂起的方法调用过多而导致执行堆栈溢出";
    }
    if ([exception rangeOfString:@"ArgumentNullException"].location != NSNotFound)
    {
        desc = @"将空引用传递给不接受它作为有效参数的方法";
    }
    if ([exception rangeOfString:@"ArgumentOutOfRangeException"].location != NSNotFound)
    {
        desc = @"参数值超出调用的方法所定义的允许取值范围";
    }
    if ([exception rangeOfString:@"DivideByZeroException"].location != NSNotFound)
    {
        desc = @"试图用零除整数值或十进制数值时引发的异常";
    }
    if ([exception rangeOfString:@"NotFiniteNumberException"].location != NSNotFound)
    {
        desc = @"浮点值为正无穷大、负无穷大或非数字（NaN）";
    }
    if ([exception rangeOfString:@"OverflowException"].location != NSNotFound)
    {
        desc = @"选中的上下文中所进行的算数运算、类型转换或转换操作导致溢出";
    }
    if ([exception rangeOfString:@"DirectoryNotFoundException"].location != NSNotFound)
    {
        desc = @"找不到文件或目录的一部分";
    }
    if ([exception rangeOfString:@"DriveNotFoundException"].location != NSNotFound)
    {
        desc = @"尝试访问的驱动器或共享不可用";
    }
    if ([exception rangeOfString:@"EndOfStreamException"].location != NSNotFound)
    {
        desc = @"读操作试图超出流的末尾时引发的异常";
    }
    if ([exception rangeOfString:@"FileLoadException"].location != NSNotFound)
    {
        desc = @"找到托管程序却不能加载它";
    }
    if ([exception rangeOfString:@"FileNotFoundException"].location != NSNotFound)
    {
        desc = @"试图访问磁盘上不存在的文件";
    }
    if ([exception rangeOfString:@"PathTooLongException"].location != NSNotFound)
    {
        desc = @"路径名或文件名超过系统定义的最大长度";
    }
    if ([exception rangeOfString:@"ArrayTypeMismatchException"].location != NSNotFound)
    {
        desc = @"试图在数组中存储错误类型的对象";
    }
    if ([exception rangeOfString:@"BadImageFormatException"].location != NSNotFound)
    {
        desc = @"图形的格式错误";
    }
    if ([exception rangeOfString:@"DivideByZeroException"].location != NSNotFound)
    {
        desc = @"除零异常";
    }
    if ([exception rangeOfString:@"DllNotFoundException"].location != NSNotFound)
    {
        desc = @"找不到引用的dll";
    }
    if ([exception rangeOfString:@"FormatException"].location != NSNotFound)
    {
        desc = @"参数格式错误";
    }
    if ([exception rangeOfString:@"MethodAccessException"].location != NSNotFound)
    {
        desc = @"试图访问私有或者受保护的方法";
    }
    if ([exception rangeOfString:@"MissingMemberException"].location != NSNotFound)
    {
        desc = @"访问一个无效版本的dll";
    }
    if ([exception rangeOfString:@"NotSupportedException"].location != NSNotFound)
    {
        desc = @"调用的方法在类中没有实现";
    }
    if ([exception rangeOfString:@"PlatformNotSupportedException"].location != NSNotFound)
    {
        desc = @"平台不支持某个特定属性";
    }
    return desc;
}

@end
