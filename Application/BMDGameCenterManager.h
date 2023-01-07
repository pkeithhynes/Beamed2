//
//  BMDGameCenterManager.h
//  Beamed
//
//  Created by Patrick Keith-Hynes on 4/30/21.
//  Copyright © 2021 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface BMDGameCenterManager : NSObject <GKGameCenterControllerDelegate>
      
/**
 * Singleton
 *
 * @return shared instance of self
 */
+ (instancetype)sharedManager;

- (BOOL)isGameCenterAvailable;

/**
 * Makes sure player is authenticated currently
 * if not, it will present the Game Center login
 * screen for the user's convenience
 */
- (void)authenticatePlayer;
      
/**
 * Presents the Game Center leaderboard UI
 */
- (void)showLeaderboard:(id)sender;
      
/**
 * Reports score to Game Center and checks
 * if any achievements have been unlocked
 *
 * @param score The user's score
 */
- (void)reportScore:(NSInteger)score;
      
@end

NS_ASSUME_NONNULL_END


      
