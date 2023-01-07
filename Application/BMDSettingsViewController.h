//
//  BMDSettingsViewController.h
//  Beamed
//
//  Created by Patrick Keith-Hynes on 8/24/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import <MessageUI/MessageUI.h>
#import <Social/Social.h>


NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface BMDSettingsViewController : UIViewController <GKGameCenterControllerDelegate, MFMailComposeViewControllerDelegate>{
    
@public
    UIView *settingsView;
    UIButton *soundsEnabledButton;
    UIButton *musicEnabledButton;
    UIButton *leaderboardsButton;
    UIButton *restorePurchasesButton;
    UIButton *emailSupportButton;
    UIButton *websiteButton;
    UIButton *shareButton;
    UIButton *aboutButton;
    UIButton *resetButton;

    UISwitch *soundsEnabledSwitch;
    UISwitch *musicEnabledSwitch;
    
    UILabel *soundEffectsEnabledLabel;
    UILabel *musicEnabledLabel;
}

@property (nonatomic, retain) UIView *settingsView;
@property (nonatomic, retain) UIButton *soundsEnabledButton;
@property (nonatomic, retain) UIButton *musicEnabledButton;
@property (nonatomic, retain) UIButton *leaderboardsButton;
@property (nonatomic, retain) UIButton *restorePurchasesButton;
@property (nonatomic, retain) UIButton *emailSupportButton;
@property (nonatomic, retain) UIButton *websiteButton;
@property (nonatomic, retain) UIButton *shareButton;
@property (nonatomic, retain) UIButton *aboutButton;
@property (nonatomic, retain) UIButton *resetButton;

@property (nonatomic, retain) UISwitch *soundsEnabledSwitch;
@property (nonatomic, retain) UISwitch *musicEnabledSwitch;

@property (nonatomic, retain) UILabel *soundEffectsEnabledLabel;
@property (nonatomic, retain) UILabel *musicEnabledLabel;

@end

NS_ASSUME_NONNULL_END
