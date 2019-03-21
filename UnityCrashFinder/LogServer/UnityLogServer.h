//
//  UnityLogServer.h
//  UnityCrashFinder
//
//  Created by Yuri Boyka on 2019/3/20.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define kUnityWebServerPort 8080  // Unity日志服务器默认端口

@interface UnityLogServer : NSObject

@property(nonatomic, assign, readonly) NSUInteger serverPort;

@property(nonatomic, copy, readonly) NSString *serverAddr;

/**
 单例

 @return 返回日志服务器单例
 */
+ (instancetype)sharedInstance;

/**
 开启服务器
 */
- (void)startServer;

/**
 开启指定端口服务器

 @param port 端口
 */
- (void)startServerWithPort:(NSUInteger)port;

/**
 停止服务器
 */
- (void)stopServer;
@end

NS_ASSUME_NONNULL_END
