

#import "ViewController.h"
#import "MyTimer.h"
#import "UIColor+Hex.h"
#import "PaddingLabel.h"
#import "TableViewCell.h"
#define viewHeight 300 // 蜡烛图高度
#define space 3 // 每条蜡烛图的间隙
#define volumeHeight 80  // 成交量图形高度
#define rsiHeight 60 // RSI 指标高度

#define TP_Parameter 0.059//止盈
#define SL_Parameter 0.017//止损

//k线模型
@interface KLineModel : NSObject
@property (nonatomic, assign) CGFloat open;
@property (nonatomic, assign) CGFloat high;
@property (nonatomic, assign) CGFloat low;
@property (nonatomic, assign) CGFloat close;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, assign) CGFloat volume;
@property (nonatomic, assign) CGFloat rsi; // 新增 RSI 属性
@property (nonatomic, assign) CGFloat bollUpper;//布林-顶
@property (nonatomic, assign) CGFloat bollMiddle;//布林-中
@property (nonatomic, assign) CGFloat bollLower;//布林-底
@property (nonatomic,   copy) NSString *signalTag;   // 标记“买入”

@end

@implementation KLineModel
@end

typedef void(^KLineScaleAction)(BOOL clickState);

@interface KLineChartView : UIView
//可视view的数据，限制最多900条蜡烛图(总的数据当中的一部分)
@property (nonatomic, strong) NSArray<KLineModel *> *visibleKLineData;
//可视图x的偏移值，(可视图相对总图的x显示位置)
@property (nonatomic, assign) CGFloat contentOffsetX;
//蜡烛图的宽度
@property (nonatomic, assign) CGFloat candleWidth;
//长按手势:是否显示虚线
@property (nonatomic, assign) BOOL showCrossLine;
//长按手势相关: 十字线的point点
@property (nonatomic, assign) CGPoint crossPoint;
//长按手势
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;
//捏合手势
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGesture;

@end

@implementation KLineChartView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //初始化蜡烛图宽度
        _candleWidth = 8;
        //长按手势初始化
        _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        _longPressGesture.minimumPressDuration = 0.3;
        _longPressGesture.allowableMovement = 15;
        [self addGestureRecognizer:_longPressGesture];
        //捏合手势初始化
        _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        [self addGestureRecognizer:_pinchGesture];
    }
    return self;
}

//长按手势处理
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self];
    
    if (gesture.state == UIGestureRecognizerStateBegan ||
        gesture.state == UIGestureRecognizerStateChanged) {
        self.showCrossLine = YES;
        self.crossPoint = point;
        [self setNeedsDisplay];
    } else {
        self.showCrossLine = NO;
        [self setNeedsDisplay];
    }
}

//捏合手势处理
/**
 1.捏合根据gesture.scale 转换成  缩放比例，缩放蜡烛图的大小
 2.重新计算  scrollView 的 contentSize 和 contentOffset
 3.缩放目标保持在中间不动(写得不好)
 */
