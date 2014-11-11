    //Custom Classes
#import "LocationDetailsViewController.h"
#import "CategoryPickerViewController.h"
#import "HudView.h"
#import "Location.h"


extern NSString * const ManagedObjectContextSaveDidFailNotification;
#define FATAL_CORE_DATA_ERROR(__error__)\
    NSLog(@"*** Fatal error in %s:%d\n%@\n%@",\
      __FILE__, __LINE__, error, [error userInfo]);\
    [[NSNotificationCenter defaultCenter] postNotificationName:\
    ManagedObjectContextSaveDidFailNotification object:error];


#pragma mark - Class Extention

@interface LocationDetailsViewController () <UITextViewDelegate, UIImagePickerControllerDelegate,
                                             UINavigationControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, weak) IBOutlet UITextView *descriptionTextView;

@property (nonatomic, weak) IBOutlet UILabel *categoryLabel;
@property (nonatomic, weak) IBOutlet UILabel *latitudeLabel;
@property (nonatomic, weak) IBOutlet UILabel *longitudeLabel;
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *imageLabel;

@end

#pragma mark - Class Implementation

@implementation LocationDetailsViewController {
    NSString *_descriptionText;
    NSString *_categoryName;
    NSDate *_date;

    UIImage *_image;

    UIActionSheet *_actionSheet;
    UIImagePickerController *_imagePicker;
}

#pragma mark - ViewController Life Cycle -

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        _descriptionText = @"";
        _categoryName = @"No Category";
        _date = [NSDate date];

        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(applicationDidEnterBackground)
            name:UIApplicationDidEnterBackgroundNotification
            object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.locationToEdit) {
        self.title = @"Edit Location";
    }

    self.descriptionTextView.text = _descriptionText;
    self.categoryLabel.text = _categoryName;
    self.latitudeLabel.text = [NSString stringWithFormat:@"%.8f", self.coordinate.latitude];
    self.longitudeLabel.text = [NSString stringWithFormat: @"%.8f", self.coordinate.longitude];

    if (self.placemark != nil) {
        self.addressLabel.text = [self stringFromPlacemark:self.placemark];
    } else {
        self.addressLabel.text = @"No Address Found";
    }
    self.dateLabel.text = [self formatDate:_date];

    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideKeyboard:)];

    gestureRecognizer.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:gestureRecognizer];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - Respond to the Notifications -

- (void)applicationDidEnterBackground {
    if (_imagePicker) {
        [self dismissViewControllerAnimated:NO completion:nil];
        _imagePicker = nil;
    } else if (_actionSheet){
        [_actionSheet dismissWithClickedButtonIndex:_actionSheet.cancelButtonIndex animated:NO];
        _actionSheet = nil;
    }
    [self.descriptionTextView resignFirstResponder];
}

#pragma mark - Set Methods Override -

- (void)setLocationToEdit:(Location *)locationToEdit {
    if (_locationToEdit != locationToEdit) {
        _locationToEdit = locationToEdit;

        _descriptionText = _locationToEdit.locationDescription;
        _categoryName = _locationToEdit.category;
        _date = _locationToEdit.date;

        self.coordinate = CLLocationCoordinate2DMake(_locationToEdit.latitude.doubleValue, _locationToEdit.longitude.doubleValue);

        self.placemark = _locationToEdit.placemark;
    }
}

#pragma mark - UIImagePickerController -

- (void)showImage:(UIImage *)image {
    self.imageView.image = _image;
    self.imageView.hidden = NO;
    self.imageView.frame = CGRectMake(10, 10, 260, 260);
    self.imageLabel.hidden = YES;
}

- (void)takePhoto {
    _imagePicker = [[UIImagePickerController alloc]init];

    _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    _imagePicker.delegate = self;
    _imagePicker.allowsEditing = YES;

    [self presentViewController:_imagePicker animated:YES completion:nil];
}

