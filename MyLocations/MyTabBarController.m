#import "MyTabBarController.h"

@interface MyTabBarController ()

@end

@implementation MyTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

    //By returning nil from childViewControllerForStatusBarStyle, the tab bar controller will look at its own preferredStatusBarStyle method.
- (UIViewController *)childViewControllerForStatusBarStyle {
    return nil;
}

@end