//
//  BSHConfigurationManager.h
//  BeaconScavengerHunt
//
//  Created by Patrick Caraher on 12/18/14.
//  Copyright (c) 2014 Mustang Data Management. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BSHBeaconManager.h"
#import "BSHBeacon.h"

@protocol BSHBeaconActionDelegate

-(void)openUrlString:(NSString *)urlString;
-(void)displayMessage:(NSString *)message;
-(void)sendEmailMessage:(NSString *)message withSubject:(NSString *)subject to:(NSString *)toAddress;
-(void)newBeaconHasBeenSeen;
-(void)checkForCompletion;
@end

@interface BSHConfigurationManager : NSObject <UITableViewDataSource,BSHBeaconManagerDelegate>

@property (nonatomic, weak) id<BSHBeaconActionDelegate>actionDelegate;
@property (nonatomic, copy) NSString *topImageUrlString;
@property (nonatomic, copy) NSString *descriptionString;
@property (nonatomic, copy) NSString *uuidString;

-(void)updateUUID:(NSString *)uuidString;
-(void)loadConfigurationAtURLString:(NSString *)urlString completionHandler:(void (^)(BOOL success, NSError *error))handler;
-(void)invokeActionForIndexPath:(NSIndexPath *)indexPath;
-(void)invokeCompletionAction;
-(void)markAllBeaconsAsUnseen;
-(BOOL)allBeaconsAreSeen;
-(BOOL)hasBeacons;
-(void)clear;

@end
