/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for the iOS & tvOS application delegate
*/

@import Foundation;
@import Network;

#import <UIKit/UIKit.h>
#include <AudioToolbox/AudioToolbox.h>
#include <AVFoundation/AVFoundation.h>
//#import <CoreHaptics/CoreHaptics.h>

#import <StoreKit/StoreKit.h>
#import <GameKit/GameKit.h>

#import "Definitions.h"
#import "BMDRenderer.h"
#import "Optics.h"
#import "BMDHintsViewController.h"
#import "BMDViewController.h"

@class BMDRenderer;
@class Optics;



API_AVAILABLE(ios(13.0))
@interface BMDAppDelegate : UIResponder <UIApplicationDelegate, AVAudioPlayerDelegate> {
    @public
    Optics    *optics;
    UIWindow    *window;
    BMDViewController *rc;
    
    // Sounds
    SystemSoundID   tapSoundFileObject;
    SystemSoundID   plopSoundFileObject;
    SystemSoundID   clinkSoundFileObject;
    SystemSoundID   twinkleSoundFileObject;
    SystemSoundID    laser1SoundFileObject;
    SystemSoundID    laser2SoundFileObject;
    SystemSoundID    jewelEnergizedSoundFileObject;
    SystemSoundID   tileCorrectlyPlacedSoundFileObject;

    SystemSoundID    puzzleBegin1_SoundFileObject;

    SystemSoundID    puzzleComplete1_SoundFileObject;
    SystemSoundID    puzzleComplete2_SoundFileObject;
    SystemSoundID    puzzleComplete3_SoundFileObject;
    SystemSoundID    puzzleComplete4_SoundFileObject;

    AVAudioPlayer   *loop1Player;
    AVAudioPlayer   *loop2Player;
    AVAudioPlayer   *loop3Player;
    
    AVAudioPlayer   *laser1Player;
    AVAudioPlayer   *laser2Player;
    AVAudioPlayer   *tapPlayer;
    AVAudioPlayer   *clinkPlayer;
    AVAudioPlayer   *tileCorrectlyPlacedPlayer;
    AVAudioPlayer   *puzzleComplete1Player;
    AVAudioPlayer   *puzzleComplete2Player;
    AVAudioPlayer   *puzzleComplete3Player;

    
    SystemSoundID    loopMusic1_SoundFileObject;

    CFURLRef        tapSoundFileURLRef;
    CFURLRef        plopSoundFileURLRef;
    CFURLRef        clinkSoundFileURLRef;
    CFURLRef        twinkleSoundFileURLRef;
    CFURLRef        laser1SoundFileURLRef;
    CFURLRef        laser2SoundFileURLRef;
    CFURLRef        jewelEnergizedSoundFileURLRef;
    CFURLRef        tileCorrectlyPlacedSoundFileURLRef;

 
    CFURLRef        puzzleBegin1_SoundFileURLRef;

    CFURLRef        puzzleComplete1_SoundFileURLRef;
    CFURLRef        puzzleComplete2_SoundFileURLRef;
    CFURLRef        puzzleComplete3_SoundFileURLRef;
    CFURLRef        puzzleComplete4_SoundFileURLRef;

    // Haptics
//    CHHapticEngine      *hapticEngine;
    
    // These control laser sound playback
    BOOL                laserSoundFlip;
    BOOL                laserSoundCurrentlyPlaying;
    
    // Puzzle textures
    NSMutableArray  *backgroundAnimationContainers;
    NSMutableArray  *backgroundTextures;
    NSMutableArray  *jewelTextures;

    NSMutableArray  *loadedTextureFiles;
    NSMutableArray  *backgroundTextureFiles;
    NSMutableArray  *jewelTextureFiles;
    NSMutableArray *tileAnimationContainers;
    NSMutableArray *beamAnimationContainers;
    NSMutableArray *ringAnimationContainers;
    NSMutableArray *logoAnimationContainers;

    // Game Logic
    NSMutableDictionary     *gameDictionaries;
    NSMutableArray          *packsArray;
    NSMutableDictionary     *dailyPuzzleGamePuzzleDictionary;
    NSMutableDictionary     *demoPuzzleDictionary;
    
    // Game Center
    GKLeaderboard   *totalPuzzlesLeaderboard;
    GKLeaderboard   *totalJewelsLeaderboard;
    
