//
//  ZZViewController.m
//  ShareLocation
//
//  Created by zhuzhi on 13-8-29.
//  Copyright (c) 2013年 ZZ. All rights reserved.
//

#import "ZZViewController.h"

#import <GoogleMaps/GoogleMaps.h>
#import "Foursquare2.h"
#import "FSConverter.h"
#import "FSVenue.h"

@interface ZZViewController ()<UITableViewDelegate,UITableViewDataSource,GMSMapViewDelegate>
{
    GMSMapView         *_mapView;
    UITableView        *_tableView;
    
    NSArray            *_nearbyVenues;
    
    __block BOOL       _searching;
}
  
@end

@implementation ZZViewController

- (id)init{
    self = [super init];
    if (self) {
        _nearbyVenues = [NSArray array];
        _searching = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Foursquare2 setupFoursquareWithKey:@"NUZ2K43IMYXBDVJTH0OUFK0ZE43TERMCIZVEQFBUKG44MNXE" secret:@"X3LGLUM1OYKUGZ0UNKHWIT1BFGCKQC1P0M33YMKPTJFWEBI0" callbackURL:@""];
    
    [self setUpUI];
}

- (void)setUpUI{
    self.title = NSLocalizedString(@"Send Location", nil);
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    _mapView = [[GMSMapView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 194.0f)];
    _mapView.myLocationEnabled = YES;
    [_mapView addObserver:self
               forKeyPath:@"myLocation"
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    _mapView.delegate = self;
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0f, CGRectGetMaxY(_mapView.frame), 320.0f, self.view.frame.size.height - 194.0f)];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.delegate = self;
    _tableView.dataSource = self;
        
    [self.view addSubview:_mapView];
    [self.view addSubview:_tableView];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _mapView.myLocationEnabled = YES;
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    [_mapView removeObserver:self
                  forKeyPath:@"myLocation"
                     context:NULL];
}

- (void)refresh{
    dispatch_async(dispatch_get_main_queue(), ^{
        _mapView.myLocationEnabled = NO;
        _mapView.myLocationEnabled = YES;
    });
}

-(void)getVenuesForLocation:(CLLocation*)location{
    [Foursquare2 searchVenuesNearByLatitude:@(location.coordinate.latitude)
								  longitude:@(location.coordinate.longitude)
								 accuracyLL:nil
								   altitude:nil
								accuracyAlt:nil
									  query:nil
									  limit:nil
									 intent:intentCheckin
                                     radius:@(500)
                                 categoryId:nil
								   callback:^(BOOL success, id result){
                                       _searching = NO;
									   if (success) {
										   NSDictionary *dic = result;
										   NSArray* venues = [dic valueForKeyPath:@"response.venues"];
                                           FSConverter *converter = [[FSConverter alloc]init];
                                           _nearbyVenues = [converter convertToObjects:venues];
                                           [_tableView reloadData];
									   }
								   }];
}

#pragma mark - KVO updates

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    CLLocation *location = [change objectForKey:NSKeyValueChangeNewKey];
    _mapView.camera = [GMSCameraPosition cameraWithTarget:location.coordinate
                                                         zoom:14];
    [self getVenuesForLocation:location];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_searching || [_nearbyVenues count] == 0) {
        return 3;
    }
    
    return [_nearbyVenues count] + 2 ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier1 = @"Cell1";
    static NSString *CellIdentifier2 = @"Cell2";
    static NSString *CellIdentifier3 = @"Cell3";
    static NSString *CellIdentifier4 = @"Cell4";
    
    FSVenue *venue;
    
    UITableViewCell *cell;
    if (indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier1];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_used_lbs_icon"]];
            [cell.contentView addSubview:imageView];
            CGPoint center = CGPointMake(280,25);
            imageView.center = center;
        }
    }
    else if(indexPath.row == 1)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier2];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UIImageView *sectionView = [[UIImageView alloc] initWithFrame:CGRectZero];
            sectionView.frame = CGRectMake(0, -2, 300, 24);
            sectionView.image = [UIImage imageNamed:@"category_bar"];
            [cell.contentView addSubview:sectionView];
        }
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.text = NSLocalizedString(@"Nearby places", nil);
        return cell;
    }
    else if(indexPath.row == 2)
    {
        if (_searching) {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier3];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier3];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                UIActivityIndicatorView *acview = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                [acview startAnimating];
                acview.center = CGPointMake(280, 25);
                [cell.contentView addSubview:acview];
            }
            cell.textLabel.text = NSLocalizedString(@"Loading...", nil);
            
            cell.textLabel.backgroundColor = [UIColor clearColor];
            return cell;
        }
        else{
            if ([_nearbyVenues count] ==0) {
                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier3];
                if (cell == nil) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier3];
                }
                cell.textLabel.text = NSLocalizedString(@"No nearby places", nil);
                return cell;
            }
            else{
                if (indexPath.row - 2 < [_nearbyVenues count]) {
                    venue = [_nearbyVenues objectAtIndex:indexPath.row - 2];
                }
                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier4];
                if (cell == nil) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier4];
                }
            }
        }
    }
    else {
        if (indexPath.row - 2 < [_nearbyVenues count]) {
            venue = [_nearbyVenues objectAtIndex:indexPath.row - 2];
        }
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier4];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier4];
        }
    }
    
    cell.textLabel.font = [UIFont boldSystemFontOfSize:18];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"Send Your Location", nil);
        if (_mapView.myLocation.horizontalAccuracy > 0) {
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Accurate to %@ meters", nil),[NSString stringWithFormat:@"%.0f",_mapView.myLocation.horizontalAccuracy]];
        }
        else{
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    else if(indexPath.row >= 2 && venue) {
        cell.textLabel.text = [venue name];
        if (venue.location.address) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",venue.location.address];
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0f;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FSVenue *venue = nil;
    
    if (indexPath.row == 0) {
        if (_mapView.myLocation) {
            //发送当前位置
            venue = [[FSVenue alloc] init];
            FSLocation *location = [[FSLocation alloc] init];
            location.coordinate = _mapView.myLocation.coordinate;
            venue.location = location;
        }
    }
    else if(indexPath.row >= 2)
    {
        if (!_searching) {
            if (indexPath.row - 2 < [_nearbyVenues count] ) {
                venue = _nearbyVenues[indexPath.row - 2];
            }
        }
    }
    
    if (venue && self.delegate && [self.delegate respondsToSelector:@selector(didSelectVenue:)]) {
        [self.delegate didSelectVenue:venue];
    }
}

@end
