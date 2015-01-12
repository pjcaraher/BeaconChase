//
//  BSHBeacon.h
//  BeaconScavengerHunt
//
//  Created by Patrick Caraher on 12/18/14.
//  Copyright (c) 2014 Mustang Data Management. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface BSHBeacon : NSObject

@property (nonatomic, strong) NSNumber *major;
@property (nonatomic, strong) NSNumber *minor;
@property (nonatomic, copy) NSString *uuid;
@property (assign) CLProximity proximity;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *actionTitle;
@property (nonatomic, copy) NSString *actionType;
@property (nonatomic, copy) NSString *actionValue;
@property BOOL hasBeenSeen;

+(id)newForDictionary:(NSDictionary *)dict;
-(BOOL)isSeenByBeacon:(CLBeacon *)beacon;
-(BOOL)matchesBeacon:(CLBeacon *)beacon;

@end