    unsigned int            currentPack;
    unsigned int            currentTutorialPuzzle;
    unsigned int            currentDailyPuzzleNumber;
    unsigned int            maximumGamePuzzle;
    unsigned int            numberOfHintsRemaining;
    unsigned int            lastLaserSoundPlayed;
    
    // Synchronization with rootViewController
    BOOL        rootViewControllerHasLoaded;
    
    // iCloud support
    id          currentiCloudToken;
    BOOL        permittedToUseiCloud;
    
    // Vungle is available
    BOOL        vungleIsLoaded;
    
    // YES means a StoreKit SKProductsRequest is issued in order to make a purchase
    // NO means a StoreKit SKProductsRequest is issued for information only - no immediate purchase
    BOOL        storeKitPurchaseRequested;
    enum eSKProductsRequest productsRequestEnum;
    BOOL applicationIsConnectedToNetwork;
    BOOL storeKitDataHasBeenReceived;
    NSMutableArray *arrayOfPaidHintPacksInfo;
    NSMutableArray *arrayOfPuzzlePacksInfo;
    NSMutableArray *arrayOfAltIconsInfo;
    
}

@property (strong, nonatomic) Optics * _Nonnull optics;
@property (strong, nonatomic) BMDViewController *_Nonnull rc;

// Network monitoring
@property (nonatomic, strong) nw_path_monitor_t _Nonnull monitor;
@property (nonatomic, strong) dispatch_queue_t _Nonnull monitorQueue;
@property (nonatomic) BOOL applicationIsConnectedToNetwork;
@property (nonatomic) BOOL storeKitDataHasBeenReceived;

@property (strong, nonatomic) UIWindow * _Nonnull window;
@property (strong, nonatomic) MTKView * _Nonnull view;
@property (nonatomic, retain) NSMutableArray  * _Nullable loadedTextureFiles;
@property (nonatomic, retain) NSMutableArray  * _Nullable backgroundAnimationContainers;
@property (nonatomic, retain) NSMutableArray  * _Nullable backgroundTextures;
@property (nonatomic, retain) NSMutableArray  * _Nullable jewelTextures;
@property (nonatomic, retain) NSMutableArray  * _Nullable tileAnimationContainers;
@property (nonatomic, retain) NSMutableArray  * _Nullable beamAnimationContainers;
@property (nonatomic, retain) NSMutableArray  * _Nullable ringAnimationContainers;
@property (nonatomic, retain) NSMutableArray  * _Nullable logoAnimationContainers;
@property (nonatomic, retain) NSMutableDictionary * _Nonnull gameDictionaries;
@property (nonatomic, retain) NSMutableDictionary * _Nonnull dailyPuzzleGamePuzzleDictionary;

@property (nonatomic) unsigned int currentPack;
@property (nonatomic) unsigned int currentTutorialPuzzle;
@property (nonatomic) unsigned int currentDailyPuzzleNumber;

@property (nonatomic) unsigned int numberOfHintsRemaining;
@property (nonatomic) BOOL rootViewControllerHasLoaded;
@property (nonatomic) id _Nullable currentiCloudToken;
@property (nonatomic) BOOL permittedToUseiCloud;
@property (nonatomic) BOOL storeKitPurchaseRequested;
@property (nonatomic) enum eSKProductsRequest productsRequestEnum;
@property (nonatomic, retain) NSMutableArray * _Nullable arrayOfPaidHintPacksInfo;
@property (nonatomic, retain) NSMutableArray * _Nullable arrayOfPuzzlePacksInfo;
@property (nonatomic, retain) NSMutableArray * _Nullable arrayOfAltIconsInfo;


@property (readwrite) CFURLRef _Nullable tapSoundFileURLRef;
@property (readwrite) CFURLRef _Nullable plopSoundFileURLRef;
@property (readwrite) CFURLRef _Nullable clinkSoundFileURLRef;
@property (readwrite) CFURLRef _Nullable twinkleSoundFileURLRef;
@property (readwrite) CFURLRef _Nullable tileCorrectlyPlacedSoundFileURLRef;
@property (readwrite) CFURLRef _Nullable laser1SoundFileURLRef;
@property (readwrite) CFURLRef _Nullable laser2SoundFileURLRef;
@property (readwrite) CFURLRef _Nullable jewelEnergizedSoundFileURLRef;

@property (readwrite) CFURLRef _Nullable puzzleBegin1_SoundFileURLRef;

