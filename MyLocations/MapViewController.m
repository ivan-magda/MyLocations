    //Custom Classes
#import "MapViewController.h"
#import "Location.h"
#import "LocationDetailsViewController.h"

    //Frameworks
#import <MapKit/MapKit.h>
#import <CoreData/CoreData.h>


extern NSString * const ManagedObjectContextSaveDidFailNotification;
#define FATAL_CORE_DATA_ERROR(__error__)\
NSLog(@"*** Fatal error in %s:%d\n%@\n%@",\
__FILE__, __LINE__, error, [error userInfo]);\
[[NSNotificationCenter defaultCenter] postNotificationName:\
ManagedObjectContextSaveDidFailNotification object:error];


@interface MapViewController () <MKMapViewDelegate, UINavigationBarDelegate>

@property (nonatomic, weak) IBOutlet MKMapView *mapView;

@end

@implementation MapViewController {
    NSArray *_locations;
}

#pragma mark - ViewController Life Cycle -

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateLocations];

    if ([_locations count] > 0) {
        [self showLocations:nil];
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [[NSNotificationCenter defaultCenter]addObserver:self
            selector:@selector(contextDidChange:)
            name:NSManagedObjectContextObjectsDidChangeNotification
            object:self.managedObjectContext];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - HelpMethods -

- (void)contextDidChange:(NSNotification *)notification {
    if ([self isViewLoaded]) {
        [self updateLocations];
    }
}

- (void)updateLocations {
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:self.managedObjectContext];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc]init];
    [fetchRequest setEntity:entity];

    NSError *error;
    NSArray *foundLocations = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (!foundLocations) {
        FATAL_CORE_DATA_ERROR(error);
        return;
    }

    if (_locations) {
        [self.mapView removeAnnotations:_locations];
    }

    _locations = foundLocations;
    [self.mapView addAnnotations:_locations];
}

#pragma mark - UINavigationBarDelegate -

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

#pragma mark - IBActions -

- (IBAction)showUser:(id)sender {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.coordinate, 1000, 1000);

    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
}

- (IBAction)showLocations:(id)sender {
    MKCoordinateRegion region = [self regionForAnnotations:_locations];

    [self.mapView setRegion:region animated:YES];
}

- (MKCoordinateRegion)regionForAnnotations:(NSArray *)annotations {
    MKCoordinateRegion region;

    if ([annotations count] == 0) {
        region = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.coordinate, 1000, 1000);
    } else if ([annotations count] == 1) {
        id<MKAnnotation> annotation = [annotations lastObject];
        region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 1000, 1000);
    } else {
        CLLocationCoordinate2D topLeftCoord;
        topLeftCoord.latitude = -90;
        topLeftCoord.longitude = 180;

        CLLocationCoordinate2D bottomRightCoord;
        bottomRightCoord.latitude = 90;
        bottomRightCoord.longitude = -180;

        for (id<MKAnnotation> anAnnotation in annotations) {
            topLeftCoord.latitude = fmax(topLeftCoord.latitude,
                                         anAnnotation.coordinate.latitude);

            topLeftCoord.longitude = fmin(topLeftCoord.longitude,
                                          anAnnotation.coordinate.longitude);

            bottomRightCoord.latitude = fmin( bottomRightCoord.latitude,
                                             anAnnotation.coordinate.latitude);

            bottomRightCoord.longitude = fmax( bottomRightCoord.longitude,
                                              anAnnotation.coordinate.longitude);
        }
        const double extraSpace = 1.5;

        region.center.latitude = topLeftCoord.latitude -
                        (topLeftCoord.latitude - bottomRightCoord.latitude) / 2.0;

        region.center.longitude = topLeftCoord.longitude -
                        (topLeftCoord.longitude - bottomRightCoord.longitude) / 2.0;

        region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * extraSpace;

        region.span.longitudeDelta = fabs(topLeftCoord.longitude - bottomRightCoord.longitude) * extraSpace;
    }
    return [self.mapView regionThatFits:region];
}

#pragma mark - MKMapViewDelegate -

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[Location class]]) {
        static NSString *identifier = @"Location";
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (!annotationView) {
            annotationView = [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:identifier];

            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.animatesDrop = NO;
            annotationView.pinColor = MKPinAnnotationColorGreen;
            annotationView.tintColor = [UIColor colorWithWhite:0.0f alpha:0.5f];

            UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [rightButton addTarget:self
                            action:@selector(showLocationDetails:)
                  forControlEvents:UIControlEventTouchUpInside];
            annotationView.rightCalloutAccessoryView = rightButton;
        } else {
            annotationView.annotation = annotation;
        }
        UIButton *button = (UIButton *)annotationView.rightCalloutAccessoryView;
        button.tag = [_locations indexOfObject:(Location *)annotation];

        return annotationView;
    }
    return nil;
}

- (void)showLocationDetails:(UIButton *)button {
    [self performSegueWithIdentifier:@"EditLocation" sender:button];
}

#pragma mark - Navigation -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"EditLocation"]) {
        UINavigationController *navigationController = segue.destinationViewController;

        LocationDetailsViewController *controller = (LocationDetailsViewController *)navigationController.topViewController;

        controller.managedObjectContext = self.managedObjectContext;

        UIButton *button = (UIButton *)sender;
        Location *location = _locations[button.tag];
        controller.locationToEdit = location;
    }
}

@end