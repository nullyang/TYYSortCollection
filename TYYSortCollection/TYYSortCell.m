

#import "TYYSortCell.h"
@interface TYYSortCell()
@property (weak, nonatomic) IBOutlet UILabel *label;

@end
@implementation TYYSortCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setText:(NSString *)text{
    _text = text;
    _label.text = text;
}

@end
