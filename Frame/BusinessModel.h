//
//  BusinessModel.h
//  Frame
//
//  Created by imac on 2025/12/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BusinessModel : NSObject
//买还是卖
@property (nonatomic,   copy) NSString *buySel;
//做空还是做多 | 亏损 还是 盈利
@property (nonatomic,   copy) NSString *longShort;
//买卖时间
@property (nonatomic,   copy) NSString *buySelTime;
//买卖价格
@property (nonatomic,   copy) NSString *buySellPrice;

//盈亏
@property (nonatomic, assign) double profitLoss;

- (instancetype)initWithBuySel:(NSString *)buySel
                     buySelTime:(NSString *)buySelTime
                   buySellPrice:(NSString *)buySellPrice
                       longShort:(NSString *)longShort
                    profitLoss:(float)profitLoss;

//买还是卖颜色
@property (nonatomic, strong) UIColor *buySelColor;
//买卖时间颜色
@property (nonatomic, strong) UIColor *buySelTimeColor;
//买卖价格颜色
@property (nonatomic, strong) UIColor *buySellPriceColor;
//做空还是做多颜色
@property (nonatomic, strong) UIColor *longShortColor;

@end

NS_ASSUME_NONNULL_END
