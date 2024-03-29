//
//  MRPlacesTableViewController.m
//  parkinator
//
//  Created by Anton Zlotnikov on 06.11.15.
//  Copyright © 2015 Anton Zlotnikov. All rights reserved.
//

#import "MRPlacesTableViewController.h"
#import "MBProgressHUD.h"
#import "MRClusterRenderer.h"
#import "HSClusterMarker.h"
#import "MRAppDataProvider.h"
#import "MRPlaceService.h"
#import "MRUserData.h"
#import "MRPlace.h"
#import "MRPlaceMarker.h"
#import "MRPlaceTableViewCell.h"
#import "MRPlaceViewController.h"
#import <SCLAlertView-Objective-C/SCLAlertView.h>
#import "MRCreatePlaceViewController.h"
#import "MRNavigationController.h"

@interface MRPlacesTableViewController ()

@end

@implementation MRPlacesTableViewController {
    UIRefreshControl* refreshControl;
    CLLocationManager *locationManager;
    CGFloat prevZoom;
    BOOL mapShown;
    BOOL firstLoad;
    NSMutableArray *items;
    NSMutableArray *itemsCopy;
    CLLocation *currentLocation;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    firstLoad = YES;

    [self clearItems];

    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self hideNavBarUnderLine:YES];
    [self.toolBar setDelegate:self];
    prevZoom = 12;
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:43.1
                                                            longitude:131.9
                                                                 zoom:prevZoom];
    mapShown = NO;
    MRClusterRenderer *clusterRenderer = [MRClusterRenderer new];
    self.mapView = [[HSClusterMapView alloc] initWithFrame:self.view.frame renderer:clusterRenderer];
    [self.mapView setHidden:YES];
    [self.mapView setCamera:camera];
    [self.mapView setDelegate:self];
    [self.mapView setClusterSize:0.11];
    [self.mapView setMinimumMarkerCountPerCluster:2];
    [self.mapView setClusteringEnabled:YES];
    [self.view addSubview:self.mapView];
//    [self.view bringSubviewToFront:self.tableView];
    [self.view bringSubviewToFront:self.toolBar];

    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@""]];
    [refreshControl addTarget:self action: @selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];

    locationManager = [[CLLocationManager alloc] init];
    MRAppDataShared.locationManager = locationManager;
    [locationManager setDistanceFilter:kCLDistanceFilterNone];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [locationManager setDelegate:self];
    [locationManager startUpdatingLocation];
    [locationManager requestWhenInUseAuthorization]; // Add This Line

    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendCoordsInfo) userInfo:nil repeats:YES];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)sendCoordsInfo {
    if (firstLoad) {
        return;
    }
    if ([[MRAppDataShared userData] acceptedContractId] || [[MRAppDataShared userData] initiatedContractId]) {
        [[MRAppDataShared placeService] sendCoordsWithLat:@(currentLocation.coordinate.latitude)
                                                   andLon:@(currentLocation.coordinate.longitude)
                                                    block:^(){

                                                    }];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"didUpdateToLocation: %@", newLocation);
    currentLocation = newLocation;
    if (firstLoad) {
        firstLoad = NO;
        [self loadItemsFromServer];
    }

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self hideNavBarUnderLine:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    [self hideNavBarUnderLine:NO];
    if (self.isMovingFromParentViewController) {
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    }
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return  UIBarPositionTop; //or UIBarPositionTopAttached
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)hideNavBarUnderLine:(BOOL)hide {
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        for (UIView *view2 in view.subviews) {
            if ([view2 isKindOfClass:[UIImageView class]] && view2.frame.size.height < 2) {
                [view2 setHidden:hide];
            }
        }
    }
}

- (void)showAlertForError:(NSError *)error {
    NSLog(@"%@", [error localizedDescription]);
    SCLAlertView *newAlert = [[SCLAlertView alloc] init];
    [newAlert showError:self.tabBarController title:@"Ошибка" subTitle:[error localizedDescription] closeButtonTitle:@"Закрыть" duration:0.0f];
}


- (void)clearItems {
    items = [NSMutableArray new];
    [self.tableView reloadData];
}

- (void)refreshTable {
    [self loadItemsFromServer];
    [refreshControl endRefreshing];
}

