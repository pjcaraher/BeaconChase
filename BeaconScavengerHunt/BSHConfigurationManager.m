//
//  BSHConfigurationManager.m
//  BeaconScavengerHunt
//
//  Created by Patrick Caraher on 12/18/14.
//  Copyright (c) 2014 Mustang Data Management. All rights reserved.
//

#import "BSHConfigurationManager.h"

#define kDataFileName @"bsh.json"

#define kBeaconsKey @"beacons"
#define kUUIDKey @"uuid"
#define kTopImageKey @"top_image"
#define kDescriptionKey @"description"
#define kCompletionKey @"completion"

#define kActionKey @"action"
#define kValueKey @"value"
#define kEmailSubjectKey @"subject"
#define kEmailToKey @"toAddress"

#define kTableViewCellReuseIdentifier @"BSHBeaconsTableView"

#define kURLActionString @"url"
#define kMessageActionString @"message"
#define kEmailActionString @"email"

#define kAlertRequiresActionTag 1
#define kAlertOKButtonIndex 1

@interface BSHConfigurationManager () <UIAlertViewDelegate>
@property (nonatomic, strong) NSMutableDictionary *beaconAlertViews;
@property (nonatomic, strong) NSArray *beacons;
@property (nonatomic, strong) NSDictionary *completionDictionary;
@property (nonatomic, strong) BSHBeaconManager *beaconManager;
-(void)promptForBeaconAction:(BSHBeacon *)bshBeacon;
-(void)triggerActionForBeacon:(BSHBeacon *)beacon onDelegate:(id<BSHBeaconActionDelegate>)delegate;
-(void)updateBeaconsFromArray:(NSArray *)array;
-(void)updateConfiguration:(NSDictionary *)dict;
@end


@implementation BSHConfigurationManager

-(id)init
{
    if (self = [super init])
    {
        self.beacons = [[NSArray alloc] init];
        self.beaconAlertViews = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    @try
    {
        [coder encodeObject: self.beacons
                     forKey: kBeaconsKey];
        [coder encodeObject: self.uuidString
                     forKey: kUUIDKey];
        [coder encodeObject: self.topImageUrlString
                     forKey: kTopImageKey];
        [coder encodeObject: self.descriptionString
                     forKey: kDescriptionKey];
        [coder encodeObject: self.completionDictionary
                     forKey: kCompletionKey];
    }
    @catch (NSException *exception)
    {
        NSLog(@"ERROR:  %s  %@", __FUNCTION__, [exception reason]);
    }
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [self init])
    {
        @try
        {
            self.beacons = [coder decodeObjectForKey: kBeaconsKey];
            self.uuidString = [coder decodeObjectForKey: kUUIDKey];
            self.topImageUrlString = [coder decodeObjectForKey: kTopImageKey];
            self.descriptionString = [coder decodeObjectForKey: kDescriptionKey];
            self.completionDictionary = [coder decodeObjectForKey: kCompletionKey];
        }
        @catch (NSException *exception)
        {
            NSLog(@"ERROR:  %s  %@", __FUNCTION__, [exception reason]);
        }
    }
    return self;
}

-(void)loadConfigurationAtURLString:(NSString *)urlString completionHandler:(void (^)(BOOL success, NSError *error))handler
{
    NSString *dataUrlString = [NSString stringWithFormat:@"%@/%@", urlString, kDataFileName];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:dataUrlString]];
    NSError *error;
    NSURLResponse *response;
    
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (!result) {
        //Display error message here
        NSLog(@"Error");
        handler(NO, error);
    } else {
        NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:result options:0 error:&error];
        
        if (error != nil) {
            handler(NO, error);
        }
        else
        {
            [self updateConfiguration:parsedObject];
            handler(YES, nil);
        }
    }
}

-(void)invokeActionForIndexPath:(NSIndexPath *)indexPath
{
    BSHBeacon *beacon = [self.beacons objectAtIndex:indexPath.row];
    
    if (beacon.hasBeenSeen)
    {
        [self promptForBeaconAction:beacon];
    }
}

-(void)invokeCompletionAction
{
    NSString *action = (self.completionDictionary) ? [self.completionDictionary valueForKey:kActionKey] : nil;
    NSString *value = [self.completionDictionary valueForKey:kValueKey];

    if ([kURLActionString compare:action] == NSOrderedSame)
    {
        [self.actionDelegate openUrlString:value];
    }
    else if ([kMessageActionString compare:action] == NSOrderedSame)
    {
        [self.actionDelegate displayMessage:value];
    }
    else if ([kEmailActionString compare:action] == NSOrderedSame)
    {
        NSString *subject = [self.completionDictionary valueForKey:kEmailSubjectKey];
        NSString *toAddress = [self.completionDictionary valueForKey:kEmailToKey];
        
        [self.actionDelegate sendEmailMessage:value withSubject:subject to:toAddress];
    }
}

