//
//  BMDSettingsViewController.m
//  Beamed
//
//  Created by Patrick Keith-Hynes on 8/24/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#import "BMDSettingsViewController.h"
#import "BMDAppDelegate.h"
#import "Firebase.h"

@import UIKit;


@interface BMDSettingsViewController ()

@end

@implementation BMDSettingsViewController{
    BMDViewController *rc;
    BMDAppDelegate *appd;
}

@synthesize settingsView;
@synthesize soundsEnabledButton;
@synthesize musicEnabledButton;
@synthesize leaderboardsButton;
@synthesize restorePurchasesButton;
@synthesize emailSupportButton;
@synthesize websiteButton;
@synthesize shareButton;
@synthesize aboutButton;
@synthesize resetButton;

@synthesize soundsEnabledSwitch;
@synthesize musicEnabledSwitch;

@synthesize soundEffectsEnabledLabel;
@synthesize musicEnabledLabel;


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    rc = (BMDViewController*)[[(BMDAppDelegate *)[[UIApplication sharedApplication]delegate] window] rootViewController];
    appd = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    CGRect settingsFrame = rc.rootView.bounds;
    
    settingsView = [[UIView alloc] initWithFrame:settingsFrame];
    self.view = settingsView;
    settingsView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    settingsView.layer.cornerRadius = 25;
    settingsView.layer.masksToBounds = YES;
    
    // Set background color and graphic image
    settingsView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.14 alpha:1.0];
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"backgroundLandscapeGrid" ofType:@"png"];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"neon-synthwave-cityscape-1" ofType:@"png"];
    UIImage *sourceImage = [UIImage imageWithContentsOfFile:filePath];
    CGFloat imageWidth = (CGFloat)sourceImage.size.width;
    CGFloat imageHeight = (CGFloat)sourceImage.size.height;
    CGFloat displayWidth = self.view.frame.size.width;
    CGFloat displayHeight = self.view.frame.size.height;
    CGFloat scaleFactor = displayHeight / imageHeight;
    CGFloat newHeight = displayHeight;
    CGFloat newWidth = imageWidth * scaleFactor;
    CGSize imageSize = CGSizeMake(newWidth, newHeight);
    UIGraphicsBeginImageContext(imageSize);
    [sourceImage drawInRect:CGRectMake(-(newWidth-displayWidth)/2.0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageView *settingsViewBackground = [[UIImageView alloc]initWithImage:newImage];
    settingsViewBackground.contentMode = UIViewContentModeScaleAspectFill;
    settingsViewBackground.clipsToBounds = YES;
    [settingsView addSubview:settingsViewBackground];
    [settingsView bringSubviewToFront:settingsViewBackground];
    
    // Set filter frame to improve icon grid and text contrast
    CGRect filterFrame = CGRectMake(0.05*self.view.frame.size.width,
                                    0.05*self.view.frame.size.height,
                                    0.9*self.view.frame.size.width,
                                    0.9*self.view.frame.size.height);
    UILabel *filterLabel = [[UILabel alloc] initWithFrame:filterFrame];
    filterLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.60];
    filterLabel.layer.masksToBounds = YES;
    filterLabel.layer.cornerRadius = 15;
    [settingsView addSubview:filterLabel];
    [settingsView bringSubviewToFront:filterLabel];

    CGFloat titleLabelSize, optionLabelSize, buttonHeight, buttonWidth, homeButtonWidthToHeightRatio;
    CGFloat backButtonIconSizeInPoints = 60;
    CGFloat switchCx;
    CGFloat w, h, settingsLabelY;
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            titleLabelSize = 36;
            optionLabelSize = 32;
            backButtonIconSizeInPoints = 60;
            buttonWidth = 0.6*settingsFrame.size.width;
            buttonHeight = buttonWidth/8.0;
            homeButtonWidthToHeightRatio = 0.4;
            switchCx = 0.74*rc.screenWidthInPixels/rc.contentScaleFactor;
            w = 0.5*settingsFrame.size.width;
            h = 1.5*titleLabelSize;
            settingsLabelY = 1.0*h;
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            titleLabelSize = 36;
            optionLabelSize = 32;
            backButtonIconSizeInPoints = 60;
            buttonWidth = 0.6*settingsFrame.size.width;
            buttonHeight = buttonWidth/8.0;
            homeButtonWidthToHeightRatio = 0.4;
            switchCx = 0.74*rc.screenWidthInPixels/rc.contentScaleFactor;
            w = 0.5*settingsFrame.size.width;
            h = 1.5*titleLabelSize;
            settingsLabelY = 2.0*h;
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            titleLabelSize = 36;
            optionLabelSize = 32;
            backButtonIconSizeInPoints = 60;
            buttonWidth = 0.6*settingsFrame.size.width;
            buttonHeight = buttonWidth/8.0;
            homeButtonWidthToHeightRatio = 0.4;
            switchCx = 0.74*rc.screenWidthInPixels/rc.contentScaleFactor;
            w = 0.5*settingsFrame.size.width;
            h = 1.5*titleLabelSize;
            settingsLabelY = 2.0*h;
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            titleLabelSize = 22;
            optionLabelSize = 22;
            backButtonIconSizeInPoints = 40;
            buttonWidth = 0.8*settingsFrame.size.width;
            buttonHeight = buttonWidth/8.0;
            homeButtonWidthToHeightRatio = 0.5;
            switchCx = 0.65*rc.screenWidthInPixels/rc.contentScaleFactor;
            w = 0.5*settingsFrame.size.width;
            h = 1.5*titleLabelSize;
            settingsLabelY = 2.0*h;
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            titleLabelSize = 22;
            optionLabelSize = 22;
            backButtonIconSizeInPoints = 40;
            buttonWidth = 0.8*settingsFrame.size.width;
            buttonHeight = buttonWidth/8.0;
            homeButtonWidthToHeightRatio = 0.5;
            switchCx = 0.65*rc.screenWidthInPixels/rc.contentScaleFactor;
            w = 0.5*settingsFrame.size.width;
            h = 1.5*titleLabelSize;
            settingsLabelY = 3.0*h;
            break;
        }
    }
    
    // Settings Label
    CGRect settingsLabelFrame = CGRectMake(0.5*settingsFrame.size.width - w/2.0,
                                           settingsLabelY,
                                           w,
                                           h);
    UILabel *settingsPageLabel = [[UILabel alloc] initWithFrame:settingsLabelFrame];
    settingsPageLabel.text = @"Settings";
    settingsPageLabel.textColor = [UIColor cyanColor];
    settingsPageLabel.layer.borderColor = [UIColor clearColor].CGColor;
    settingsPageLabel.layer.borderWidth = 1.0;
    [settingsPageLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:titleLabelSize]];
    settingsPageLabel.textAlignment = NSTextAlignmentCenter;
    settingsPageLabel.adjustsFontSizeToFitWidth = NO;
    [settingsView addSubview:settingsPageLabel];
    [settingsView bringSubviewToFront:settingsPageLabel];
    
    //
    // backButton icon
    //
    // Create a back arrow icon at the left hand side
    UIButton *homeArrow = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect homeArrowRect = CGRectMake(h/2,
                                      settingsLabelY,
                                      backButtonIconSizeInPoints,
                                      backButtonIconSizeInPoints);
    homeArrow.frame = homeArrowRect;
    homeArrow.enabled = YES;
    [homeArrow addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImage *homeArrowImage = [UIImage imageNamed:@"homeArrow.png"];
    [homeArrow setBackgroundImage:homeArrowImage forState:UIControlStateNormal];
    [settingsView addSubview:homeArrow];
    [settingsView bringSubviewToFront:homeArrow];
    
    //
    // Sound Effects Enable/Disable Switch
    //
    //    CGFloat switchCx = 0.65*rc.screenWidthInPixels/rc.contentScaleFactor;
    CGFloat switchCy = settingsLabelY + (2.0*(float)(0 + 1))*buttonHeight;
    CGRect switchRect = CGRectMake(switchCx, switchCy, 0, 0);
    soundsEnabledSwitch = [[UISwitch alloc]initWithFrame:switchRect];
    if ([[appd getStringFromDefaults:@"soundsEnabled"] isEqualToString:@"YES"]){
        [soundsEnabledSwitch setOn:YES animated:NO];
    }
    else {
        [soundsEnabledSwitch setOn:NO animated:NO];
    }
    [self.soundsEnabledSwitch addTarget:self action:@selector(soundEffectSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [settingsView addSubview:soundsEnabledSwitch];
    [settingsView bringSubviewToFront:soundsEnabledSwitch];
    
    //
    // Sound Effects Enable/Disable Label
    //
    w = 0.5*settingsFrame.size.width;
    h = optionLabelSize;
    CGRect soundEffectsLabelFrame =
    CGRectMake(0.20*rc.screenWidthInPixels/rc.contentScaleFactor,
               settingsLabelY + (2.0*(float)(0 + 1))*buttonHeight,
               w,
               h);
    soundEffectsEnabledLabel = [[UILabel alloc] initWithFrame:soundEffectsLabelFrame];
    soundEffectsEnabledLabel.text = @"Sound Effects";
    if ([[appd getStringFromDefaults:@"soundsEnabled"] isEqualToString:@"YES"]){
        soundEffectsEnabledLabel.textColor = [UIColor greenColor];
    }
    else {
        soundEffectsEnabledLabel.textColor = [UIColor redColor];
    }
    soundEffectsEnabledLabel.layer.borderColor = [UIColor clearColor].CGColor;
    soundEffectsEnabledLabel.layer.borderWidth = 1.0;
    [soundEffectsEnabledLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:optionLabelSize]];
    soundEffectsEnabledLabel.textAlignment = NSTextAlignmentLeft;
    soundEffectsEnabledLabel.adjustsFontSizeToFitWidth = NO;
    [settingsView addSubview:soundEffectsEnabledLabel];
    [settingsView bringSubviewToFront:soundEffectsEnabledLabel];
    
    //
    // Music Enable/Disable Switch
    //
    //    switchCx = 0.65*rc.screenWidthInPixels/rc.contentScaleFactor;
    switchCy = settingsLabelY + (3.0*(float)(0 + 1))*buttonHeight;
    switchRect = CGRectMake(switchCx, switchCy, 0, 0);
    musicEnabledSwitch = [[UISwitch alloc]initWithFrame:switchRect];
    if ([[appd getStringFromDefaults:@"musicEnabled"] isEqualToString:@"YES"]){
        [musicEnabledSwitch setOn:YES animated:NO];
    }
    else {
        [musicEnabledSwitch setOn:NO animated:NO];
    }
    [self.musicEnabledSwitch addTarget:self action:@selector(musicSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [settingsView addSubview:musicEnabledSwitch];
    [settingsView bringSubviewToFront:musicEnabledSwitch];
    
    //
    // Music Enable/Disable Label
    //
    w = 0.5*settingsFrame.size.width;
    h = optionLabelSize;
    CGRect musicLabelFrame =
    CGRectMake(0.20*rc.screenWidthInPixels/rc.contentScaleFactor,
               settingsLabelY + (3.0*(float)(0 + 1))*buttonHeight,
               w,
               h);
    musicEnabledLabel = [[UILabel alloc] initWithFrame:musicLabelFrame];
    musicEnabledLabel.text = @"Music";
    if ([[appd getStringFromDefaults:@"musicEnabled"] isEqualToString:@"YES"]){
        musicEnabledLabel.textColor = [UIColor greenColor];
    }
    else {
        musicEnabledLabel.textColor = [UIColor redColor];
    }
    musicEnabledLabel.layer.borderColor = [UIColor clearColor].CGColor;
    musicEnabledLabel.layer.borderWidth = 1.0;
    [musicEnabledLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:optionLabelSize]];
    musicEnabledLabel.textAlignment = NSTextAlignmentLeft;
    musicEnabledLabel.adjustsFontSizeToFitWidth = NO;
    [settingsView addSubview:musicEnabledLabel];
    [settingsView bringSubviewToFront:musicEnabledLabel];
    
    //
    // Leaderboards Button
    //
    leaderboardsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *btnImage = [UIImage imageNamed:@"yellowRectangle.png"];
    UIImage *btnSelectedImage = [UIImage imageNamed:@"yellowRectangleSelected.png"];
    [leaderboardsButton setBackgroundImage:btnImage forState:UIControlStateNormal];
    [leaderboardsButton setBackgroundImage:btnSelectedImage forState:UIControlStateHighlighted];
    CGFloat buttonCx = settingsFrame.size.width/2.0;
    CGFloat buttonCy = settingsLabelY + (4.0*(float)(0 + 1))*buttonHeight;
    CGRect buttonRect = CGRectMake(buttonCx-buttonWidth/2.0, buttonCy, buttonWidth, 1.0*buttonHeight);
    [leaderboardsButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:titleLabelSize]];
    leaderboardsButton.frame = buttonRect;
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            [leaderboardsButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:30]];
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            [leaderboardsButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:36]];
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            [leaderboardsButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:30]];
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            [leaderboardsButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:20]];
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            [leaderboardsButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:20]];
            break;
        }
    }
    [leaderboardsButton setTitle:@"Leaderboards" forState:UIControlStateNormal];
    [leaderboardsButton addTarget:self action:@selector(leaderboardsButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    leaderboardsButton.showsTouchWhenHighlighted = YES;
    [leaderboardsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [leaderboardsButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    [settingsView addSubview:leaderboardsButton];
    [settingsView bringSubviewToFront:leaderboardsButton];
    
    //
    // Restore Purchases Button
    //
    restorePurchasesButton = [UIButton buttonWithType:UIButtonTypeCustom];
    btnImage = [UIImage imageNamed:@"yellowRectangle.png"];
    btnSelectedImage = [UIImage imageNamed:@"yellowRectangleSelected.png"];
    [restorePurchasesButton setBackgroundImage:btnImage forState:UIControlStateNormal];
    [restorePurchasesButton setBackgroundImage:btnSelectedImage forState:UIControlStateHighlighted];
    buttonCx = settingsFrame.size.width/2.0;
    buttonCy = buttonCy + 1.3*buttonHeight;
    buttonRect = CGRectMake(buttonCx-buttonWidth/2.0, buttonCy, buttonWidth, 1.0*buttonHeight);
    [restorePurchasesButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:titleLabelSize]];
    restorePurchasesButton.frame = buttonRect;
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            [restorePurchasesButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:30]];
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            [restorePurchasesButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:36]];
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            [restorePurchasesButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:30]];
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            [restorePurchasesButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:20]];
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            [restorePurchasesButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:20]];
            break;
        }
    }
    [restorePurchasesButton setTitle:@"Restore Purchases" forState:UIControlStateNormal];
    [restorePurchasesButton addTarget:self action:@selector(restorePurchasesButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    restorePurchasesButton.showsTouchWhenHighlighted = YES;
    [restorePurchasesButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [restorePurchasesButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    [settingsView addSubview:restorePurchasesButton];
    [settingsView bringSubviewToFront:restorePurchasesButton];
    
    //
    // Email support
    //
    if (![MFMailComposeViewController canSendMail]) {
        DLog("Mail services are not available.");
    }
    else {
        emailSupportButton = [UIButton buttonWithType:UIButtonTypeCustom];
        btnImage = [UIImage imageNamed:@"yellowRectangle.png"];
        btnSelectedImage = [UIImage imageNamed:@"yellowRectangleSelected.png"];
        [emailSupportButton setBackgroundImage:btnImage forState:UIControlStateNormal];
        [emailSupportButton setBackgroundImage:btnSelectedImage forState:UIControlStateHighlighted];
        buttonCx = settingsFrame.size.width/2.0;
        buttonCy = buttonCy + 1.3*buttonHeight;
        buttonRect = CGRectMake(buttonCx-buttonWidth/2.0, buttonCy, buttonWidth, 1.0*buttonHeight);
        [emailSupportButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:titleLabelSize]];
        emailSupportButton.frame = buttonRect;
        switch (rc.displayAspectRatio) {
            case ASPECT_4_3:{
                // iPad (9th generation)
                [emailSupportButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:30]];
                break;
            }
            case ASPECT_10_7:{
                // iPad Air (5th generation)
                [emailSupportButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:36]];
                break;
            }
            case ASPECT_3_2: {
                // iPad Mini (6th generation)
                [emailSupportButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:30]];
                break;
            }
            case ASPECT_16_9: {
                // iPhone 8
                [emailSupportButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:20]];
                break;
            }
            case ASPECT_13_6: {
                // iPhone 14
                [emailSupportButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:20]];
                break;
            }
        }
        [emailSupportButton setTitle:@"Email Support" forState:UIControlStateNormal];
        [emailSupportButton addTarget:self action:@selector(emailSupportButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        emailSupportButton.showsTouchWhenHighlighted = YES;
        [emailSupportButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [emailSupportButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
        [settingsView addSubview:emailSupportButton];
        [settingsView bringSubviewToFront:emailSupportButton];
    }
    
    //
    // Website
    //
    websiteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    btnImage = [UIImage imageNamed:@"yellowRectangle.png"];
    btnSelectedImage = [UIImage imageNamed:@"yellowRectangleSelected.png"];
    [websiteButton setBackgroundImage:btnImage forState:UIControlStateNormal];
    [websiteButton setBackgroundImage:btnSelectedImage forState:UIControlStateHighlighted];
    buttonCx = settingsFrame.size.width/2.0;
    buttonCy = buttonCy + 1.3*buttonHeight;
    buttonRect = CGRectMake(buttonCx-buttonWidth/2.0, buttonCy, buttonWidth, 1.0*buttonHeight);
    [websiteButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:titleLabelSize]];
    websiteButton.frame = buttonRect;
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            [websiteButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:30]];
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            [websiteButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:36]];
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            [websiteButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:30]];
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            [websiteButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:20]];
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            [websiteButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:20]];
            break;
        }
    }
    [websiteButton setTitle:@"Website" forState:UIControlStateNormal];
    [websiteButton addTarget:self action:@selector(websiteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    websiteButton.showsTouchWhenHighlighted = YES;
    [websiteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [websiteButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    [settingsView addSubview:websiteButton];
    [settingsView bringSubviewToFront:websiteButton];
    
    //
    // Share
    //
    shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    btnImage = [UIImage imageNamed:@"yellowRectangle.png"];
    btnSelectedImage = [UIImage imageNamed:@"yellowRectangleSelected.png"];
    [shareButton setBackgroundImage:btnImage forState:UIControlStateNormal];
    [shareButton setBackgroundImage:btnSelectedImage forState:UIControlStateHighlighted];
    buttonCx = settingsFrame.size.width/2.0;
    buttonCy = buttonCy + 1.3*buttonHeight;
    buttonRect = CGRectMake(buttonCx-buttonWidth/2.0, buttonCy, buttonWidth, 1.0*buttonHeight);
    [shareButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:titleLabelSize]];
    shareButton.frame = buttonRect;
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            [shareButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:30]];
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            [shareButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:36]];
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            [shareButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:30]];
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            [shareButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:20]];
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            [shareButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:20]];
            break;
        }
    }
    [shareButton setTitle:@"Share" forState:UIControlStateNormal];
    [shareButton addTarget:self action:@selector(shareButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    shareButton.showsTouchWhenHighlighted = YES;
    [shareButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [shareButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    [settingsView addSubview:shareButton];
    [settingsView bringSubviewToFront:shareButton];
    
    //
    // About
    //
    aboutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    btnImage = [UIImage imageNamed:@"yellowRectangle.png"];
    btnSelectedImage = [UIImage imageNamed:@"yellowRectangleSelected.png"];
    [aboutButton setBackgroundImage:btnImage forState:UIControlStateNormal];
    [aboutButton setBackgroundImage:btnSelectedImage forState:UIControlStateHighlighted];
    buttonCx = settingsFrame.size.width/2.0;
    buttonCy = buttonCy + 1.3*buttonHeight;
    buttonRect = CGRectMake(buttonCx-buttonWidth/2.0, buttonCy, buttonWidth, 1.0*buttonHeight);
    [aboutButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:titleLabelSize]];
    aboutButton.frame = buttonRect;
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            [aboutButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:30]];
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            [aboutButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:36]];
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            [aboutButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:30]];
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            [aboutButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:20]];
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            [aboutButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:20]];
            break;
        }
    }
    [aboutButton setTitle:@"About" forState:UIControlStateNormal];
    [aboutButton addTarget:self action:@selector(aboutButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    aboutButton.showsTouchWhenHighlighted = YES;
    [aboutButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [aboutButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    [settingsView addSubview:aboutButton];
    [settingsView bringSubviewToFront:aboutButton];
    
    //
    // Reset Puzzle
    //
    resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    btnImage = [UIImage imageNamed:@"yellowRectangle.png"];
    btnSelectedImage = [UIImage imageNamed:@"yellowRectangleSelected.png"];
    [resetButton setBackgroundImage:btnImage forState:UIControlStateNormal];
    [resetButton setBackgroundImage:btnSelectedImage forState:UIControlStateHighlighted];
    buttonCx = settingsFrame.size.width/2.0;
    buttonCy = buttonCy + 1.3*buttonHeight;
    buttonRect = CGRectMake(buttonCx-buttonWidth/2.0, buttonCy, buttonWidth, 1.0*buttonHeight);
    [resetButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:titleLabelSize]];
    resetButton.frame = buttonRect;
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            [resetButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:30]];
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            [resetButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:36]];
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            [resetButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:30]];
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            [resetButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:20]];
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            [resetButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:20]];
            break;
        }
    }
    [resetButton setTitle:@"Reset Progress" forState:UIControlStateNormal];
    [resetButton addTarget:self action:@selector(resetPuzzleProgressButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    resetButton.showsTouchWhenHighlighted = YES;
    [resetButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [resetButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    [settingsView addSubview:resetButton];
    [settingsView bringSubviewToFront:resetButton];
}

- (void)viewDidAppear:(BOOL)animated {
    DLog("BMDSettingsViewController.viewDidAppear");
    [appd playMusicLoop:appd.loop1Player];
    NSString *adFree = [appd getObjectFromDefaults:@"AD_FREE_PUZZLES"];
    if (![adFree isEqualToString:@"YES"]){
        [settingsView addSubview:rc.bannerAdView];
        [settingsView bringSubviewToFront:rc.bannerAdView];
    }
    rc.gamekitAccessPoint.active = NO;
    if (ENABLE_GA == YES){
        
        [FIRAnalytics logEventWithName:kFIREventSelectContent
                            parameters:@{
            kFIRParameterItemID:[NSString stringWithFormat:@"id-%@", @"SettingsVC viewDidAppear"],
            kFIRParameterItemName:@"SettingsVC viewDidAppear",
            kFIRParameterContentType:@"image"
        }];
    }
}

- (void)setupBackButton:(CGRect)frame size:(CGSize)buttonSize position:(CGPoint)buttonPosition {
    // Setup home button at the bottom of the screen
    //
    // Back Button
    //
    CGFloat homeFontSize;
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:
            // iPad (9th generation)
        case ASPECT_10_7:
            // iPad Air (5th generation)
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            homeFontSize = 28;
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            homeFontSize = 14;
            break;
        }
        default:
        case ASPECT_13_6: {
            // iPhone 14
            homeFontSize = 16;
            break;
        }
    }
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect buttonRect = CGRectMake(buttonPosition.x, buttonPosition.y, buttonSize.width, buttonSize.height);
    backButton.frame = buttonRect;
    backButton.layer.borderWidth = 1.0f;
    backButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [backButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Light" size:homeFontSize]];
    [backButton setTitle:[NSString stringWithFormat:@"Back"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    backButton.showsTouchWhenHighlighted = YES;
    backButton.hidden = NO;
    [backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    [self.view addSubview:backButton];
    [self.view bringSubviewToFront:backButton];
}



//
// Button Handler Methods Go Here
//

- (void)backButtonPressed {
    DLog("BMDSettingsViewController.backButtonPressed");
    [appd playSound:appd.tapPlayer];
    if ([self.parentViewController isKindOfClass:[BMDViewController class]]){
        DLog("backButtonPressed parentViewController is BMDViewController");
        [rc refreshHomeView];
        [self willMoveToParentViewController:self.parentViewController];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        rc.renderPuzzleON = NO;
        rc.renderOverlayON = NO;
        [rc refreshHomeView];
        [rc loadAppropriateSizeBannerAd];
        [rc startMainScreenMusicLoop];
    }
    else if ([self.parentViewController isKindOfClass:[BMDPuzzleViewController class]]){
        DLog("backButtonPressed parentViewController is BMDPuzzleViewController");

        // If not yet solved then store startTime for timeSegment
        long startTime = [[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]] longValue];
        int currentPackNumber = -1;
        int currentPuzzleNumber = 0;
        NSMutableDictionary *emptyJewelCountDictionary = [appd buildEmptyJewelCountDictionary];
        if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
            currentPackNumber = [appd fetchCurrentPackNumber];
            currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
            if ([appd puzzleSolutionStatus:currentPackNumber
                              puzzleNumber:currentPuzzleNumber] == -1){
                [appd updatePuzzleScoresArray:currentPackNumber
                                 puzzleNumber:currentPuzzleNumber
                               numberOfJewels:emptyJewelCountDictionary
                                    startTime:startTime        // New segment startTime
                                      endTime:-1
                                       solved:NO];
            }
        }
        else if (rc.appCurrentGamePackType == PACKTYPE_DAILY) {
            currentPackNumber = -1;
            currentPuzzleNumber = [appd fetchDailyPuzzleNumber];
            if ([appd puzzleSolutionStatus:currentPackNumber
                              puzzleNumber:currentPuzzleNumber] == -1){
                [appd updatePuzzleScoresArray:currentPackNumber
                                 puzzleNumber:currentPuzzleNumber
                               numberOfJewels:emptyJewelCountDictionary
                                    startTime:startTime        // New segment startTime
                                      endTime:-1
                                       solved:NO];
            }
        }

        if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
            [appd playMusicLoop:appd.loop1Player];
        }
        else {
            [appd playMusicLoop:appd.loop2Player];
        }

        [self willMoveToParentViewController:self.parentViewController];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }
    else{
        DLog("backButtonPressed parentViewController is unknown");
        [self willMoveToParentViewController:self.parentViewController];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }
}

- (void)leaderboardsButtonPressed {
    GKGameCenterViewController *leaderboardViewController =
        [[GKGameCenterViewController alloc]initWithState:GKGameCenterViewControllerStateLeaderboards];
    leaderboardViewController.gameCenterDelegate = self;
    [self showViewController:leaderboardViewController sender:self];
    [appd playSound:appd.tapPlayer];
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)viewController
{
    DLog("Close");
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)restorePurchasesButtonPressed {
    // Restore purchases from the App Store
    [appd playSound:appd.tapPlayer];
    [appd restorePurchases];
}

- (void)emailSupportButtonPressed {
    // Set up an email to support for the user to complete and send if desired
    MFMailComposeViewController* composeVC = [[MFMailComposeViewController alloc] init];
    composeVC.mailComposeDelegate = self;

    // Configure the fields of the interface.
    [composeVC setToRecipients:@[@"support@squaretailsoftware.com"]];
    [composeVC setSubject:@"Bug Report / Feature Request"];
    [composeVC setMessageBody:@"Please enter a description of the bug or feature request here." isHTML:NO];

    // Present the view controller modally.
    [self presentViewController:composeVC animated:YES completion:nil];
}

- (void)websiteButtonPressed {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://squaretailsoftware.com"] options:@{} completionHandler:nil];
}

- (UIImage *)captureScreenAsImage {
    // Capture an image of the screen
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    CGRect rect = [keyWindow bounds];
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [keyWindow.layer renderInContext:context];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}


- (void)shareButtonPressed {
    NSMutableArray* sharedObjects=[NSMutableArray arrayWithObjects:@"http://beamed2.squarespace.com",
                                   @"Check out Beamed 2, a fun relaxing puzzle game I'm playing!",
                                   nil];

    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:sharedObjects applicationActivities:nil];
    
    NSArray* excludedActivityTypes = [NSArray arrayWithObjects:UIActivityTypeAirDrop,
                                      UIActivityTypeAssignToContact,
                                      UIActivityTypeAddToReadingList,
                                      UIActivityTypeCopyToPasteboard,
                                      UIActivityTypeSaveToCameraRoll,
                                      UIActivityTypePrint,
                                      UIActivityTypeMarkupAsPDF,
                                      UIActivityTypeOpenInIBooks,
                                      UIApplicationLaunchOptionsUserActivityTypeKey,
                                      nil];
    activityViewController.excludedActivityTypes = excludedActivityTypes;
    
    if ([self deviceIsIPhone]){
        // iPhone
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
    else {
        // iPad
        activityViewController.modalPresentationStyle = UIModalPresentationPopover;
        activityViewController.popoverPresentationController.sourceView = settingsView;
        
        activityViewController.popoverPresentationController.sourceRect = CGRectMake(0.25*rc.safeFrame.size.width,
                                                                                     0.25*rc.safeFrame.size.height,
                                                                                     0,
                                                                                     0);
        activityViewController.popoverPresentationController.popoverLayoutMargins = UIEdgeInsetsZero;
        activityViewController.popoverPresentationController.canOverlapSourceViewRect = NO;
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
}


- (BOOL)deviceIsIPhone {
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:
        case ASPECT_10_7:
        case ASPECT_3_2:{
            // iPads
            return NO;
            break;
        }
        case ASPECT_16_9:
        case ASPECT_13_6:
        default:{
            // iPhones
            return YES;
            break;
        }
    }
}


- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
   // Check the result or perform other tasks.
 
   // Dismiss the mail compose view controller.
   [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)aboutButtonPressed {
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString* versionString = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString* titleString = @"Beamed 2, version ";
    titleString = [titleString stringByAppendingString:versionString];
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:titleString
                               message:@"Copyright 2023\rSquaretail Software\rSan Diego CA"
                               preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {}];

    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)resetPuzzleProgressButtonPressed {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Beamed 2"
                               message:@"All Puzzle Progress Erased"
                               preferredStyle:UIAlertControllerStyleAlert];

    [appd resetPuzzleProgressAndScores];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {}];

    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)soundEffectSwitchChanged:(UISwitch *)sender {
    // Do something
    BOOL soundEffectSwitchValue = sender.on;
    if (soundEffectSwitchValue == YES){
        [appd setObjectInDefaults:@"YES" forKey:@"soundsEnabled"];
        soundEffectsEnabledLabel.textColor = [UIColor greenColor];
    }
    else {
        [appd setObjectInDefaults:@"NO" forKey:@"soundsEnabled"];
        soundEffectsEnabledLabel.textColor = [UIColor redColor];
    }
    [appd playSound:appd.tapPlayer];
}

- (void)musicSwitchChanged:(UISwitch *)sender {
    // Do something
    BOOL musicSwitchValue = sender.on;
    if (musicSwitchValue == YES){
        [appd setObjectInDefaults:@"YES" forKey:@"musicEnabled"];
        musicEnabledLabel.textColor = [UIColor greenColor];
        [appd playMusicLoop:appd.loop1Player];
    }
    else {
        [appd setObjectInDefaults:@"NO" forKey:@"musicEnabled"];
        musicEnabledLabel.textColor = [UIColor redColor];
        [appd.loop1Player pause];
    }
    [appd playSound:appd.tapPlayer];
}

@end
