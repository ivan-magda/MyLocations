#import "LocationsViewController.h"
#import "Location.h"

    //Frameworks
#import <CoreData/CoreData.h>


extern NSString * const ManagedObjectContextSaveDidFailNotification;
#define FATAL_CORE_DATA_ERROR(__error__)\
NSLog(@"*** Fatal error in %s:%d\n%@\n%@",\
__FILE__, __LINE__, error, [error userInfo]);\
[[NSNotificationCenter defaultCenter] postNotificationName:\
ManagedObjectContextSaveDidFailNotification object:error];


@interface LocationsViewController ()

@end

@implementation LocationsViewController {
    NSArray *_locations;
}

- (NSArray *)listOfLocationsObjects {
        //To retrieve an object that at the data store, need to create a fetch
        //request that describes the search parameters of the object.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc]init];

        //The NSEntityDescription tells the fetch request that you’re looking for Location entities.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];

        //The NSSortDescriptor tells the fetch request to sort on the date attribute, in ascending order.
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];

        //Tell the context to execute fetch request.
    NSError *error;
    NSArray *foundObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (!foundObjects) {
        FATAL_CORE_DATA_ERROR(error);
        return nil;
    }
    return foundObjects;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _locations = [self listOfLocationsObjects];
}

#pragma mark - UITableViewDataSource -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_locations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView
                             dequeueReusableCellWithIdentifier:@"Location"];

    Location *location = _locations[indexPath.row];

    UILabel *descriptionLabel = (UILabel *)[cell viewWithTag:100];
    descriptionLabel.text = location.locationDescription;

    UILabel *adressLabel = (UILabel *)[cell viewWithTag:101];
    adressLabel.text = [NSString stringWithFormat:@"%@ %@, %@",
                        location.placemark.subThoroughfare,
                        location.placemark.thoroughfare,
                        location.placemark.locality];

    return cell;
}

@end