- (void)choosePhotoFromLibrary {
    _imagePicker = [[UIImagePickerController alloc]init];

    _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    _imagePicker.delegate = self;
    _imagePicker.allowsEditing = YES;

    [self presentViewController:_imagePicker animated:YES completion:nil];
}

- (void)showPhotoMenu {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        _actionSheet = [[UIActionSheet alloc]
                                      initWithTitle:nil
                                      delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      destructiveButtonTitle:nil
                                      otherButtonTitles:@"Take Photo", @"Choose From Library", nil];

        [_actionSheet showInView:self.view];
    } else {
        [self choosePhotoFromLibrary];
    }
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    _image = info[UIImagePickerControllerEditedImage];

    [self showImage:_image];
    [self.tableView reloadData];

    [self dismissViewControllerAnimated:YES completion:nil];

    _imagePicker = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];

    _imagePicker = nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        return 88;
    } else if (indexPath.section == 1) {
        if (self.imageView.hidden) {
            return 44;
        } else {
            return 280;
        }
    } else if (indexPath.section == 2 && indexPath.row == 2) {
        CGRect rect = CGRectMake(100, 10, 205, 10000);
        self.addressLabel.frame = rect;
        [self.addressLabel sizeToFit];
        rect.size.height = self.addressLabel.frame.size.height;
        self.addressLabel.frame = rect;

        return self.addressLabel.frame.size.height + 20;
    } else {
        return 44;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 || indexPath.section == 1) {
        return indexPath;
    } else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        [self.descriptionTextView becomeFirstResponder];
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self showPhotoMenu];
    }
}

#pragma mark - Helper Methods -

- (NSString *)stringFromPlacemark:(CLPlacemark *)placemark {
    return [NSString stringWithFormat:@"%@ %@, %@, %@ %@, %@",
            placemark.subThoroughfare, placemark.thoroughfare, placemark.locality,
            placemark.administrativeArea, placemark.postalCode, placemark.country];
}

- (NSString *)formatDate:(NSDate *)theDate {
    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return [formatter stringFromDate:theDate];
}

- (void)hideKeyboard:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self.tableView];

    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];

    if (indexPath && indexPath.section == 0 && indexPath.row == 0) {
        return;
    }
    [self.descriptionTextView resignFirstResponder];
}

#pragma mark - IBActions -

- (IBAction)done:(id)sender {
    HudView *hudView = [HudView hudInView:self.navigationController.view animated:YES];

    Location *location = nil;
    if (self.locationToEdit) {
        hudView.text = @"Updated";
        location = self.locationToEdit;
    } else {
        hudView.text = @"Tagged";
        location = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:self.managedObjectContext];
    }

    location.locationDescription = _descriptionText;
    location.latitude  = @(self.coordinate.latitude);
    location.longitude = @(self.coordinate.longitude);
    location.category  = _categoryName;
    location.placemark = self.placemark;
    location.date = _date;

        //Save the contents of the context to the data store.
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        FATAL_CORE_DATA_ERROR(error);
        return;
    }

    [self performSelector:@selector(closeScreen) withObject:nil afterDelay:0.6];
}

- (IBAction)cancel:(id)sender {
    [self closeScreen];
}

- (void)closeScreen {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Unwind Segue

- (IBAction)categoryPickerDidPickCategory:(UIStoryboardSegue *)segue {
    CategoryPickerViewController *categoryPickerViewController = segue.sourceViewController;
    _categoryName = categoryPickerViewController.selectedCategoryName;
    self.categoryLabel.text = _categoryName;
}

#pragma mark - Navigation -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PickCategory"]) {
        CategoryPickerViewController *categoryPickerViewController = segue.destinationViewController;
        categoryPickerViewController.selectedCategoryName = _categoryName;
    }
}

#pragma mark - UITextView Delegate -

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    _descriptionText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    _descriptionText = textView.text;
}

#pragma mark - UIActionSheetDelegate -

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self takePhoto];
    } else if (buttonIndex == 1) {
        [self choosePhotoFromLibrary];
    }
    _actionSheet = nil;
}

@end