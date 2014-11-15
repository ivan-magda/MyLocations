#import <UIKit/UIKit.h>

@class NSManagedObjectContext;

@interface MapViewController : UIViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end