@property (readwrite) CFURLRef _Nullable puzzleComplete1_SoundFileURLRef;
@property (readwrite) CFURLRef _Nullable puzzleComplete2_SoundFileURLRef;
@property (readwrite) CFURLRef _Nullable puzzleComplete3_SoundFileURLRef;
@property (readwrite) CFURLRef _Nullable puzzleComplete4_SoundFileURLRef;

//@property (nonatomic, assign) BOOL supportsHaptics;
@property (nonatomic, retain) CHHapticEngine * _Nullable hapticEngine;

@property (readonly)    SystemSoundID   tapSoundFileObject;
@property (readonly)    SystemSoundID   plopSoundFileObject;
@property (readonly)    SystemSoundID   clinkSoundFileObject;
@property (readonly)    SystemSoundID   twinkleSoundFileObject;
@property (readonly)    SystemSoundID   tileCorrectlyPlacedSoundFileObject;
@property (readonly)    SystemSoundID   laser1SoundFileObject;
@property (readonly)    SystemSoundID   laser2SoundFileObject;
@property (readonly)    SystemSoundID   jewelEnergizedSoundFileObject;

@property (readonly)    SystemSoundID   puzzleBegin1_SoundFileObject;

@property (readonly)    SystemSoundID   puzzleComplete1_SoundFileObject;
@property (readonly)    SystemSoundID   puzzleComplete2_SoundFileObject;
@property (readonly)    SystemSoundID   puzzleComplete3_SoundFileObject;
@property (readonly)    SystemSoundID   puzzleComplete4_SoundFileObject;

@property (readonly)    SystemSoundID   loopMusic1_SoundFileObject;
@property (nonatomic, retain) AVAudioPlayer * _Nullable loop1Player;
@property (nonatomic, retain) AVAudioPlayer * _Nullable loop2Player;
@property (nonatomic, retain) AVAudioPlayer * _Nullable loop3Player;

@property (nonatomic, retain) AVAudioPlayer * _Nullable laser1Player;
@property (nonatomic, retain) AVAudioPlayer * _Nullable laser2Player;
@property (nonatomic, retain) AVAudioPlayer * _Nullable tapPlayer;
@property (nonatomic, retain) AVAudioPlayer * _Nullable clinkPlayer;
@property (nonatomic, retain) AVAudioPlayer * _Nullable tileCorrectlyPlacedPlayer;
@property (nonatomic, retain) AVAudioPlayer * _Nullable puzzleComplete1Player;
@property (nonatomic, retain) AVAudioPlayer * _Nullable puzzleComplete2Player;
@property (nonatomic, retain) AVAudioPlayer * _Nullable puzzleComplete3Player;

@property (nonatomic, retain) GKLeaderboard   * _Nullable totalPuzzlesLeaderboard;
@property (nonatomic, retain) GKLeaderboard   * _Nullable totalJewelsLeaderboard;

- (BOOL)initAllTextures:(nonnull MTKView *)mtkView metalRenderer:(nonnull BMDRenderer *)metalRenderer;
- (BOOL)loadMetalTextureFromFile:(NSString *_Nonnull)name withExtension:(NSString *_Nonnull)ext;

- (void)saveDailyPuzzleNumber:(unsigned int)puzzleNumber;
- (int)fetchDailyPuzzleNumber;
- (NSMutableDictionary *_Nullable)fetchDailyPuzzle:(unsigned int)puzzleNumber;


- (int)countNumberOfPacksInArray:(NSString *_Nonnull)key;

- (NSMutableArray *_Nullable)fetchPacksArray:(NSString *_Nonnull)key;
- (uint)getLocalDaysSinceReferenceDate;

- (BOOL)editModeIsEnabled;
- (BOOL)autoGenIsEnabled;
- (NSMutableDictionary *_Nonnull)fetchGameDictionaryForKey:(NSString *_Nonnull)key;
- (void)activateGameCenter;
- (NSMutableDictionary *_Nullable)fetchGamePuzzle:(int)packIndex puzzleIndex:(int)puzzleIndex;
- (NSString *_Nonnull)queryCurrentGameDictionaryName;

//
// Methods to keep score including updating and querying the puzzleScoresArray from defaults
//
- (void)resetPuzzleProgressAndScores;

