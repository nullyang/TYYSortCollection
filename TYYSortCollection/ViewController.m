

#import "ViewController.h"
#import "TYYSortCellCollectionView.h"
#import "TYYSortCell.h"

@interface ViewController ()<TYYSortCellCollectionViewDelegate,TYYSortCellCollectionViewDataSource>
@property (weak, nonatomic) IBOutlet TYYSortCellCollectionView *collectionView;
@property (nonatomic ,strong)NSArray *datas;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return self.datas.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.datas[section] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    TYYSortCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"sortCellId" forIndexPath:indexPath];
    cell.text = [self.datas[indexPath.section] objectAtIndex:indexPath.row];
    cell.backgroundColor = [UIColor colorWithRed:(arc4random()%255)/255.0f green:(arc4random()%255)/255.0f blue:(arc4random()%255)/255.0f alpha:1];
    return cell;
}

- (NSArray *)dataArrayInCollectionView:(TYYSortCellCollectionView *)collectionView{
    return self.datas;
}

- (void)sortCellCollectionView:(TYYSortCellCollectionView *)collectionView sortedDataArray:(NSArray *)sortedDataArray{
    self.datas = sortedDataArray;
}

- (NSArray *)datas{
    if (_datas) {
        return _datas;
    }
    NSMutableArray *datas = @[].mutableCopy;
    for (int section=0; section<2; section ++) {
        NSMutableArray *subDatas = @[].mutableCopy;
        for (int row=0; row<(section?40:30); row++) {
            [subDatas addObject:[NSString stringWithFormat:@"sec:%zd row%zd",section,row]];
        }
        [datas addObject:subDatas];
    }
    return datas.copy;
}

@end
