//
//  Definitions.h
//  Beamed
//
//  Created by pkeithhynes on 11/4/2010.
//  Copyright Patrick Keith-Hynes 2010. All rights reserved.
//
#import <UIKit/UIKit.h>

#define METAL_RENDERER_FPS 24

#define ENABLE_GA YES           // YES enables Google Analytics
#define ENABLE_GAMECENTER YES           // YES enables GemCenter
#define ENABLE_REVIEW_REQUESTS YES      // YES enables a review request every 366/3 = 122 days
#define FORCE_PUZZLE_EDITOR_AUTOGEN NO    // YES forces AutoGen mode when PE enabled
#define ENABLE_HOME_SCREEN_ANIMATION YES

#define ENABLE_VUNGLE_ADS YES

#define ENABLE_PUZZLE_EDITOR NO     // YES Enables puzzle editing and playback
                                     // NO Disables puzzle editing and enables gameplay only
#define ENABLE_PUZZLE_VERIFY NO     // YES Enables puzzle verification when ENABLE_PUZZLE_EDITOR == YES
                                     // NO Disables puzzle verification

// Coordinate systems
// - All tiles are positioned on a grid ranging from 6x8 to 12x16
//        X grid values range from [0:11] and the Y grid values range from [0:15]
#define kDefaultGridMinSizeX 4
#define kDefaultGridMinSizeY 6
#define kDefaultGridStartingSizeX 6
#define kDefaultGridStartingSizeY 8
#define kDefaultGridMaxSizeX 12
#define kDefaultGridMaxSizeY 16
#define kDefaultPuzzleGridTopAndBottomBorderWidthInPixels 6
#define kDefaultPuzzleGridLeftAndRightBorderWidthInPixels 6


// Handle debug logging
#define DEBUG_MODE 1
#ifdef DEBUG_MODE
#    define DLog(...) NSLog(@__VA_ARGS__)
#else
#    define DLog(...) /* */
#endif

#ifndef YESNO
#define YESNO(b) (b ? @"YES" : @"NO")
#endif

// Numerical Constants
#define PI 3.141592654
#define TICK_LENGTH 1.0/30.0

// Counts of various things
#define kNumberOfBeamLevels 32

// Track CFBundleShortVersionString that have been reviewed
#define kCFBundleShortVersionStringHasBeenReviewed @"CFBundleShortVersionStringHasBeenReviewed"

// Game Center leaderboards
#define kTotalPuzzlesLeaderboard @"BEAMED2_TOTAL_PUZZLES_LEADERBOARD"
#define kTotalJewelsLeaderboard @"BEAMED2_TOTAL_JEWELS_LEADERBOARD"

// Game Center leaderboard categories
#define kPuzzlePointValueKey @"puzzlePoints"
#define kPuzzleHintValueKey @"puzzleHints"

// Various dictionary keys
//#define kCurrentPackScoresDictionaryKey @"currentPackScoresDictionary"
#define kAllPacksScoresDictionaryKey @"allPacksScoresDictionary"
#define kPaidPuzzlePacksKey @"paidPuzzlePacksDictionary"
#define kPaidHintPacksKey @"paidHintPacksDictionary"
#define kPaidAltIconsKey @"paidAltIconsDictionary"

// Paid puzzle pack identifiers
#define kPaidPack1ProductIdentifier @"BMD2_PAIDLEVEL_AAAA0001"
#define kPaidPack2ProductIdentifier @"BMD2_PAIDLEVEL_AAAA0002"
#define kPaidPack3ProductIdentifier @"BMD2_PAIDLEVEL_AAAA0003"
#define kPaidPack4ProductIdentifier @"BMD2_PAIDLEVEL_AAAA0004"
#define kPaidPack5ProductIdentifier @"BMD2_PAIDLEVEL_AAAA0005"
#define kPaidPack6ProductIdentifier @"BMD2_PAIDLEVEL_AAAA0006"
#define kPaidPack7ProductIdentifier @"BMD2_PAIDLEVEL_AAAA0007"
#define kPaidPack8ProductIdentifier @"BMD2_PAIDLEVEL_AAAA0008"