- (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
    static CGFloat lastScale = 1.0;

    if (gesture.state == UIGestureRecognizerStateBegan) {
        lastScale = 1.0;
    }

    CGFloat scale = gesture.scale / lastScale;
    lastScale = gesture.scale;

    // 限制 candleWidth 范围
    CGFloat newWidth = self.candleWidth * scale;
    newWidth = MAX(2, MIN(newWidth, 40));

    if (fabs(newWidth - self.candleWidth) < 0.01) return;

    // 找到手势中心点在 chartView 中的坐标
    CGPoint pinchCenterInView = [gesture locationInView:self];
    CGFloat centerX = pinchCenterInView.x;

    // 旧宽度下的 index
    NSInteger oldIndex = centerX / (self.candleWidth + space);

    // 旧相对偏移比例（在 scrollView 中）
    CGFloat ratio = (centerX) / self.bounds.size.width;

    // 更新 candleWidth
    self.candleWidth = newWidth;

    // 更新自身 frame 宽度
    CGFloat newChartWidth = self.visibleKLineData.count * (self.candleWidth + space);
    CGRect frame = self.frame;
    frame.size.width = newChartWidth;
    self.frame = frame;

    // 更新 scrollView 的 contentSize 和 contentOffset
    if ([self.superview isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        scrollView.contentSize = CGSizeMake(newChartWidth, scrollView.contentSize.height);

        // 重新计算缩放后的偏移
        CGFloat newOffsetX = oldIndex * (self.candleWidth + space) - ratio * scrollView.bounds.size.width;
        newOffsetX = MAX(0, MIN(newOffsetX, scrollView.contentSize.width - scrollView.bounds.size.width));
        scrollView.contentOffset = CGPointMake(newOffsetX, 0);
    }

    [self setNeedsDisplay];
}

- (void)setContentOffsetX:(CGFloat)contentOffsetX {
    _contentOffsetX = contentOffsetX;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (!self.visibleKLineData || self.visibleKLineData.count == 0) return;

    // 创建绘图上下文（画布对象）“画布 + 画笔 + 样式设置”
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    //===================== 绘制底部虚线网格 =====================//

    CGFloat gridTop = 0;                      // 网格顶部
    CGFloat gridBottom = viewHeight;          // 蜡烛图高度
    CGFloat gridLeft = 0;
    CGFloat gridRight = self.bounds.size.width;

    // 你想要分几段
    int horizontalLines = 6;   // 横向（价格方向）虚线数量
    int verticalLines = 160;     // 纵向（时间方向）虚线数量

    // 虚线样式：线长=空隙长
    CGFloat dashPattern[] = {6, 6};
    CGContextSetLineDash(ctx, 0, dashPattern, 2);
    CGContextSetLineWidth(ctx, 0.6);
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0.85 alpha:1].CGColor);

    //
    // ----------- 画横向虚线（等距）-----------
    //
    for (int i = 1; i < horizontalLines; i++) {
        CGFloat y = gridTop + (gridBottom - gridTop) * (i * 1.0 / horizontalLines);

        CGContextMoveToPoint(ctx, gridLeft, y);
        CGContextAddLineToPoint(ctx, gridRight, y);
        CGContextStrokePath(ctx);
    }

    //
    // ----------- 画纵向虚线（等距）-----------
    //
    for (int i = 1; i < verticalLines; i++) {
        CGFloat x = gridLeft + (gridRight - gridLeft) * (i * 1.0 / verticalLines);

        CGContextMoveToPoint(ctx, x, gridTop);
        CGContextAddLineToPoint(ctx, x, gridBottom);
        CGContextStrokePath(ctx);
    }

    // 关闭虚线
    CGContextSetLineDash(ctx, 0, NULL, 0);
    
    //===================== 计算 max / min =====================//

    // 可视view  显示的个数
    NSInteger countInView = ceil(SCREEN_WIDTH / (self.candleWidth + space)) + 1;
    // 可视view  开始的index
    NSInteger startIndex = MAX(0, self.contentOffsetX / (self.candleWidth + space));
    // 可视view  结束的index
    NSInteger endIndex = MIN(startIndex + countInView, self.visibleKLineData.count);

    // 局部最大最小价
    CGFloat maxPrice  = -MAXFLOAT;
    CGFloat minPrice  = MAXFLOAT;
    CGFloat maxVolume = -MAXFLOAT;

    for (NSInteger i = startIndex; i < endIndex; i++) {
        KLineModel *model = self.visibleKLineData[i];
        // 考虑蜡烛图和布林线上下轨
        maxPrice = MAX(maxPrice, model.high);
//        maxPrice = MAX(maxPrice, model.bollUpper);
        
        minPrice = MIN(minPrice, model.low);
//        minPrice = MIN(minPrice, model.bollLower);
        maxVolume = MAX(maxVolume, model.volume);
    }

    CGFloat marginRatio = 0.1;
    CGFloat priceRange = maxPrice - minPrice;
    CGFloat padding = priceRange * marginRatio;
    maxPrice += padding;
    minPrice -= padding;

    //求出可视view一格代表多少钱(1格/100元，1格/200元)
    CGFloat scale = viewHeight / (maxPrice - minPrice);
    CGFloat volumeTop = viewHeight + 10;

    // 给文字预留空间（数值高度 + 上边距）
    CGFloat volumeTextGap = 12; // 你可以调整成 8、10、12

    // 重新计算真正可用的绘制高度
    CGFloat volumeDrawHeight = volumeHeight - volumeTextGap;
    if (volumeDrawHeight < 1) volumeDrawHeight = 1;

    // 更新 volumeScale
    CGFloat volumeScale = (maxVolume > 0) ? (volumeDrawHeight / maxVolume) : 0;
    
    CGFloat rsiTop = volumeTop + volumeHeight + 10;
    
    //===================== 绘制K线 =====================//
    // for循环遍历可视化的绘制数据
    for (NSInteger i = startIndex; i < endIndex; i++) {
        //绘制 K线
        KLineModel *model = self.visibleKLineData[i];
        CGFloat x = i * (self.candleWidth + space);
        CGFloat openY = (maxPrice - model.open) * scale;
        CGFloat closeY = (maxPrice - model.close) * scale;
        CGFloat highY = (maxPrice - model.high) * scale;
        CGFloat lowY = (maxPrice - model.low) * scale;

        UIColor *color = model.close >= model.open ? [UIColor redColor] : [UIColor colorWithRed:0.23 green:0.74 blue:0.52 alpha:1.0];
        CGContextSetStrokeColorWithColor(ctx, color.CGColor);
        CGContextSetLineWidth(ctx, 1);
        //绘制 上下影线（High-Low）
        CGContextMoveToPoint(ctx, x + self.candleWidth/2, highY);
        CGContextAddLineToPoint(ctx, x + self.candleWidth/2, lowY);
        CGContextStrokePath(ctx);
        //绘制实体 Body（开盘价到收盘价）
        CGContextSetFillColorWithColor(ctx, color.CGColor);
        if (model.close >= model.open) {
            CGContextFillRect(ctx, CGRectMake(x, closeY, self.candleWidth, openY - closeY));
        } else {
            CGContextFillRect(ctx, CGRectMake(x, openY, self.candleWidth, closeY - openY));
        }
        
        // ====== 绘制 RSI-BOLL 买入标记 ======
        if (model.signalTag) {

            NSString *txt = model.signalTag;

            NSDictionary *attr = @{
                NSFontAttributeName: [UIFont boldSystemFontOfSize:10],
                NSForegroundColorAttributeName: [UIColor orangeColor]
            };

            CGSize tsize = [txt sizeWithAttributes:attr];

            CGFloat textX = x + (self.candleWidth - tsize.width) / 2;
            CGFloat textY = highY - tsize.height - 2; // 放在高点上方

            [txt drawAtPoint:CGPointMake(textX, textY) withAttributes:attr];
        }
        
        // 绘制每条k线涨跌幅 显示在蜡烛图的底部的数值
        if (model.open > 0) {
            CGFloat changePercent = ((model.close - model.open) / model.open) * 100;
            NSString *percentText = [NSString stringWithFormat:@"%.1f", changePercent];
            NSDictionary *percentAttr = @{
                NSFontAttributeName: [UIFont systemFontOfSize:8],
                NSForegroundColorAttributeName: color
            };
            CGSize size = [percentText sizeWithAttributes:percentAttr];
            
            // 正确：基于最低价位置绘制文字
            CGFloat textX = x + (self.candleWidth - size.width) / 2;
            CGFloat textY = lowY + 2; // lowY 是最低价对应的 Y 坐标

            [percentText drawAtPoint:CGPointMake(textX, textY) withAttributes:percentAttr];
        }
        
        // 绘制 成交量柱子
        CGFloat volHeight = model.volume * volumeScale;
        CGFloat volY = volumeTop + volumeHeight - volHeight;
        CGContextFillRect(ctx, CGRectMake(x, volY, self.candleWidth, volHeight));
        
        // 绘制 成交量柱上方绘制成交量数值
        if (model.volume > 0) {

            // 两种交替颜色（你可自由调整）
            UIColor *color1 = [UIColor colorWithWhite:0.2 alpha:1];          // 深灰
            UIColor *color2 = [UIColor colorWithRed:0 green:0.45 blue:1 alpha:1]; // 蓝色

            // 根据 index 决定颜色（相邻不同色）
            UIColor *textColor = (i % 2 == 0) ? color1 : color2;

            NSString *volText = [NSString stringWithFormat:@"%.0f", model.volume];
            NSDictionary *volAttr = @{
                NSFontAttributeName: [UIFont systemFontOfSize:7],
                NSForegroundColorAttributeName: textColor
            };

            CGSize volSize = [volText sizeWithAttributes:volAttr];

            CGFloat volTextX = x + (self.candleWidth - volSize.width) / 2;
            CGFloat volTextY = volY - volSize.height - 2;

            // 防止文字被蜡烛图盖住
            if (volTextY > viewHeight + 5) {
                [volText drawAtPoint:CGPointMake(volTextX, volTextY) withAttributes:volAttr];
            }
        }
        
        // ======== 固定 RSI 显示区间 0~100 ========
        CGFloat fixedRSIMax = 100;
        CGFloat fixedRSIMin = 0;
        CGFloat rsiScale = rsiHeight / (fixedRSIMax - fixedRSIMin);

        // 绘制 RSI 曲线
        CGContextSetLineWidth(ctx, 1.0);
        CGContextSetStrokeColorWithColor(ctx, [UIColor purpleColor].CGColor);

        for (NSInteger i = startIndex; i < endIndex - 1; i++) {
            KLineModel *m1 = self.visibleKLineData[i];
            KLineModel *m2 = self.visibleKLineData[i+1];

            CGFloat x1 = i * (self.candleWidth + space) + self.candleWidth/2;
            CGFloat x2 = (i+1) * (self.candleWidth + space) + self.candleWidth/2;

            CGFloat y1 = rsiTop + rsiHeight - (m1.rsi - fixedRSIMin) * rsiScale;
            CGFloat y2 = rsiTop + rsiHeight - (m2.rsi - fixedRSIMin) * rsiScale;

            CGContextMoveToPoint(ctx, x1, y1);
            CGContextAddLineToPoint(ctx, x2, y2);
            CGContextStrokePath(ctx);
        }

        // === RSI 虚线 (20, 80)
        NSArray<NSNumber *> *rsiLevels = @[@20, @80];
        CGContextSetLineWidth(ctx, 0.5);
        CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
        CGFloat dashPattern[] = {4, 2};
        CGContextSetLineDash(ctx, 0, dashPattern, 2);

        for (NSNumber *level in rsiLevels) {
            CGFloat y = rsiTop + rsiHeight - (level.floatValue - fixedRSIMin) * rsiScale;
            CGContextMoveToPoint(ctx, 0, y);
            CGContextAddLineToPoint(ctx, self.bounds.size.width, y);
            CGContextStrokePath(ctx);
        }

        CGContextSetLineDash(ctx, 0, NULL, 0); //关闭虚线

    }
    
    // ========= 画布林线 =========
    CGContextSetLineWidth(ctx, 1.0);

    // 中轨线 (黄色)
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithHexString:@"FF00FF"].CGColor);
    for (NSInteger i = startIndex; i < endIndex - 1; i++) {
        KLineModel *m1 = self.visibleKLineData[i];
        KLineModel *m2 = self.visibleKLineData[i+1];

        if (m1.bollMiddle == 0 || m2.bollMiddle == 0) continue;

        CGFloat x1 = i * (self.candleWidth + space) + self.candleWidth/2;
        CGFloat x2 = (i+1) * (self.candleWidth + space) + self.candleWidth/2;

        CGFloat y1 = (maxPrice - m1.bollMiddle) * scale;
        CGFloat y2 = (maxPrice - m2.bollMiddle) * scale;

        CGContextMoveToPoint(ctx, x1, y1);
        CGContextAddLineToPoint(ctx, x2, y2);
        CGContextStrokePath(ctx);
    }

    // 上轨线 (蓝色)
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithHexString:@"FFA500"].CGColor);
    for (NSInteger i = startIndex; i < endIndex - 1; i++) {
        KLineModel *m1 = self.visibleKLineData[i];
        KLineModel *m2 = self.visibleKLineData[i+1];

        if (m1.bollUpper == 0 || m2.bollUpper == 0) continue;

        CGFloat x1 = i * (self.candleWidth + space) + self.candleWidth/2;
        CGFloat x2 = (i+1) * (self.candleWidth + space) + self.candleWidth/2;

        CGFloat y1 = (maxPrice - m1.bollUpper) * scale;
        CGFloat y2 = (maxPrice - m2.bollUpper) * scale;

        CGContextMoveToPoint(ctx, x1, y1);
        CGContextAddLineToPoint(ctx, x2, y2);
        CGContextStrokePath(ctx);
    }

    // 下轨线 (黑色)
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithHexString:@"6A5ACD"].CGColor);
    for (NSInteger i = startIndex; i < endIndex - 1; i++) {
        KLineModel *m1 = self.visibleKLineData[i];
        KLineModel *m2 = self.visibleKLineData[i+1];

        if (m1.bollLower == 0 || m2.bollLower == 0) continue;

        CGFloat x1 = i * (self.candleWidth + space) + self.candleWidth/2;
        CGFloat x2 = (i+1) * (self.candleWidth + space) + self.candleWidth/2;

        CGFloat y1 = (maxPrice - m1.bollLower) * scale;
        CGFloat y2 = (maxPrice - m2.bollLower) * scale;

        CGContextMoveToPoint(ctx, x1, y1);
        CGContextAddLineToPoint(ctx, x2, y2);
        CGContextStrokePath(ctx);
    }
    
    // =================== 可视范围内最高价 / 最低价 标记 ===================

    // 1. 找到最高价、最低价出现的 index
    NSInteger maxIndex = startIndex;
    NSInteger minIndex = startIndex;

    for (NSInteger i = startIndex; i < endIndex; i++) {
        KLineModel *m = self.visibleKLineData[i];
        if (m.high >= maxPrice - padding) maxIndex = i;
        if (m.low  <= minPrice + padding) minIndex = i;
    }

    // 2. 转换为坐标
    KLineModel *maxModel = self.visibleKLineData[maxIndex];
    KLineModel *minModel = self.visibleKLineData[minIndex];

    // ⭐⭐⭐ 关键修改点：从蜡烛中间开始（不是最左边） ⭐⭐⭐
    CGFloat candleFullWidth = self.candleWidth + space;
    CGFloat maxX = maxIndex * candleFullWidth + self.candleWidth * 0.5;
    CGFloat minX = minIndex * candleFullWidth + self.candleWidth * 0.5;

    CGFloat maxY = (maxPrice - maxModel.high) * scale;
    CGFloat minY = (maxPrice - minModel.low) * scale;

    CGContextSetLineWidth(ctx, 1.0);
    CGContextSetStrokeColorWithColor(ctx, [UIColor lightGrayColor].CGColor);

    // 横线长度
    CGFloat lineLength = 24;

    // ========== 最高价（向左画线 + 左侧写字） ==========
    CGContextMoveToPoint(ctx, maxX, maxY);
    CGContextAddLineToPoint(ctx, maxX - lineLength, maxY); // ← 向左
    CGContextStrokePath(ctx);

    // 写文字（放到左边）
    NSString *maxText = [NSString stringWithFormat:@"%.2f", maxModel.high];
    NSDictionary *maxAttr = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:10],
        NSForegroundColorAttributeName: [UIColor lightGrayColor]
    };
    CGSize maxSize = [maxText sizeWithAttributes:maxAttr];
    // ← 文本放在线左边（注意减去文字宽度）
    [maxText drawAtPoint:CGPointMake(maxX - lineLength - 2 - maxSize.width,
                                     maxY - maxSize.height/2)
           withAttributes:maxAttr];


    // ========== 最低价（向左画线 + 左侧写字） ==========
    CGContextMoveToPoint(ctx, minX, minY);
    CGContextAddLineToPoint(ctx, minX - lineLength, minY); // ← 向左
    CGContextStrokePath(ctx);

    // 写文字（放到左边）
    NSString *minText = [NSString stringWithFormat:@"%.2f", minModel.low];
    NSDictionary *minAttr = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:10],
        NSForegroundColorAttributeName: [UIColor lightGrayColor]
    };
    CGSize minSize = [minText sizeWithAttributes:minAttr];

    [minText drawAtPoint:CGPointMake(minX - lineLength - 2 - minSize.width,
                                     minY - minSize.height/2)
           withAttributes:minAttr];
  


    
    //长按十字线
    if (self.showCrossLine) {
        NSInteger index = round(self.crossPoint.x / (self.candleWidth + space));
        
        if (index >= 0 && index < self.visibleKLineData.count) {
            KLineModel *model = self.visibleKLineData[index];

            // 计算该蜡烛的中心 X 位置
            CGFloat candleCenterX = index * (self.candleWidth + space) + self.candleWidth / 2.0;
            CGFloat y = self.crossPoint.y;

            // 绘制虚线
            CGContextSetLineWidth(ctx, 0.5);
            CGContextSetStrokeColorWithColor(ctx, [UIColor grayColor].CGColor);
            CGFloat dashPattern[] = {4, 2};
            CGContextSetLineDash(ctx, 0, dashPattern, 2);

            // 横线
            CGContextMoveToPoint(ctx, 0, y);
            CGContextAddLineToPoint(ctx, self.bounds.size.width, y);
            CGContextStrokePath(ctx);

            // 纵线
            CGContextMoveToPoint(ctx, candleCenterX, 0);
            CGContextAddLineToPoint(ctx, candleCenterX, self.bounds.size.height);
            CGContextStrokePath(ctx);
            CGContextSetLineDash(ctx, 0, NULL, 0); // 关闭虚线

            // 长按显示：价格
            CGFloat priceRange = maxPrice - minPrice;
            CGFloat scale = viewHeight / priceRange;
            CGFloat price = maxPrice - y / scale;
            NSString *priceText = [NSString stringWithFormat:@"%.2f", price];
            NSDictionary *attr = @{NSFontAttributeName:[UIFont systemFontOfSize:18], NSForegroundColorAttributeName:[UIColor blackColor]};
            CGSize priceTextSize = [priceText sizeWithAttributes:attr];
            CGFloat leftX = self.contentOffsetX + 2; // 加2是为了内边距美观
            CGFloat priceTextY = y - priceTextSize.height / 2.0;
            [priceText drawAtPoint:CGPointMake(leftX, priceTextY) withAttributes:attr];

            // 长按显示：时间、成交量
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:model.timestamp];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyy-MM-dd HH";
            NSString *dateStr = [formatter stringFromDate:date];
            NSString *volumeStr = [NSString stringWithFormat:@"量: %.0f", model.volume];
            NSString *info = [NSString stringWithFormat:@"%@  %@", dateStr, volumeStr];
            CGSize textSize = [info sizeWithAttributes:attr];
            // 显示在成交量图下方（比 volume 区域再低一些）
            CGFloat textY = viewHeight - 18; // 比成交量底部低 5px
            CGFloat infoX = MIN(MAX(0, candleCenterX - textSize.width / 2), self.bounds.size.width - textSize.width);
            [info drawAtPoint:CGPointMake(infoX, textY) withAttributes:attr];
        }
    }
    
}

