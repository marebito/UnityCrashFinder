//
//  IPUtil.h
//  UnityCrashFinder
//
//  Created by Yuri Boyka on 2019/3/20.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define DEVICE_IP [IPUtil getIPAddress:YES]

@interface IPUtil : NSObject

+ (NSString *)getIPAddress:(BOOL)preferIPv4;

+ (NSDictionary *)getIPAddresses;

@end

NS_ASSUME_NONNULL_END
