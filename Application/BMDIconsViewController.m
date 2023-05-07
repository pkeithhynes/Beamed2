//
//  BMDIconsViewController.m
//  Beamed
//
//  Created by Patrick Keith-Hynes on 3/23/23.
//  Copyright © 2023 Apple. All rights reserved.
//

#import "BMDIconsViewController.h"
#import "BMDAppDelegate.h"
#import "BMDPuzzleViewController.h"
#import "Firebase.h"

@import UIKit;


@interface BMDIconsViewController ()

@end

@implementation BMDIconsViewController{
    BMDViewController *rc;
    BMDPuzzleViewController *vc;
    BMDAppDelegate *appd;
    
    // Values needed for alt icon grid layout
    unsigned int nrows, ncols, iconGridSizeInPoints, iconsYoffset;
    unsigned int posY;
    CGFloat settingsLabelY;
}

@synthesize iconsView;
@synthesize alternateIconsArray;
@synthesize alternateIconsButtonsArray;
@synthesize alternateIconsPriceLabelArray;

    
- (void)viewDidLoad {
    
    [super viewDidLoad];

    rc = (BMDViewController*)[[(BMDAppDelegate *)[[UIApplication sharedApplication]delegate] window] rootViewController];
    appd = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // No banner ads in this UIViewController
    [appd vungleCloseBannerAd];
    
//    [[NSNotificationCenter defaultCenter]
//     addObserver: self
//     selector: @selector (handleStoreKitDataReceived:)
//     name: @"storeKitDataReceived"
//     object: nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector (handleNetworkConnectivityChanged:)
     name: @"com.beamed.network.status-change"
     object: nil];
    
    // Detect when app gains focus so you can refresh Alt Icons
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector (handleUIApplicationDidBecomeActiveNotification)
     name: UIApplicationDidBecomeActiveNotification
     object: nil];

    // Register to receive notifications regarding Alt Icon purchases
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector (handleAltIconPurchased:)
     name: @"altIconPurchased"
     object: nil];
    
    [appd playMusicLoop:appd.loop1Player];

    // Use live StoreKit data if it is available
    if (appd.arrayOfAltIconsInfo != nil &&
        [appd.arrayOfAltIconsInfo count] > 0){
        alternateIconsArray = [NSMutableArray arrayWithCapacity:1];
        alternateIconsArray = [self fetchAlternateIconsArray:alternateIconsArray
                                      alternateIconsArrayFromStoreKit:appd.arrayOfAltIconsInfo];
    }
    // else try to load it from StoreKit if Data Network is connected
    else if (appd.applicationIsConnectedToNetwork &&
             !appd.storeKitDataHasBeenReceived &&
             appd.productsRequestEnum == REQ_NIL){
        appd.arrayOfPuzzlePacksInfo = nil;
        [appd requestPuzzlePacksInfo];
        alternateIconsArray = [NSMutableArray arrayWithCapacity:1];
        alternateIconsArray = [self fetchAlternateIconsArray:alternateIconsArray
                                      alternateIconsArrayFromStoreKit:appd.arrayOfAltIconsInfo];
    }
    // else use the Alt Icon plist from the app bundle
    else {
        alternateIconsArray = [NSMutableArray arrayWithCapacity:1];
        alternateIconsArray = [self fetchAlternateIconsArray:alternateIconsArray];
    }
    
    // Debug layout - show all icons in bundle plist
