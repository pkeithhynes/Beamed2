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
    
    
    rc = (BMDViewController*)[[(BMDAppDelegate *)[[UIApplication sharedApplication]delegate] window] rootViewController];
    appd = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    CGRect settingsFrame = rc.rootView.bounds;
    
    iconsView = [[UIView alloc] initWithFrame:settingsFrame];
    self.view = iconsView;
    iconsView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    iconsView.layer.cornerRadius = 25;
    iconsView.layer.masksToBounds = YES;

    // Set background color and graphic image
    iconsView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.14 alpha:1.0];
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
    UIImageView *iconsViewBackground = [[UIImageView alloc]initWithImage:newImage];
    iconsViewBackground.contentMode = UIViewContentModeScaleAspectFill;
    iconsViewBackground.clipsToBounds = YES;
    [iconsView addSubview:iconsViewBackground];
    [iconsView bringSubviewToFront:iconsViewBackground];
    
    CGFloat titleLabelSize, optionLabelSize, buttonHeight, buttonWidth, homeButtonWidthToHeightRatio;
    CGFloat backButtonIconSizeInPoints = 60;
    CGFloat switchCx;
    CGFloat w, h, settingsLabelY;
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
            settingsLabelY = 3.0*h;
            nrows = 5;
            ncols = 4;
            break;
        }
    }
    iconGridSizeInPoints = 0.8*settingsFrame.size.width/ncols;
    iconSizeInPoints = 0.8*iconGridSizeInPoints;

    // Settings Label
    CGRect iconsLabelFrame = CGRectMake(0.5*settingsFrame.size.width - w/2.0,
                                           settingsLabelY,
                                           w,
                                           6.0*h);
    UILabel *iconsPageLabel = [[UILabel alloc] initWithFrame:iconsLabelFrame];
    iconsPageLabel.text = @"Buy me a Coffee,\n choose a fancy new App icon!\n\nYour USD $0.99 allows me to keep improving Beamed 2.";
    iconsPageLabel.numberOfLines = 0;
    iconsPageLabel.layer.borderColor = [UIColor clearColor].CGColor;
    iconsPageLabel.textColor = [UIColor cyanColor];
    iconsPageLabel.layer.borderWidth = 1.0;
    [iconsPageLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:titleLabelSize]];
    iconsPageLabel.textAlignment = NSTextAlignmentCenter;
    iconsPageLabel.adjustsFontSizeToFitWidth = NO;
    [iconsView addSubview:iconsPageLabel];
    [iconsView bringSubviewToFront:iconsPageLabel];

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
    [iconsView addSubview:homeArrow];
    [iconsView bringSubviewToFront:homeArrow];
    
    
    //
    // Create array of icon UIButtons
    //
    alternateIconsArray = [self fetchAlternateIconsArray:alternateIconsArray];
    alternateIconsButtonsArray = [NSMutableArray arrayWithCapacity:1];
    if (alternateIconsArray != nil){
        unsigned int gridX, gridY;
        unsigned int posX, posY;
        unsigned int arrayLen = (unsigned int)[alternateIconsArray count];
        for (unsigned int idx=0; idx<arrayLen-1; idx++){
            gridX = (idx % ncols);
            gridY = (idx / ncols);
            posX = (idx % ncols) * iconGridSizeInPoints + 0.1*settingsFrame.size.width;
            posY = (idx / ncols) * iconGridSizeInPoints + settingsLabelY + 6.0*h;
            UIButton *iconButton = [UIButton buttonWithType:UIButtonTypeCustom];
            CGRect iconRect = CGRectMake(posX+(iconGridSizeInPoints-iconSizeInPoints)/2.0,
                                         posY+(iconGridSizeInPoints-iconSizeInPoints)/2.0,
                                         iconSizeInPoints,
                                         iconSizeInPoints);
            iconButton.frame = iconRect;
            iconButton.enabled = YES;
            [iconButton addTarget:self action:@selector(iconButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            NSMutableDictionary *iconDict = [NSMutableDictionary dictionaryWithDictionary:[alternateIconsArray objectAtIndex:idx]];
            NSString *iconName = [iconDict objectForKey:@"appIcon"];
            NSString *iconImageFileName = [iconDict objectForKey:@"iconImage"];
            UIImage *iconImage = [UIImage imageNamed:iconImageFileName];
            [iconButton setBackgroundImage:iconImage forState:UIControlStateNormal];
            [iconsView addSubview:iconButton];
            [iconsView bringSubviewToFront:iconButton];
        }
    }
    
    
    //
    // icon button
    //
//    UIButton *icon1 = [UIButton buttonWithType:UIButtonTypeCustom];
//    CGRect icon1ArrowRect = CGRectMake(settingsFrame.size.width/2,
//                                       settingsFrame.size.height/2,
//                                       100,
//                                       100);
//    icon1.frame = icon1ArrowRect;
//    icon1.enabled = YES;
//    [icon1 addTarget:self action:@selector(icon1ButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//    UIImage *icon1Image = [UIImage imageNamed:@"icon8.png"];
//    [icon1 setBackgroundImage:icon1Image forState:UIControlStateNormal];
//    [iconsView addSubview:icon1];
//    [iconsView bringSubviewToFront:icon1];

}

//
// Button Handler Methods Go Here
//

- (void)iconButtonPressed {
    BOOL supportsAlternateIcons = [UIApplication.sharedApplication supportsAlternateIcons];
    if (supportsAlternateIcons){
        [UIApplication.sharedApplication setAlternateIconName:@"AppIcon 8" completionHandler:^(NSError *error){
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
