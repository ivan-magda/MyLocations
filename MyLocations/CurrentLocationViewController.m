#import "CurrentLocationViewController.h"

@interface CurrentLocationViewController ()

@end

@implementation CurrentLocationViewController {
        //get location
    CLLocationManager *_locationManager;
    CLLocation        *_location;
    BOOL               _updatingLocation;
    NSError           *_lastLocationError;

        //reverse geocoding
    CLGeocoder *_geocoder; //is the object that will perform the geocoding
    CLPlacemark *_placemark; //is the object that contains the address results
    BOOL _performingReverseGeocoding; //set to YES when a geocoding operation is taking place
    NSError *_lastGeocodingError;
}

#pragma mark - View Controller LifeCycle -

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        _locationManager = [[CLLocationManager alloc]init];
        _geocoder = [[CLGeocoder alloc]init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self updateLabels];
    [self configureGetButton];
}

#pragma mark - IBActions -

    //If the button is pressed while the app is already doing the location fetching,
    //then stop the location manager.
    //Also clear out the old location, error, placemark, geoErr objects before start looking for a new location.
- (IBAction)getLocation:(id)sender {
    if (_updatingLocation) {
        [self stopLocationManager];
    } else {
        _location = nil;
        _lastLocationError = nil;
        _placemark = nil;
        _lastGeocodingError = nil;

        [self startLocationManager];
    }
    [self updateLabels];
    [self configureGetButton];
}

#pragma mark - Transition -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"TagLocation"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        
        LocationDetailsViewController *locationDetailsViewController = (LocationDetailsViewController *)navigationController.topViewController;

        locationDetailsViewController.coordinate = _location.coordinate;
        locationDetailsViewController.placemark  = _placemark;
        locationDetailsViewController.managedObjectContext = self.managedObjectContext;

        [self stopLocationManager];
    }
}

#pragma mark - CLLocationManagerDelegate -

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError %@", error);

    if (error.code == kCLErrorLocationUnknown) {
        return;
    }

    [self stopLocationManager];
    _lastLocationError = error;

    [self updateLabels];
    [self configureGetButton];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *newLocation = [locations lastObject];

    NSLog(@"didUpdateLocations %@", newLocation);

        //ignore these locations if they are too old.
    if ([newLocation.timestamp timeIntervalSinceNow] < -5.0) {
        return;
    }
        //if measurements are invalid ignore them.
    if (newLocation.horizontalAccuracy < 0) {
        return;
    }
        //calculates the distance between the new reading and the previous reading
    CLLocationDistance distance = MAXFLOAT;
    if (_location) {
        distance = [newLocation distanceFromLocation:_location];
    }

        //if the new reading coordinates is more useful than the previous one
        //larger accuracy value actually means less accurate
    if (_location == nil ||
        _location.horizontalAccuracy > newLocation.horizontalAccuracy) {

        _lastLocationError = nil;
        _location = newLocation;
        [self updateLabels];

        if (newLocation.horizontalAccuracy <= _locationManager.desiredAccuracy) {
            NSLog(@"We're done!");
            [self stopLocationManager];
            [self configureGetButton];

                //if distance is 0, then this location is the same as the location from
                //a previous reading and you don’t need to reverse geocode it anymore
            if (distance > 0) {
                _performingReverseGeocoding = NO;
            }
        }

        if (!_performingReverseGeocoding) {
            NSLog(@"*** Going to geocode");

            _performingReverseGeocoding = YES;

                //reverse geocode the location, and that the code in the block
                //following completionHandler should be executed as soon as the
                //geocoding is completed
            [_geocoder reverseGeocodeLocation:_location
                            completionHandler:^(NSArray *placemarks, NSError *error) {
                                NSLog(@"*** Found placemarks: %@, error: %@",placemarks, error);

                                _lastGeocodingError = error;
                                if (error == nil && [placemarks count] > 0) {
                                    _placemark = [placemarks lastObject];
                                } else {
                                    _placemark = nil;
                                }
                                
                                _performingReverseGeocoding = NO;
                                [self updateLabels];
                            }];
        }
            //If the coordinate from this reading is not significantly different from
            //the previous reading and it has been more than 10 seconds since you’ve
            //received that original reading, then it’s a good point to hang up your
            //hat and stop.
    } else if (distance < 1.0) {
        NSTimeInterval timeInterval = [newLocation.timestamp timeIntervalSinceDate:_location.timestamp];
        if (timeInterval > 10) {
            NSLog(@"*** Force done!");

            [self stopLocationManager];
            [self updateLabels];
            [self configureGetButton];
        }
    }
}