@end

@interface ViewController () <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) MyTimer *myTimer;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) KLineChartView *chartView;
@property (nonatomic, strong) PaddingLabel *lumpsumLabel;//总金额Label
@property (nonatomic, strong) PaddingLabel *allQuantityLabel;//交易数量
@property (nonatomic, strong) PaddingLabel *profitQuantityLabel;//盈利数量
@property (nonatomic, strong) PaddingLabel *winningRateLabel;//胜率
@property (nonatomic, strong) UITableView  *tableView;


@property (nonatomic, strong) NSMutableArray<KLineModel *> *allKLineData;
@property (nonatomic, strong) NSMutableArray<KLineModel *> *futureKLineData;

@property (nonatomic, assign) NSInteger winCount;    //赢的次数
@property (nonatomic, assign) NSInteger lowerCount;  //输的次数
@property (nonatomic, assign) double finalBalance;   // 最终资金
@property (nonatomic, assign) NSInteger tradeCount;  // 总交易数
@property (nonatomic, assign) NSInteger winTrades;   // 获利交易数
@property (nonatomic, strong) NSMutableArray<NSNumber *> *lossStreaks;  // 连败统计数组 1~12
@property (nonatomic, strong) NSMutableArray<NSNumber *> *returnsArray; // 累计每一盘的盈亏
@property (nonatomic, assign) NSInteger currentLossStreak; // 当前连败数

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [self buildUI];

    self.allKLineData      = [NSMutableArray<KLineModel *> new];
    self.futureKLineData   = [NSMutableArray<KLineModel *> new];
    self.finalBalance      = 1.0;
    self.tradeCount        = 0;
    self.winTrades         = 0;
    self.currentLossStreak = 0;
    self.returnsArray      = [NSMutableArray<NSNumber *> new];
    self.lossStreaks       = [NSMutableArray<NSNumber *> new];
    for (int i = 0; i < 12; i++) {
        [self.lossStreaks addObject:@0];
    }

    self.futureKLineData     = [self creatDataWithTime:@"2025-02-09--2025-02-10.json" withFuture:YES];
    self.allKLineData        = [self creatDataWithTime:@"2025-02-09--2025-02-10.json" withFuture:NO];
    
    CGFloat chartViewHeight  = viewHeight + 10 + volumeHeight + 10 + rsiHeight;
    CGRect scrollerRect = CGRectMake(0, SAFE_AREA_TOP_HEIGHT, SCREEN_WIDTH, chartViewHeight);
    self.scrollView          = [[UIScrollView alloc] initWithFrame:scrollerRect];
    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];

    //计算 股票图的contentSize.width(可滑动的宽度)
    [self setupChartView:chartViewHeight];
    //计算 RSI的模型数据
    [self calculateRSIWithPeriod:6];
    //计算BOLL的模型数据
    [self calculateBOLLWithPeriod:20];
    /*
     1.当RSI>80 且 k线的实体上穿布林线的蓝色线(bollUpper)时,等到出现k线下跌的第一根(开盘价大于收盘价),在K线的顶部标记橙色买入的字样
     2.当RSI<20 且 k线的实体下穿最底部布林线黑色(bollLower)时,等到出现k线上升的第一根(开盘价小于收盘价),在K线的顶部标记橙色买入的字样
     */
    [self detectRSI_BOLL_Signals];
    //打印结果
    //[self printBacktestSummary];

    
