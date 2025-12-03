//
//  MyTimer.m
//  Frame
//
//  Created by 冯汉栩 on 2025/12/3.
//

#import "MyTimer.h"

@interface MyTimer ()
@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, copy) void(^taskBlock)(void);
@end

@implementation MyTimer

+ (MyTimer *)scheduledTimerWithBlock:(void(^)(void))block {
    MyTimer *t = [[MyTimer alloc] init];
    t.taskBlock = block;
    [t setupTimer];
    return t;
}

- (void)setupTimer {
    dispatch_queue_t queue = dispatch_get_main_queue();
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);

    // 每 1 秒执行一次
    dispatch_source_set_timer(_timer,
                              DISPATCH_TIME_NOW,
                              1.0 * NSEC_PER_SEC,
                              0.1 * NSEC_PER_SEC);

    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(_timer, ^{
        if (weakSelf.taskBlock) {
            weakSelf.taskBlock();
        }
    });
}

- (void)start {
    if (_timer) {
        dispatch_resume(_timer);
    }
}

- (void)pause {
    if (_timer) {
        dispatch_suspend(_timer);
    }
}

- (void)invalidate {
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
}

@end

