//
//  BMDPacksViewController.m
//  Beamed
//
//  Created by Patrick Keith-Hynes on 8/22/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#import "BMDPacksViewController.h"
#import "BMDAppDelegate.h"
#import "Firebase.h"



@interface BMDPacksViewController () 
@end

@implementation BMDPacksViewController{
    BMDViewController *rc;
    BMDAppDelegate *appd;
    CGRect puzzlePacksFrame;
    CGFloat buttonWidth, buttonHeight, buttonCy;
    UIImage *btnImageFree, *btnSelectedImageFree, *btnImageLocked, *btnImagePaid, *btnSelectedImagePaid;
    BOOL latchApplicationIsConnectedToNetwork;
}

@synthesize packsView;
@synthesize contentView;
@synthesize puzzlePacksButtonsArray;
@synthesize puzzlePacksLockIconsArray;
@synthesize scrollView;


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    rc = (BMDViewController*)[[(BMDAppDelegate *)[[UIApplication sharedApplication]delegate] window] rootViewController];
    appd = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    latchApplicationIsConnectedToNetwork = appd.applicationIsConnectedToNetwork;
    
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector(handleNetworkConnectivityChanged:)
     name: @"com.beamed.network.status-change"
     object: nil];
    
    CGRect homeFrame = rc.rootView.bounds;
    
    puzzlePacksFrame = CGRectMake(homeFrame.origin.x,
                                         homeFrame.origin.y,
                                         homeFrame.size.width,
                                         homeFrame.size.height);
    
    CGRect scrollViewFrame, titleFrame;
    
    CGRect puzzlePacksContentFrame = CGRectMake(homeFrame.origin.x,
                                                homeFrame.origin.y,
                                                homeFrame.size.width,
                                                1.00*homeFrame.size.height);
    
    // Set up fonts and button sizes based on device display aspect ratio
    unsigned int packFontSize, titleLabelSize, backButtonFontSize;
    CGFloat homeButtonWidthToHeightRatio;
    CGFloat backButtonIconSizeInPoints = 60;
    CGFloat scrollContentOffset;
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (8th, 9th, 10th generation)
            titleLabelSize = 36;
            packFontSize = 24;
            backButtonFontSize = 28;
            buttonWidth = 0.6*puzzlePacksFrame.size.width;
            buttonHeight = buttonWidth/8.0;
            backButtonIconSizeInPoints = 60;
            scrollContentOffset = 550;
            homeButtonWidthToHeightRatio = 0.4;
            titleFrame = CGRectMake(0.5*puzzlePacksFrame.size.width - 0.5*rc.screenWidthInPixels/rc.contentScaleFactor/2.0,
                                    2.0*titleLabelSize,
                                    0.5*rc.screenWidthInPixels/rc.contentScaleFactor,
                                    titleLabelSize);
            scrollViewFrame= CGRectMake(homeFrame.origin.x,
                                        4.0*titleLabelSize,
                                        homeFrame.size.width,
                                        homeFrame.size.height-280);
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            titleLabelSize = 36;
            packFontSize = 24;
            backButtonFontSize = 28;
            buttonWidth = 0.6*puzzlePacksFrame.size.width;
            buttonHeight = buttonWidth/8.0;
            backButtonIconSizeInPoints = 60;
            scrollContentOffset = 60;
            homeButtonWidthToHeightRatio = 0.4;
            titleFrame = CGRectMake(0.5*puzzlePacksFrame.size.width - 0.5*rc.screenWidthInPixels/rc.contentScaleFactor/2.0,
                                    2.0*titleLabelSize,
                                    0.5*rc.screenWidthInPixels/rc.contentScaleFactor,
                                    titleLabelSize);
            scrollViewFrame= CGRectMake(homeFrame.origin.x,
                                        4.0*titleLabelSize,
                                        homeFrame.size.width,
                                        homeFrame.size.height-300);
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            titleLabelSize = 36;
            packFontSize = 24;
            backButtonFontSize = 28;
            buttonWidth = 0.6*puzzlePacksFrame.size.width;
            buttonHeight = buttonWidth/8.0;
            backButtonIconSizeInPoints = 60;
            scrollContentOffset = 0;
            homeButtonWidthToHeightRatio = 0.4;
            titleFrame = CGRectMake(0.5*puzzlePacksFrame.size.width - 0.5*rc.screenWidthInPixels/rc.contentScaleFactor/2.0,
                                    2.0*titleLabelSize,
                                    0.5*rc.screenWidthInPixels/rc.contentScaleFactor,
                                    titleLabelSize);
            scrollViewFrame= CGRectMake(homeFrame.origin.x,
                                        4.0*titleLabelSize,
                                        homeFrame.size.width,
                                        homeFrame.size.height-290);
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            titleLabelSize = 24;
            packFontSize = 20;
            backButtonFontSize = 14;
            buttonWidth = 0.8*puzzlePacksFrame.size.width;
            buttonHeight = buttonWidth/8.0;
            backButtonIconSizeInPoints = 40;
            scrollContentOffset = 30;
            homeButtonWidthToHeightRatio = 0.5;
            titleFrame = CGRectMake(0.5*puzzlePacksFrame.size.width - 0.5*rc.screenWidthInPixels/rc.contentScaleFactor/2.0,
                                    2.0*titleLabelSize,
                                    0.5*rc.screenWidthInPixels/rc.contentScaleFactor,
                                    titleLabelSize);
            scrollViewFrame= CGRectMake(homeFrame.origin.x,
                                        4.0*titleLabelSize,
                                        homeFrame.size.width,
                                        homeFrame.size.height-170);
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            titleLabelSize = 22;
            packFontSize = 12;
            backButtonFontSize = 16;
            buttonWidth = 0.8*puzzlePacksFrame.size.width;
            buttonHeight = buttonWidth/8.0;
            backButtonIconSizeInPoints = 40;
            scrollContentOffset = -40;
            homeButtonWidthToHeightRatio = 0.5;
            titleFrame = CGRectMake(0.5*puzzlePacksFrame.size.width - 0.5*rc.screenWidthInPixels/rc.contentScaleFactor/2.0,
                                    4.0*titleLabelSize,
                                    0.5*rc.screenWidthInPixels/rc.contentScaleFactor,
                                    titleLabelSize);
            scrollViewFrame= CGRectMake(homeFrame.origin.x,
                                        6.0*titleLabelSize,
                                        homeFrame.size.width,
                                        homeFrame.size.height-240);
            break;
        }
    }
    
    // Create packsView
    packsView = [[UIView alloc] initWithFrame:puzzlePacksFrame];
    self.view = packsView;
    packsView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    packsView.layer.cornerRadius = 25;
    packsView.layer.masksToBounds = YES;
    
    // Set background color and graphic image
    packsView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.14 alpha:1.0];
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
    UIImageView *packsViewBackground = [[UIImageView alloc]initWithImage:newImage];
    packsViewBackground.contentMode = UIViewContentModeScaleAspectFill;
    packsViewBackground.clipsToBounds = YES;
    [packsView addSubview:packsViewBackground];
    [packsView bringSubviewToFront:packsViewBackground];

    // Set filter frame to improve icon grid and text contrast
    CGRect filterFrame = CGRectMake(0.05*self.view.frame.size.width,
                                    0.05*self.view.frame.size.height,
                                    0.9*self.view.frame.size.width,
                                    0.9*self.view.frame.size.height);
    UILabel *filterLabel = [[UILabel alloc] initWithFrame:filterFrame];
    filterLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.60];
    filterLabel.layer.masksToBounds = YES;
    filterLabel.layer.cornerRadius = 15;
    [packsView addSubview:filterLabel];
    [packsView bringSubviewToFront:filterLabel];

    // Create contentView
    contentView = [[UIView alloc] initWithFrame:puzzlePacksContentFrame];
    
    // packsViewLabel
