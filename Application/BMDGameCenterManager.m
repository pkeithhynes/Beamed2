//
//  BMDGameCenterManager.m
//  Beamed
//
//  Created by Patrick Keith-Hynes on 4/30/21.
//  Copyright © 2021 Apple. All rights reserved. 
//

#import "BMDGameCenterManager.h"
#import "BMDAppDelegate.h"

#define LEADERBOARD_ID @"BEAMED_2_LEADERBOARD_0001"
#define ACHIEVEMENT_NOVICE_ID @"supertap.novice"
#define ACHIEVEMENT_INT_ID @"supertap.intermediate"
#define ACHIEVEMENT_EXPERT_ID @"supertap.expert"

@interface BMDGameCenterManager()
      
@property (nonatomic, strong) UIViewController *presentationController;
      
@end
      
@implementation BMDGameCenterManager
      
#pragma mark Singelton
      
+ (instancetype)sharedManager {
    static BMDGameCenterManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[BMDGameCenterManager alloc] init];
    });
    return sharedManager;
}

#pragma mark GameCenter even available?

- (BOOL)isGameCenterAvailable {
    // Check for presence of GKLocalPlayer API.
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // The device must be running running iOS 4.1 or later.
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported);
}

      
#pragma mark Initialization
      
- (id)init {
    self = [super init];
    if (self) {
        [self authenticatePlayer];
        BMDAppDelegate *del = (BMDAppDelegate*)[[UIApplication sharedApplication] delegate];
        self.presentationController = del.window.rootViewController;
    }
    return self;
}
      
#pragma mark Player Authentication
      
- (void)authenticatePlayer {
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    BMDAppDelegate *del = (BMDAppDelegate*)[[UIApplication sharedApplication] delegate];

    [localPlayer setAuthenticateHandler:
     ^(UIViewController *viewController, NSError *error) {
        if (viewController != nil) {
            [self.presentationController
            presentViewController:viewController
            animated:YES completion:nil];
        } else if ([GKLocalPlayer localPlayer].authenticated) {
            DLog("Player successfully authenticated");
        } else if (error) {
            DLog("Game Center authentication error: %@", error);
        }
    }];
}
      
#pragma mark Leaderboard and Achievement handling
      
- (void)showLeaderboard:(id)sender {
    GKGameCenterViewController *gcViewController =
    [[GKGameCenterViewController alloc] init];
    gcViewController.gameCenterDelegate = self;
    gcViewController.viewState =
    GKGameCenterViewControllerStateLeaderboards;
    gcViewController.leaderboardIdentifier = LEADERBOARD_ID;
    
//    [self.presentationController
//    presentViewController:gcViewController
//    animated:YES completion:nil];
    
    [self.presentationController showViewController:gcViewController sender:sender];
}
      
- (void)reportScore:(NSInteger)score {
    GKScore *gScore = [[GKScore alloc] initWithLeaderboardIdentifier:LEADERBOARD_ID];
    gScore.value = score;
    gScore.context = 0;
    
    [GKScore reportScores:@[gScore]
    withCompletionHandler:^(NSError *error) {
        if (!error) {
            DLog("Score reported successfully!");
            
            // score reported, so lets see if it
            // unlocked any achievements
            NSMutableArray *achievements =
            [[NSMutableArray alloc] init];
            
            // if the player hit an achievement threshold,
            // create the achievement using the ID and add
            // it to the array
            if(score >= 100) {
                GKAchievement *noviceAchievement =
                [[GKAchievement alloc]
                initWithIdentifier:ACHIEVEMENT_NOVICE_ID];
                noviceAchievement.percentComplete = 100;
                [achievements addObject:noviceAchievement];
            }
            
            if(score >= 150) {
                GKAchievement *intAchievement =
                [[GKAchievement alloc]
                initWithIdentifier:ACHIEVEMENT_INT_ID];
                intAchievement.percentComplete = 100;
                [achievements addObject:intAchievement];
            }
            
            if(score >= 200) {
                GKAchievement *expertAchievement =
                [[GKAchievement alloc]
                initWithIdentifier:ACHIEVEMENT_EXPERT_ID];
                expertAchievement.percentComplete = 100;
                [achievements addObject:expertAchievement];
            }
            
            // tell the Game Center to mark
            // the array of achievements as completed
            [GKAchievement reportAchievements:achievements
            withCompletionHandler:^(NSError *error) {
                if (error != nil) {
                    DLog("%@", [error localizedDescription]);
                }
            }];
        }
        else {
            DLog("Unable to report score");
        }
    }];
}
      
#pragma mark GameKit Delegate Methods
      
- (void)gameCenterViewControllerDidFinish:
  (GKGameCenterViewController *)gameCenterViewController {
    [gameCenterViewController
    dismissViewControllerAnimated:YES completion:nil];
}

@end

