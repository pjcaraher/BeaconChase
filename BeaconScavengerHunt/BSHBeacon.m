//
//  BSHBeacon.m
//  BeaconScavengerHunt
//
//  Created by Patrick Caraher on 12/18/14.
//  Copyright (c) 2014 Mustang Data Management. All rights reserved.
//

#import "BSHBeacon.h"

#define kBeaconMajorKey @"major"
#define kBeaconMinorKey @"minor"
#define kBeaconUUIDKey @"uuid"
#define kBeaconProximityKey @"proximity"
#define kBeaconTitleKey @"title"
#define kBeaconActionTitleKey @"action_title"
#define kBeaconActionTypeKey @"action_type"
#define kBeaconActionValueKey @"action_value"

#define kBeaconHasBeenSeenKey @"hasBeenSeen"

@interface BSHBeacon ()
+(CLProximity)proximityForString:(NSString *)pString;
@end

@implementation BSHBeacon

+(id)newForDictionary:(NSDictionary *)dict
{
    BSHBeacon *bshBeacon = [[BSHBeacon alloc] init];
    
    if (bshBeacon)
    {
        bshBeacon.major = [dict objectForKey:kBeaconMajorKey];
        bshBeacon.minor = [dict objectForKey:kBeaconMinorKey];
        bshBeacon.uuid = [dict objectForKey:kBeaconUUIDKey];
        bshBeacon.proximity = [BSHBeacon proximityForString:[dict objectForKey:kBeaconProximityKey]];
        bshBeacon.actionTitle = [dict valueForKey:kBeaconActionTitleKey];
        bshBeacon.actionType = [dict valueForKey:kBeaconActionTypeKey];
        bshBeacon.actionValue = [dict valueForKey:kBeaconActionValueKey];
        bshBeacon.title = [dict valueForKey:kBeaconTitleKey];
        bshBeacon.hasBeenSeen = NO;
    }
    
    return bshBeacon;
}

+(CLProximity)proximityForString:(NSString *)pString
{
    CLProximity proximity = CLProximityUnknown;  // Default to unknown
    
    if ([@"Immediate" caseInsensitiveCompare:pString] == NSOrderedSame)
    {
        proximity = CLProximityImmediate;
    }
    else if ([@"Near" caseInsensitiveCompare:pString] == NSOrderedSame)
    {
        proximity = CLProximityNear;
    }
    else if ([@"Far" caseInsensitiveCompare:pString] == NSOrderedSame)
    {
        proximity = CLProximityFar;
    }
    
    return proximity;
}


+(id)newForMajor:(NSNumber *)major minor:(NSNumber *)minor uuid:(NSString *)uuid proximity:(CLProximity)proximity
{
    BSHBeacon *bshBeacon = [[BSHBeacon alloc] init];
    
    if (bshBeacon)
    {
        bshBeacon.major = major;
        bshBeacon.minor = minor;
        bshBeacon.uuid = uuid;
        bshBeacon.proximity = proximity;
    }
    
    return bshBeacon;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    @try
    {
        [coder encodeObject: self.major
                     forKey: kBeaconMajorKey];
        [coder encodeObject: self.minor
                     forKey: kBeaconMinorKey];
        [coder encodeObject: self.uuid
                     forKey: kBeaconUUIDKey];
        [coder encodeObject: [NSNumber numberWithUnsignedInteger:self.proximity]
                     forKey: kBeaconProximityKey];
        [coder encodeObject: self.title
                     forKey: kBeaconTitleKey];
        [coder encodeObject: self.actionTitle
                     forKey: kBeaconActionTitleKey];
        [coder encodeObject: self.actionType
                     forKey: kBeaconActionTypeKey];
        [coder encodeObject: self.actionValue
                     forKey: kBeaconActionValueKey];
        [coder encodeObject: [NSNumber numberWithBool:self.hasBeenSeen]
                     forKey:kBeaconHasBeenSeenKey];
    }
    @catch (NSException *exception)
    {
        NSLog(@"ERROR:  %s  %@", __FUNCTION__, [exception reason]);
    }
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init])
    {
        @try
        {
            self.major = [coder decodeObjectForKey: kBeaconMajorKey];
            self.minor = [coder decodeObjectForKey: kBeaconMinorKey];
            self.uuid = [coder decodeObjectForKey: kBeaconUUIDKey];
            self.proximity = [(NSNumber *)[coder decodeObjectForKey:kBeaconProximityKey] unsignedIntegerValue];
            self.title = [coder decodeObjectForKey: kBeaconTitleKey];
            self.actionTitle = [coder decodeObjectForKey: kBeaconActionTitleKey];
            self.actionType = [coder decodeObjectForKey: kBeaconActionTypeKey];
            self.actionValue = [coder decodeObjectForKey: kBeaconActionValueKey];
            self.hasBeenSeen = [(NSNumber *)[coder decodeObjectForKey:kBeaconHasBeenSeenKey] boolValue];
        }
        @catch (NSException *exception)
        {
            NSLog(@"ERROR:  %s  %@", __FUNCTION__, [exception reason]);
        }
    }
    return self;
}

-(BOOL)isSeenByBeacon:(CLBeacon *)beacon
{
    BOOL isSeen = NO;
    
    if ([self matchesBeacon:beacon])
    {
        if ((beacon.proximity > CLProximityUnknown) && (beacon.proximity <= self.proximity))
        {
            isSeen = YES;
        }
    }
    
    return isSeen;
}

// Note - we are only comparing major and minor for now.  We don't want to
// weigh this down with a UUID comparison.
-(BOOL)matchesBeacon:(CLBeacon *)beacon
{
    return (([self.major intValue] == [beacon.major intValue]) &&
            ([self.minor intValue] == [beacon.minor intValue])
            );
}


@end