//    CGFloat w = 0.5*puzzlePacksFrame.size.width;
    CGFloat h = 1.5*titleLabelSize;
    UILabel *packsViewLabel = [[UILabel alloc] initWithFrame:titleFrame];
    packsViewLabel.text = @"Packs";
    packsViewLabel.textColor = [UIColor cyanColor];
    packsViewLabel.layer.borderColor = [UIColor clearColor].CGColor;
    packsViewLabel.layer.borderWidth = 1.0;
    [packsViewLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:titleLabelSize]];
    packsViewLabel.textAlignment = NSTextAlignmentCenter;
    packsViewLabel.adjustsFontSizeToFitWidth = NO;
    [packsView addSubview:packsViewLabel];
    [packsView bringSubviewToFront:packsViewLabel];
    
    //
    // backButton icon
    //
    // Create a back arrow icon at the left hand side
    UIButton *homeArrow = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect homeArrowRect = CGRectMake(h/2,
                                      titleFrame.origin.y,
                                      backButtonIconSizeInPoints,
                                      backButtonIconSizeInPoints);
    homeArrow.frame = homeArrowRect;
    homeArrow.enabled = YES;
    [homeArrow addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImage *homeArrowImage = [UIImage imageNamed:@"homeArrow.png"];
    [homeArrow setBackgroundImage:homeArrowImage forState:UIControlStateNormal];
    [packsView addSubview:homeArrow];
    [packsView bringSubviewToFront:homeArrow];

    //
    // Load button images
    //
    btnImageFree = [UIImage imageNamed:@"cyanRectangle.png"];
    btnSelectedImageFree = [UIImage imageNamed:@"cyanRectangleSelected.png"];
    btnImagePaid = [UIImage imageNamed:@"yellowRectangle.png"];
    btnSelectedImagePaid = [UIImage imageNamed:@"yellowRectangleSelected.png"];
    btnImageLocked = [UIImage imageNamed:@"locked.png"];

    [self buildPackSelectionButtons];
    
    CGFloat packsFrameWidth = homeFrame.size.width;
    CGFloat packsFrameHeight = buttonCy + 4.0*buttonHeight;
    CGFloat packsFramePositionX = homeFrame.origin.x + (homeFrame.size.width - packsFrameWidth)/2.0;
    CGFloat packsFramePositionY = homeFrame.origin.y;

    [contentView setFrame:CGRectMake(packsFramePositionX, packsFramePositionY, packsFrameWidth, packsFrameHeight)];

    // Create UIScrollView
    scrollView = [[UIScrollView alloc] initWithFrame:scrollViewFrame];
    [scrollView addSubview:contentView];
    scrollView.contentSize = CGSizeMake(contentView.frame.size.width,
                                        contentView.frame.size.height);
    
    scrollView.contentOffset = CGPointMake(0, 0);
    scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);

    scrollView.showsVerticalScrollIndicator = YES;
    scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    scrollView.bounces = YES;
    [packsView addSubview:scrollView];
    [packsView bringSubviewToFront:scrollView];
    
    [self highlightCurrentlySelectedPack];
    [rc loadAppropriateSizeBannerAd];
}

