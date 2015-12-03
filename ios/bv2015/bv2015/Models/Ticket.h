//
//  Ticket.h
//  bv2015
//
//  Created by Bartosz Irzyk on 21/11/15.
//  Copyright © 2015 Bartosz Irzyk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Ticket : NSObject
@property(copy,nonatomic) NSString *status;
@property(nonatomic) float cost;
@property(strong,nonatomic) NSURL *qrCode;
@property(strong,nonatomic) NSDate *expires;
@property(nonatomic) BOOL oneJourneyTicket;
@property(nonatomic) NSInteger refreshIn;

+(instancetype)ticeketFromDictionary:(NSDictionary *) dict;

@end
