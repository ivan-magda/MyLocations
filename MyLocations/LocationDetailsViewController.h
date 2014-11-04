#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationDetailsViewController : UITableViewController

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) CLPlacemark *placemark;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