- (void)buildPackSelectionButtons {
    DLog("> buildPackSelectionButtons");
    // First remove any existing buttons
    [self removeEveryPackButton];
    //
    // Add pack selections buttons to packsView
    //
    NSMutableArray *packsArray = [NSMutableArray arrayWithCapacity:1];
    if (appd.storeKitDataHasBeenReceived &&
        appd->arrayOfPuzzlePacksInfoValid  &&
        appd.arrayOfPuzzlePacksInfo != nil &&
        [appd.arrayOfPuzzlePacksInfo count] > 0){
        packsArray = [NSMutableArray arrayWithArray:[NSArray arrayWithArray:appd.arrayOfPuzzlePacksInfo]];
    }
    else {
        packsArray = [appd fetchPacksArray:@"puzzlePacksArray.plist"];
    }
    if ([packsArray count] > 0){
        NSEnumerator *packsEnum = [packsArray objectEnumerator];
        UIButton *packButton, *lockImage;
        CGFloat buttonCx = 0;
        buttonCy = 0;
        CGFloat packsButtonY = 0.0;
        CGRect buttonRect, lockRect;
        puzzlePacksButtonsArray = [NSMutableArray arrayWithCapacity:1];
        puzzlePacksLockIconsArray = [NSMutableArray arrayWithCapacity:1];
        NSMutableDictionary *packDictionary;
        unsigned packDisplayIndex = 0;
        unsigned packIndex = 0;
        while (packDictionary = [packsEnum nextObject]){
            unsigned packNumber = packIndex;
            NSString *packTitle;
            packButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [packButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Light" size:[self querySmallFontSize]]];
            [puzzlePacksButtonsArray insertObject:packButton atIndex:packIndex];
            buttonCx = puzzlePacksFrame.size.width/2.0;
            buttonCy = packsButtonY + (1.2*(float)(packDisplayIndex))*buttonHeight;
            buttonRect = CGRectMake(buttonCx-buttonWidth/2.0, buttonCy, buttonWidth, buttonHeight);
            packButton.frame = buttonRect;
            packButton.layer.borderWidth = 0.0f;
            
            lockImage = nil;
            CGFloat lockHeight = 0.75*buttonHeight;
            lockImage = [UIButton buttonWithType:UIButtonTypeCustom];
            [puzzlePacksLockIconsArray insertObject:lockImage atIndex:packIndex];
            lockRect = CGRectMake(buttonCx+buttonWidth/2.0-1.1*lockHeight, buttonCy+buttonHeight/2.0-lockHeight/2.0, lockHeight, lockHeight);
            lockImage.frame = lockRect;
            [lockImage setBackgroundImage:btnImageLocked forState:UIControlStateNormal];
            [lockImage setBackgroundImage:btnImageLocked forState:UIControlStateHighlighted];
            lockImage.hidden = YES;
            
            long packCost = [[packDictionary objectForKey:@"AppStorePackCost"] integerValue];
            NSString *packName = [packDictionary objectForKey:@"pack_name"];
            UIImage *btnImagePackCompleted = [UIImage imageNamed:@"grayRectangle.png"];
            UIImage *packButtonCheckMarkImage = nil;
            if (packCost == 0){
                // Free Pack
                [packButton setBackgroundImage:btnImageFree forState:UIControlStateNormal];
                if ([appd queryNumberOfPuzzlesLeftInPack:packNumber] == 0){
                    // All puzzles solved
                    [packButton setBackgroundImage:btnImagePackCompleted forState:UIControlStateNormal];
                    [packButton setBackgroundImage:btnImagePackCompleted forState:UIControlStateHighlighted];
                    packTitle = [NSString stringWithFormat:@"%s", [packName UTF8String]];
                    packButtonCheckMarkImage = [UIImage imageNamed:@"CheckmarkInCircle.png"];
                }
                else if ([appd queryNumberOfPuzzlesLeftInPack:packNumber] == 1){
                    // One puzzle left
                    [packButton setBackgroundImage:btnSelectedImageFree forState:UIControlStateHighlighted];
                    [packButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                    packTitle = [NSString stringWithFormat:@"%s -  %d left", [packName UTF8String], [appd queryNumberOfPuzzlesLeftInPack:packNumber]];
                }
                else {
                    // > 1 puzzle left
                    [packButton setBackgroundImage:btnSelectedImageFree forState:UIControlStateHighlighted];
                    [packButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                    packTitle = [NSString stringWithFormat:@"%s -  %d left", [packName UTF8String], [appd queryNumberOfPuzzlesLeftInPack:packNumber]];
                }
                [packButton setTitle:packTitle forState:UIControlStateNormal];
                packButton.enabled = YES;
            }
            else {
                // Paid Pack
                if ([appd queryPurchasedPuzzlePack:packNumber]){
                    // This pack has been purchased
                    if ([appd queryNumberOfPuzzlesLeftInPack:packNumber] == 0){
                        // All puzzles solved
                        [packButton setBackgroundImage:btnImagePackCompleted forState:UIControlStateNormal];
                        [packButton setBackgroundImage:btnImagePackCompleted forState:UIControlStateHighlighted];
                        packTitle = [NSString stringWithFormat:@"%s", [packName UTF8String]];
                        packButtonCheckMarkImage = [UIImage imageNamed:@"CheckmarkInCircle.png"];
                    }
                    else if ([appd queryNumberOfPuzzlesLeftInPack:packNumber] == 1){
                        // One puzzle left
                        [packButton setBackgroundImage:btnImageFree forState:UIControlStateNormal];
                        [packButton setBackgroundImage:btnSelectedImageFree forState:UIControlStateHighlighted];
                        packTitle = [NSString stringWithFormat:@"%s -  %d left", [packName UTF8String], [appd queryNumberOfPuzzlesLeftInPack:packNumber]];
                    }
                    else {
                        // > 1 puzzle left
                        [packButton setBackgroundImage:btnImageFree forState:UIControlStateNormal];
                        [packButton setBackgroundImage:btnSelectedImageFree forState:UIControlStateHighlighted];
                        packTitle = [NSString stringWithFormat:@"%s -  %d left", [packName UTF8String], [appd queryNumberOfPuzzlesLeftInPack:packNumber]];
                    }
                    [packButton setTitle:packTitle forState:UIControlStateNormal];
                    [packButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                    packButton.enabled = YES;
                }
                else {
                    // This pack has not been purchased
                    lockImage.hidden = NO;
                    [packButton setBackgroundImage:btnImagePaid forState:UIControlStateNormal];
                    [packButton setBackgroundImage:btnSelectedImagePaid forState:UIControlStateHighlighted];
                    [packButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                    
                    if (appd.storeKitDataHasBeenReceived &&
                        [packDictionary objectForKey:@"formatted_price_string"] &&
                        appd.applicationIsConnectedToNetwork){
                        NSString *packTitleBeginning = [packDictionary objectForKey:@"formatted_price_string"];
                        NSString *packTitleMiddle = [packTitleBeginning stringByAppendingString:@" - "];
                        packTitle = [packTitleMiddle stringByAppendingString:
                                     packName];
                    }
                    else {
                        packTitle = [NSString stringWithFormat:@"%s -  %d left", [packName UTF8String], [appd queryNumberOfPuzzlesLeftInPack:packNumber]];
                    }
                    [packButton setTitle:packTitle forState:UIControlStateNormal];
                    packButton.enabled = appd.applicationIsConnectedToNetwork;
                }
            }
            if ([appd queryNumberOfPuzzlesLeftInPack:packNumber] > 0){
                packButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                packButton.tag = packIndex;
                [packButton addTarget:self action:@selector(puzzlePackButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                packButton.showsTouchWhenHighlighted = YES;
                [packButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
                [contentView addSubview:packButton];
                [contentView bringSubviewToFront:packButton];
                if (lockImage != nil){
                    [contentView addSubview:lockImage];
                    [contentView bringSubviewToFront:lockImage];
                }
                if (packButtonCheckMarkImage != nil){
                    CGFloat checkmarkHeight = 0.75*buttonHeight;
                    UIButton *checkmarkImage = [UIButton buttonWithType:UIButtonTypeCustom];
                    CGRect checkmarkRect = CGRectMake(buttonCx+buttonWidth/2.0-1.1*checkmarkHeight, buttonCy+buttonHeight/2.0-checkmarkHeight/2.0, checkmarkHeight, checkmarkHeight);
                    checkmarkImage.frame = checkmarkRect;
                    [checkmarkImage setBackgroundImage:packButtonCheckMarkImage forState:UIControlStateNormal];
                    [checkmarkImage setBackgroundImage:packButtonCheckMarkImage forState:UIControlStateHighlighted];
                    [contentView addSubview:checkmarkImage];
                    [contentView bringSubviewToFront:checkmarkImage];
                }
                packDisplayIndex++;
            }
            packIndex++;
        }
    }
    DLog("< buildPackSelectionButtons");
}

- (void)viewDidAppear:(BOOL)animated {
    DLog("BMDPacksViewController.viewDidAppear");
    [appd playMusicLoop:appd.loop1Player];
    [self updateAllPackTitles];
    NSString *adFree = [appd getObjectFromDefaults:@"AD_FREE_PUZZLES"];
    if (![adFree isEqualToString:@"YES"]){
        [packsView addSubview:rc.bannerAdView];
        [packsView bringSubviewToFront:rc.bannerAdView];
    }
    rc.gamekitAccessPoint.active = NO;
    if (ENABLE_GA == YES){
        
        [FIRAnalytics logEventWithName:kFIREventSelectContent
                            parameters:@{
            kFIRParameterItemID:[NSString stringWithFormat:@"id-%@", @"PacksVC viewDidAppear"],
            kFIRParameterItemName:@"PacksVC viewDidAppear",
            kFIRParameterContentType:@"image"
        }];
    }}

- (void)updateOnePackButtonTitle:(int)packDisplayIndex
                      packNumber:(int)packNumber
                          button:(UIButton *)button {
    NSMutableString *packName = [[NSMutableString alloc] init];
    packName = [appd queryPuzzlePackName:packName pack:packDisplayIndex];
    int unsolvedCount = [appd queryNumberOfPuzzlesLeftInPack:packNumber];
    NSMutableAttributedString *packTitle1, *packTitle2;
    NSString *packTitle = [NSString stringWithFormat:@"%s", [packName UTF8String]];
    packTitle1 = [[NSMutableAttributedString alloc] initWithString:packTitle];
    if (unsolvedCount == 0){
        packTitle = [NSString stringWithFormat:@""];
    }
    else if (unsolvedCount == 1) {
        packTitle = [NSString stringWithFormat:@" - %d left", unsolvedCount];
    }
    else {
        packTitle = [NSString stringWithFormat:@" - %d left", unsolvedCount];
    }
    
    NSRange range2 = NSMakeRange(0, [packTitle1 length]);
    [packTitle1 addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFang SC Semibold" size:[self querySmallFontSize]] range:range2];
    
    NSRange range1 = NSMakeRange(0, [packTitle length]);
    packTitle2 = [[NSMutableAttributedString alloc] initWithString:packTitle];
    [packTitle2 addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFang SC Semibold" size:[self querySmallFontSize]] range:range1];
    [packTitle1 appendAttributedString:packTitle2];
    if (button == nil){
        if ([puzzlePacksButtonsArray count] > packDisplayIndex){
            UIButton *packButton = [puzzlePacksButtonsArray objectAtIndex:packDisplayIndex];
            [packButton setAttributedTitle:packTitle1 forState:UIControlStateNormal];
        }
    }
    else {
        [button setAttributedTitle:packTitle1 forState:UIControlStateNormal];
    }
}

- (void)highlightCurrentlySelectedPack {
    // First set all pack button borders to thin width and white color
    UIButton *packButtonObject;
    // Set the pack button corresponding to currentPackIndex to thick width
    unsigned int currentPackNumber = [appd fetchCurrentPackNumber];
    unsigned int currentPackIndex = [appd fetchPackIndexForPackNumber:currentPackNumber];
    if ([puzzlePacksButtonsArray count] > currentPackIndex){
        packButtonObject = [puzzlePacksButtonsArray objectAtIndex:currentPackIndex];
        packButtonObject.layer.borderColor = [UIColor colorWithRed:251.0/255.0
                                                             green:212.0/255.0
                                                              blue:12.0/255.0
                                                             alpha:1.0].CGColor;
        packButtonObject.layer.borderWidth = 4.0f;
    }
}

- (void)unHighlightAllPacks {
    // First set all pack button borders to thin width and white color
    NSEnumerator *packButtonEnum = [puzzlePacksButtonsArray objectEnumerator];
    UIButton *packButtonObject;
    while (packButtonObject = [packButtonEnum nextObject]){
        packButtonObject.layer.borderWidth = 0.0f;
    }
}

- (void)updateAllPackTitles {
    DLog("> updateAllPackTitles");
    // Update the label text for each pack button to reflect its current unsolved puzzle count
//    NSMutableArray *packsArray = [appd.gameDictionaries objectForKey:kPuzzlePacksArray];
    NSMutableArray *packsArray;
    if (appd.storeKitDataHasBeenReceived &&
        appd.arrayOfPuzzlePacksInfo != nil &&
        [appd.arrayOfPuzzlePacksInfo count] > 0){
        packsArray = [NSMutableArray arrayWithArray:[NSArray arrayWithArray:appd.arrayOfPuzzlePacksInfo]];
    }
    else {
        packsArray = [appd fetchPacksArray:@"puzzlePacksArray.plist"];
    }
    if ([packsArray count] > 0){
        NSEnumerator *packsEnum = [packsArray objectEnumerator];
        UIButton *packButton;
        NSString *packTitle;
        NSMutableDictionary *packDictionary;
        unsigned packDisplayIndex = 0;
        while (packDictionary = [packsEnum nextObject]){
            // PKH pack_number {
            //        unsigned int packNumber = [[packDictionary objectForKey:@"pack_number"]intValue];
            unsigned int packNumber = packDisplayIndex;
            // PKH pack_number }
            unsigned int unsolvedCount = [appd queryNumberOfPuzzlesLeftInPack:packNumber];
            long packCost = [[packDictionary objectForKey:@"AppStorePackCost"] integerValue];
            if ([puzzlePacksButtonsArray count] > packDisplayIndex){
                packButton = [puzzlePacksButtonsArray objectAtIndex:packDisplayIndex];
                NSString *packName = [packDictionary objectForKey:@"pack_name"];
                // Free Packs
                if (packCost == 0){
                    [self updateOnePackButtonTitle:packDisplayIndex
                                        packNumber:packNumber
                                            button:packButton];
                    if (unsolvedCount == 0){
                        packButton.backgroundColor = [UIColor clearColor];
                        packButton.enabled = NO;
                    }
                    else {
                        packButton.enabled = YES;
                    }
                }
                // Paid Packs
                else {
                    // Packs that have been purchased
                    if ([appd queryPurchasedPuzzlePack:packNumber]){
                        [self updateOnePackButtonTitle:packDisplayIndex
                                            packNumber:packNumber
                                                button:packButton];
                        if (unsolvedCount == 0){
                            packButton.enabled = NO;
                        }
                        else {
                            packButton.enabled = YES;
                        }
                    }
                    // Packs that have NOT been purchased
                    else {
                        if (appd.storeKitDataHasBeenReceived &&
                            [packDictionary objectForKey:@"formatted_price_string"] &&
                            appd.applicationIsConnectedToNetwork){
                            NSString *packTitleBeginning = [packDictionary objectForKey:@"formatted_price_string"];
                            NSString *packTitleMiddle = [packTitleBeginning stringByAppendingString:@" - "];
                            packTitle = [packTitleMiddle stringByAppendingString:
                                         packName];
                            NSString *packTitle1 = [NSString stringWithFormat:@" - %d left", unsolvedCount];
                            packTitle = [packTitle stringByAppendingString:packTitle1];
                        }
                        else {
                            packTitle = [NSString stringWithFormat:@"%s -  %d left", [packName UTF8String], [appd queryNumberOfPuzzlesLeftInPack:packNumber]];
                        }
                        packButton.enabled = appd.applicationIsConnectedToNetwork;
                        [packButton setTitle:packTitle forState:UIControlStateNormal];
                    }
                }
            }
            packDisplayIndex++;
        }
    }
    DLog("< updateAllPackTitles");

}

//
// Button Press and Gesture Handler Methods Go Here
//

- (void)puzzlePackButtonPressed:(UIButton *)sender {
    [appd playSound:appd.tapPlayer];
    unsigned int packIndex = (unsigned int)sender.tag;
    NSMutableArray *array = [appd.gameDictionaries objectForKey:kPuzzlePacksArray];
    if ([array count] > packIndex){
        NSMutableDictionary *packDictionary = [array objectAtIndex:packIndex];
        unsigned int packNumber = packIndex;
        // PKH pack_number }
        long packCost = [[packDictionary objectForKey:@"AppStorePackCost"] integerValue];
        NSString *packName = [packDictionary objectForKey:@"pack_name"];
        NSString *productionId = [packDictionary objectForKey:@"production_id"];
        if (packCost == 0){
            // Free pack
            rc.startPuzzleButton.backgroundColor = [UIColor clearColor];
            rc.startPuzzleButton.layer.borderColor = [UIColor whiteColor].CGColor;
            [rc.startPuzzleButton setTitle:packName forState:UIControlStateNormal];
            
            unsigned int packNumber = [appd fetchPackNumberForPackIndex:(unsigned int)sender.tag];
            appd.currentPack = packNumber;
            [appd saveCurrentPackNumber:packNumber];
            
            // Handle the various possible calling chains
            if ([self.parentViewController isKindOfClass:[BMDViewController class]]){
                [self willMoveToParentViewController:self.parentViewController];
                [rc startNewPuzzleFromPacksViewController];
                [self.view removeFromSuperview];
                [self removeFromParentViewController];
            }
            else if ([self.parentViewController isKindOfClass:[BMDPuzzleViewController class]]){
                [self willMoveToParentViewController:self.parentViewController];
                [self.parentViewController viewDidLoad];
                [self.view removeFromSuperview];
                [self removeFromParentViewController];
            }
            else {
                DLog("puzzlePackButtonPressed: unknown parentViewController");
            }            
        }
        else {
            if (![appd queryPurchasedPuzzlePack:(int)packNumber]){
                // Paid pack - unpurchased
                [appd purchasePuzzlePack:productionId];
            }
            else {
                // Paid pack - purchased
                rc.startPuzzleButton.backgroundColor = [UIColor clearColor];
                rc.startPuzzleButton.layer.borderColor = [UIColor whiteColor].CGColor;
                [rc.startPuzzleButton setTitle:packName forState:UIControlStateNormal];
                
                unsigned int packNumber = [appd fetchPackNumberForPackIndex:(unsigned int)sender.tag];
                appd.currentPack = packNumber;
                [appd saveCurrentPackNumber:packNumber];
                
                // Handle the various possible calling chains
                if ([self.parentViewController isKindOfClass:[BMDViewController class]]){
                    [self willMoveToParentViewController:self.parentViewController];
                    [rc startNewPuzzleFromPacksViewController];
                    [self.view removeFromSuperview];
                    [self removeFromParentViewController];
                }
                else if ([self.parentViewController isKindOfClass:[BMDPuzzleViewController class]]){
                    [self willMoveToParentViewController:self.parentViewController];
                    [self.parentViewController viewDidLoad];
                    [self.view removeFromSuperview];
                    [self removeFromParentViewController];
                }
                else {
                    DLog("puzzlePackButtonPressed: unknown parentViewController");
                }
                
//                rc.appCurrentGamePackType = PACKTYPE_MAIN;
//                rc.puzzleViewController = [[BMDPuzzleViewController alloc]init];
//                [rc addChildViewController:rc.puzzleViewController];
//                [rc.view addSubview:rc.puzzleViewController.view];
//                [rc.puzzleViewController didMoveToParentViewController:rc];
            }
        }
        DLog("puzzlePackButtonPressed %d", packIndex);
        [self unHighlightAllPacks];
        [self highlightCurrentlySelectedPack];
        [self updateAllPackTitles];
    }
}


- (void)backButtonPressed {
    DLog("BMDPacksViewController.backButtonPressed");
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

//
// Utility Methods Go Here
//

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
            packSmallFontSize = 20;
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            packSmallFontSize = 20;
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            packSmallFontSize = 12;
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            packSmallFontSize = 12;
            break;
        }
    }
    return packSmallFontSize;
}


- (void)removeEveryPackButton {
    if (puzzlePacksButtonsArray &&
        [puzzlePacksButtonsArray count] > 0){
        NSEnumerator *arrayEnum = [puzzlePacksButtonsArray objectEnumerator];
        UIButton *packButton;
        while (packButton = [arrayEnum nextObject]){
            packButton.hidden = YES;
            packButton = nil;
        }
        [puzzlePacksButtonsArray removeAllObjects];
    }
    if (puzzlePacksLockIconsArray &&
        [puzzlePacksLockIconsArray count] > 0){
        NSEnumerator *arrayEnum = [puzzlePacksLockIconsArray objectEnumerator];
        UIButton *lockImageButton;
        while (lockImageButton = [arrayEnum nextObject]){
            lockImageButton.hidden = YES;
            lockImageButton = nil;
        }
        [puzzlePacksLockIconsArray removeAllObjects];
    }
}


- (void)handleNetworkConnectivityChanged:(NSNotification *)notification{
    NSLog(@"Packs - handleNetworkConnectivityChanged - %@",notification.object);
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:notification.userInfo];
    if ([userInfo objectForKey:@"status"] != nil){
        if ([[userInfo objectForKey:@"status"] intValue] == 1 &&
            latchApplicationIsConnectedToNetwork == NO){
            latchApplicationIsConnectedToNetwork = YES;
            [self updateAllPackTitles];
        }
        else if ([[userInfo objectForKey:@"status"] intValue] != 1 &&
                 latchApplicationIsConnectedToNetwork == YES){
            latchApplicationIsConnectedToNetwork = NO;
            [self updateAllPackTitles];
        }
    }
}



@end
