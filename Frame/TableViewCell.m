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
@property (nonatomic, strong) PaddingLabel *directionLabel;
@property (nonatomic, strong) PaddingLabel *buyTimeLabel;
@property (nonatomic, strong) PaddingLabel *buyPriceLabel;
@end

@implementation TableViewCell

- (void)setModel:(BusinessModel *)model {
    _model = model;
    
    self.saleLabel.str(_model.buySel);
    self.directionLabel.str(_model.longShort);
    self.buyTimeLabel.str(_model.buySelTime);
    self.buyPriceLabel.str(_model.buySellPrice);
    
    self.saleLabel.bgColor(_model.buySelColor);
    self.directionLabel.bgColor(_model.longShortColor);
    self.buyTimeLabel.bgColor(_model.buySelTimeColor);
    self.buyPriceLabel.bgColor(_model.buySellPriceColor);
}

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

    self.saleLabel = [PaddingLabel new];
    self.saleLabel.textColor = [UIColor whiteColor];
    self.saleLabel.textInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    self.saleLabel.str(@"买入").fnt(14).bgColor(self.model.buySelColor).borderRadius(15).centerAlignment.fixWH(50,30);
    
    self.directionLabel = [PaddingLabel new];
    self.directionLabel.textColor = [UIColor whiteColor];
    self.directionLabel.textInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    self.directionLabel.str(@"做空").fnt(14).bgColor(self.model.longShortColor).borderRadius(15).centerAlignment.fixWH(50,30);
    
    self.buyTimeLabel = [PaddingLabel new];
    self.buyTimeLabel.textColor = [UIColor whiteColor];
    self.buyTimeLabel.textInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    self.buyTimeLabel.str(@"2025-12-04").fnt(14).bgColor(self.model.buySelTime).borderRadius(15).centerAlignment.fixWH(130,30);
    
    self.buyPriceLabel = [PaddingLabel new];
    self.buyPriceLabel.textColor = [UIColor whiteColor];
    self.buyPriceLabel.textInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    self.buyPriceLabel.str(@"买入价: 999999").fnt(14).bgColor(self.model.buySellPriceColor).borderRadius(15).centerAlignment.fixWH(100,30);

    id H = HorStack(
             NERSpring,
            self.saleLabel,
            NERSpring,
            self.directionLabel,
             NERSpring,
            self.buyTimeLabel,
             NERSpring,
             self.buyPriceLabel,
             NERSpring
       );
    
    VerStack(NERSpring, H, NERSpring).embedIn(self.contentView);
    
}

@end