// Paid hint pack identifiers
#define kPaidHint1ProductIdentifier10hints @"BMD2_PAIDHINT_AAAA0001"
#define kPaidHint2ProductIdentifier25hints @"BMD2_PAIDHINT_AAAA0002"
#define kPaidHint3ProductIdentifier50hints @"BMD2_PAIDHINT_AAAA0003"
#define kPaidHint4ProductIdentifier75hints @"BMD2_PAIDHINT_AAAA0004"
#define kPaidHint4ProductIdentifier100hints @"BMD2_PAIDHINT_AAAA0005"


// Initial free hints
#define kInitialFreeHints 10

// How frequently we send players to the Robot Diner after puzzle completion
#define kSendToRobotDinerNoIconPurchase 2
#define kSendToRobotDinerYesIconPurchase 5


// Scoring constants
#define kPointsPerJewel 100
#define kPointsPerTile  25

// File paths for texture resources
#define kBackgroundTextures @"backgroundTextures.plist"
#define kBackgroundAnimationTextures @"backgroundAnimationTextures.plist"
#define kJewelTextures @"jewelTextures.plist"

// File paths for game puzzles
#define kPuzzlePacksArray @"puzzlePacksArray.plist"
#define kDemoPuzzlePackDictionary @"demoPuzzlePackDictionary.plist"
#define kDailyPuzzlesPackDictionary @"dailyPuzzlesPackDictionary.plist"

// File path for hints packs
#define kPaidHintsPacks @"paidHintPacksArray.plist"

// File path for alt icons
#define kAltIconsPacks @"alternateIcons.plist"

// File paths for sound effects
#define kButtonClinkSoundEffect @"085149494-puzzle-game-organic-wood-block"
#define kButtonClickSoundEffect @"085149494-puzzle-game-organic-wood-block"
//#define kButtonClinkSoundEffect @"TapClink"
//#define kButtonClickSoundEffect @"Click"
#define kLaserSound1 @"003577572-light-sabersci-fihighswingsfas"
#define kLaserSound2 @"003577603-light-sabersci-filowswingfast-"
//#define kLaserSound1 @"LaserQuick2"
//#define kLaserSound2 @"LaserQuick"
#define kScreenCaptureJPEG @"beamedScreenCapture.jpg"
#define kProductsPlist @"products"
#define kProductUpgradeKey @"upgrade0001"

#define kLoopMusic1 @"InternalCalculations"
#define kLoopMusic2 @"NightDrive"
#define kLoopMusic3 @"MysteryPuzzleLoop2"

#define kTilePlacedCorrectly @"Reward"
#define kPuzzleBegin1 @"Mobile_Game_Melodic_Stinger_Dreamy_Synth_Level_Up_2"

#define kPuzzleComplete1 @"win-game-puzzle-119"
#define kPuzzleComplete2 @"win-game-puzzle-52"
#define kPuzzleComplete3 @"win-game-puzzle-93"
#define kPuzzleComplete4 @"win-game-puzzle-50"

// Enumerated types
enum eDisplayAspectRatio {
    ASPECT_4_3,
    ASPECT_10_7,
    ASPECT_3_2,
    ASPECT_16_9,
    ASPECT_13_6 };
enum eObjectAngle {
    ANGLE0,
    ANGLE45,
    ANGLE90,
    ANGLE135,
    ANGLE180,
    ANGLE225,
    ANGLE270,
    ANGLE315 };
enum ePuzzleCompletionCondition {
    ALL_JEWELS_ENERGIZED,
    TILE_POSITIONING_AND_ROTATION,
    USER_TOUCH,
    INFO_SCREEN };
// --- Tiles
enum eTileShape {
    RECTANGLE,
    CIRCLE,
    BEAMSPLITTER,
    MIRROR,
    JEWEL,
    PRISM,
    LASER,
    BACKGROUND };
enum eTileAnimations {
    TILE_A_WAITING,
    TILE_A_ENERGIZED,
    TILE_A_LIGHTSWEEP,
    TILE_A_STATIC };
