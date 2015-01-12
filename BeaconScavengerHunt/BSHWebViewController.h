//
//  BSHWebViewController.h
//  BeaconScavengerHunt
//
//  Created by Patrick Caraher on 12/30/14.
//  Copyright (c) 2014 Mustang Data Management. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BSHWebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, strong) IBOutlet UIWebView *webview;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *loadingSpinner;

@end
