//
//  OutputInputStream.h
//  UnityCrashFinder
//
//  Created by Yuri Boyka on 2019/3/20.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OutputInputStream : NSObject

+ (OutputInputStream *)shareOutputInputStream;

/**
 读取文件
 
 @param filePath 需要读取文件的地址
 */
- (void)creatInputStreamWithFilePath:(NSString *) filePath;
/**
 创建 写入流
 
 @param filePath 内容写入的文件地址
 */
- (void)creatOutputStreamWithFilePath:(NSString *) filePath;
@end
