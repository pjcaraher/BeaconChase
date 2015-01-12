//
//  BSHSettingsViewController.h
//  BeaconScavengerHunt
//
//  Created by Patrick Caraher on 1/10/15.
//  Copyright (c) 2015 Mustang Data Management. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BSHConfigurationManager.h"
#import "ViewController.h"

@interface BSHSettingsViewController : UIViewController

@property (nonatomic, strong) BSHConfigurationManager *configurationManager;
@property (nonatomic, strong) ViewController *homeViewController;

@end
