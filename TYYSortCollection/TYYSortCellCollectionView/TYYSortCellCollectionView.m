

#import "TYYSortCellCollectionView.h"
#import <math.h>

typedef NS_ENUM(NSUInteger, TYYSortCollectionViewScrollDirection) {
    TYYSortCollectionViewScrollDirectionNone = 0,
    TYYSortCollectionViewScrollDirectionLeft,
    TYYSortCollectionViewScrollDirectionRight,
    TYYSortCollectionViewScrollDirectionUp,
    TYYSortCollectionViewScrollDirectionDown
};

@interface TYYSortCellCollectionView ()
@property (nonatomic, strong) NSIndexPath *startIndexPath;
@property (nonatomic, strong) NSIndexPath *moveIndexPath;
@property (nonatomic, weak) UIView *tempMoveCell;
@property (nonatomic, weak) UILongPressGestureRecognizer *longPressGesture;
@property (nonatomic, strong) CADisplayLink *edgeTimer;
@property (nonatomic, assign) TYYSortCollectionViewScrollDirection scrollDirection;
@property (nonatomic, assign) CGFloat oldMinPressDuration;
@property (nonatomic ,assign)CGPoint lastPoint;
@property (nonatomic, assign) BOOL sorting;
@end

@implementation TYYSortCellCollectionView

@dynamic delegate;
@dynamic dataSource;

#pragma mark - initailize methods

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(nonnull UICollectionViewLayout *)layout{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        self.minPressDuration = 1;
        self.edgeScrollEable = YES;
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
        self.longPressGesture = longPress;
        longPress.minimumPressDuration = self.minPressDuration;
        [self addGestureRecognizer:longPress];
    }
    return self;
}

- (void)awakeFromNib{
    [super awakeFromNib];
    self.minPressDuration = 1;
    self.edgeScrollEable = YES;
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    self.longPressGesture = longPress;
    longPress.minimumPressDuration = self.minPressDuration;
    [self addGestureRecognizer:longPress];
}

#pragma mark - longPressGesture methods

- (void)longPressed:(UILongPressGestureRecognizer *)longPressGesture{
    if (longPressGesture.state == UIGestureRecognizerStateBegan) {
        [self gestureBegan:longPressGesture];
    }
    if (longPressGesture.state == UIGestureRecognizerStateChanged) {
        [self gestureChange:longPressGesture];
    }
    if (longPressGesture.state == UIGestureRecognizerStateCancelled ||
        longPressGesture.state == UIGestureRecognizerStateEnded){
        [self gestureEndOrCancle:longPressGesture];
    }
}

- (void)gestureBegan:(UILongPressGestureRecognizer *)longPressGesture{
    //获取手指所在的cell
    self.startIndexPath = [self indexPathForItemAtPoint:[longPressGesture locationOfTouch:0 inView:longPressGesture.view]];
    UICollectionViewCell *cell = [self cellForItemAtIndexPath:self.startIndexPath];
    UIView *tempMoveCell = [cell snapshotViewAfterScreenUpdates:NO];
    cell.hidden = YES;
    self.tempMoveCell = tempMoveCell;
    self.tempMoveCell.frame = cell.frame;
    [self addSubview:self.tempMoveCell];
    
    //开启边缘滚动定时器
    [self startEdgeTimer];
    self.lastPoint = [longPressGesture locationOfTouch:0 inView:longPressGesture.view];
}

- (void)gestureChange:(UILongPressGestureRecognizer *)longPressGesture{
    CGFloat tranX = [longPressGesture locationOfTouch:0 inView:longPressGesture.view].x - self.lastPoint.x;
    CGFloat tranY = [longPressGesture locationOfTouch:0 inView:longPressGesture.view].y - self.lastPoint.y;
    self.tempMoveCell.center = CGPointApplyAffineTransform(self.tempMoveCell.center, CGAffineTransformMakeTranslation(tranX, tranY));
    self.lastPoint = [longPressGesture locationOfTouch:0 inView:longPressGesture.view];
    [self moveCell];
}

- (void)gestureEndOrCancle:(UILongPressGestureRecognizer *)longPressGesture{
    UICollectionViewCell *cell = [self cellForItemAtIndexPath:self.startIndexPath];
    self.userInteractionEnabled = NO;
    [self stopEdgeTimer];
    [UIView animateWithDuration:0.25 animations:^{
        self.tempMoveCell.center = cell.center;
    } completion:^(BOOL finished) {
        [self.tempMoveCell removeFromSuperview];
        cell.hidden = NO;
        self.userInteractionEnabled = YES;
    }];
}

#pragma mark - setter methods

- (void)setMinPressDuration:(NSTimeInterval)minPressDuration{
    _minPressDuration = minPressDuration;
    self.longPressGesture.minimumPressDuration = minPressDuration;
}

#pragma mark - timer methods