//    __weak typeof(self) weakSelf = self;
//    self.myTimer = [MyTimer scheduledTimerWithBlock:^{
//        if (weakSelf.futureKLineData.count <= 0) {
//            [self.myTimer pause];
//            return;
//        }
//        [weakSelf.allKLineData addObject:weakSelf.futureKLineData.firstObject];
//        [weakSelf.futureKLineData removeObjectAtIndex:0];
//        [weakSelf.allKLineData removeObjectAtIndex:0];
//        //k线图赋值最新数据
//        weakSelf.chartView.visibleKLineData = weakSelf.allKLineData;
//        //重新绘制k线图
//        [weakSelf.chartView setNeedsDisplay];
//        //把k线图移动到最右边
//        dispatch_async(dispatch_get_main_queue(), ^{
//            UIScrollView *scrollView = weakSelf.scrollView;
//            if (!scrollView) return;
//            CGFloat maxOffsetX = scrollView.contentSize.width - scrollView.bounds.size.width;
//            if (maxOffsetX < 0) maxOffsetX = 0;
//            [scrollView setContentOffset:CGPointMake(maxOffsetX, 0) animated:NO];
//        });
//
//        //计算 RSI的模型数据
//        [weakSelf calculateRSIWithPeriod:6];
//        //计算BOLL的模型数据
//        [weakSelf calculateBOLLWithPeriod:20];
//        /*
//         1.当RSI>80 且 k线的实体上穿布林线的蓝色线(bollUpper)时,等到出现k线下跌的第一根(开盘价大于收盘价),在K线的顶部标记橙色买入的字样
//         2.当RSI<20 且 k线的实体下穿最底部布林线黑色(bollLower)时,等到出现k线上升的第一根(开盘价小于收盘价),在K线的顶部标记橙色买入的字样
//         */
//        [weakSelf detectRSI_BOLL_Signals];
//    }];
//    [self.myTimer start];

}

