//
//  LoginViewController.m
//  bv2015
//
//  Created by Bartosz Irzyk on 21/11/15.
//  Copyright © 2015 Bartosz Irzyk. All rights reserved.
//

#import "LoginViewController.h"
#import "MainViewController.h"

@interface LoginViewController ()<UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITextField *loginTextField;

@property (strong, nonatomic) IBOutlet UITextField *passwordTextView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;


@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loginTextField.delegate = self;
    self.passwordTextView.delegate = self;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
}
-(void)dismissKeyboard {
    [self.loginTextField resignFirstResponder];
    [self.passwordTextView resignFirstResponder];
    self.bottomConstraint.constant = 75;
    [UIView animateWithDuration:0.5 animations:^{
        [self.view layoutIfNeeded];
    }];
}
- (IBAction)loginAction:(UIButton *)sender {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle bundleForClass:[self class]]];
    MainViewController *vc = (MainViewController *) [storyboard instantiateViewControllerWithIdentifier:@"MainViewController"];
    ;
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:vc animated:YES completion:nil];

}
-(void)textFieldDidBeginEditing:(UITextField *)textField{
        self.bottomConstraint.constant = self.view.frame.size.height / 2.65;
        [UIView animateWithDuration:0.5 animations:^{
            [self.view layoutIfNeeded];
        }];
    
}
-(void)textFieldDidEndEditing:(UITextField *)textField{
}

@end
