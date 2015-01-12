//
//  BSHBeaconManager.h
//  BeaconScavengerHunt
//
//  Created by Patrick Caraher on 12/18/14.
//  Copyright (c) 2014 Mustang Data Management. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BSHBeaconManagerDelegate
-(void)didRangeBeacons:(NSArray *)beacons;
@end

@interface BSHBeaconManager : NSObject

-(id)initWithUUID:(NSString *)uuid forDelegate:(id<BSHBeaconManagerDelegate>)delegate;
@end
