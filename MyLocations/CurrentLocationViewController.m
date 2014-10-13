#import "CurrentLocationViewController.h"

@interface CurrentLocationViewController ()

@end

@implementation CurrentLocationViewController {
    CLLocationManager *_locationManager;
    CLLocation        *_location;
    BOOL               _updatingLocation;
    NSError           *_lastLocationError;

        //reverse coding
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
    //also clear out the old location and error objects before start looking for a new location.
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

        //if the new reading coordinates is more useful than the previous one
        //larger accuracy value actually means less accurate
    if (_location == nil || _location.horizontalAccuracy > newLocation.horizontalAccuracy) {
        _lastLocationError = nil;
        _location = newLocation;
        [self updateLabels];

        if (newLocation.horizontalAccuracy <= _locationManager.desiredAccuracy) {
            NSLog(@"We're done!");
            [self stopLocationManager];
            [self configureGetButton];
        }

        if (!_performingReverseGeocoding) {
            NSLog(@"*** Going to geocode");

            _performingReverseGeocoding = YES;

                //reverse geocode the location, and that the code in the block
                //following completionHandler should be executed as soon as the
                //geocoding is completed
            [_geocoder reverseGeocodeLocation:_location
                            completionHandler:
             ^(NSArray *placemarks, NSError *error) {
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
    }
}

- (NSString *)stringFromPlacemark:(CLPlacemark *)thePlacemark {
    return [NSString stringWithFormat:@"%@ %@\n%@ %@ %@",
            thePlacemark.subThoroughfare,
            thePlacemark.thoroughfare,
            thePlacemark.locality,
            thePlacemark.administrativeArea,
            thePlacemark.postalCode];
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

- (void)startLocationManager {
    if ([CLLocationManager locationServicesEnabled]) {
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        [_locationManager requestWhenInUseAuthorization];
        [_locationManager startUpdatingLocation];
        _updatingLocation = YES;
    }
}

- (void)stopLocationManager {
    if (_updatingLocation) {
        [_locationManager stopUpdatingLocation];
        _locationManager.delegate = nil;
        _updatingLocation = NO;
    }
}

@end
