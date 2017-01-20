

#import <UIKit/UIKit.h>
@class TYYSortCellCollectionView;

@protocol  TYYSortCellCollectionViewDelegate<UICollectionViewDelegate>

@required
// 排序后，须将返回的新数据源，设置为当前collectionview的数据源
// sortedDataArray 排序后新的数据源
- (void)sortCellCollectionView:(TYYSortCellCollectionView *)collectionView sortedDataArray:(NSArray *)sortedDataArray;

@optional

// 在这里，可以根据具体的业务来添加其他协议方法

@end

@protocol  TYYSortCellCollectionViewDataSource<UICollectionViewDataSource>

@required

// 返回整个CollectionView的数据,排序时，会在内部对这个数据排序
- (NSArray *)dataArrayInCollectionView:(TYYSortCellCollectionView *)collectionView;

@end

@interface TYYSortCellCollectionView : UICollectionView

@property (nonatomic, assign) id<TYYSortCellCollectionViewDelegate> delegate;
@property (nonatomic, assign) id<TYYSortCellCollectionViewDataSource> dataSource;

// 长按触发拖动的时间，默认1秒，如果设置为0，立即触发
@property (nonatomic, assign) NSTimeInterval minPressDuration;

// 是否开启拖动到边缘滚动CollectionView的功能，默认YES
@property (nonatomic, assign) BOOL edgeScrollEable;

// 是否正在排序
@property (nonatomic, assign, readonly, getter=isSorting) BOOL sorTing;

@end