- (void)updatePuzzleScoresArray:(int)packNumber
                   puzzleNumber:(int)puzzleNumber
                 numberOfJewels:(NSDictionary *_Nullable)numberOfJewels
                      startTime:(long)startTime
                        endTime:(long)endTime
                         solved:(BOOL)solved;


// +1   Puzzle is solved
//  0   Puzzle is unsolved
// -1   Puzzle is in progress
// -2   timeSegmentArray incorrectly formed
- (int)puzzleSolutionStatus:(int)packNumber
               puzzleNumber:(int)puzzleNumber;

- (void)incrementNumberOfMovesInPuzzleScoresArray:(int)packNumber
                                     puzzleNumber:(int)puzzleNumber;

- (long)calculateSolutionTime:(int)packNumber puzzleNumber:(int)puzzleNumber;

- (long)fetchTotalSolutionTimeForAllPacks;

- (int)countTotalJewelsCollected;

- (int)countTotalJewelsCollectedByColorKey:(NSString *_Nonnull)colorKey;

- (int)countPuzzlesSolved;

- (int)queryPuzzleJewelCount:(int)puzzleNumber;

- (int)queryPuzzleJewelCountFromDictionary:(NSMutableDictionary *_Nonnull)dictionary;

- (NSMutableDictionary *_Nonnull)queryPuzzleJewelCountByColor:(int)puzzleNumber;

- (NSMutableDictionary *_Nonnull)buildEmptyJewelCountDictionary;

- (BOOL)puzzleIsEmpty:(NSMutableDictionary *_Nullable)puzzle;

//
// StoreKit and Paid Puzzles
//
- (BOOL)queryPurchasedPuzzlePack:(unsigned int)packNumber;
- (BOOL)queryPurchasedAltIcon:(unsigned int)iconNumber;
- (BOOL)existPurchasedAltIcons;
- (void)saveCurrentAltIconNumber:(int)currentAltIconNumber;
- (int)fetchCurrentAltIconNumber;
- (NSMutableString *_Nullable)queryPuzzlePackName:(NSMutableString *_Nonnull)name pack:(unsigned int)packIndex;
- (NSMutableString *_Nullable)queryHintPackName:(NSMutableString *_Nonnull)name pack:(unsigned int)hintPack;
- (void)updateHintsRemainingDisplayAndStorage:(int)newHints;
- (void)purchasePuzzlePack:(NSString *_Nonnull)productionId;
- (void)purchaseHintPack:(NSString *_Nonnull)productionId;
- (void)purchaseAltIcon:(NSString *)productionId;
- (void)purchaseAdFreePuzzles;
- (void)restorePurchases;

// In-app purchase information request methods
- (void)requestAdFreePuzzlesInfo;
- (void)requestHintPacksInfo;
- (void)requestPuzzlePacksInfo;

//
// GameCenter
//
- (BOOL)isGameCenterAvailable;
- (void)authenticatePlayer;

//
// iCloud or Local defaults handlers
//
- (void)setObjectInDefaults:(id _Nonnull )object forKey:(NSString *_Nonnull)key;
- (id _Nullable)getObjectFromDefaults:(NSString *_Nonnull)key;
- (id _Nullable)getObjectFromCloudDefaults:(NSString *_Nonnull)key;
- (NSString *_Nullable)getStringFromDefaults:(NSString *_Nonnull)key;
- (NSDictionary *_Nullable)getDictionaryFromDefaults:(NSString *_Nonnull)key;
- (void)initializePuzzlePacksProgress;
- (unsigned int)fetchCurrentPackNumber;
- (void)saveCurrentPackNumber:(unsigned int)packNumber;
- (unsigned int)fetchCurrentPuzzleNumberForPack:(unsigned int)packNumber;
- (void)saveCurrentPuzzleNumberForPack:(unsigned int)packNumber puzzleNumber:(unsigned int)puzzleNumber;
//- (BOOL)incrementPuzzleNumberForCurrentPack;
- (NSMutableDictionary *_Nonnull)fetchPackDictionaryFromPlist:(NSString *_Nonnull)key;
- (unsigned int)fetchCurrentPuzzleNumber;
- (unsigned int)queryNumberOfPuzzlesLeftInCurrentPack;
- (unsigned int)queryNumberOfPuzzlesLeftInPack:(unsigned int)packNumber;
- (BOOL)existsKeyInNSUbiquitousKeyValueStore:(NSString *_Nonnull)key;
- (BOOL)existsKeyInDefaults:(NSString *_Nonnull)key;
- (unsigned int)fetchCurrentPackLength;
- (unsigned int)fetchPackLength:(unsigned int)packIndex;
- (void)saveCurrentPuzzleNumber:(unsigned int)puzzleNumber;
- (NSMutableDictionary *_Nonnull)fetchCurrentPuzzleFromPackGameProgress:(unsigned int)packNumber;
- (NSMutableDictionary *_Nonnull)fetchPuzzlePack:(unsigned int)packNumber;
- (void)saveCurrentPuzzleToPackGameProgress:(unsigned int)packNumber puzzle:(NSMutableDictionary *_Nonnull)puzzle;
- (void)saveDailyPuzzle:(unsigned int)puzzleNumber puzzle:(NSMutableDictionary *_Nonnull)puzzle;
- (NSMutableDictionary *_Nonnull)fetchCurrentPuzzleFromPackDictionary:(unsigned int)packNumber;
- (void)setUnsignedIntInDefaults:(unsigned int)number forKey:(NSString *_Nonnull)key;
- (unsigned int)fetchDemoPuzzleNumber;
- (void)saveDemoPuzzleNumber:(unsigned int)puzzleNumber;
-(BOOL)packHasBeenCompleted;