- (void)loadItemsFromServer {
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    [MRAppDataShared.placeService loadPlacesWithLat:@(currentLocation.coordinate.latitude)
                                             andLon:@(currentLocation.coordinate.longitude)
                                         andCarType:MRAppDataShared.userData.carType
                                              block:^(NSError *error, NSArray *newItems) {
                                                  [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
                                                  if (!error) {
                                                      items = [newItems mutableCopy];
                                                      [self.tableView reloadData];
                                                      [self.mapView clear];
                                                      for (MRPlace *place in items) {
                                                          MRPlaceMarker *marker = [MRPlaceMarker markerWithPosition:CLLocationCoordinate2DMake([place.lat doubleValue], [place.lon doubleValue])];
                                                          [marker setAppearAnimation:kGMSMarkerAnimationPop];
                                                          [marker setPlace:place];
                                                          [marker setIcon:[UIImage imageNamed:@"marker"]];
                                                          [self.mapView addMarker:marker];
                                                      }
                                                      [self.mapView cluster];
                                                  } else {
                                                      [self showAlertForError:error];
                                                  }

                                              }];

}


#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
//    return 0;
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [items count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 74;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MRPlaceTableViewCell *cell = (MRPlaceTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"placeCell" forIndexPath:indexPath];
    
    MRPlace *place = items[indexPath.row];
    [cell.addressLabel setText:place.address];
    [cell.distanceLabel setText:[NSString stringWithFormat:@"%0.3gкм", [place.dist doubleValue] / 1000.0]];
    [cell.priceLabel setText:[NSString stringWithFormat:@"%@", place.price]];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[place.leaveDt longValue]];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"HH:mm"];
    NSString *leaveDtStr = [format stringFromDate:date];

    [cell.timeLabel setText:[NSString stringWithFormat:@"%@", leaveDtStr]];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    MRPlace *place = items[indexPath.row];
    MRPlaceViewController *placeViewController = [[MRPlaceViewController alloc] init];
    [placeViewController setPlace:place];
    [self.navigationController pushViewController:placeViewController animated:YES];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)mapView:(GMSMapView *)mV didChangeCameraPosition:(GMSCameraPosition *)position {
    if (position.zoom != prevZoom) {
        prevZoom = position.zoom;
        [self.mapView cluster];
    }
}

- (BOOL)mapView:(GMSMapView *)mV didTapMarker:(GMSMarker *)marker {
    if ([marker isKindOfClass:[HSClusterMarker class]]) {
        items = [NSMutableArray new];
        for (MRPlaceMarker *placeMarker in ((HSClusterMarker *)marker).markersInCluster) {
            [items addObject:placeMarker.place];
        }
    } else if ([marker isKindOfClass:[MRPlaceMarker class]]) {
        items = [@[((MRPlaceMarker *)marker).place] mutableCopy];
    }
    [self.tableView reloadData];
    if (self.tableView.hidden) {
        [self.tableView setHidden:NO];
        [UIView animateWithDuration:1 //this is the length of time the animation will take
                         animations:^{
                             self.mapView.frame = CGRectMake(
                                     self.mapView.frame.origin.x,
                                     self.toolBar.frame.origin.y + self.toolBar.frame.size.height,
                                     self.mapView.frame.size.width,
                                     200
                             );

                         }
                         completion:^(BOOL finished) {

                         }];
    }
    return NO;
}

- (void)mapView:(GMSMapView *)mV didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    [UIView animateWithDuration:1 //this is the length of time the animation will take
                     animations:^{
                         self.mapView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - 40, self.view.frame.size.width, self.view.frame.size.height);
                     }
                     completion:^(BOOL finished){
                         [self.tableView setHidden:YES];
                         items = itemsCopy;
                     }];

}

- (IBAction)viewTypeSegmentChange:(UISegmentedControl *)sender {
    mapShown = !mapShown;
    [self.mapView setHidden:!mapShown];
    [self.tableView setHidden:mapShown];

    [MBProgressHUD hideHUDForView:self.navigationController.view animated:NO];
    if (!mapShown) {
        items = itemsCopy;
        self.tableViewTopConstaint.constant = 44.0f;
    } else {
        itemsCopy = items;
        self.tableViewTopConstaint.constant = 200.0f + 44.0f;
    }
    self.mapView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - 40, self.view.frame.size.width, self.view.frame.size.height);
    [self.tableView setNeedsLayout];
    [self.tableView reloadData];
}

- (IBAction)createPlaceAction:(id)sender {
    MRCreatePlaceViewController  *createViewController = [[UIStoryboard storyboardWithName:@"addPlace" bundle:nil] instantiateViewControllerWithIdentifier:@"placesController"];
    MRNavigationController *placesNavigationController = [[MRNavigationController alloc] initWithRootViewController:createViewController];
    [self presentViewController:placesNavigationController animated:YES completion:^{
        //
    }];
}

@end
