//
//  BusinessModel.m
//  Frame
//
//  Created by imac on 2025/12/4.
//

#import "BusinessModel.h"
#import "UIColor+Hex.h"

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

//买还是卖颜色
- (UIColor *)buySelColor {
    if (_buySelColor == nil) {
        _buySelColor = [self randomColorFromList];
    }
    return _buySelColor;
}

//买卖时间颜色
- (UIColor *)buySelTimeColor {
    if (_buySelTimeColor == nil) {
        _buySelTimeColor = [self randomColorFromList];
    }
    return _buySelTimeColor;
}

//买卖价格颜色
- (UIColor *)buySellPriceColor {
    if (_buySellPriceColor == nil) {
        _buySellPriceColor = [self randomColorFromList];
    }
    return _buySellPriceColor;
}

//做空还是做多颜色
- (UIColor *)longShortColor {
    if (_longShortColor == nil) {
        _longShortColor = [self randomColorFromList];
    }
    return _longShortColor;
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

// 从颜色列表中获取随机颜色的辅助方法
- (UIColor *)randomColorFromList {
    NSArray *colors = @[
        [UIColor colorWithHexString:@"FFB6C1"],
        [UIColor colorWithHexString:@"8B008B"],
        [UIColor colorWithHexString:@"9400D3"],
        [UIColor colorWithHexString:@"6A5ACD"],
        [UIColor colorWithHexString:@"1E90FF"],
        [UIColor colorWithHexString:@"5F9EA0"],
        [UIColor colorWithHexString:@"3CB371"],
        [UIColor colorWithHexString:@"BDB76B"],
        [UIColor colorWithHexString:@"FFD700"],
        [UIColor colorWithHexString:@"DAA520"],
        [UIColor colorWithHexString:@"FFA500"],
        [UIColor colorWithHexString:@"DEB887"],
        [UIColor colorWithHexString:@"CD853F"],
        [UIColor colorWithHexString:@"8B4513"],
        [UIColor colorWithHexString:@"8B0000"],
        [UIColor colorWithHexString:@"F0E68C"],
        [UIColor colorWithHexString:@"FFFACD"],
        [UIColor colorWithHexString:@"DC143C"],
        [UIColor colorWithHexString:@"DB7093"],
        [UIColor colorWithHexString:@"FF69B4"],
        [UIColor colorWithHexString:@"FF1493"],
        [UIColor colorWithHexString:@"C71585"],
        [UIColor colorWithHexString:@"DA70D6"],
        [UIColor colorWithHexString:@"BA55D3"],
        [UIColor colorWithHexString:@"4B0082"],
        [UIColor colorWithHexString:@"8A2BE2"],
        [UIColor colorWithHexString:@"7B68EE"],
        [UIColor colorWithHexString:@"191970"],
        [UIColor colorWithHexString:@"778899"],
        [UIColor colorWithHexString:@"4682B4"],
        [UIColor colorWithHexString:@"00BFFF"],
        [UIColor colorWithHexString:@"AFEEEE"],
        [UIColor colorWithHexString:@"D4F2E7"],
        [UIColor colorWithHexString:@"00CED1"],
        [UIColor colorWithHexString:@"2F4F4F"],
        [UIColor colorWithHexString:@"008B8B"],
        [UIColor colorWithHexString:@"48D1CC"],
        [UIColor colorWithHexString:@"00FA9A"],
        [UIColor colorWithHexString:@"2E8B57"],
        [UIColor colorWithHexString:@"8FBC8F"],
        [UIColor colorWithHexString:@"32CD32"],
        [UIColor colorWithHexString:@"228B22"],
        [UIColor colorWithHexString:@"006400"],
        [UIColor colorWithHexString:@"ADFF2F"],
        [UIColor colorWithHexString:@"556B2F"],
        [UIColor colorWithHexString:@"F5F5DC"],
        [UIColor colorWithHexString:@"808000"],
        [UIColor colorWithHexString:@"EEE8AA"],
        [UIColor colorWithHexString:@"FFE4B5"],
        [UIColor colorWithHexString:@"FAEBD7"],
        [UIColor colorWithHexString:@"D2B48C"],
        [UIColor colorWithHexString:@"FF8C00"],
        [UIColor colorWithHexString:@"F4A460"],
        [UIColor colorWithHexString:@"FFDAB9"],
        [UIColor colorWithHexString:@"FFDAB9"],
        [UIColor colorWithHexString:@"A0522D"],
        [UIColor colorWithHexString:@"FFA07A"],
        [UIColor colorWithHexString:@"FF7F50"],
        [UIColor colorWithHexString:@"E9967A"],
        [UIColor colorWithHexString:@"FF6347"],
        [UIColor colorWithHexString:@"FA8072"],
        [UIColor colorWithHexString:@"F08080"],
        [UIColor colorWithHexString:@"BC8F8F"],
        [UIColor colorWithHexString:@"CD5C5C"],
        [UIColor colorWithHexString:@"A52A2A"],
        [UIColor colorWithHexString:@"B22222"],
        [UIColor colorWithHexString:@"B22222"],
      ];
    if (colors.count > 0) {
        return colors[arc4random_uniform((uint32_t)colors.count)];
    } else {
        return [UIColor blackColor];
    }
}




@end
