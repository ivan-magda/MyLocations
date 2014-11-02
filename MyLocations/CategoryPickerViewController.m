#import "CategoryPickerViewController.h"

@implementation CategoryPickerViewController {
    NSArray *_categories;
    NSIndexPath *_selectedIndexPath;
}

#pragma mark - View Controller Life Cycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    _categories = @[
                    @"No Category",
                    @"Apple Store",
                    @"Bar",
                    @"Bookstore",
                    @"Club",
                    @"Grocery Store",
                    @"Historic Building",
                    @"House",
                    @"Icecream Vendor",
                    @"Landmark",
                    @"Park"
                    ];
}

#pragma mark - UITableViewDataSource -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_categories count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *tableViewCell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    NSString *categoryName = _categories[indexPath.row];
    tableViewCell.textLabel.text = categoryName;

    if ([categoryName isEqualToString:self.selectedCategoryName]) {
        tableViewCell.accessoryType = UITableViewCellAccessoryCheckmark;
        _selectedIndexPath = indexPath;
    } else {
        tableViewCell.accessoryType = UITableViewCellAccessoryNone;
    }
    return tableViewCell;
}

#pragma mark - UITableViewDelegate -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.row != _selectedIndexPath.row) {
        UITableViewCell *newCell = [tableView cellForRowAtIndexPath:indexPath];
        newCell.accessoryType = UITableViewCellAccessoryCheckmark;

        UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:_selectedIndexPath];
        oldCell.accessoryType = UITableViewCellAccessoryNone;

        _selectedIndexPath = indexPath;
    }
}

#pragma mark - Unwind Segue -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PickedCategory"]) {
        UITableViewCell *cell = sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        _selectedCategoryName = _categories[indexPath.row];
    }
}


@end