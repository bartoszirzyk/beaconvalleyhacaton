//
//  ViewController.h
//  KanarBV
//
//  Created by Bartosz Irzyk on 21/11/15.
//  Copyright © 2015 Bartosz Irzyk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QRCodeReaderDelegate.h"

@interface ViewController : UIViewController <QRCodeReaderDelegate>

- (IBAction)scanAction:(id)sender;

@end
