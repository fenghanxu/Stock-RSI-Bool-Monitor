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
//买卖时间
@property (nonatomic,   copy) NSString *buySelTime;
//买卖价格
@property (nonatomic,   copy) NSString *buySellPrice;
//做空还是做多
@property (nonatomic,   copy) NSString *longShort;
//盈亏
@property (nonatomic, assign) float profitLoss;

- (instancetype)initWithBuySel:(NSString *)buySel
                     buySelTime:(NSString *)buySelTime
                   buySellPrice:(NSString *)buySellPrice
                       longShort:(NSString *)longShort
                    profitLoss:(float)profitLoss;

@end

NS_ASSUME_NONNULL_END