-(void)triggerActionForBeacon:(BSHBeacon *)beacon onDelegate:(id<BSHBeaconActionDelegate>)delegate
{
    if ([kURLActionString caseInsensitiveCompare:beacon.actionType] == NSOrderedSame)
    {
        [delegate openUrlString:beacon.actionValue];
    }
    else if ([kMessageActionString caseInsensitiveCompare:beacon.actionType] == NSOrderedSame)
    {
        [delegate displayMessage:beacon.actionValue];
    }
}

-(void)markAllBeaconsAsUnseen
{
    for (BSHBeacon *beacon in self.beacons)
    {
        [beacon setHasBeenSeen:NO];
    }
}

-(BOOL)allBeaconsAreSeen
{
    BOOL allSeen = (self.beacons.count > 0);
    
    for (BSHBeacon *beacon in self.beacons)
    {
        if (![beacon hasBeenSeen])
        {
            allSeen = NO;
            break;
        }
    }

    return allSeen;
}

-(BOOL)hasBeacons
{
    return (self.beacons && self.beacons.count);
}

-(void)clear
{
    self.beacons = [[NSArray alloc] init];
    [self.beaconManager performSelectorOnMainThread:@selector(stopMonitoring) withObject:nil waitUntilDone:YES];
    self.beaconManager = nil;
}

-(void)promptForBeaconAction:(BSHBeacon *)bshBeacon
{
    UIAlertView *av = nil;
    NSString *message = nil;
    NSString *cancelButtonTitle = nil;
    NSUInteger tag = 0;
    
    if ([kURLActionString caseInsensitiveCompare:bshBeacon.actionType] == NSOrderedSame)
    {
        message = bshBeacon.actionTitle;
        tag = kAlertRequiresActionTag;
        cancelButtonTitle = @"Cancel";
    }
    else if ([kMessageActionString caseInsensitiveCompare:bshBeacon.actionType] == NSOrderedSame)
    {
        message = bshBeacon.actionValue;
    }

    av = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:@"OK", nil];
    [av setTag:tag];
    
    [self.beaconAlertViews setObject:bshBeacon forKey:[NSValue valueWithNonretainedObject:av]];
    
    [av show];
}

-(void)updateBeaconsFromArray:(NSArray *)array
{
    NSMutableArray *newBeacons = [[NSMutableArray alloc] init];
    
    for (NSDictionary *bDict in array)
    {
        BSHBeacon *beacon = [BSHBeacon newForDictionary:bDict];
        [newBeacons addObject:beacon];
    }
    
    self.beacons = newBeacons;
}

-(void)updateConfiguration:(NSDictionary *)dict
{
    NSArray *updateBeaconsArray = [dict objectForKey:kBeaconsKey];
    self.uuidString = [dict valueForKey:kUUIDKey];
    self.topImageUrlString = [dict valueForKey:kTopImageKey];
    self.descriptionString = [dict valueForKey:kDescriptionKey];
    self.completionDictionary = [dict valueForKey:kCompletionKey];
    
    [self updateBeaconsFromArray:updateBeaconsArray];
}

-(void)updateUUID:(NSString *)uuidString
{
    self.beaconManager = [[BSHBeaconManager alloc] initWithUUID:uuidString forDelegate:self];
}

-(void)checkProximityForBeacon:(CLBeacon *)beacon
{
    for (BSHBeacon *bshBeacon in self.beacons)
    {
        if (![bshBeacon hasBeenSeen])
        {
            if ([bshBeacon isSeenByBeacon:beacon])
            {
                [bshBeacon setHasBeenSeen:YES];
                [self.actionDelegate newBeaconHasBeenSeen];
                [self promptForBeaconAction:bshBeacon];
            }
        }
    }
}

#pragma mark protocol UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.beacons.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellReuseIdentifier];
    BSHBeacon *beacon = [self.beacons objectAtIndex:indexPath.row];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kTableViewCellReuseIdentifier];
    }
    
    if (beacon.hasBeenSeen)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.text = beacon.title;
    
    return cell;
}

#pragma mark protocol BSHBeaconManagerDelegate

-(void)didRangeBeacons:(NSArray *)beacons
{
    for (CLBeacon *beacon in beacons)
    {
        [self checkProximityForBeacon:beacon];
    }
}

#pragma mark - protocol UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    BSHBeacon* beacon = [self.beaconAlertViews objectForKey:[NSValue valueWithNonretainedObject:alertView]];
    
    if (kAlertRequiresActionTag == [alertView tag])
    {
        if (kAlertOKButtonIndex == buttonIndex)
        {
            [self triggerActionForBeacon:beacon onDelegate:self.actionDelegate];
        }
        else
        {
            [self.actionDelegate checkForCompletion];
        }
    }
    else
    {
        [self.actionDelegate checkForCompletion];
    }
    
    [self.beaconAlertViews removeObjectForKey:[NSValue valueWithNonretainedObject:alertView]];
}

@end
