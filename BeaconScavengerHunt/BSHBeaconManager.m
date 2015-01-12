//
//  BSHBeaconManager.m
//  BeaconScavengerHunt
//
//  Created by Patrick Caraher on 12/18/14.
//  Copyright (c) 2014 Mustang Data Management. All rights reserved.
//

#import "BSHBeaconManager.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

#define kBeaconIdentifier @"Beacon Scavenger Hunt"


@interface BSHBeaconManager () <CLLocationManagerDelegate>
@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, weak) id<BSHBeaconManagerDelegate> delegate;
@property (nonatomic, retain) CLLocationManager *locationManager;
-(void)_reactToEnterForegroundNotification:(NSNotification *)notification;
-(void)_startMonitoringForUUID:(NSString *)uuid;
-(void)_stopMonitoringForUUID:(NSString *)uuid;
@end

@implementation BSHBeaconManager

-(id)initWithUUID:(NSString *)uuid forDelegate:(id<BSHBeaconManagerDelegate>)delegate
{
    if (self = [super init])
    {
        self.uuid = uuid;
        self.delegate = delegate;
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;

        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(_reactToEnterForegroundNotification:)
         name:UIApplicationWillEnterForegroundNotification
         object:nil];
        
        [self _startMonitoringForUUID:self.uuid];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}

#pragma mark protocol CLLocationManagerDelegate<NSObject>

/*
 *  locationManager:didDetermineState:forRegion:
 *
 *  Discussion:
 *    Invoked when there's a state transition for a monitored region or in response to a request for state via a
 *    a call to requestStateForRegion:.
 */
- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    switch (state)
    {
        case CLRegionStateInside:
            [manager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
            break;
        case CLRegionStateUnknown:
        case CLRegionStateOutside:
        default:
            [manager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
            break;
    }
}

/*
 *  locationManager:didRangeBeacons:inRegion:
 *
 *  Discussion:
 *    Invoked when a new set of beacons are available in the specified region.
 *    beacons is an array of CLBeacon objects.
 *    If beacons is empty, it may be assumed no beacons that match the specified region are nearby.
 *    Similarly if a specific beacon no longer appears in beacons, it may be assumed the beacon is no longer received
 *    by the device.
 */
- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (self.delegate)
    {
        [self.delegate didRangeBeacons:beacons];
    }
}

/*
 *  locationManager:rangingBeaconsDidFailForRegion:withError:
 *
 *  Discussion:
 *    Invoked when an error has occurred ranging beacons in a region. Error types are defined in "CLError.h".
 */
- (void)locationManager:(CLLocationManager *)manager
rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
              withError:(NSError *)error
{
    NSLog(@"%s [%@]", __func__, error);
}

/*
 *  locationManager:didEnterRegion:
 *
 *  Discussion:
 *    Invoked when the user enters a monitored region.  This callback will be invoked for every allocated
 *    CLLocationManager instance with a non-nil delegate that implements this method.
 */
- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region
{
    [manager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
}

/*
 *  locationManager:didExitRegion:
 *
 *  Discussion:
 *    Invoked when the user exits a monitored region.  This callback will be invoked for every allocated
 *    CLLocationManager instance with a non-nil delegate that implements this method.
 */
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    [manager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
}

/*
 *  locationManager:didStartMonitoringForRegion:
 *
 *  Discussion:
 *    Invoked when a monitoring for a region started successfully.
 */
- (void)locationManager:(CLLocationManager *)manager
didStartMonitoringForRegion:(CLRegion *)region
{
    [self.locationManager requestStateForRegion:region];
}

/*
 *  locationManager:monitoringDidFailForRegion:withError:
 *
 *  Discussion:
 *    Invoked when a region monitoring error has occurred. Error types are defined in "CLError.h".
 */
- (void)locationManager:(CLLocationManager *)manager
monitoringDidFailForRegion:(CLRegion *)region
              withError:(NSError *)error
{
    NSLog(@"%s [%@]", __func__, error);
}

/*
 *  locationManager:didChangeAuthorizationStatus:
 *
 *  Discussion:
 *    Invoked when the authorization status changes for this application.
 */
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if ((status >= kCLAuthorizationStatusAuthorizedAlways) && (status <= kCLAuthorizationStatusAuthorizedWhenInUse))
    {
        if (nil != self.uuid)
        {
            [self _startMonitoringForUUID:self.uuid];
        }
    }
    else
    {
        if (nil != self.uuid)
        {
            [self _stopMonitoringForUUID:self.uuid];
        }
    }
}

-(void)_startMonitoringForUUID:(NSString *)uuid
{
    if (nil != uuid)
    {
        [self startMonitoring];
    }
    else
    {
        [self stopMonitoring];
    }
}

-(void)_stopMonitoringForUUID:(NSString *)uuid
{
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:uuid];
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:kBeaconIdentifier];
    
    [self.locationManager stopMonitoringForRegion:region];
    [self.locationManager stopRangingBeaconsInRegion:region];
}

-(void)startMonitoring
{
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:self.uuid];
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:kBeaconIdentifier];

    region.notifyOnEntry = YES;
    region.notifyOnExit = YES;
    region.notifyEntryStateOnDisplay = YES;

    if ([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusAvailable) {
        
        NSLog(@"Background updates are available for the app.");
    }else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusDenied)
    {
        NSLog(@"The user explicitly disabled background behavior for this app or for the whole system.");
    }else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusRestricted)
    {
        NSLog(@"Background updates are unavailable and the user cannot enable them again. For example, this status can occur when parental controls are in effect for the current user.");
    }

    NSLog(@"Authorization Status is %d", [CLLocationManager authorizationStatus]);

    // If the authorization status has yet to be determined or, if it is set to only
    // when in use, request Always in order to allow for Monitoring.
    if ((kCLAuthorizationStatusNotDetermined == [CLLocationManager authorizationStatus]) && [self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
    {
        [self.locationManager requestAlwaysAuthorization];
        //        [self.locationManager requestWhenInUseAuthorization];
    }
    else
    {
        BOOL available = [CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]];
        
        if (available)
        {
            [self.locationManager startMonitoringForRegion:region];
        }
        else
        {
            NSLog(@"Monitoring not available for Beacons.");
        }
    }
}

-(void)stopMonitoring
{
    // stop monitoring for any and all current regions
    for (CLRegion *region in [[self.locationManager monitoredRegions] allObjects]) {
        [self.locationManager stopMonitoringForRegion:region];
    }
}

-(void)_reactToEnterForegroundNotification:(NSNotification *)notification
{
    [self _startMonitoringForUUID:self.uuid];
}

@end