-(unsigned int)countPuzzlesWithinPack:(NSMutableDictionary *_Nonnull)packDictionary;
- (unsigned int)fetchPackIndexForPackNumber:(unsigned int)packNumber;
- (unsigned int)fetchPackNumberForPackIndex:(unsigned int)packIndex;

- (BOOL)checkForEndlessHintsPurchased;
- (void)setEndlessHintsPurchased;

- (BOOL)reviewRequestIsAppropriate;
- (BOOL)automatedReviewRequestIsAppropriate;
- (BOOL)automatedRobotCafeIsAppropriate;

//
// Support Puzzle Editing
//
//- (BOOL)saveEditedPuzzleArrayToFile:(NSMutableArray *_Nonnull)array;

//
// Methods that support Puzzle Editing using an NSMutableDictionary pack of puzzles in Defaults
//
// There is only one pack stored as an NSMutableDictionary of NSMutableDictionary puzzles
// The pack NSMutableDictionary maybe be fetched or written all at once
// Individual pack puzzles may be fetched or written by specifying their index
// Pack puzzle indices begin with index 0
// A pointer to the "current" pack puzzle index may be fetched as an int (-1 means fetch fails)
// A pointer to the "current" pack puzzle index may be written as an unsigned int
//

- (NSMutableDictionary *_Nullable)fetchEditedPack;
- (BOOL)saveEditedPack:(NSMutableDictionary *_Nonnull)packDictionary;
- (NSMutableDictionary *_Nullable)fetchEditedPackFromDefaults;
- (NSMutableDictionary *_Nullable)fetchEditedPackFromMainBundle;
- (BOOL)saveEditedPackToDefaults:(NSMutableDictionary *_Nonnull)packDictionary;
- (NSMutableDictionary *_Nullable)fetchEditedPuzzleFromPackInDefaults:(unsigned int)index;
- (BOOL)replaceEditedPuzzleInPackInDefaults:(unsigned int)index puzzle:(NSMutableDictionary *_Nonnull)puzzle;
- (int)fetchEditedPuzzleIndexFromDefaults;
- (void)saveEditedPuzzleIndexToDefaults:(unsigned int)index;
- (BOOL)saveArrayOfPuzzlesToFile:(NSMutableArray *)puzzleArray fileName:(NSString *)fileName;
- (BOOL)savePuzzlePackDictionaryToFile:(NSMutableDictionary *)pack  fileName:(NSString *)fileName;


//
// Vungle Ad Methods
//
- (void)vungleLoadBannerAd;
- (void)vungleCloseBannerAd;
- (void)vungleLoadBannerLeaderboardAd;
- (void)vungleLoadRewardedAd;
//- (void)vunglePlayRewardedAd;

- (void)playSound:(AVAudioPlayer *_Nonnull)player;
- (void)playLaserSound;
- (void)playPuzzleCompleteSoundEffect;
- (void)pauseLoopMusic;
- (void)playMusicLoop;
- (void)playMusicLoop:(AVAudioPlayer *_Nonnull)player;
- (void)duckLoopMusic;
- (void)unduckLoopMusic;



@end
