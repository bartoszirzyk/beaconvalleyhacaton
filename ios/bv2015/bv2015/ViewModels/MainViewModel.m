//
//  MainViewModel.m
//  bv2015
//
//  Created by Bartosz Irzyk on 21/11/15.
//  Copyright © 2015 Bartosz Irzyk. All rights reserved.
//

#import "MainViewModel.h"
#import "KontaktSDK.h"
#import <UIKit/UIKit.h>
#import "AFHTTPRequestOperation.h"
#import "AFHTTPRequestOperationManager.h"
#import "KTKBeaconManager.h"
#import "Ticket.h"

@interface MainViewModel()<KTKLocationManagerDelegate>
@property KTKLocationManager *locationManager;
@property (nonatomic) NSUInteger flag;
@property (nonatomic) BOOL inRegion;
@property (nonatomic) NSUInteger transfer;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (strong,nonatomic) NSTimer *timer;
@property (strong,nonatomic) Ticket *currentTicket;

@end

@implementation MainViewModel

-(instancetype)init{
    self = [super init];
    
    if (self)
    {
        self.transfer = 0;
        self.inRegion = NO;
        self.locationManager = [KTKLocationManager new];
        self.locationManager.delegate = self;
        self.flag = 0;
        if ([KTKLocationManager canMonitorBeacons])
        {
            KTKRegion *region =[[KTKRegion alloc] init];
            region.uuid = @"9c2f2ed1-f3b6-4fcd-b705-3da1251fbf52"; // kontakt.io proximity UUID
            [self.locationManager setRegions:@[region]];
            [self.locationManager startMonitoringBeacons];
        }
        [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
        }];
        
    }
    
    return self;
}

-(void)stopScan{
    [self.locationManager stopMonitoringBeacons];
}

#pragma mark - KTKLocationManagerDelegate


- (void)locationManager:(KTKLocationManager *)locationManager didChangeState:(KTKLocationManagerState)state withError:(NSError *)error{
    if (state == KTKLocationManagerStateFailed){
        NSLog(@"Something went wrong with your Location Services settings. Check OS settings.");
    }
}

- (void)locationManager:(KTKLocationManager *)locationManager didEnterRegion:(KTKRegion *)region{
    NSLog(@"Enter region %@", region.uuid);
    self.inRegion = YES;
    if (self.transfer == 1 ) {
        self.transfer = 2;
    }
}

- (void)locationManager:(KTKLocationManager *)locationManager didExitRegion:(KTKRegion *)region{
    NSLog(@"Exit region %@", region.uuid);
    self.inRegion = NO;
    if (self.transfer == 0) {
        self.transfer = 1;
    }
    
    NSDate* sourceDate = [NSDate date];
    
    NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    
    NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
    NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
    
    NSDate *currentDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate];
    NSTimeInterval time = [self.currentTicket.expires timeIntervalSinceDate:currentDate];
    NSString *string = [NSString stringWithFormat:@"%02li:%02li:%02li",
                        lround(floor(time/ 3600.)) % 100,
                        lround(floor(time/ 60.)) % 60,
                        lround(floor(time)) % 60];
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.alertBody = [NSString stringWithFormat:@"You left vehicle. Ticket valid for %@ %@",string,self.currentTicket.oneJourneyTicket ? @"or one journey": @""];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    
    
}

- (void)locationManager:(KTKLocationManager *)locationManager didRangeBeacons:(NSArray *)beacons{
    if (beacons.count != 0) {
        self.inRegion = YES;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self sendToService:@"buy_ticket"];
        });
    }else{
        self.inRegion = NO;
    }
}

#pragma mark - communication with sevice

-(void)sendToService:(NSString *)type{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *url = [NSString stringWithFormat:@"http://178.62.146.62:3000/%@",type];
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc]init];
    NSUUID *uuid = [UIDevice currentDevice].identifierForVendor;
    parameters[@"device_id"] =  uuid.UUIDString;
    parameters[@"in_region"] = [NSString stringWithFormat:@"%d",self.inRegion ? 1 : 0 ];
    parameters[@"switched_vehicle"] = [NSString stringWithFormat:@"%d",self.transfer == 2 ? 1 : 0 ];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        Ticket *ticket = [Ticket ticeketFromDictionary:responseObject];
        self.currentTicket = ticket;
        [self updateTodayWidgetWithTicket:ticket];
        [self sendLocalNotificationWithStatus:ticket.status];
        [self.delegate updateViewWithTicket:ticket];
        if (![ticket.status isEqualToString:@"finished"]) {
            [self startTimerWithTime:ticket.refreshIn];
        }
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        
    }];
}

-(void)updateTodayWidgetWithTicket:(Ticket *)ticket{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"todayWidget"
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:@[ticket] forKey:@"ticket"]];
}

-(void)sendLocalNotificationWithStatus:(NSString *)status{
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.alertBody = status;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

-(void)startTimerWithTime:(NSInteger) time{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:time * 60 target:self selector:@selector(refreshTicket) userInfo:nil repeats:NO];
}
-(void)refreshTicket{
    [self sendToService:@"refresh"];
}
@end
