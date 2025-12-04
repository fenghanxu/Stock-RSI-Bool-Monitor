//
//  UIColor+Hex.m
//  Frame
//
//  Created by 冯汉栩 on 2025/12/4.
//

#import "UIColor+Hex.h"

@implementation UIColor (Hex)

+ (UIColor *)colorWithHexString:(NSString *)hexString {
    return [self colorWithHexString:hexString alpha:1.0f];
}

+ (UIColor *)colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha {
    // 去除字符串中的空格和换行符
    NSString *cString = [[hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // 移除前缀
    if ([cString hasPrefix:@"#"]) {
        cString = [cString substringFromIndex:1];
    } else if ([cString hasPrefix:@"0X"] || [cString hasPrefix:@"0x"]) {
        cString = [cString substringFromIndex:2];
    }
    
    // 验证长度
    if (cString.length != 6 && cString.length != 8) {
        // 如果不是6位或8位RGB/RGBA，尝试支持3位RGB
        if (cString.length == 3) {
            // 将3位扩展为6位: RGB -> RRGGBB
            unichar r = [cString characterAtIndex:0];
            unichar g = [cString characterAtIndex:1];
            unichar b = [cString characterAtIndex:2];
            cString = [NSString stringWithFormat:@"%C%C%C%C%C%C", r, r, g, g, b, b];
        } else {
            // 长度不符合要求，返回nil
            NSLog(@"Hex string format error: %@", hexString);
            return nil;
        }
    }
    
    // 如果是8位RGBA，处理透明度
    CGFloat finalAlpha = alpha;
    if (cString.length == 8) {
        // 从最后两位提取alpha值
        NSString *alphaString = [cString substringWithRange:NSMakeRange(6, 2)];
        unsigned int alphaValue;
        [[NSScanner scannerWithString:alphaString] scanHexInt:&alphaValue];
        finalAlpha = alphaValue / 255.0f;
        cString = [cString substringWithRange:NSMakeRange(0, 6)];
    }
    
    // 分离RGB值
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    // 红色
    NSString *rString = [cString substringWithRange:range];
    
    // 绿色
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    // 蓝色
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // 转换为整数
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    // 返回UIColor
    return [UIColor colorWithRed:((CGFloat)r / 255.0f)
                           green:((CGFloat)g / 255.0f)
                            blue:((CGFloat)b / 255.0f)
                           alpha:finalAlpha];
}

@end
