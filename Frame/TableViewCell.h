//
//  TableViewCell.h
//  Frame
//
//  Created by 冯汉栩 on 2025/12/4.
//

#import <UIKit/UIKit.h>
#import "BusinessModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface TableViewCell : UITableViewCell

@property (nonatomic, strong) BusinessModel *model;
+ (instancetype)cellWithTableView:(UITableView *)tableView;

@end

NS_ASSUME_NONNULL_END
