//
//  Ticket.m
//  bv2015
//
//  Created by Bartosz Irzyk on 21/11/15.
//  Copyright © 2015 Bartosz Irzyk. All rights reserved.
//

#import "Ticket.h"

@implementation Ticket

+(instancetype)ticeketFromDictionary:(NSDictionary *) dict{
    Ticket *ticket = [[Ticket alloc]init];
    ticket.status = dict[@"status"] == nil ? @"" : dict[@"status"];
    ticket.cost = dict[@"cost"] == nil ? 0 : [dict[@"cost"] floatValue];
    ticket.qrCode = dict[@"qr_code"] == nil ? [NSURL URLWithString:@""] : [NSURL URLWithString:dict[@"qr_code"]];
    ticket.oneJourneyTicket = [dict[@"one_journey_ticket"] boolValue];
    
    if(dict[@"expires"] != nil){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        ticket.expires = [dateFormatter dateFromString:dict[@"expires"]];
        NSDate* sourceDate = ticket.expires;
        
        NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
        
        NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
        NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
        NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
        
        ticket.expires = [[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate];
        
    }
    ticket.refreshIn = dict[@"refresh_in"] == nil ? -1 : [dict[@"refresh_in"] integerValue];
    
    return ticket;
    
}

@end
