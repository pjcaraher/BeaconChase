//
//  BSHWebViewController.m
//  BeaconScavengerHunt
//
//  Created by Patrick Caraher on 12/30/14.
//  Copyright (c) 2014 Mustang Data Management. All rights reserved.
//

#import "BSHWebViewController.h"

@interface BSHWebViewController ()

@end

@implementation BSHWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];
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

- (IBAction)closeButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - protocol UIWebViewDelegate <NSObject>

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.loadingSpinner.hidden = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.loadingSpinner.hidden = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    self.loadingSpinner.hidden = YES;
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to load webpage." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [av show];
}

@end
