#import "Location.h"


@implementation Location

    //The @dynamic keyword tells the compiler that these properties will
    //be resolved at runtime by Core Data

@dynamic latitude;
@dynamic longitude;
@dynamic date;
@dynamic locationDescription;
@dynamic category;
@dynamic placemark;

@end
