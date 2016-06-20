//
//  ViewController.m
//  MyCamera
//
//  Created by 珍玮 on 16/6/20.
//  Copyright © 2016年 ZhenWei. All rights reserved.
//

#import "ViewController.h"
#import "CardIO.h"
#import "CardIOPaymentViewControllerDelegate.h"
#import "MyCameraViewController.h"

@interface ViewController ()<CardIOPaymentViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.label.text = @"";
    [CardIOUtilities preload];
}

//点击进入信用卡扫描界面
- (IBAction)btnAction:(id)sender {
    
    CardIOPaymentViewController *scanVC = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:self];
    [self presentViewController:scanVC animated:YES completion:nil];
    
}

-(void)userDidCancelPaymentViewController:(CardIOPaymentViewController *)paymentViewController{
    
    [paymentViewController dismissViewControllerAnimated:YES completion:nil];

}

-(void)userDidProvideCreditCardInfo:(CardIOCreditCardInfo *)cardInfo inPaymentViewController:(CardIOPaymentViewController *)paymentViewController{
    //扫描结果
    NSLog(@"Received card info. Number: %@, expiry: %02i/%i, cvv: %@.", cardInfo.redactedCardNumber, cardInfo.expiryMonth, cardInfo.expiryYear, cardInfo.cvv);
    
    [paymentViewController dismissViewControllerAnimated:YES completion:nil];

}


- (IBAction)openMyCamera:(id)sender {
    
    MyCameraViewController *myCamera = [[MyCameraViewController alloc] init];
    
    [self presentViewController:myCamera animated:YES completion:nil];
    
}




@end