-(void)buildUI {
    
    CGFloat topDistance = SAFE_AREA_TOP_HEIGHT + viewHeight + 10 + volumeHeight + 10 + rsiHeight + 10;
    
    self.lumpsumLabel = [PaddingLabel new];
    self.lumpsumLabel.textColor = [UIColor whiteColor];
    self.lumpsumLabel.textInsets = UIEdgeInsetsMake(0, 8, 0, 8);
    self.lumpsumLabel.addTo(self.view).str(@"总金额: 1.45倍").fnt(14).bgColor([UIColor colorWithHexString:@"9932CC"]).borderRadius(15).centerAlignment.makeCons(^{
        make.left.equal.view(self.view).constants(10);
        make.top.equal.view(self.view).constants(topDistance);
        make.width.equal.constants(110);
        make.height.equal.constants(30);
    });
    
    self.allQuantityLabel = [PaddingLabel new];
    self.allQuantityLabel.textColor = [UIColor whiteColor];
    self.allQuantityLabel.textInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    self.allQuantityLabel.addTo(self.view).str(@"交易笔数: 999").fnt(14).bgColor([UIColor colorWithHexString:@"008B8B"]).borderRadius(15).centerAlignment.makeCons(^{
        make.left.equal.view(self.lumpsumLabel).right.constants(10);
        make.centerY.equal.view(self.lumpsumLabel);
        make.width.equal.constants(115);
        make.height.equal.constants(30);
    });
    
    self.profitQuantityLabel = [PaddingLabel new];
    self.profitQuantityLabel.textColor = [UIColor whiteColor];
    self.profitQuantityLabel.textInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    self.profitQuantityLabel.addTo(self.view).str(@"盈利笔数: 60").fnt(14).bgColor([UIColor colorWithHexString:@"DAA520"]).borderRadius(15).centerAlignment.makeCons(^{
        make.left.equal.view(self.allQuantityLabel).right.constants(10);
        make.centerY.equal.view(self.lumpsumLabel);
        make.width.equal.constants(115);
        make.height.equal.constants(30);
    });
    
    self.winningRateLabel = [PaddingLabel new];
    self.winningRateLabel.textColor = [UIColor whiteColor];
    self.winningRateLabel.textInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    self.winningRateLabel.addTo(self.view).str(@"胜率: 83%").fnt(14).bgColor([UIColor colorWithHexString:@"FF4500"]).borderRadius(15).centerAlignment.makeCons(^{
        make.left.equal.view(self.view).constants(10);
        make.top.equal.view(self.lumpsumLabel).bottom.constants(10);
        make.width.equal.constants(110);
        make.height.equal.constants(30);
    });

    self.tableView = [[UITableView alloc] init];
    self.tableView.addTo(self.view);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tag = 20251204;
    self.tableView.rowHeight = 44;
    [self.tableView registerClass:[TableViewCell class] forCellReuseIdentifier:@"TableViewCellID"];
    //为解决tableview  Group的问题
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
    self.tableView.sectionHeaderHeight = CGFLOAT_MIN;
    self.tableView.sectionFooterHeight = CGFLOAT_MIN;
    //为解决ios11 后tableview刷新跳动的问题
    self.tableView.estimatedRowHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;
    self.tableView.makeCons(^{
        make.left.right.equal.view(self.view);
        make.top.equal.view(self.winningRateLabel).bottom.constants(10);
        make.bottom.equal.view(self.view).constants(-SAFE_AREA_BOTTOM);
    });

}

#pragma  mark UITableViewDelegate 的代理方法
//设置行数
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

//cell的内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCell *cell = [TableViewCell cellWithTableView:tableView];
    return cell;
}


//计算 股票图的contentSize.width(可滑动的宽度)
- (void)setupChartView:(CGFloat)chartHeight {
    CGFloat width = self.allKLineData.count * (8 + space);
    KLineChartView *chartView = [[KLineChartView alloc] initWithFrame:CGRectMake(0, 0, width, chartHeight)];
    chartView.backgroundColor = [UIColor whiteColor];
    chartView.visibleKLineData = self.allKLineData;
    //移除scrollView上面的所有子控件
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.scrollView addSubview:chartView];
    self.scrollView.contentSize = chartView.bounds.size;
    self.chartView = chartView;
    //程序启动k线图显示在最右边
    UIScrollView *scrollView = self.scrollView;
    if (!scrollView) return;
    CGFloat maxOffsetX = scrollView.contentSize.width - scrollView.bounds.size.width;
    if (maxOffsetX < 0) maxOffsetX = 0;
    [scrollView setContentOffset:CGPointMake(maxOffsetX, 0) animated:NO];
}

