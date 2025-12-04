//
//  PaddingLabel.m
//  Frame
//
//  Created by 冯汉栩 on 2025/12/4.
//

#import "PaddingLabel.h"

@implementation PaddingLabel

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.textInsets)];
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    size.width += self.textInsets.left + self.textInsets.right;
    size.height += self.textInsets.top + self.textInsets.bottom;
    return size;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize adjustedSize = [super sizeThatFits:CGSizeMake(size.width - self.textInsets.left - self.textInsets.right,
                                                       size.height - self.textInsets.top - self.textInsets.bottom)];
    adjustedSize.width += self.textInsets.left + self.textInsets.right;
    adjustedSize.height += self.textInsets.top + self.textInsets.bottom;
    return adjustedSize;
}

@end