enum eTileAnimationContainers {
    TILE_AC_GLOWWHITE_RECTANGLE,
    TILE_AC_GLOWWHITE_CIRCLE,
    TILE_AC_BEAMSPLITTER,
    TILE_AC_MIRROR,
    TILE_AC_JEWEL,
    TILE_AC_AURA,
    TILE_AC_PRISM,
    TILE_AC_SPECTRUMR,
    TILE_AC_SPECTRUML,
    TILE_AC_LASER };
enum eTileMotions {
    MOTION_NONE,
    MOTION_CIRCLE,
    MOTION_LINEAR,
    MOTION_DROP };
enum eTileColors {
    COLOR_RED,
    COLOR_GREEN,
    COLOR_BLUE,
    COLOR_YELLOW,
    COLOR_MAGENTA,
    COLOR_CYAN,
    COLOR_WHITE,
    COLOR_OPAQUE,
    COLOR_GRAY,
    COLOR_ALL };
// --- Beams
enum eBeamColors {
    BEAM_RED,
    BEAM_GREEN,
    BEAM_BLUE,
    BEAM_YELLOW,
    BEAM_MAGENTA,
    BEAM_CYAN,
    BEAM_WHITE };
enum eBeamAnimations { BEAM_A_STEADY };
enum eBeamAnimationContainers { BEAM_AC_GLOWWHITE_RECTANGLE_HORIZONTAL };
enum eBackgroundTextures {
    OVERLAY_TILE_OUTLINE,
    TILE_BG,
    SINGLE_ARROW_1,
    BACKGROUND_ASPECT_4_3,
    TAP_TO_ROTATE,
    TAP_TO_ROTATE_TEXT,
    DRAG_TILE_TEXT,
    TILE_SQUARE_BRIGHT,
    TILE_SQUARE_TRANSLUCENT,
    TILE_CHECKMARK,
    PACK_COMPLETED,
    PUZZLE_BACKGROUND_IMAGE1,
    PUZZLE_BACKGROUND_NEON_CITYSCAPE1,
    PUZZLE_BACKGROUND_NEON_CITYSCAPE2,
    PUZZLE_BACKGROUND_NEON_CITYSCAPE3,
    PUZZLE_BACKGROUND_NEON_CITYSCAPE4,
    PUZZLE_BACKGROUND_NEON_CITYSCAPE5,
    PUZZLE_BACKGROUND_NEON_CITYSCAPE6,
    FILTER_IMAGE,
    HELP_IMAGE,
    LOGO_IMAGE
};
enum eTextAlignment {
    ALIGN_LEFT,
    ALIGN_CENTER,
    ALIGN_RIGHT };
// --- Various Animations
enum eVariousAnimations { RING_EXPANDING };

// --- App Pages
enum eAppPageNumber {
    PAGE_HOME,
    PAGE_PACKS,
    PAGE_HINTS,
    PAGE_OPTIONS,
    PAGE_GAME,
    PAGE_EDIT};
// --- Game Packs
enum eGamePackType {
    PACKTYPE_MAIN,
    PACKTYPE_DAILY,
    PACKTYPE_EDITOR,
    PACKTYPE_DEMO};

// --- StoreKit SKProductsRequest detail indicating information request or purchase
enum eSKProductsRequest {
    REQ_NIL,
    REQ_INFO_PUZZLE_PACK,
    REQ_INFO_HINT_PACK,
    REQ_INFO_AD_FREE,
    REQ_INFO_ICON,
    REQ_PURCHASE
};

// Vungle Ad Platform Constants
#define vungleAppID @"62f0a11e710a2947ac9f4d53"
#define vunglePlacementRewardedHint @"VUNGLEREWARDEDADHINT0001-2229652"
#define vunglePlacementBanner @"VUNGLEBANNERADLOWER0002-8374108"
#define vunglePlacementBannerLeaderboard @"VUNGLEBANNERADLOWER0001-5187390"

// Visual effects
#define buttonBorderWidth 0.0f