// 计算 RSI
- (void)calculateRSIWithPeriod:(NSInteger)n {
    if (self.allKLineData.count < n) return;

    CGFloat gainSum = 0, lossSum = 0;
    for (NSInteger i = 1; i <= n; i++) {
        CGFloat diff = self.allKLineData[i].close - self.allKLineData[i-1].close;
        if (diff >= 0) gainSum += diff;
        else lossSum += -diff;
    }
    CGFloat avgGain = gainSum / n;
    CGFloat avgLoss = lossSum / n;
    self.allKLineData[n].rsi = avgLoss == 0 ? 100 : 100 - (100 / (1 + avgGain/avgLoss));

    for (NSInteger i = n+1; i < self.allKLineData.count; i++) {
        CGFloat diff = self.allKLineData[i].close - self.allKLineData[i-1].close;
        CGFloat gain = diff > 0 ? diff : 0;
        CGFloat loss = diff < 0 ? -diff : 0;

        avgGain = (avgGain * (n - 1) + gain) / n;
        avgLoss = (avgLoss * (n - 1) + loss) / n;

        self.allKLineData[i].rsi = avgLoss == 0 ? 100 : 100 - (100 / (1 + avgGain/avgLoss));
    }
}

// 计算布林线：默认 N=20
- (void)calculateBOLLWithPeriod:(NSInteger)n {
    if (self.allKLineData.count < n) return;

    for (NSInteger i = n - 1; i < self.allKLineData.count; i++) {

        CGFloat sum = 0;
        for (NSInteger j = i - n + 1; j <= i; j++) {
            sum += self.allKLineData[j].close;
        }
        CGFloat ma = sum / n;

        // 计算标准差
        CGFloat variance = 0;
        for (NSInteger j = i - n + 1; j <= i; j++) {
            CGFloat diff = self.allKLineData[j].close - ma;
            variance += diff * diff;
        }
        CGFloat md = sqrt(variance / n);

        self.allKLineData[i].bollMiddle = ma;
        self.allKLineData[i].bollUpper = ma + 2 * md;
        self.allKLineData[i].bollLower = ma - 2 * md;
    }
}

/*
 做空（short）触发条件
 必须同时满足：
 1. RSI > 80
 2. 收盘价 > 开盘价（阳线，上涨 K 线）
 3. 收盘价 > 顶部布林线（向上站在布林线上方）
 📌 触发后不是立刻做空，而是等待 ➡ 等待出现第一根下跌 K 线（open > close）的下一根k线开盘价做空

 做空止盈止损
 止盈固定：-0.7%    即: 0.993(跌0.007)
 止损固定：+1%        即:1.01(升0.1)




 做多（long）触发条件
 必须同时满足：
 1. RSI < 20
 2. 收盘价 < 开盘价（阴线，下跌 K 线）
 3. 收盘价 < 底部布林线（向下站在布林线外）
 📌 触发后不是立刻做多，而是等待 ➡ 等待出现第一根上涨 K 线（open < close）的下一根k线开盘价做多

 做多止盈止损
 止盈固定：+0.7%    即:1.007(升0.07)
 止损固定：−1%       即:0.99(跌0.01)
 
 */
- (void)detectRSI_BOLL_Signals {

    BOOL inPosition = NO;
    NSInteger buyIndex = -1;
    CGFloat buyPrice = 0;
    NSString *direction = @"";
    
    BOOL waitForRise = NO;    // 等上涨确认 → 买升
    BOOL waitForDrop = NO;    // 等下跌确认 → 买跌

    self.winCount = 0;
    self.lowerCount = 0;

    for (NSInteger i = 1; i < self.allKLineData.count; i++) {

        KLineModel *m = self.allKLineData[i];

        // ==============================================================
        // ① 已持仓 → 检查卖出是否满足 TP / SL
        // ==============================================================
        if (inPosition) {

            BOOL closed = [self evaluateProfitFromIndex:i
                                               buyIndex:buyIndex
                                              buyPrice:buyPrice
                                              direction:direction];

            if (closed) {
                inPosition = NO;
                buyIndex = -1;
                buyPrice = 0;
            }

            continue;
        }

        // ==============================================================
        // ② 当前没有持仓 → 等待确认 K 线开仓
        // ==============================================================

        // ---- 等涨确认 → 买升（多单）----
        if (waitForRise) {

            if (m.close > m.open) {   // 必须是涨 K 才开仓（与 Python 一致）

                direction = @"long";
                buyIndex = i;
                buyPrice = m.close;    // 符合条件收盘价开仓

                m.signalTag = @"买升";
                inPosition = YES;

                waitForRise = NO;
                waitForDrop = NO;

                continue;
            }
        }

        // ---- 等跌确认 → 买跌（空单）----
        if (waitForDrop) {

            if (m.open > m.close) {   // 必须是跌 K 才开仓（与 Python 一致）

                direction = @"short";
                buyIndex = i;
                buyPrice = m.close; // 符合条件收盘价开仓

                m.signalTag = @"买跌";
                inPosition = YES;

                waitForDrop = NO;
                waitForRise = NO;

                continue;
            }
        }

        // ==============================================================
        // ③ 无仓位，也没有等待确认 → 检测信号本体
        // ==============================================================

        // ----------- RSI < 20 下穿下轨 → 下一根涨 K 才买升 -----------
        if (m.rsi < 20 &&
            m.close < m.open &&
            m.close < m.bollLower &&
            m.bollLower > 0.0) {

            waitForRise = YES;
            waitForDrop = NO;
            continue;
        }

        // ----------- RSI > 80 上穿上轨 → 下一根跌 K 才买跌 -----------
        if (m.rsi > 80 &&
            m.close > m.open &&
            m.close > m.bollUpper &&
            m.bollUpper > 0.0) {

            waitForDrop = YES;
            waitForRise = NO;
            continue;
        }
    }

}



