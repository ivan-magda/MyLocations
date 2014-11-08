#import "Location.h"

@implementation Location

    //The @dynamic keyword tells the compiler that these properties will be resolved at runtime by Core Data

@dynamic latitude;
@dynamic longitude;
@dynamic date;
@dynamic locationDescription;
@dynamic category;
@dynamic placemark;

#pragma mark - MKAnnotationProtocol -

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
}

- (NSString *)title {
    if ([self.locationDescription length] > 0) {
        return self.locationDescription;
    }
    return @"(No Description)";
}

- (NSString *)subtitle {
    return self.category;
}

@end
