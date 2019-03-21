//
//  SystemLogManager.h
//  UnityCrashFinder
//
//  Created by Yuri Boyka on 2019/3/20.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <asl.h>
#import "SystemLogMessage.h"
@interface SystemLogManager : NSObject

/**
 *  利用ASL提供的接口获取日志
 *
 *  @param time 指定的时间
 *
 *  @return 获取到的日志
 */
+ (NSArray<SystemLogMessage *> *)allLogAfterTime:(CFAbsoluteTime) time;


@end
