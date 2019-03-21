//
//  InterfactionLogger.h
//  UnityCrashFinder
//
//  Created by Yuri Boyka on 2019/3/20.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 日志文件名在这里 统一 标记，作为全局的名称

 */
#define LogName @"LAAvatarLog"

/**
 只需要引入 宏 传递相应的参数

 @param logString 需要记录的日志内容
 @param fileName 日志文件名
 */
#define WLog(logMessage, fileName) \
    [[InteractionLogger shareInteractionLogger] writeLog:logMessage withfileName:fileName]

/**
 精简日志

 @param logMessage 日志内容
 @param fileName 日志文件名
 */
#define WSLog(logMessage, fileName) \
    [[InteractionLogger shareInteractionLogger] writeLog:logMessage withfileName:fileName detail:NO]

/**
 获取日志文件路径

 @param fileName 日志文件名
 @return 返回日志路径
 */
#define LogPath(fileName) [[InteractionLogger shareInteractionLogger] getPathWithFileName:fileName]

@interface InteractionLogger : NSObject

+ (InteractionLogger *)shareInteractionLogger;

/**
 获取日志文件路径

 @param fileName 日志文件
 @return 返回值
 */
- (NSURL *)getPathWithFileName:(NSString *)fileName;

/**
 写日志

 @param logString 日志内容
 @param fileName 日志文件
 */
- (void)writeLog:(NSString *)logString withfileName:(NSString *)fileName;

/**
 写日志

 @param logString 日志内容
 @param fileName 日志文件
 @param detail 是否详细
 */
- (void)writeLog:(NSString *)logString withfileName:(NSString *)fileName detail:(BOOL)detail;

/**
 发送 和 分享日志文件，便于查阅

 @param fileName 文件名
 */
- (void)sendLogFile:(NSString *)fileName;

@end
