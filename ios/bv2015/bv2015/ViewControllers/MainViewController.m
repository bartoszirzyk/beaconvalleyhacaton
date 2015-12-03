//
//  MainViewController.m
//  bv2015
//
//  Created by Bartosz Irzyk on 21/11/15.
//  Copyright © 2015 Bartosz Irzyk. All rights reserved.
//

#import "MainViewController.h"
#import "MainViewModel.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "Ticket.h"
#import <MBProgressHUD/MBProgressHUD.h>
@interface MainViewController ()<MainViewModelDelegate>
@property (strong,nonatomic) MainViewModel *viewModel;
@property (strong, nonatomic) IBOutlet UILabel *costLabel;
@property (strong, nonatomic) IBOutlet UILabel *expiresLabel;
@property (strong, nonatomic) IBOutlet UILabel *costTitle;
@property (strong, nonatomic) IBOutlet UIImageView *qrImage;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) BOOL oneJourney;
@property (nonatomic) NSTimeInterval interval;
@property (strong, nonatomic) MBProgressHUD *hud;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Allow application to pay for tickets"
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:@"Yes"
                                          otherButtonTitles:@"No",nil];
    [alert show];

}

-(void)timerAction{
    NSLog(@"timer");
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.viewModel stopScan];
}


#pragma mark UIAlertView delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        self.viewModel = [[MainViewModel alloc]init];
        self.viewModel.delegate = self;
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.mode = MBProgressHUDModeIndeterminate;
        self.hud.labelText = @"Loading";
        [self.hud show:YES];
    }
    else if (buttonIndex == 1) {
        [self.viewModel stopScan];
        exit(0);
    }
}

#pragma mark MainViewModelDelegate

-(void)updateViewWithTicket:(Ticket *)ticket{
    [self.qrImage sd_setImageWithURL:ticket.qrCode];
    self.costLabel.text = [NSString stringWithFormat:@"%.2f PLN",ticket.cost];
    self.oneJourney = ticket.oneJourneyTicket;
    NSDate* sourceDate = [NSDate date];
    
    NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    
    NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
    NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
    
    NSDate *currentDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate];
    self.interval = [ticket.expires timeIntervalSinceDate:currentDate];
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
   
}

-(void)updateTime{
    [self.hud hide:YES];
    self.costTitle.hidden = NO;
    self.interval--;
    NSString *string = [NSString stringWithFormat:@"%02li:%02li:%02li",
                        lround(floor(self.interval / 3600.)) % 100,
                        lround(floor(self.interval / 60.)) % 60,
                        lround(floor(self.interval)) % 60];
    self.expiresLabel.text = [NSString stringWithFormat:@"Ticket valid for %@ %@",string,self.oneJourney ?@"or one journey": @"" ];
}
@end
