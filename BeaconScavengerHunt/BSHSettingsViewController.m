//
//  BSHSettingsViewController.m
//  BeaconScavengerHunt
//
//  Created by Patrick Caraher on 1/10/15.
//  Copyright (c) 2015 Mustang Data Management. All rights reserved.
//

#import "BSHSettingsViewController.h"

#define kAlertOKButtonIndex 1

#define kClearBeaconsTitle @"Clear Scanned Beacons"
#define kNewScavengerHuntTitle @"Scan a new Scavenger Hunt"
#define kResendCompletionTitle @"Repeat Completion Message"

#define kClearBeaconsActionMessage @"Clear all of the beacons in your Scavenger Hunt and start again."
#define kNewScavengerHuntMessage @"Quit this Scavenger Hunt and look for a new Scavenger Hunt"
#define kResendCompletionMessage @"Resend the Scavenger Hunt Completion Message"

@interface BSHSettingsViewController () <UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate>
{
    NSArray *rows;
    NSArray *messages;
}
@end

@implementation BSHSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    rows = @[kClearBeaconsTitle, kNewScavengerHuntTitle];
    messages = @[kClearBeaconsActionMessage, kNewScavengerHuntMessage];
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

#pragma mark - protocol UITableViewDataSource<NSObject>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *settingsTableIdentifier = @"SettingsTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:settingsTableIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:settingsTableIdentifier];
    }
    
    cell.textLabel.text = rows[indexPath.row];
    
    return cell;
}

#pragma mark - protocol UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *message = messages[indexPath.row];
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [av setTag:indexPath.row];
    [av show];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - protocol UIAlertViewDelegate <NSObject>

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (kAlertOKButtonIndex == buttonIndex)
    {
        NSInteger index = [alertView tag];
        NSString *title = rows[index];

        if ([kClearBeaconsTitle isEqualToString:title])
        {
            [self.configurationManager markAllBeaconsAsUnseen];
        }
        else if ([kNewScavengerHuntTitle isEqualToString:title])
        {
            [self.homeViewController clearScavengerHunt];
        }
        else if ([kResendCompletionTitle isEqualToString:title])
        {
            [self.configurationManager invokeCompletionAction];
        }
    }

}

@end