//    alternateIconsArray = [NSMutableArray arrayWithCapacity:1];
//    alternateIconsArray = [self fetchAlternateIconsArray:alternateIconsArray];


    if (alternateIconsArray != nil){
                
        iconsView = [[UIView alloc] initWithFrame:rc.rootView.bounds];
        self.view = iconsView;
        iconsView.backgroundColor = [UIColor blackColor];
        iconsView.layer.cornerRadius = 25;
        iconsView.layer.masksToBounds = YES;
        
        // Set background graphic image
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"coffeeRobotNeon" ofType:@"png"];
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
        UIImageView *iconsViewBackground = [[UIImageView alloc]initWithImage:newImage];
        iconsViewBackground.contentMode = UIViewContentModeScaleAspectFill;
        iconsViewBackground.clipsToBounds = YES;
        iconsViewBackground.alpha = 1.0;
        [iconsView addSubview:iconsViewBackground];
        [iconsView bringSubviewToFront:iconsViewBackground];
        
        // Set filter frame to improve icon grid and text contrast
        CGRect filterFrame = CGRectMake(0.05*self.view.frame.size.width,
                                        0.05*self.view.frame.size.height,
                                        0.9*self.view.frame.size.width,
                                        0.9*self.view.frame.size.height);
        UILabel *filterLabel = [[UILabel alloc] initWithFrame:filterFrame];
        filterLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.65];
        filterLabel.layer.masksToBounds = YES;
        filterLabel.layer.cornerRadius = 15;
        [iconsView addSubview:filterLabel];
        [iconsView bringSubviewToFront:filterLabel];

        
        CGFloat titleLabelSize, optionLabelSize, buttonHeight, buttonWidth, homeButtonWidthToHeightRatio;
        CGFloat backButtonIconSizeInPoints = 60;
        CGFloat switchCx;
        CGFloat w, h, backButtonY;
        switch (rc.displayAspectRatio) {
            case ASPECT_4_3:{
                // iPad (9th generation)
                titleLabelSize = 36;
                optionLabelSize = 32;
                backButtonIconSizeInPoints = 60;
                buttonWidth = 0.6*rc.rootView.bounds.size.width;
                buttonHeight = buttonWidth/8.0;
                homeButtonWidthToHeightRatio = 0.4;
                switchCx = 0.74*rc.screenWidthInPixels/rc.contentScaleFactor;
                w = 0.8*rc.rootView.bounds.size.width;
                h = 1.5*titleLabelSize;
                backButtonY = 1.0*h;
                settingsLabelY = 1.0*h;
                nrows = 5;
                ncols = 4;
                iconGridSizeInPoints = 0.8*rc.rootView.bounds.size.width/nrows;
                iconsYoffset = 2.5*h;
                break;
            }
            case ASPECT_10_7:{
                // iPad Air (5th generation)
                titleLabelSize = 36;
                optionLabelSize = 32;
                backButtonIconSizeInPoints = 60;
                buttonWidth = 0.6*rc.rootView.bounds.size.width;
                buttonHeight = buttonWidth/8.0;
                homeButtonWidthToHeightRatio = 0.4;
                switchCx = 0.74*rc.screenWidthInPixels/rc.contentScaleFactor;
                w = 0.8*rc.rootView.bounds.size.width;
                h = 1.5*titleLabelSize;
                backButtonY = 1.0*h;
                settingsLabelY = 2.0*h;
                nrows = 5;
                ncols = 4;
                iconGridSizeInPoints = 0.8*rc.rootView.bounds.size.width/nrows;
                iconsYoffset = 2.5*h;
                break;
            }
            case ASPECT_3_2: {
                // iPad Mini (6th generation)
                titleLabelSize = 36;
                optionLabelSize = 32;
                backButtonIconSizeInPoints = 60;
                buttonWidth = 0.6*rc.rootView.bounds.size.width;
                buttonHeight = buttonWidth/8.0;
                homeButtonWidthToHeightRatio = 0.4;
                switchCx = 0.74*rc.screenWidthInPixels/rc.contentScaleFactor;
                w = 0.8*rc.rootView.bounds.size.width;
                h = 1.5*titleLabelSize;
                backButtonY = 1.0*h;
                settingsLabelY = 2.0*h;
                nrows = 5;
                ncols = 4;
                iconGridSizeInPoints = 0.8*rc.rootView.bounds.size.width/nrows;
                iconsYoffset = 2.5*h;
                break;
            }
            case ASPECT_16_9: {
                // iPhone 8
                titleLabelSize = 22;
                optionLabelSize = 22;
                backButtonIconSizeInPoints = 40;
                buttonWidth = 0.8*rc.rootView.bounds.size.width;
                buttonHeight = buttonWidth/8.0;
                homeButtonWidthToHeightRatio = 0.5;
                switchCx = 0.65*rc.screenWidthInPixels/rc.contentScaleFactor;
                w = 0.8*rc.rootView.bounds.size.width;
                h = 1.5*titleLabelSize;
                backButtonY = 1.0*h;
                settingsLabelY = 2.0*h;
                nrows = 5;
                ncols = 4;
                iconGridSizeInPoints = 0.8*rc.rootView.bounds.size.width/ncols;
                iconsYoffset = 3.5*h;
                break;
            }
            case ASPECT_13_6: {
                // iPhone 14
                titleLabelSize = 20;
                optionLabelSize = 20;
                backButtonIconSizeInPoints = 40;
                buttonWidth = 0.8*rc.rootView.bounds.size.width;
                buttonHeight = buttonWidth/8.0;
                homeButtonWidthToHeightRatio = 0.5;
                switchCx = 0.65*rc.screenWidthInPixels/rc.contentScaleFactor;
                w = 0.8*rc.rootView.bounds.size.width;
                h = 1.5*titleLabelSize;
                backButtonY = 1.5*h;
                settingsLabelY = 3.0*h;
                nrows = 5;
                ncols = 4;
                iconGridSizeInPoints = 0.8*rc.rootView.bounds.size.width/ncols;
                iconsYoffset = 3.0*h;
                break;
            }
        }
        
        //
        // backButton icon
        //
        // Create a back arrow icon at the left hand side
        UIButton *homeArrow = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect homeArrowRect = CGRectMake(h/2,
                                          backButtonY,
                                          backButtonIconSizeInPoints,
                                          backButtonIconSizeInPoints);
        homeArrow.frame = homeArrowRect;
        homeArrow.enabled = YES;
        [homeArrow addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        UIImage *homeArrowImage = [UIImage imageNamed:@"homeArrow.png"];
        [homeArrow setBackgroundImage:homeArrowImage forState:UIControlStateNormal];
        [iconsView addSubview:homeArrow];
        [iconsView bringSubviewToFront:homeArrow];
        
        
        // Label 1
        CGRect iconsLabelFrame = CGRectMake(0.5*rc.rootView.bounds.size.width - w/2.0,
                                            settingsLabelY,
                                            w,
                                            2.5*h);
        UILabel *iconsPageLabel1 = [[UILabel alloc] initWithFrame:iconsLabelFrame];
        iconsPageLabel1.text = @"Buy us a snack and choose a new App Icon for yourself!";
        iconsPageLabel1.numberOfLines = 0;
        iconsPageLabel1.layer.borderColor = [UIColor clearColor].CGColor;
        iconsPageLabel1.textColor = [UIColor cyanColor];
        iconsPageLabel1.layer.borderWidth = 1.0;
        [iconsPageLabel1 setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:titleLabelSize]];
        iconsPageLabel1.textAlignment = NSTextAlignmentCenter;
        iconsPageLabel1.adjustsFontSizeToFitWidth = NO;
        [iconsView addSubview:iconsPageLabel1];
        [iconsView bringSubviewToFront:iconsPageLabel1];
        
        // Create and display a grid of alt icon UIButtons
        [self buildAltIconButtons];
        
        // Label 2
        iconsLabelFrame = CGRectMake(0.5*rc.rootView.bounds.size.width - w/2.0,
                                     posY + 2.5*h,
                                     w,
                                     1.0*h);
        UILabel *iconsPageLabel2 = [[UILabel alloc] initWithFrame:iconsLabelFrame];
        iconsPageLabel2.text = @"Check back for new icons!";
        iconsPageLabel2.numberOfLines = 0;
        iconsPageLabel2.layer.borderColor = [UIColor clearColor].CGColor;
        iconsPageLabel2.textColor = [UIColor cyanColor];
        iconsPageLabel2.layer.borderWidth = 1.0;
        [iconsPageLabel2 setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:titleLabelSize]];
        iconsPageLabel2.textAlignment = NSTextAlignmentCenter;
        iconsPageLabel2.adjustsFontSizeToFitWidth = NO;
        [iconsView addSubview:iconsPageLabel2];
        [iconsView bringSubviewToFront:iconsPageLabel2];
    }
}