#pragma mark - UI methods -

- (NSString *)stringFromPlacemark:(CLPlacemark *)thePlacemark {
    return [NSString stringWithFormat:@"%@ %@\n%@ %@ %@",
            thePlacemark.subThoroughfare,    //is the house number
            thePlacemark.thoroughfare,       //is the street name
            thePlacemark.locality,           //is the city
            thePlacemark.administrativeArea, //is the state or province
            thePlacemark.postalCode          //is the zip code or postal code
            ];
}

- (void)updateLabels {
    if (_location) {
        self.latitudeLabel.text = [NSString stringWithFormat:@"%.8f", _location.coordinate.latitude];
        self.longitudeLabel.text = [NSString stringWithFormat:@"%.8f", _location.coordinate.longitude];
        self.tagButton.hidden = NO;
        self.messageLabel.text = @"";

        if (_placemark) {
            self.addressLabel.text = [self stringFromPlacemark:_placemark];
        } else if (_performingReverseGeocoding) {
            self.addressLabel.text = @"Searching for Address...";
        } else if (_lastGeocodingError) {
            self.addressLabel.text = @"Error Finding Address";
        } else {
            self.addressLabel.text = @"No Address Found";
        }
    } else {
        self.latitudeLabel.text  = @"";
        self.longitudeLabel.text = @"";
        self.addressLabel.text   = @"";
        self.tagButton.hidden = YES;

        NSString *statusMessage;
        if (_lastLocationError) {
            if ([_lastLocationError.domain isEqualToString: kCLErrorDomain] &&
                _lastLocationError.code == kCLErrorDenied) {
                statusMessage = @"Location Services Disabled";
            } else {
                statusMessage = @"Error Getting Location";
            }
        } else if (![CLLocationManager locationServicesEnabled]) {
            statusMessage = @"Location Services Disabled";
        } else if (_updatingLocation) {
            statusMessage = @"Searching...";
        } else {
            statusMessage = @"Press the Button to Start";
        }
        self.messageLabel.text = statusMessage;
    }
}

- (void)configureGetButton {
    if (_updatingLocation) {
        [self.getButton setTitle:@"Stop" forState:UIControlStateNormal];
    } else {
        [self.getButton setTitle:@"Get My Location" forState:UIControlStateNormal];
    }
}

#pragma mark - ConfigureLocationManager -

- (void)startLocationManager {
    if ([CLLocationManager locationServicesEnabled]) {
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;

        [_locationManager requestWhenInUseAuthorization];
        [_locationManager startUpdatingLocation];

        _updatingLocation = YES;

        [self performSelector:@selector(didTimeOut:) withObject:nil afterDelay:60];
    }
}

- (void)stopLocationManager {
    if (_updatingLocation) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(didTimeOut:) object:nil];

        [_locationManager stopUpdatingLocation];
        
        _locationManager.delegate = nil;
        _updatingLocation = NO;
    }
}

- (void)didTimeOut:(id)obj {
    NSLog(@"*** Time out");

    if (!_location) {
        [self stopLocationManager];

        _lastLocationError = [NSError errorWithDomain:@"MyLocationsErrorDomain"
                                                 code:1
                                             userInfo:nil];
        [self updateLabels];
        [self configureGetButton];
    }
}

@end