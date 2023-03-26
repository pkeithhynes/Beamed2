//
//  BMDIconsViewController.m
//  Beamed
//
//  Created by Patrick Keith-Hynes on 3/23/23.
//  Copyright © 2023 Apple. All rights reserved.
//

#import "BMDIconsViewController.h"
#import "BMDAppDelegate.h"
#import "Firebase.h"

@import UIKit;


@interface BMDIconsViewController ()

@end

@implementation BMDIconsViewController{
    BMDViewController *rc;
    BMDAppDelegate *appd;
}

@synthesize iconsView;
@synthesize alternateIconsArray;
@synthesize alternateIconsButtonsArray;

    
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    alternateIconsArray = [self fetchAlternateIconsArray:alternateIconsArray];
    if (alternateIconsArray != nil){
        
        rc = (BMDViewController*)[[(BMDAppDelegate *)[[UIApplication sharedApplication]delegate] window] rootViewController];
        appd = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        CGRect settingsFrame = rc.rootView.bounds;
        
        iconsView = [[UIView alloc] initWithFrame:settingsFrame];
        self.view = iconsView;
        iconsView.backgroundColor = [UIColor blackColor];
        iconsView.layer.cornerRadius = 25;
        iconsView.layer.masksToBounds = YES;
        
        // Set background graphic image
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"coffeeRobotNeon" ofType:@"png"];
//        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"coffeePinkNeon" ofType:@"png"];
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
        filterLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.80];
        filterLabel.layer.masksToBounds = YES;
        filterLabel.layer.cornerRadius = 15;
        [iconsView addSubview:filterLabel];
        [iconsView bringSubviewToFront:filterLabel];

        
        CGFloat titleLabelSize, optionLabelSize, buttonHeight, buttonWidth, homeButtonWidthToHeightRatio;
        CGFloat backButtonIconSizeInPoints = 60;
        CGFloat switchCx;
        CGFloat w, h, backButtonY, settingsLabelY;
        unsigned int nrows, ncols, iconGridSizeInPoints, iconSizeInPoints;
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
                w = 0.8*settingsFrame.size.width;
                h = 1.5*titleLabelSize;
                backButtonY = 1.0*h;
                settingsLabelY = 1.0*h;
                nrows = 4;
                ncols = 5;
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
                w = 0.8*settingsFrame.size.width;
                h = 1.5*titleLabelSize;
                backButtonY = 1.0*h;
                settingsLabelY = 2.0*h;
                nrows = 4;
                ncols = 5;
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
                w = 0.8*settingsFrame.size.width;
                h = 1.5*titleLabelSize;
                backButtonY = 1.0*h;
                settingsLabelY = 2.0*h;
                nrows = 4;
                ncols = 5;
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
                w = 0.8*settingsFrame.size.width;
                h = 1.5*titleLabelSize;
                backButtonY = 1.0*h;
                settingsLabelY = 2.0*h;
                nrows = 5;
                ncols = 4;
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
                w = 0.8*settingsFrame.size.width;
                h = 1.5*titleLabelSize;
                backButtonY = 1.5*h;
                settingsLabelY = 3.0*h;
                nrows = 5;
                ncols = 4;
                break;
            }
        }
        iconGridSizeInPoints = 0.8*settingsFrame.size.width/ncols;
        iconSizeInPoints = 0.8*iconGridSizeInPoints;
        
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
        CGRect iconsLabelFrame = CGRectMake(0.5*settingsFrame.size.width - w/2.0,
                                            settingsLabelY,
                                            w,
                                            2.0*h);
        UILabel *iconsPageLabel1 = [[UILabel alloc] initWithFrame:iconsLabelFrame];
        iconsPageLabel1.text = @"Buy me a Coffee for $0.99\n and get a new App icon!";
        iconsPageLabel1.numberOfLines = 0;
        iconsPageLabel1.layer.borderColor = [UIColor clearColor].CGColor;
        iconsPageLabel1.textColor = [UIColor cyanColor];
        iconsPageLabel1.layer.borderWidth = 1.0;
        [iconsPageLabel1 setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:titleLabelSize]];
        iconsPageLabel1.textAlignment = NSTextAlignmentCenter;
        iconsPageLabel1.adjustsFontSizeToFitWidth = NO;
        [iconsView addSubview:iconsPageLabel1];
        [iconsView bringSubviewToFront:iconsPageLabel1];
        
        //
        // Create and display a grid of icon UIButtons
        //
        alternateIconsButtonsArray = [NSMutableArray arrayWithCapacity:1];
        unsigned int gridX, gridY;
        unsigned int posX, posY;
        unsigned int arrayLen = (unsigned int)[alternateIconsArray count];
        for (unsigned int idx=0; idx<arrayLen-1; idx++){
            gridX = (idx % ncols);
            gridY = (idx / ncols);
            posX = (idx % ncols) * iconGridSizeInPoints + 0.1*settingsFrame.size.width;
            posY = (idx / ncols) * iconGridSizeInPoints + settingsLabelY + 3.0*h;
            UIButton *iconButton = [UIButton buttonWithType:UIButtonTypeCustom];
            CGRect iconRect = CGRectMake(posX,
                                         posY,
                                         iconGridSizeInPoints,
                                         iconGridSizeInPoints);
            //            CGRect iconRect = CGRectMake(posX+(iconGridSizeInPoints-iconSizeInPoints)/2.0,
            //                                         posY+(iconGridSizeInPoints-iconSizeInPoints)/2.0,
            //                                         iconSizeInPoints,
            //                                         iconSizeInPoints);
            iconButton.frame = iconRect;
            iconButton.enabled = YES;
            iconButton.tag = idx;
            [iconButton addTarget:self action:@selector(iconButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            NSMutableDictionary *iconDict = [NSMutableDictionary dictionaryWithDictionary:[alternateIconsArray objectAtIndex:idx]];
            iconButton.layer.borderWidth = 0;
            iconButton.layer.cornerRadius = 15;
            iconButton.layer.borderColor = [UIColor grayColor].CGColor;
            NSString *iconImageFileName = [iconDict objectForKey:@"iconImage"];
            UIImage *iconBackgroundImage = [UIImage imageNamed:iconImageFileName];
            [iconButton setBackgroundImage:iconBackgroundImage forState:UIControlStateNormal];
//            UIImage *iconImage = [UIImage imageNamed:@"goldenCrownSelectedLayer.png"];
//            UIImage *iconImage = [UIImage imageNamed:@"goldenCrownLayer.png"];
            UIImage *iconImage = [UIImage imageNamed:@"99centLayer.png"];
            [iconButton setImage:iconImage forState:UIControlStateNormal];
            [iconsView addSubview:iconButton];
            [iconsView bringSubviewToFront:iconButton];
        }
        
        // Label 2
        iconsLabelFrame = CGRectMake(0.5*settingsFrame.size.width - w/2.0,
                                     posY + 2.0*h,
                                     w,
                                     4.0*h);
        UILabel *iconsPageLabel2 = [[UILabel alloc] initWithFrame:iconsLabelFrame];
        iconsPageLabel2.text = @"Your support allows me to keep improving Beamed 2.";
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
// Button Handler Methods Go Here
//

- (void)iconButtonPressed:(UIButton *)sender {
    [appd playSound:appd.tapPlayer];
    // Fetch the name of the selection App Icon
    unsigned int idx = (unsigned int)sender.tag;
    NSMutableDictionary *iconDict = [NSMutableDictionary dictionaryWithDictionary:[alternateIconsArray objectAtIndex:idx]];
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

- (void)backButtonPressed {
    DLog("BMDIconsViewController.backButtonPressed");
    [appd playSound:appd.tapPlayer];
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

//
// Utility Methods Go Here
//

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

- (NSMutableArray *)fetchAlternateIconsArray:(NSMutableArray *)alternateIconsArray {
    NSString *filePath = [[NSBundle bundleForClass:[self class]]
                          pathForResource:@"alternateIcons"
                          ofType:@"plist"];
    alternateIconsArray = [NSMutableArray arrayWithCapacity:1];
    alternateIconsArray = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
    return alternateIconsArray;
}

@end