//
// Utility Methods
//
- (void)removeEveryAltIconButton {
    if (alternateIconsButtonsArray &&
        [alternateIconsButtonsArray count] > 0){
        NSEnumerator *arrayEnum = [alternateIconsButtonsArray objectEnumerator];
        UIButton *iconButton;
        while (iconButton = [arrayEnum nextObject]){
            iconButton.hidden = YES;
            iconButton = nil;
        }
        [alternateIconsButtonsArray removeAllObjects];
        
        arrayEnum = [alternateIconsPriceLabelArray objectEnumerator];
        UILabel *priceLabel;
        while (priceLabel = [arrayEnum nextObject]){
            priceLabel.hidden = YES;
            priceLabel = nil;
        }
        [alternateIconsPriceLabelArray removeAllObjects];
    }
}

- (void)buildAltIconButtons {
    //
    // Create and display a grid of icon UIButtons
    //
    // First clear out alternateIconsButtonsArray
    [self removeEveryAltIconButton];
    
    alternateIconsButtonsArray = [NSMutableArray arrayWithCapacity:1];
    alternateIconsPriceLabelArray = [NSMutableArray arrayWithCapacity:1];
    unsigned int gridX, gridY;
    unsigned int posX;
    unsigned int arrayLen = (unsigned int)[alternateIconsArray count];
    UIButton *iconButton;
    UILabel *priceLabel;
    NSMutableDictionary *iconDict;
    for (unsigned int idx=0; idx<arrayLen-1; idx++){
        gridX = (idx % ncols);
        gridY = (idx / ncols);
        CGFloat iconGridWidthInPoints = ncols * iconGridSizeInPoints;
        CGFloat gapXinPoints = rc.rootView.bounds.size.width - iconGridWidthInPoints;
        posX = (idx % ncols) * iconGridSizeInPoints + gapXinPoints/2.0;
        posY = (idx / ncols) * iconGridSizeInPoints + settingsLabelY + iconsYoffset;
        iconButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect iconRect = CGRectMake(posX,
                                     posY,
                                     iconGridSizeInPoints,
                                     iconGridSizeInPoints);
        iconButton.frame = iconRect;
        iconButton.tag = idx;
        [iconButton addTarget:self action:@selector(altIconButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        iconDict = [NSMutableDictionary dictionaryWithDictionary:[alternateIconsArray objectAtIndex:idx]];
        iconButton.layer.borderWidth = 0;
        iconButton.layer.cornerRadius = 15;
        iconButton.layer.borderColor = [UIColor grayColor].CGColor;
        if ([iconDict objectForKey:@"formatted_price_string"] != nil){
            iconButton.enabled = YES;
            iconButton.imageView.alpha = 1.0;
        }
        else {
            iconButton.enabled = NO;
            iconButton.imageView.alpha = 0.5;
        }
        
        // The iconImage is used as the button background image
        NSString *iconImageFileName = [iconDict objectForKey:@"iconImage"];
        UIImage *iconBackgroundImage = [UIImage imageNamed:iconImageFileName];
        [iconButton setBackgroundImage:iconBackgroundImage forState:UIControlStateNormal];
        
        // The golden crown is used as the foreground image when the icon has been purchased
        priceLabel = nil;
        CGRect priceFrame = CGRectMake(0,
                                       0,
                                       iconGridSizeInPoints/2.0,
                                       iconGridSizeInPoints/3.5);
        
        if ([appd queryPurchasedAltIcon:idx]){
            UIImage *iconImage;
            if ([appd fetchCurrentAltIconNumber] == idx){
                iconImage = [UIImage imageNamed:@"goldenCrownSelectedLayer.png"];
            }
            else {
                iconImage = [UIImage imageNamed:@"goldenCrownLayer.png"];
            }
            [iconButton setImage:iconImage forState:UIControlStateNormal];
            priceLabel.hidden = YES;
        }
        
        if (appd.applicationIsConnectedToNetwork &&
                 appd.storeKitDataHasBeenReceived &&
                 appd.arrayOfAltIconsInfo != nil &&
                 [appd.arrayOfAltIconsInfo count] > 0 &&
                 ![appd queryPurchasedAltIcon:idx]){
            priceLabel = [[UILabel alloc] initWithFrame:priceFrame];
            priceLabel.backgroundColor = [UIColor blackColor];
            priceLabel.layer.masksToBounds = YES;
            priceLabel.layer.cornerRadius = 5;
            if ([iconDict objectForKey:@"formatted_price_string"] != nil){
                priceLabel.text = [iconDict objectForKey:@"formatted_price_string"];
                priceLabel.adjustsFontSizeToFitWidth = YES;
                priceLabel.textAlignment = NSTextAlignmentCenter;
                priceLabel.textColor = [UIColor colorWithRed:251.0/255.0
                                                       green:212.0/255.0
                                                        blue:12.0/255.0
                                                       alpha:1.0];
                priceLabel.layer.borderColor = [UIColor cyanColor].CGColor;
                priceLabel.layer.borderWidth = 1.0;
                [iconButton addSubview:priceLabel];
                [iconButton bringSubviewToFront:priceLabel];
            }
        }
        if (priceLabel){
            [alternateIconsPriceLabelArray addObject:priceLabel];
        }
        [alternateIconsButtonsArray addObject:iconButton];
        
        [iconsView addSubview:iconButton];
        [iconsView bringSubviewToFront:iconButton];
    }
    
    // The element of alternateIconsArray at position arrayLen-1 is the default App Icon
    posX = rc.rootView.bounds.size.width/2.0 - iconGridSizeInPoints/2.0;
    // If the array contains more than just the default icon
    if (arrayLen > 1){
        posY = posY + iconGridSizeInPoints;
    }
    // If only the default icon is in the array adjust posY accordingly
    else {
        posY = iconGridSizeInPoints + settingsLabelY + iconsYoffset;
    }
    iconButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect iconRect = CGRectMake(posX,
                                 posY,
                                 iconGridSizeInPoints,
                                 iconGridSizeInPoints);
    iconButton.frame = iconRect;
    iconButton.enabled = YES;
    iconButton.tag = arrayLen - 1;
    [iconButton addTarget:self action:@selector(defaultIconButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    iconDict = [NSMutableDictionary dictionaryWithDictionary:[alternateIconsArray objectAtIndex:arrayLen-1]];
    iconButton.layer.borderWidth = 0;
    iconButton.layer.cornerRadius = 15;
    iconButton.layer.borderColor = [UIColor grayColor].CGColor;
    // The iconImage is used as the button background image
    NSString *iconImageFileName = [iconDict objectForKey:@"iconImage"];
    UIImage *iconBackgroundImage = [UIImage imageNamed:iconImageFileName];
    [iconButton setBackgroundImage:iconBackgroundImage forState:UIControlStateNormal];
    // Check to see whether the default icon is also the current icon
    if ([appd fetchCurrentAltIconNumber] == -1){
        UIImage *iconImage;
        iconImage = [UIImage imageNamed:@"selectedLayer.png"];
        [iconButton setImage:iconImage forState:UIControlStateNormal];
    }
    [alternateIconsButtonsArray addObject:iconButton];
    [iconsView addSubview:iconButton];
    [iconsView bringSubviewToFront:iconButton];
}

//
// Handler Methods Go Here
//
- (void)handleUIApplicationDidBecomeActiveNotification {
//    if (appd.applicationIsConnectedToNetwork){
//        [self updateEveryUnpurchasedAltIconButton:YES];
//    }
//    else {
//        [self updateEveryUnpurchasedAltIconButton:NO];
//    }
    [self buildAltIconButtons];
}

- (void)handleStoreKitDataReceived:(NSNotification *) notification{
    // Use live StoreKit data if it is available
//    if (appd.arrayOfAltIconsInfo != nil &&
//        [appd.arrayOfAltIconsInfo count] > 0){
//        alternateIconsArray = [NSMutableArray arrayWithArray:[NSArray arrayWithArray:appd.arrayOfAltIconsInfo]];
//        [self buildAltIconButtons];
//        DLog("handleStoreKitDataReceived: success in displaying alt icons");
//    }
//    else {
//        DLog("handleStoreKitDataReceived: failure in displaying alt icons");
//    }
    [self buildAltIconButtons];
}

- (void)handleNetworkConnectivityChanged:(NSNotification *) notification{
    NSLog(@"Icons - handleNetworkConnectivityChanged - %@",notification.object);
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:notification.userInfo];
//    if ([userInfo objectForKey:@"status"] != nil){
//        if ([[userInfo objectForKey:@"status"] intValue] == 1){
//            [self updateEveryUnpurchasedAltIconButton:YES];
//            DLog("Data Network Connected - IconsVC");
//        }
//        else {
//            [self updateEveryUnpurchasedAltIconButton:NO];
//            DLog("Data Network Disconnected - IconsVC");
//        }
//    }
//    else {
//        [self updateEveryUnpurchasedAltIconButton:NO];
//        DLog("Data Network Disconnected - IconsVC");
//    }
    [self buildAltIconButtons];
}

- (void)handleAltIconPurchased:(NSNotification *) notification{
    NSLog(@"%@",notification.object);
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:notification.userInfo];
    NSMutableDictionary *status = [info objectForKey:@"Status"];
    NSNumber *idxNumber = [status objectForKey:@"idx"];
    int idx = [idxNumber intValue];
    [self buildAltIconButtons];
    DLog("handleAltIconPurchased");
}

- (void)defaultIconButtonPressed:(UIButton *)sender {
    DLog("Default Icon Button Pressed");
    BOOL supportsAlternateIcons = [UIApplication.sharedApplication supportsAlternateIcons];
    if (supportsAlternateIcons){
        [UIApplication.sharedApplication setAlternateIconName:nil completionHandler:^(NSError *error){
            if (error == nil){
                DLog("Success: icon changed");
            }
            else {
                DLog("Failure with error");
            }
        }];
    }
    [appd saveCurrentAltIconNumber:-1];
    [self buildAltIconButtons];
}

- (void)altIconButtonPressed:(UIButton *)sender {
    unsigned int idx = (unsigned int)sender.tag;
    NSMutableDictionary *iconDict = [NSMutableDictionary dictionaryWithDictionary:[alternateIconsArray objectAtIndex:idx]];
    [appd playSound:appd.tapPlayer];
    if (![appd queryPurchasedAltIcon:idx]){
        // Alt Icon not yet purchased
        
        // Create and start in-app purchase indicator spinner
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        CGFloat spinnerSquareSize = rc.rootView.bounds.size.width/5.0;
        spinner.frame = CGRectMake(rc.rootView.bounds.size.width/2.0-spinnerSquareSize/2.0,
                                   rc.rootView.bounds.size.height/2.0-spinnerSquareSize/2.0,
                                   spinnerSquareSize,
                                   spinnerSquareSize);
        [spinner startAnimating];
        [iconsView addSubview:spinner];
        [iconsView bringSubviewToFront:spinner];
        
        // Start purchase
        NSString *productionId = [iconDict objectForKey:@"production_id"];
        [appd purchaseAltIcon:productionId];
    }
    else {
        // Alt Icon has been purchased
        [appd saveCurrentAltIconNumber:idx];
        [self buildAltIconButtons];
        NSString *iconName = [iconDict objectForKey:@"appIcon"];
        BOOL supportsAlternateIcons = [UIApplication.sharedApplication supportsAlternateIcons];
        if (supportsAlternateIcons){
            [UIApplication.sharedApplication setAlternateIconName:iconName completionHandler:^(NSError *error){
                if (error == nil){
                    DLog("Success: icon changed");
                }
                else {
                    DLog("Failure with error");
                }
            }];
        }
    }
}

- (void)backButtonPressed {
    DLog("BMDIconsViewController.backButtonPressed");
    [appd playSound:appd.tapPlayer];
    if ([self.parentViewController isKindOfClass:[BMDViewController class]]){
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
        
        // If puzzleHasBeenCompleted then we are here because the user pressed nextButton and we want them
        // to buy an icon.  Go to the next puzzle after this.
        if (appd->optics->puzzleHasBeenCompleted == YES){
            vc = (BMDPuzzleViewController *)self.parentViewController;
            [vc.puzzleView releaseDrawables];

            [vc.view removeFromSuperview];
            [vc removeFromParentViewController];
            [rc startNewPuzzleFromPacksViewController];
            [self.view removeFromSuperview];
            [self removeFromParentViewController];
        }
        else {
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
    }
    else{
        DLog("backButtonPressed parentViewController is unknown");
        [self willMoveToParentViewController:self.parentViewController];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }
}

- (UIImageView *)createImageView:(NSString *)imageFileName
                           width:(CGFloat)width
                            posX:(CGFloat)posX
                            posY:(CGFloat)posY {
    UIImage *image = [UIImage imageNamed:imageFileName];
    CGFloat height = width*image.size.height/image.size.width;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(posX-0.5*width,
                                 posY-0.5*height,
                                 width,
                                 height);
    return imageView;
}

- (NSMutableArray *)fetchAlternateIconsArray:(NSMutableArray *)alternateIconsArray
                      alternateIconsArrayFromStoreKit:(NSMutableArray *)alternateIconsArrayFromStoreKit{
    NSMutableArray *alternateIconsArrayFromPlist = [NSMutableArray arrayWithCapacity:1];
    alternateIconsArrayFromPlist = [self fetchAlternateIconsArray:alternateIconsArrayFromPlist];
    NSEnumerator *arrayEnum = [alternateIconsArrayFromPlist objectEnumerator];
    NSMutableDictionary *dict;
    unsigned int idx = 0;
    unsigned int arrayLen = (unsigned int)[alternateIconsArrayFromPlist count];
    while ([arrayEnum nextObject]){
        if (idx < [alternateIconsArrayFromStoreKit count]-1 &&
            (dict = [alternateIconsArrayFromStoreKit objectAtIndex:idx]) != nil){
            [alternateIconsArray addObject:dict];
        }
        else if (idx == arrayLen-1){
            [alternateIconsArray addObject:[alternateIconsArrayFromStoreKit lastObject]];
        }
        else {
            [alternateIconsArray addObject:[alternateIconsArrayFromPlist objectAtIndex:idx]];
        }
        idx++;
    }
    return alternateIconsArray;
}

- (NSMutableArray *)fetchAlternateIconsArray:(NSMutableArray *)alternateIconsArray {
    NSString *filePath = [[NSBundle bundleForClass:[self class]]
                          pathForResource:@"alternateIcons"
                          ofType:@"plist"];
    alternateIconsArray = [NSMutableArray arrayWithCapacity:1];
    alternateIconsArray = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
    return alternateIconsArray;
}

@end

