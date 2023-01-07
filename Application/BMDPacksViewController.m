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
    
    CGRect homeFrame = rc.rootView.bounds;
    
    CGRect puzzlePacksFrame = CGRectMake(homeFrame.origin.x,
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
    CGFloat buttonWidth, buttonHeight, homeButtonWidthToHeightRatio;
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
    UIImageView *packsViewBackground = [[UIImageView alloc]initWithImage:newImage];
    packsViewBackground.contentMode = UIViewContentModeScaleAspectFill;
    packsViewBackground.clipsToBounds = YES;
    [packsView addSubview:packsViewBackground];
    [packsView bringSubviewToFront:packsViewBackground];
    
    // Create contentView
    contentView = [[UIView alloc] initWithFrame:puzzlePacksContentFrame];
    
    // packsViewLabel
    CGFloat w = 0.5*puzzlePacksFrame.size.width;
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
    UIButton *backArrow = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect backArrowRect = CGRectMake(h/2,
                                      titleFrame.origin.y,
                                      backButtonIconSizeInPoints,
                                      backButtonIconSizeInPoints);
    backArrow.frame = backArrowRect;
    backArrow.enabled = YES;
    [backArrow addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImage *backArrowImage = [UIImage imageNamed:@"backArrow.png"];
    [backArrow setBackgroundImage:backArrowImage forState:UIControlStateNormal];
    [packsView addSubview:backArrow];
    [packsView bringSubviewToFront:backArrow];

    //
    // Load button images
    //
    UIImage *btnImageFree = [UIImage imageNamed:@"cyanRectangle.png"];
    UIImage *btnSelectedImageFree = [UIImage imageNamed:@"cyanRectangleSelected.png"];
    UIImage *btnImagePaid = [UIImage imageNamed:@"yellowRectangle.png"];
    UIImage *btnSelectedImagePaid = [UIImage imageNamed:@"yellowRectangleSelected.png"];
    UIImage *btnImageLocked = [UIImage imageNamed:@"locked.png"];

    //
    // Add pack selections buttons to packsView
    //
    NSMutableArray *packsArray = [appd.gameDictionaries objectForKey:kPuzzlePacksArray];
    NSEnumerator *packsEnum = [packsArray objectEnumerator];
    UIButton *packButton, *lockImage;
    CGFloat buttonCx = 0, buttonCy = 0;
    CGFloat packsButtonY = 0.0;
    CGRect buttonRect, lockRect;
    puzzlePacksButtonsArray = [NSMutableArray arrayWithCapacity:1];
    puzzlePacksLockIconsArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableDictionary *packDictionary;
    unsigned packDisplayIndex = 0;
    unsigned packIndex = 0;
    while (packDictionary = [packsEnum nextObject]){
        // PKH pack_number {
//        unsigned packNumber = [[packDictionary objectForKey:@"pack_number"]intValue];
        unsigned packNumber = packIndex;
        // PKH pack_number }
        NSString *packTitle;
        packButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [packButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Light" size:[self querySmallFontSize]]];
        [puzzlePacksButtonsArray insertObject:packButton atIndex:packIndex];
        buttonCx = puzzlePacksFrame.size.width/2.0;
        //        buttonCy = packsButtonY + (1.2*(float)(packDisplayIndex + 1))*buttonHeight;
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
                [packButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                //                [self updateOnePackButtonTitle:[packIndex intValue] button:packButton];
            }
            else {
                // This pack has not been purchased
                lockImage.hidden = NO;
                //                CGFloat lockHeight = 0.75*buttonHeight;
                //                lockImage = [UIButton buttonWithType:UIButtonTypeCustom];
                //                lockRect = CGRectMake(buttonCx+buttonWidth/2.0-1.1*lockHeight, buttonCy+buttonHeight/2.0-lockHeight/2.0, lockHeight, lockHeight);
                //                lockImage.frame = lockRect;
                //                [lockImage setBackgroundImage:btnImageLocked forState:UIControlStateNormal];
                //                [lockImage setBackgroundImage:btnImageLocked forState:UIControlStateHighlighted];
                [packButton setBackgroundImage:btnImagePaid forState:UIControlStateNormal];
                [packButton setBackgroundImage:btnSelectedImagePaid forState:UIControlStateHighlighted];
                [packButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                NSString *packTitle = [NSString stringWithFormat:@"$%1.2f - %s -  %d left", (float)packCost/100.0, [packName UTF8String], [appd queryNumberOfPuzzlesLeftInPack:packNumber]];
                [packButton setTitle:packTitle forState:UIControlStateNormal];
            }
        }
        if ([appd queryNumberOfPuzzlesLeftInPack:packNumber] > 0){
            packButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
            packButton.tag = packIndex;
            [packButton addTarget:self action:@selector(puzzlePackButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            packButton.showsTouchWhenHighlighted = YES;
            [packButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
            w = buttonWidth;  h = w/8;
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
    
    CGFloat packsFrameWidth = homeFrame.size.width;
    CGFloat packsFrameHeight = buttonCy + 4.0*buttonHeight;
    CGFloat packsFramePositionX = homeFrame.origin.x + (homeFrame.size.width - packsFrameWidth)/2.0;
    CGFloat packsFramePositionY = homeFrame.origin.y;
//    CGFloat packsFramePositionY = homeFrame.origin.y + (homeFrame.size.height - packsFrameHeight)/2.0;

    [contentView setFrame:CGRectMake(packsFramePositionX, packsFramePositionY, packsFrameWidth, packsFrameHeight)];
//    [contentView setFrame:CGRectMake(scrollViewFrame.origin.x, scrollViewFrame.origin.y, packsFrameWidth, packsFrameHeight)];

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

- (void)viewDidAppear:(BOOL)animated {
    [self updateAllPackTitles];
    NSString *adFree = [appd getObjectFromDefaults:@"AD_FREE_PUZZLES"];
    if (![adFree isEqualToString:@"YES"]){
        [packsView addSubview:rc.bannerAdView];
        [packsView bringSubviewToFront:rc.bannerAdView];
    }
    rc.gamekitAccessPoint.active = NO;
#ifdef ENABLE_GA

    [FIRAnalytics logEventWithName:kFIREventSelectContent
                        parameters:@{
                                     kFIRParameterItemID:[NSString stringWithFormat:@"id-%@", @"PacksVC viewDidAppear"],
                                     kFIRParameterItemName:@"PacksVC viewDidAppear",
                                     kFIRParameterContentType:@"image"
                                     }];
#endif
}

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
    // Update the label text for each pack button to reflect its current unsolved puzzle count
    NSMutableArray *packsArray = [appd.gameDictionaries objectForKey:kPuzzlePacksArray];
    NSEnumerator *packsEnum = [packsArray objectEnumerator];
    UIButton *packButton;
    NSString *packTitle;
    NSMutableAttributedString *packTitle1, *packTitle2;
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
                    packTitle = [NSString stringWithFormat:@"$%1.2f - %s", (float)packCost/100.0, [packName UTF8String]];
                    packTitle1 = [[NSMutableAttributedString alloc] initWithString:packTitle];
                    packTitle = [NSString stringWithFormat:@" - %d left", unsolvedCount];
                    NSRange range1 = NSMakeRange(0, [packTitle length]);
                    packTitle2 = [[NSMutableAttributedString alloc] initWithString:packTitle];
                    [packTitle2 addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFang SC Semibold" size:[self querySmallFontSize]] range:range1];
                    [packTitle1 appendAttributedString:packTitle2];
                    packButton.enabled = YES;
                    [packButton setAttributedTitle:packTitle1 forState:UIControlStateNormal];
                }
            }
        }
        packDisplayIndex++;
    }
}

//
// Button Press and Gesture Handler Methods Go Here
//

- (void)puzzlePackButtonPressed:(UIButton *)sender {
    [appd playSound:appd.tapSoundFileObject];
    unsigned int packIndex = (unsigned int)sender.tag;
    NSMutableArray *array = [appd.gameDictionaries objectForKey:kPuzzlePacksArray];
    if ([array count] > packIndex){
        NSMutableDictionary *packDictionary = [array objectAtIndex:packIndex];
        // PKH pack_number {
//        unsigned int packNumber = [[packDictionary objectForKey:@"pack_number"]intValue];
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

            rc.appCurrentGamePackType = PACKTYPE_MAIN;
            BMDPuzzleViewController *puzzleViewController = [[BMDPuzzleViewController alloc]init];
            [rc addChildViewController:puzzleViewController];
            [rc.view addSubview:puzzleViewController.view];
            [puzzleViewController didMoveToParentViewController:rc];
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
                
                rc.appCurrentGamePackType = PACKTYPE_MAIN;
                BMDPuzzleViewController *puzzleViewController = [[BMDPuzzleViewController alloc]init];
                [rc addChildViewController:puzzleViewController];
                [rc.view addSubview:puzzleViewController.view];
                [puzzleViewController didMoveToParentViewController:rc];
            }
        }
        DLog("puzzlePackButtonPressed %d", packIndex);
        [self unHighlightAllPacks];
        [self highlightCurrentlySelectedPack];
        [self updateAllPackTitles];
    }
}

- (void)backButtonPressed {
    DLog("backButtonPressed");
    [appd playSound:appd.tapSoundFileObject];
    [(BMDViewController *)self.parentViewController refreshHomeView];
    [self willMoveToParentViewController:self.parentViewController];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    rc.renderON = NO;
    [rc refreshHomeView];
    [rc loadAppropriateSizeBannerAd];
    [rc startMainScreenMusicLoop];
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

@end
