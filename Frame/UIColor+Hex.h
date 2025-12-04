//
//  UIColor+Hex.h
//  Frame
//
//  Created by 冯汉栩 on 2025/12/4.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (Hex)

/**
 从十六进制字符串创建颜色
 @param hexString 十六进制字符串，支持格式: @"#RRGGBB", @"RRGGBB", @"0xRRGGBB"
 @return UIColor对象，如果格式错误返回nil
 */
+ (UIColor *)colorWithHexString:(NSString *)hexString;

/**
 从十六进制字符串创建颜色，带透明度
 @param hexString 十六进制字符串
 @param alpha 透明度 (0.0 - 1.0)
 @return UIColor对象
 */
+ (UIColor *)colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

@end

NS_ASSUME_NONNULL_END