// ============================================================
// 根据买点向后判断是否 赚 / 亏
// direction = @"down" 表示买跌
// direction = @"up"   表示买升
// ============================================================
- (BOOL)evaluateProfitFromIndex:(NSInteger)i
                       buyIndex:(NSInteger)buyIndex
                       buyPrice:(CGFloat)buyPrice
                      direction:(NSString *)direction {

    if (buyIndex < 0) return NO;

    // ===== 止盈止损百分比 =====
    CGFloat tpPct = TP_Parameter;    // 止盈
    CGFloat slPct = SL_Parameter;    // 止损

    CGFloat TP, SL;

    // ============================
    //   按多空方向计算目标价格
    // ============================
    if ([direction isEqualToString:@"long"]) {

        // 做多
        TP = buyPrice * (1 + tpPct);   // 上涨止盈
        SL = buyPrice * (1 - slPct);   // 下跌止损

    } else {

        // 做空
        TP = buyPrice * (1 - tpPct);   // 下跌止盈
        SL = buyPrice * (1 + slPct);   // 上涨止损
    }

    KLineModel *cur = self.allKLineData[i];

    // =====================
    //       做多逻辑
    // =====================
    if ([direction isEqualToString:@"long"]) {

        // --- 止盈（价格 >= TP）---
        if (cur.high >= TP) {
            self.winCount++;
            self.allKLineData[i].signalTag = @"赚";
            
            NSDate *buy_date = [NSDate dateWithTimeIntervalSince1970:self.allKLineData[buyIndex].timestamp];
            NSDateFormatter *buy_formatter = [[NSDateFormatter alloc] init];
            buy_formatter.dateFormat = @"yyyy-MM-dd HH";
            NSString *buy_dateStr = [buy_formatter stringFromDate:buy_date];
            
            NSDate *sall_date = [NSDate dateWithTimeIntervalSince1970:self.allKLineData[i].timestamp];
            NSDateFormatter *sall_formatter = [[NSDateFormatter alloc] init];
            sall_formatter.dateFormat = @"yyyy-MM-dd HH";
            NSString *sall_dateStr = [sall_formatter stringFromDate:sall_date];
                        
            NSLog(@"WIN 多单 | 买入时间: %@ | 卖出时间: %@ | 买: %.2f | 卖: %.2f | 盈利 %.2f%%",
                  buy_dateStr, sall_dateStr, buyPrice, TP, (TP-buyPrice)/buyPrice*100);
            
            // ======== 统计部分开始 ========
            // 总交易笔数
            self.tradeCount += 1;
            // 盈利笔数
            self.winTrades += 1;

            // 清零当前连败并记录到 streak 数组
            if (self.currentLossStreak > 0) {
                NSInteger idx = MIN(self.currentLossStreak - 1, 11);
                NSInteger old = self.lossStreaks[idx].integerValue;
                self.lossStreaks[idx] = @(old + 1);
                self.currentLossStreak = 0;
            }
            
            double pct = (TP - buyPrice) / buyPrice * 100.0;//单笔收益率(%) 赢一次固定 8%
            // === 复利计算（和 Python 完全一致）===
            double multiplier = 1.0 + pct / 100.0; //总金额的 1.08
            self.finalBalance *= multiplier;//总金额 * 1.08
            
            // 添加到数组（用于计算平均回报）
            [self.returnsArray addObject:@(pct)];
            // ======== 统计部分结束 ========


            return YES;
        }

        // --- 止损（价格 <= SL）---
        if (cur.low <= SL) {
            self.lowerCount++;
            self.allKLineData[i].signalTag = @"亏";
            
            NSDate *buy_date = [NSDate dateWithTimeIntervalSince1970:self.allKLineData[buyIndex].timestamp];
            NSDateFormatter *buy_formatter = [[NSDateFormatter alloc] init];
            buy_formatter.dateFormat = @"yyyy-MM-dd HH";
            NSString *buy_dateStr = [buy_formatter stringFromDate:buy_date];
            
            NSDate *sall_date = [NSDate dateWithTimeIntervalSince1970:self.allKLineData[i].timestamp];
            NSDateFormatter *sall_formatter = [[NSDateFormatter alloc] init];
            sall_formatter.dateFormat = @"yyyy-MM-dd HH";
            NSString *sall_dateStr = [sall_formatter stringFromDate:sall_date];
            
            NSLog(@"LOSE 多单 | 买入时间: %@ | 卖出时间: %@ | 买: %.2f | 卖: %.2f | 盈利 %.2f%%",
                  buy_dateStr, sall_dateStr, buyPrice, SL, (SL-buyPrice)/buyPrice*100);
            
            // ======== 统计部分开始 ========
            // 总交易笔数
            self.tradeCount += 1;
            // 总交易笔数
            self.currentLossStreak += 1;
            
            double pct = (SL -buyPrice) / buyPrice * 100.0;//单笔收益率(%)
            // === 复利计算（和 Python 完全一致）===
            double multiplier = 1.0 + pct / 100.0;
            self.finalBalance *= multiplier;
            // 添加到数组（用于计算平均回报）
            [self.returnsArray addObject:@(pct)];
            // ======== 统计部分结束 ========

            return YES;
        }
    }

    // =====================
    //       做空逻辑
    // =====================
    else {

        // --- 止盈（价格 <= TP）---
        if (cur.low <= TP) {
            self.winCount++;
            self.allKLineData[i].signalTag = @"赚";
            
            NSDate *buy_date = [NSDate dateWithTimeIntervalSince1970:self.allKLineData[buyIndex].timestamp];
            NSDateFormatter *buy_formatter = [[NSDateFormatter alloc] init];
            buy_formatter.dateFormat = @"yyyy-MM-dd HH";
            NSString *buy_dateStr = [buy_formatter stringFromDate:buy_date];
            
            NSDate *sall_date = [NSDate dateWithTimeIntervalSince1970:self.allKLineData[i].timestamp];
            NSDateFormatter *sall_formatter = [[NSDateFormatter alloc] init];
            sall_formatter.dateFormat = @"yyyy-MM-dd HH";
            NSString *sall_dateStr = [sall_formatter stringFromDate:sall_date];
            
            NSLog(@"WIN 空单 | 买入时间: %@ | 卖出时间: %@ | 卖空: %.2f | 平仓: %.2f | 盈利 %.2f%%",
                  buy_dateStr, sall_dateStr, buyPrice, TP, (buyPrice-TP)/buyPrice*100);
            
            // ======== 统计部分开始 ========
            // 总交易笔数
            self.tradeCount += 1;
            // 盈利笔数
            self.winTrades += 1;

            // 清零当前连败并记录到 streak 数组
            if (self.currentLossStreak > 0) {
                NSInteger idx = MIN(self.currentLossStreak - 1, 11);
                NSInteger old = self.lossStreaks[idx].integerValue;
                self.lossStreaks[idx] = @(old + 1);
                self.currentLossStreak = 0;
            }
            
            double pct = (buyPrice - TP) / buyPrice * 100.0;//单笔收益率(%)  8%
            // === 复利计算（和 Python 完全一致）===
            double multiplier = 1.0 + pct / 100.0;
            self.finalBalance *= multiplier;
            // 添加到数组（用于计算平均回报）
            [self.returnsArray addObject:@(pct)];
            // ======== 统计部分结束 ========

            return YES;
        }

        // --- 止损（价格 >= SL）---
        if (cur.high >= SL) {
            self.lowerCount++;
            self.allKLineData[i].signalTag = @"亏";
            
            NSDate *buy_date = [NSDate dateWithTimeIntervalSince1970:self.allKLineData[buyIndex].timestamp];
            NSDateFormatter *buy_formatter = [[NSDateFormatter alloc] init];
            buy_formatter.dateFormat = @"yyyy-MM-dd HH";
            NSString *buy_dateStr = [buy_formatter stringFromDate:buy_date];
            
            NSDate *sall_date = [NSDate dateWithTimeIntervalSince1970:self.allKLineData[i].timestamp];
            NSDateFormatter *sall_formatter = [[NSDateFormatter alloc] init];
            sall_formatter.dateFormat = @"yyyy-MM-dd HH";
            NSString *sall_dateStr = [sall_formatter stringFromDate:sall_date];
            
            NSLog(@"LOSE 空单 | 买入时间: %@ | 卖出时间: %@ | 卖空: %.2f | 平仓: %.2f | 盈利 %.2f%%",
                  buy_dateStr, sall_dateStr, buyPrice, SL, (buyPrice-SL)/buyPrice*100);
            
            // ======== 统计部分开始 ========
            // 总交易笔数
            self.tradeCount += 1;
            // 亏损笔数
            self.currentLossStreak += 1;
            
            double pct = (buyPrice - SL) / buyPrice * 100.0;//单笔收益率(%) -12
            // === 复利计算（和 Python 完全一致）===
            double multiplier = 1.0 + pct / 100.0;  //剩余总金额的 0.88 88%
            self.finalBalance *= multiplier;// 总金额 * 88%
            // 添加到数组（用于计算平均回报）
            [self.returnsArray addObject:@(pct)];
            // ======== 统计部分结束 ========

            
            return YES;
        }
    }

    return NO; // 继续持仓
}

