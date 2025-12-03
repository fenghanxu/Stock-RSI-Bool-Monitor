//
//  MyTimer.h
//  Frame
//
//  Created by 冯汉栩 on 2025/12/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MyTimer : NSObject
/// 创建 1 秒执行一次的定时器
+ (MyTimer *)scheduledTimerWithBlock:(void(^)(void))block;

/// 开始
- (void)start;

/// 暂停
- (void)pause;

/// 停止并销毁
- (void)invalidate;
@end

NS_ASSUME_NONNULL_END
