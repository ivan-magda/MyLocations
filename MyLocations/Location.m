#import "Location.h"

@implementation Location

    //The @dynamic keyword tells the compiler that these properties will be resolved at runtime by Core Data

@dynamic latitude;
@dynamic longitude;
@dynamic photoId;
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

#pragma mark - Working with the photo file -

- (BOOL)hasPhoto {
    return (self.photoId) && ([self.photoId integerValue] != -1);
}

- (UIImage *)photoImage {
    NSAssert(self.photoId, @"No photo ID set");
    NSAssert([self.photoId integerValue] != -1, @"Photo ID is -1");

    return [UIImage imageWithContentsOfFile:[self photoPath]];
}

+ (NSInteger)nextPhotoId {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    NSInteger photoId = [userDefaults integerForKey:@"PhotoID"];
    [userDefaults setInteger:photoId + 1 forKey:@"PhotoID"];
    [userDefaults synchronize];

    return photoId;
}

- (void)removePhotoFile {
    NSString *path = [self photoPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error;
        if (![fileManager removeItemAtPath:path error:&error]) {
            NSLog(@"Error removing file: %@", error);
        }
    }
}

#pragma mark Full path to the JPEG file

- (NSString *)documentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths lastObject];
    return documentsDirectory;
}

- (NSString *)photoPath {
    NSString *fileName = [NSString stringWithFormat:@"Photo-%ld.jpg", (long)[self.photoId integerValue]];
    return [[self documentsDirectory]stringByAppendingPathComponent:fileName];
}

@end