-(NSMutableArray<KLineModel *> *)creatDataWithTime:(NSString *)time withFuture:(BOOL)future {
    NSMutableArray *initialList = [NSMutableArray array];
    NSMutableArray *futureList = [NSMutableArray array];
    NSArray *paths = [[NSBundle mainBundle] pathsForResourcesOfType:@"json" inDirectory:nil];
    NSArray *sortedPaths = [paths sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [[obj1 lastPathComponent] localizedStandardCompare:[obj2 lastPathComponent]];
    }];

    NSMutableArray *frontArray = [NSMutableArray array];
    NSMutableArray *laterArray = [NSMutableArray array];
    BOOL frontTag = YES;
    for (NSString *filePath in sortedPaths) {
        if ([[filePath lastPathComponent] isEqualToString:time]) {
            frontTag = NO;
        }
        if (frontTag) {
            [frontArray addObject:filePath];
        } else {
            [laterArray addObject:filePath];
        }
    }
    
    
    for (NSString *filePath in frontArray) {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        if (!data) continue;
        NSError *error;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (error) continue;
        NSArray *klineList = json[@"data"][@"kline_list"];
        for (NSDictionary *dict in klineList) {
            KLineModel *model = [[KLineModel alloc] init];
            model.open = [dict[@"open_price"] floatValue];
            model.high = [dict[@"high_price"] floatValue];
            model.low = [dict[@"low_price"] floatValue];
            model.close = [dict[@"close_price"] floatValue];
            model.timestamp = [dict[@"timestamp"] doubleValue];
            model.volume = [dict[@"volume"] floatValue];
            [initialList addObject:model];
        }
    }
    
    for (NSString *filePath in laterArray) {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        if (!data) continue;
        NSError *error;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (error) continue;
        NSArray *klineList = json[@"data"][@"kline_list"];
        for (NSDictionary *dict in klineList) {
            KLineModel *model = [[KLineModel alloc] init];
            model.open = [dict[@"open_price"] floatValue];
            model.high = [dict[@"high_price"] floatValue];
            model.low = [dict[@"low_price"] floatValue];
            model.close = [dict[@"close_price"] floatValue];
            model.timestamp = [dict[@"timestamp"] doubleValue];
            model.volume = [dict[@"volume"] floatValue];
            [futureList addObject:model];
        }
    }
    
    
    return future ? futureList : initialList;
}






//其实数据
-(NSMutableArray<KLineModel *> *)data_initial {
    NSMutableArray *result = [NSMutableArray array];
    NSMutableArray *filePathArr = [NSMutableArray array];
    NSString *filePath_0 = [[NSBundle mainBundle] pathForResource:@"2025-01-02--2025-01-03" ofType:@"json"];
    NSString *filePath_1 = [[NSBundle mainBundle] pathForResource:@"2025-01-03--2025-01-04" ofType:@"json"];
    [filePathArr addObject:filePath_0];
    [filePathArr addObject:filePath_1];
    
    NSArray *sortedPaths = [filePathArr sortedArrayUsingComparator:^NSComparisonResult(NSString *p1, NSString *p2) {
        return [[p1 lastPathComponent] localizedStandardCompare:[p2 lastPathComponent]];
    }];
    
    for (NSString *filePath in sortedPaths) {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        if (!data) continue;
        NSError *error;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (error) continue;
        NSArray *klineList = json[@"data"][@"kline_list"];
        for (NSDictionary *dict in klineList) {
            KLineModel *model = [[KLineModel alloc] init];
            model.open = [dict[@"open_price"] floatValue];
            model.high = [dict[@"high_price"] floatValue];
            model.low = [dict[@"low_price"] floatValue];
            model.close = [dict[@"close_price"] floatValue];
            model.timestamp = [dict[@"timestamp"] doubleValue];
            model.volume = [dict[@"volume"] floatValue];
            [result addObject:model];
        }
    }
    return result;
}

//读取 未来的k线数据
- (NSMutableArray<KLineModel *> *)data_future {
    NSMutableArray *result = [NSMutableArray array];
    NSArray *paths = [[NSBundle mainBundle] pathsForResourcesOfType:@"json" inDirectory:nil];
    NSArray *sortedPaths = [paths sortedArrayUsingComparator:^NSComparisonResult(NSString *p1, NSString *p2) {
        return [[p1 lastPathComponent] localizedStandardCompare:[p2 lastPathComponent]];
    }];

    for (NSString *filePath in sortedPaths) {
        if ([[filePath lastPathComponent] isEqualToString:@"2025-01-02--2025-01-03.json"] || [[filePath lastPathComponent] isEqualToString:@"2025-01-03--2025-01-04.json"]) {
            continue;
        }
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        if (!data) continue;
        NSError *error;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (error) continue;
        NSArray *klineList = json[@"data"][@"kline_list"];
        for (NSDictionary *dict in klineList) {
            KLineModel *model = [[KLineModel alloc] init];
            model.open = [dict[@"open_price"] floatValue];
            model.high = [dict[@"high_price"] floatValue];
            model.low = [dict[@"low_price"] floatValue];
            model.close = [dict[@"close_price"] floatValue];
            model.timestamp = [dict[@"timestamp"] doubleValue];
            model.volume = [dict[@"volume"] floatValue];
            [result addObject:model];
        }
    }
    return result;
}

// 左右滑动执行
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.tag == 20251204) { return; }
    self.chartView.contentOffsetX = scrollView.contentOffset.x;
}

@end






