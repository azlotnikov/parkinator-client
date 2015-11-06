//
//  MRTabBarController.m
//  parkinator
//
//  Created by Anton Zlotnikov on 06.11.15.
//  Copyright © 2015 Anton Zlotnikov. All rights reserved.
//

#import "MRTabBarController.h"
#import "MRPlacesTableViewController.h"
#import "MRNavigationController.h"

@interface MRTabBarController ()

@end

@implementation MRTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tabBar setTranslucent:NO];
    [self setExtendedLayoutIncludesOpaqueBars:YES];

    UIStoryboard *placesStoryboard = [UIStoryboard storyboardWithName:@"places" bundle:nil];
    MRPlacesTableViewController *placesTableViewController = [placesStoryboard instantiateViewControllerWithIdentifier:@"placesController"];
    MRNavigationController *placesNavigationController = [[MRNavigationController alloc] initWithRootViewController:placesTableViewController];
    [placesNavigationController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Места" image:nil selectedImage:nil]];

    [self setViewControllers:@[
            placesNavigationController
    ]];


}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end