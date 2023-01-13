//
//  BMDHintsViewController.m
//  Beamed
//
//  Created by Patrick Keith-Hynes on 8/12/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#import "BMDHintsViewController.h"
#import "BMDAppDelegate.h"
#import <VungleSDK/VungleSDK.h>
#import "Firebase.h"

@import UIKit;



@interface BMDHintsViewController ()

@end

@implementation BMDHintsViewController{
    BMDViewController *rc;
    BMDAppDelegate *appd;
    BOOL playRewardedAd;
}

@synthesize hintsView;
@synthesize hintsViewLabel;
@synthesize hintPacksButtonsArray;


- (void)viewDidLoad {
    DLog("BMDHintsViewController.viewDidLoad");

    [super viewDidLoad];
    
    rc = (BMDViewController*)[[(BMDAppDelegate *)[[UIApplication sharedApplication]delegate] window] rootViewController];
    appd = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];

    playRewardedAd = NO;
    
    CGRect hintPacksFrame = rc.rootView.bounds;
    
    // Create hintsView
    hintsView = [[UIView alloc] initWithFrame:hintPacksFrame];
    self.view = hintsView;
    hintsView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    hintsView.layer.cornerRadius = 25;
    hintsView.layer.masksToBounds = YES;

    // Set background color and graphic image
    hintsView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.14 alpha:1.0];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"backgroundLandscapeGrid" ofType:@"png"];
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
    UIImageView *hintsViewBackground = [[UIImageView alloc]initWithImage:newImage];
    hintsViewBackground.contentMode = UIViewContentModeScaleAspectFill;
    hintsViewBackground.clipsToBounds = YES;
    [hintsView addSubview:hintsViewBackground];
    [hintsView bringSubviewToFront:hintsViewBackground];

    // Set up fonts and button sizes based on device display aspect ratio
    unsigned int titleLabelSize;
    CGFloat buttonWidth, buttonHeight, homeButtonWidthToHeightRatio;
    CGFloat backButtonIconSizeInPoints = 60;
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            titleLabelSize = 36;
            buttonWidth = 0.6*rc.screenWidthInPixels/rc.contentScaleFactor;
            buttonHeight = buttonWidth/8.0;
            homeButtonWidthToHeightRatio = 0.4;
            backButtonIconSizeInPoints = 60;
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            titleLabelSize = 36;
            buttonWidth = 0.6*rc.screenWidthInPixels/rc.contentScaleFactor;
            buttonHeight = buttonWidth/6.0;
            homeButtonWidthToHeightRatio = 0.4;
            backButtonIconSizeInPoints = 60;
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            titleLabelSize = 36;
            buttonWidth = 0.6*rc.screenWidthInPixels/rc.contentScaleFactor;
            buttonHeight = buttonWidth/6.0;
            homeButtonWidthToHeightRatio = 0.4;
            backButtonIconSizeInPoints = 60;
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            titleLabelSize = 24;
            buttonWidth = 0.8*rc.screenWidthInPixels/rc.contentScaleFactor;
            buttonHeight = buttonWidth/5.0;
            homeButtonWidthToHeightRatio = 0.5;
            backButtonIconSizeInPoints = 40;
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            titleLabelSize = 24;
            buttonWidth = 0.8*rc.screenWidthInPixels/rc.contentScaleFactor;
            buttonHeight = buttonWidth/5.0;
            homeButtonWidthToHeightRatio = 0.5;
            backButtonIconSizeInPoints = 40;
            break;
        }
    }

    // hintsViewLabel
    CGFloat w = 0.5*hintPacksFrame.size.width;
    CGFloat h = 1.5*titleLabelSize;
    CGFloat settingsLabelY = 2.0*h;
    CGRect hintsLabelFrame = CGRectMake(0.5*hintPacksFrame.size.width - w/2.0,
                                        settingsLabelY,
                                        w,
                                        h);
    hintsViewLabel = [[UILabel alloc] initWithFrame:hintsLabelFrame];
    if ([appd checkForEndlessHintsPurchased]){
        hintsViewLabel.text = @"Endless Hints";
    }
    else {
        int numberOfHintsRemaining = [[appd getObjectFromDefaults:@"numberOfHintsRemaining"] intValue];
        if (numberOfHintsRemaining <= 0){
            hintsViewLabel.text = @"No Hints";
        }
        else if (numberOfHintsRemaining == 1){
            hintsViewLabel.text = @"1 Hint";
        }
        else {
            hintsViewLabel.text = [NSString stringWithFormat:@"%d Hints", numberOfHintsRemaining];
        }
    }
    hintsViewLabel.textColor = [UIColor cyanColor];
    hintsViewLabel.layer.borderColor = [UIColor clearColor].CGColor;
    hintsViewLabel.layer.borderWidth = 1.0;
    [hintsViewLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:titleLabelSize]];
    hintsViewLabel.textAlignment = NSTextAlignmentCenter;
    hintsViewLabel.adjustsFontSizeToFitWidth = YES;
    [hintsView addSubview:hintsViewLabel];
    [hintsView bringSubviewToFront:hintsViewLabel];
    
    //
    // backButton icon
    //
    // Create a back arrow icon at the left hand side
    UIButton *backArrow = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect backArrowRect = CGRectMake(h/2,
                                      settingsLabelY,
                                      backButtonIconSizeInPoints,
                                      backButtonIconSizeInPoints);
    backArrow.frame = backArrowRect;
    backArrow.enabled = YES;
    [backArrow addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImage *backArrowImage = [UIImage imageNamed:@"backArrow.png"];
    [backArrow setBackgroundImage:backArrowImage forState:UIControlStateNormal];
    [hintsView addSubview:backArrow];
    [hintsView bringSubviewToFront:backArrow];

    
    //
    // Add hint buttons to hintsView
    //
    NSMutableArray *arrayOfPaidHintPacks = [appd fetchPacksArray:@"paidHintPacksArray.plist"];
    NSEnumerator *hintsEnum = [arrayOfPaidHintPacks objectEnumerator];
    UIButton *hintPackButton;
    CGFloat buttonCx = 0, buttonCy = 0;
    CGFloat hintsButtonY = hintsLabelFrame.origin.y + hintsLabelFrame.size.height/2.0;
    hintPacksButtonsArray = [NSMutableArray arrayWithCapacity:1];
    
    //
    // Load button images
    //
    UIImage *btnImage = [UIImage imageNamed:@"yellowRectangle.png"];
    UIImage *btnSelectedImage = [UIImage imageNamed:@"yellowRectangleSelected.png"];

    //
    // Add hint video reward button to hintsView
    //
    hintPackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [hintPackButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Light" size:[self querySmallFontSize]+3]];
    [hintPackButton setBackgroundImage:btnImage forState:UIControlStateNormal];
    [hintPackButton setBackgroundImage:btnSelectedImage forState:UIControlStateHighlighted];
    [hintPacksButtonsArray insertObject:hintPackButton atIndex:0];
    buttonCx = hintPacksFrame.size.width/2.0;
    buttonCy = hintsButtonY + buttonHeight;
    CGRect buttonRect = CGRectMake(buttonCx-buttonWidth/2.0, buttonCy, buttonWidth, buttonHeight);
    hintPackButton.frame = buttonRect;
    hintPackButton.layer.borderWidth = 0.0f;
    NSString *hintTitle = [NSString stringWithFormat:@"Watch Video for 1 Hint"];
    [hintPackButton setTitle:hintTitle forState:UIControlStateNormal];
//    hintPackButton.layer.borderColor = [UIColor whiteColor].CGColor;
    hintPackButton.tag = 0;
    [hintPackButton addTarget:self action:@selector(hintRewardVideoButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    hintPackButton.showsTouchWhenHighlighted = YES;
    [hintPackButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [hintPackButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    w = buttonWidth;  h = w/8;
    [hintsView addSubview:hintPackButton];
    [hintsView bringSubviewToFront:hintPackButton];

    //
    // Add hint purchase buttons to hintsView
    //
    NSMutableDictionary *hintDictionary;
    while (hintDictionary = [hintsEnum nextObject]){
        NSNumber *hintIndex = [hintDictionary objectForKey:@"pack_number"];
        hintPackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [hintPackButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Light" size:[self querySmallFontSize]+3]];
        [hintPackButton setBackgroundImage:btnImage forState:UIControlStateNormal];
        [hintPackButton setBackgroundImage:btnSelectedImage forState:UIControlStateHighlighted];
        [hintPacksButtonsArray insertObject:hintPackButton atIndex:[hintIndex integerValue]+1];
        buttonCx = hintPacksFrame.size.width/2.0;
        buttonCy = hintsButtonY + buttonHeight +(1.2*(float)([hintIndex integerValue] + 1))*buttonHeight;
        buttonRect = CGRectMake(buttonCx-buttonWidth/2.0, buttonCy, buttonWidth, buttonHeight);
        hintPackButton.frame = buttonRect;
        hintPackButton.layer.borderWidth = 1.0f;
        long hintCost = [[hintDictionary objectForKey:@"AppStorePackCost"] integerValue];
        NSString *hintPackName = [hintDictionary objectForKey:@"pack_name"];
        // Hint pack buttons have a blue background
//        hintPackButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.75 alpha:1.0];
        if (hintCost == 0){
            hintTitle = [NSString stringWithFormat:@"%s", [hintPackName UTF8String]];
        }
        else {
            hintTitle = [NSString stringWithFormat:@"$%1.2f - %s", (float)hintCost/100.0, [hintPackName UTF8String]];
        }
        [hintPackButton setTitle:hintTitle forState:UIControlStateNormal];
//        hintPackButton.layer.borderColor = [UIColor whiteColor].CGColor;
        hintPackButton.tag = [hintIndex integerValue] + 1;
        [hintPackButton addTarget:self action:@selector(hintPackButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        hintPackButton.showsTouchWhenHighlighted = YES;
        [hintPackButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [hintPackButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
        w = buttonWidth;  h = w/8;
        [hintsView addSubview:hintPackButton];
        [hintsView bringSubviewToFront:hintPackButton];
    }
    
}

- (void)viewDidAppear:(BOOL)animated {
    DLog("BMDHintsViewController.viewDidAppear");
    
    [appd playMusicLoop:appd.loop1Player];
    
    NSString *adFree = [appd getObjectFromDefaults:@"AD_FREE_PUZZLES"];
    if (![adFree isEqualToString:@"YES"]){
        [hintsView addSubview:rc.bannerAdView];
        [hintsView bringSubviewToFront:rc.bannerAdView];
    }

    playRewardedAd = NO;
    rc.gamekitAccessPoint.active = NO;
    if (ENABLE_GA == YES){
        
        [FIRAnalytics logEventWithName:kFIREventSelectContent
                            parameters:@{
            kFIRParameterItemID:[NSString stringWithFormat:@"id-%@", @"HintsVC viewDidAppear"],
            kFIRParameterItemName:@"HintsVC viewDidAppear",
            kFIRParameterContentType:@"image"
        }];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    DLog("BMDHintsViewController.viewDidDisappear");
    if (playRewardedAd == YES){
        [rc vunglePlayRewardedAd];
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

- (void)updateHintsViewLabel {
    hintsViewLabel.attributedText = nil;
    if ([appd checkForEndlessHintsPurchased]){
        hintsViewLabel.text = @"Endless Hints";
    }
    else {
        int numberOfHintsRemaining = [[appd getObjectFromDefaults:@"numberOfHintsRemaining"] intValue];
        if (numberOfHintsRemaining <= 0){
            hintsViewLabel.text = @"No Hints";
        }
        else if (numberOfHintsRemaining == 1){
            hintsViewLabel.text = @"1 Hint";
        }
        else {
            hintsViewLabel.text = [NSString stringWithFormat:@"%d Hints", numberOfHintsRemaining];
        }
    }
}




- (void)vunglePlayRewardedAd {
    VungleSDK* sdk = [VungleSDK sharedSDK];
    NSError *error;
    if (![sdk playAd:self.parentViewController options:nil placementID:vunglePlacementRewardedHint error:&error]) {
        if (error) {
            DLog("Error encountered playing ad: %@", error);
        }
    }
}



- (unsigned int)querySmallFontSize {
    unsigned int packSmallFontSize;
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            packSmallFontSize = 20;
           break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            packSmallFontSize = 22;
           break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            packSmallFontSize = 20;
           break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            packSmallFontSize = 14;
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            packSmallFontSize = 14;
            break;
        }
    }
    return packSmallFontSize;
}

//
// Button Press and Gesture Handler Methods Go Here
//

- (void)hintRewardVideoButtonPressed {
    // Close BMDHintViewController
    [rc refreshHomeView];
    playRewardedAd = YES;
    [self willMoveToParentViewController:self.parentViewController];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

- (void)hintPackButtonPressed:(UIButton *)sender {
    [appd playSound:appd.tapPlayer];
    unsigned int pack = (unsigned int)sender.tag;
    DLog("hintPackButtonPressed %d", pack);
    NSMutableArray *array = [appd fetchPacksArray:@"paidHintPacksArray.plist"];
//    NSMutableArray *array = [appd.gameDictionaries objectForKey:@"paidHintPacksArray.plist"];
    // Buttons for paid packs begin with button 1 because Watch Viseo is button 0
    // TODO Adjust to an index base of 0.  Clearly a hack that needs to be fixed.
    pack = pack - 1;
    if ([array count] > pack){
        NSMutableDictionary *packDictionary = [array objectAtIndex:pack];
        NSString *productionId = [packDictionary objectForKey:@"production_id"];
        [appd purchaseHintPack:productionId];
    }
}

- (void)backButtonPressed {
    DLog("BMDHintsViewController.backButtonPressed");
    [appd playSound:appd.tapPlayer];
    if ([self.parentViewController isKindOfClass:[BMDViewController class]]){
        DLog("backButtonPressed parentViewController is BMDViewController");
        [rc refreshHomeView];
        [self willMoveToParentViewController:self.parentViewController];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        rc.renderPuzzleON = NO;
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
        
        // Pause loop1Player
        if (appd.loop1Player.isPlaying){
            [appd.loop1Player pause];
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

@end
