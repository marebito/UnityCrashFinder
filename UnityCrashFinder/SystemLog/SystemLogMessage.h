//
//  SystemLogManager.h
//  UnityCrashFinder
//
//  Created by Yuri Boyka on 2019/3/20.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <asl.h>
@interface SystemLogMessage : NSObject
+ (instancetype)logMessageFromASLMessage:(aslmsg)aslMessage;

@property(nonatomic, strong) NSDate *date;
@property(nonatomic, assign) NSTimeInterval timeInterval;
@property(nonatomic, copy) NSString *sender;
@property(nonatomic, copy) NSString *messageText;
@property(nonatomic, assign) long long messageID;

- (NSString *)displayedTextForLogMessage;
+ (NSString *)logTimeStringFromDate:(NSDate *)date;
@end
