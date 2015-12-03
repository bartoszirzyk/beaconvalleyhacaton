//
//  MainViewModel.h
//  bv2015
//
//  Created by Bartosz Irzyk on 21/11/15.
//  Copyright © 2015 Bartosz Irzyk. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Ticket;

@protocol MainViewModelDelegate
-(void)updateViewWithTicket:(Ticket *)ticket;
@end

@interface MainViewModel : NSObject
@property(nonatomic, assign) id<MainViewModelDelegate> delegate;
-(void)stopScan;
@end
