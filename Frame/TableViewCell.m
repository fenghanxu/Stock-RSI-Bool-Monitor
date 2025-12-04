//
//  TableViewCell.m
//  Frame
//
//  Created by 冯汉栩 on 2025/12/4.
//

#import "TableViewCell.h"
#import "PaddingLabel.h"
#import "UIColor+Hex.h"

@interface TableViewCell()
@property (nonatomic, strong) PaddingLabel *saleLabel;
@property (nonatomic, strong) PaddingLabel *buyTimeLabel;
@property (nonatomic, strong) PaddingLabel *buyPriceLabel;
@property (nonatomic, strong) PaddingLabel *directionLabel;
@property (nonatomic, strong) NSArray *list;
@end

@implementation TableViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView {
    static NSString *identifier = @"TableViewCellID";
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[TableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    return cell;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self buildUI];
    }
    return self;
}

- (void)buildUI{
    self.backgroundColor = [UIColor whiteColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    self.list = @[
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
    
    
    self.saleLabel = [PaddingLabel new];
    self.saleLabel.textColor = [UIColor whiteColor];
    self.saleLabel.textInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    self.saleLabel.str(@"买入").fnt(14).bgColor(self.list[arc4random_uniform((uint32_t)self.list.count)]).borderRadius(15).centerAlignment.fixWH(50,30);
    
    self.buyTimeLabel = [PaddingLabel new];
    self.buyTimeLabel.textColor = [UIColor whiteColor];
    self.buyTimeLabel.textInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    self.buyTimeLabel.str(@"2025-12-04").fnt(14).bgColor(self.list[arc4random_uniform((uint32_t)self.list.count)]).borderRadius(15).centerAlignment.fixWH(100,30);
    
    self.buyPriceLabel = [PaddingLabel new];
    self.buyPriceLabel.textColor = [UIColor whiteColor];
    self.buyPriceLabel.textInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    self.buyPriceLabel.str(@"买入价: 999999").fnt(14).bgColor(self.list[arc4random_uniform((uint32_t)self.list.count)]).borderRadius(15).centerAlignment.fixWH(130,30);
    
    self.directionLabel = [PaddingLabel new];
    self.directionLabel.textColor = [UIColor whiteColor];
    self.directionLabel.textInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    self.directionLabel.str(@"做空").fnt(14).bgColor(self.list[arc4random_uniform((uint32_t)self.list.count)]).borderRadius(15).centerAlignment.fixWH(50,30);
    
    id H = HorStack(
             NERSpring,
            self.saleLabel,
             NERSpring,
            self.buyTimeLabel,
             NERSpring,
             self.buyPriceLabel,
             NERSpring,
             self.directionLabel,
             NERSpring
       );
    
    VerStack(NERSpring, H, NERSpring).embedIn(self.contentView);
    
}

@end
