//
//  BusinessModel.m
//  Frame
//
//  Created by imac on 2025/12/4.
//

#import "BusinessModel.h"

@implementation BusinessModel

- (NSString *)buySel {
    if (_buySel == nil) {
        _buySel = [NSString new];
    }
    return _buySel;
}

- (NSString *)buySelTime {
    if (_buySelTime == nil) {
        _buySelTime = [NSString new];
    }
    return _buySelTime;
}

- (NSString *)buySellPrice {
    if (_buySellPrice == nil) {
        _buySellPrice = [NSString new];
    }
    return _buySellPrice;
}

- (NSString *)longShort {
    if (_longShort == nil) {
        _longShort = [NSString new];
    }
    return  _longShort;
}



// 自定义初始化方法
- (instancetype)initWithBuySel:(NSString *)buySel
                     buySelTime:(NSString *)buySelTime
                   buySellPrice:(NSString *)buySellPrice
                       longShort:(NSString *)longShort
                     profitLoss:(float)profitLoss {
    self = [super init];
    if (self) {
        _buySel = [buySel copy];
        _buySelTime = [buySelTime copy];
        _buySellPrice = [buySellPrice copy];
        _longShort = [longShort copy];
        _profitLoss = profitLoss;
    }
    return self;
}

@end