- (void)startEdgeTimer{
    if (!self.edgeTimer && self.edgeScrollEable) {
        self.edgeTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(edgeScroll)];
        [self.edgeTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)stopEdgeTimer{
    if (self.edgeTimer) {
        [self.edgeTimer invalidate];
        self.edgeTimer = nil;
    }
}


#pragma mark - private methods

- (void)moveCell{
    for (UICollectionViewCell *cell in [self visibleCells]) {
        if ([self indexPathForCell:cell] == self.startIndexPath) {
            continue;
        }
        //计算中心距
        CGFloat spacingX = fabs(self.tempMoveCell.center.x - cell.center.x);
        CGFloat spacingY = fabs(self.tempMoveCell.center.y - cell.center.y);
        if (spacingX <= self.tempMoveCell.bounds.size.width / 2.0f && spacingY <= self.tempMoveCell.bounds.size.height / 2.0f) {
            self.moveIndexPath = [self indexPathForCell:cell];
            //更新数据源
            [self updateDataSource];
            //移动
            [self moveItemAtIndexPath:self.startIndexPath toIndexPath:self.moveIndexPath];
            //设置移动后的起始indexPath
            self.startIndexPath = self.moveIndexPath;
            break;
        }
    }
}

- (void)updateDataSource{
    NSMutableArray *temp = @[].mutableCopy;
    if ([self.dataSource respondsToSelector:@selector(dataArrayInCollectionView:)]) {
        temp = [[self.dataSource dataArrayInCollectionView:self] mutableCopy];
    }
    //判断是单个section还是多个嵌套
    BOOL multipleSection = ([self numberOfSections] != 1 || ([self numberOfSections] == 1 && [temp[0] isKindOfClass:[NSArray class]]));
    if (multipleSection) {
        for (int i = 0; i < temp.count; i ++) {
            [temp replaceObjectAtIndex:i withObject:[temp[i] mutableCopy]];
        }
    }
    if (self.moveIndexPath.section == self.startIndexPath.section) {
        NSMutableArray *orignalSection = multipleSection ? temp[self.startIndexPath.section] : temp;
        if (self.moveIndexPath.item > self.startIndexPath.item) {
            for (NSUInteger i = self.startIndexPath.item; i < self.moveIndexPath.item ; i ++) {
                [orignalSection exchangeObjectAtIndex:i withObjectAtIndex:i + 1];
            }
        }else{
            for (NSUInteger i = self.startIndexPath.item; i > self.moveIndexPath.item ; i --) {
                [orignalSection exchangeObjectAtIndex:i withObjectAtIndex:i - 1];
            }
        }
    }else{
        NSMutableArray *orignalSection = temp[self.startIndexPath.section];
        NSMutableArray *currentSection = temp[self.moveIndexPath.section];
        [currentSection insertObject:orignalSection[self.startIndexPath.item] atIndex:self.moveIndexPath.item];
        [orignalSection removeObject:orignalSection[self.startIndexPath.item]];
    }
    //将重排好的数据传递给外部
    if ([self.delegate respondsToSelector:@selector(sortCellCollectionView:sortedDataArray:)]) {
        [self.delegate sortCellCollectionView:self sortedDataArray:temp.copy];
    }
}

- (void)edgeScroll{
    [self makeScrollDirection];
    CGFloat x = self.lastPoint.x;
    CGFloat y = self.lastPoint.y;
    switch (self.scrollDirection) {
        case TYYSortCollectionViewScrollDirectionLeft:{
            //这里的动画必须设为NO
            [self setContentOffset:CGPointMake(self.contentOffset.x - 4, self.contentOffset.y) animated:NO];
            self.tempMoveCell.center = CGPointMake(self.tempMoveCell.center.x - 4, self.tempMoveCell.center.y);
            self.lastPoint = CGPointMake(x - 4, y);
            
        }
            break;
        case TYYSortCollectionViewScrollDirectionRight:{
            [self setContentOffset:CGPointMake(self.contentOffset.x + 4, self.contentOffset.y) animated:NO];
            self.tempMoveCell.center = CGPointMake(self.tempMoveCell.center.x + 4, self.tempMoveCell.center.y);
            self.lastPoint = CGPointMake(x+4, y);
            
        }
            break;
        case TYYSortCollectionViewScrollDirectionUp:{
            [self setContentOffset:CGPointMake(self.contentOffset.x, self.contentOffset.y - 4) animated:NO];
            self.tempMoveCell.center = CGPointMake(self.tempMoveCell.center.x, self.tempMoveCell.center.y - 4);
            self.lastPoint = CGPointMake(x, y-4);
        }
            break;
        case TYYSortCollectionViewScrollDirectionDown:{
            [self setContentOffset:CGPointMake(self.contentOffset.x, self.contentOffset.y + 4) animated:NO];
            self.tempMoveCell.center = CGPointMake(self.tempMoveCell.center.x, self.tempMoveCell.center.y + 4);
            self.lastPoint = CGPointMake(x, y+4);
        }
            break;
        default:
            break;
    }
}

- (void)makeScrollDirection{
    self.scrollDirection = TYYSortCollectionViewScrollDirectionNone;
    if (self.bounds.size.height + self.contentOffset.y - self.tempMoveCell.center.y < self.tempMoveCell.bounds.size.height / 2 && self.bounds.size.height + self.contentOffset.y < self.contentSize.height) {
        self.scrollDirection = TYYSortCollectionViewScrollDirectionDown;
    }
    if (self.tempMoveCell.center.y - self.contentOffset.y < self.tempMoveCell.bounds.size.height / 2 && self.contentOffset.y > 0) {
        self.scrollDirection = TYYSortCollectionViewScrollDirectionUp;
    }
    if (self.bounds.size.width + self.contentOffset.x - self.tempMoveCell.center.x < self.tempMoveCell.bounds.size.width / 2 && self.bounds.size.width + self.contentOffset.x < self.contentSize.width) {
        self.scrollDirection = TYYSortCollectionViewScrollDirectionRight;
    }
    
    if (self.tempMoveCell.center.x - self.contentOffset.x < self.tempMoveCell.bounds.size.width / 2 && self.contentOffset.x > 0) {
        self.scrollDirection = TYYSortCollectionViewScrollDirectionLeft;
    }
}


#pragma mark - hittest
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    NSIndexPath *indexpath = [self indexPathForItemAtPoint:point];
    self.longPressGesture.enabled = indexpath != nil;
    return [super hitTest:point withEvent:event];
}

@end
