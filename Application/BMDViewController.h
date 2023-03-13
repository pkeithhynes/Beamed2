/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for the cross-platform view controller
*/

#if defined(TARGET_IOS) || defined(TARGET_TVOS)
@import UIKit;
#define PlatformViewController UIViewController
#else
@import AppKit;
#define PlatformViewController NSViewController
#endif

@import MetalKit;

#include <AudioToolbox/AudioToolbox.h>
#import <GameKit/GameKit.h>
#import <UIKit/UIKit.h>
#import "BMDRenderer.h"
#import "BMDRenderer.h"
#import "Controls.h"
#import "BMDHintsViewController.h"
#import "BMDPacksViewController.h"
#import "BMDPuzzleViewController.h"
#import "BMDSettingsViewController.h"
#import "Foreground.h"
#import "Background.h"
#import "TextureRenderData.h"

@class Foreground;
@class Background;
@class TextureRenderData;



API_AVAILABLE(ios(13.0))
@interface BMDViewController : PlatformViewController <GKGameCenterControllerDelegate>{
    @public
    
    // Single instance of BMDRenderer
    BMDRenderer *renderer;
    NSMutableDictionary *backgroundRenderDictionary;
    Background *background;
    Foreground *foreground;
    TextureRenderData *backgroundRenderDataImage;
    TextureRenderData *logoRenderDataImage;
    TextureRenderData *backgroundAnimationImage;
    unsigned long animationFrame;
    long animationFrameMarker1, animationFrameMarker2;
    CGPoint animationCenter;
    unsigned int timeBetweenAnimationsInSeconds;
    unsigned int animationDurationInSeconds;
    unsigned int animationColor;
    unsigned int animationSizeX, animationSizeY;
    CGFloat animationScaleFactor;
    BOOL syncFrame;
    NSMutableArray *ringRenderArray;

    
    // Render MetalKit View ON/OFF
    BOOL renderPuzzleON;
    BOOL renderBackgroundON;
    BOOL renderOverlayON;

    // Store view controller information here
    BMDHintsViewController *hintsViewController;
    BMDPacksViewController *packsViewController;
    BMDPuzzleViewController *puzzleViewController;
    BMDSettingsViewController *settingsViewController;


    //
    // Page views
    //
    UIView *rootView;
    MTKView *homeView;
    UIView *launchView;
    UIView *bannerAdView;
    UIView *scoresView;
    //
    // Page subViews
    //
    UIImageView *logoView;
    UIImageView *puzzleSolvedView;
    //
    // Puzzle Editing Buttons
    //
    UIButton *editPlayButton;
    UIButton *deleteButton;
    UIButton *saveButton;
    UIButton *duplicateButton;
    //
    // Puzzle Play Buttons
    //
    UIButton *prevButton;
    UIButton *backButton;
    UIButton *soundsEnabledButton;
    UIButton *musicEnabledButton;
    UIButton *leaderboardsButton;
    UIButton *startPuzzleButton;
    UIButton *startPuzzleButtonCheckmark;
    UIButton *dailyPuzzleButton;
    UIButton *dailyPuzzleButtonCheckmark;
    UIButton *moreHintPacksButton;
    UIButton *noAdsButton;
    UIButton *reviewButton;
    UIButton *howToPlayButton;
    UILabel *removeAdsLabel;
    NSMutableArray *packButtonsArray;
    NSMutableArray *hintButtonsArray;
    
    //
    // Prev, Back, Next buttons have different locations in edit mode or playback mode
    //
    CGRect prevButtonRectEdit;
    CGRect prevButtonRectPlay;
    CGRect backButtonRectEdit;
    CGRect backButtonRectPlay;
    CGRect nextButtonRectEdit;
    CGRect nextButtonRectPlay;

    //
    // Labels
    //
    UILabel *gameTitleLabel;
    UILabel *puzzleSolvedLabel;
    UILabel *gamePuzzleLabel;
    UILabel *todaysDateLabelHome;
    UILabel *todaysDateLabelGame;
    UILabel *packAndPuzzlesLabel;
    UILabel *puzzleCompleteMessage;
    CGRect  puzzleSolvedLabelFrame;
    UILabel *numberOfPointsLabel;
    UILabel *jewelsCollectedLabelStats;
    UILabel *puzzlesSolvedLabelStats;
    UILabel *pointsLabelStats;
    UILabel *tilesPositionedStats;

    UILabel *tutorialHeadingLabel;
    NSString *tutorialTitleLabelText;     // Store text for current Tutorial heading

    UILabel *tutorialMessageLabel1;
    UILabel *tutorialMessageLabel2;
    UILabel *tutorialMessageLabel3;
    UILabel *tutorialMessageLabel4;
    NSString *puzzleCompleteMessageText;
    
    UILabel *packAndPuzzleNumbersLabel;

    // Store display information here 
    CGFloat contentScaleFactor;
    CGRect safeFrame;
    CGFloat topPaddingInPoints;
    CGFloat bottomPaddingInPoints;
    CGFloat screenWidthInPixels;
    CGFloat screenHeightInPixels;
    CGFloat safeAreaScreenWidthInPixels;
    CGFloat safeAreaScreenHeightInPixels;
    enum eDisplayAspectRatio displayAspectRatio;
    unsigned int appCurrentPageNumber;
    unsigned int appPreviousPageNumber;
    enum eGamePackType appCurrentGamePackType;
    enum eGamePackType appPreviousGamePackType;

    // Score information
    unsigned int numberOfJewelsBeamed;
    unsigned int numberOfPoints;
    unsigned int numberOfMoves;
    NSDate *lpuzzleStartTime;
    NSTimeInterval puzzleSolutionTime;
    GKAccessPoint *gamekitAccessPoint;
    
    // Logo size and position information for Metal rendering
    CGFloat logoWidth, logoHeight;
    CGFloat logoCx, logoCy;

}

@property (nonatomic, retain) BMDRenderer *renderer;
@property (nonatomic, retain) NSMutableDictionary *backgroundRenderDictionary;
@property (nonatomic, retain) Background *background;
@property (nonatomic, retain) Foreground *foreground;
@property (nonatomic, retain) NSMutableArray *ringRenderArray;


@property (nonatomic, retain) UILabel *gameTitleLabel;
@property (nonatomic, retain) UILabel *puzzleSolvedLabel;
@property (nonatomic, retain) UILabel *gamePuzzleLabel;
@property (nonatomic, retain) UILabel *numberOfPointsLabel;
@property (nonatomic, retain) UILabel *todaysDateLabelHome;
@property (nonatomic, retain) UILabel *todaysDateLabelGame;
@property (nonatomic, retain) UILabel *packAndPuzzlesLabel;
@property (nonatomic, retain) UILabel *puzzleCompleteMessage;
@property (nonatomic) CGRect puzzleSolvedLabelFrame;
@property (nonatomic) CGRect puzzleCompleteMessageInitialFrame;

@property (nonatomic) CGRect prevButtonRectEdit;
@property (nonatomic) CGRect prevButtonRectPlay;
@property (nonatomic) CGRect backButtonRectEdit;
@property (nonatomic) CGRect backButtonRectPlay;
@property (nonatomic) CGRect nextButtonRectEdit;
@property (nonatomic) CGRect nextButtonRectPlay;

@property (nonatomic, retain) NSString *puzzleCompleteMessageText;
@property (nonatomic, retain) UILabel *jewelsCollectedLabelStats;
@property (nonatomic, retain) UILabel *puzzlesSolvedLabelStats;
@property (nonatomic, retain) UILabel *pointsLabelStats;
@property (nonatomic, retain) UILabel *tilesPositionedStats;
@property (nonatomic, retain) NSDate *puzzleStartTime;
@property (nonatomic) NSTimeInterval puzzleSolutionTime;

@property (nonatomic, retain) BMDHintsViewController *hintsViewController;
@property (nonatomic, retain) BMDPacksViewController *packsViewController;
@property (nonatomic, retain) BMDPuzzleViewController *puzzleViewController;
@property (nonatomic, retain) BMDSettingsViewController *settingsViewController;

@property (nonatomic, retain) UIView *rootView;
@property (nonatomic, retain) MTKView *homeView;
@property (nonatomic, retain) UIView *bannerAdView;
@property (nonatomic, retain) UIView *scoresView;


//@property (nonatomic, retain) UIButton *nextButton;
@property (nonatomic, retain) UIButton *prevButton;
@property (nonatomic, retain) UIButton *backButton;
@property (nonatomic, retain) UIButton *soundsEnabledButton;
@property (nonatomic, retain) UIButton *musicEnabledButton;
@property (nonatomic, retain) UIButton *leaderboardsButton;
@property (nonatomic, retain) UIButton *startPuzzleButton;
@property (nonatomic, retain) UIButton *dailyPuzzleButton;
@property (nonatomic, retain) UIButton *startPuzzleButtonCheckmark;
@property (nonatomic, retain) UIButton *dailyPuzzleButtonCheckmark;
@property (nonatomic, retain) UIButton *moreHintPacksButton;
@property (nonatomic, retain) UIButton *noAdsButton;
@property (nonatomic, retain) UIButton *reviewButton;
@property (nonatomic, retain) UIButton *howToPlayButton;
@property (nonatomic, retain) UILabel *removeAdsLabel;

@property (nonatomic, retain) UIButton *editPlayButton;
@property (nonatomic, retain) UIButton *saveButton;
@property (nonatomic, retain) UIButton *deleteButton;
@property (nonatomic, retain) UIButton *duplicateButton;

@property (nonatomic, retain) NSMutableArray *packButtonsArray;
@property (nonatomic, retain) NSMutableArray *hintButtonsArray;

@property (nonatomic, retain) NSString *tutorialTitleLabelText;
@property (nonatomic, retain) UILabel *tutorialHeadingLabel;
@property (nonatomic, retain) UILabel *tutorialMessageLabel1;
@property (nonatomic, retain) UILabel *tutorialMessageLabel2;
@property (nonatomic, retain) UILabel *tutorialMessageLabel3;
@property (nonatomic, retain) UILabel *tutorialMessageLabel4;

@property (nonatomic, retain) UILabel *packAndPuzzleNumbersLabel;

@property (nonatomic, retain) UIImageView *logoView;
@property (nonatomic, retain) UIImageView *puzzleSolvedView;
@property (nonatomic) CGFloat contentScaleFactor;
@property (nonatomic) CGRect safeFrame;
@property (nonatomic) CGFloat topPaddingInPoints;
@property (nonatomic) CGFloat bottomPaddingInPoints;
@property (nonatomic) CGFloat screenWidthInPixels;
@property (nonatomic) CGFloat screenHeightInPixels;
@property (nonatomic) CGFloat safeAreaScreenWidthInPixels;
@property (nonatomic) CGFloat safeAreaScreenHeightInPixels;
@property (nonatomic) enum eDisplayAspectRatio displayAspectRatio;
@property (nonatomic) unsigned int appCurrentPageNumber;
@property (nonatomic) unsigned int appPreviousPageNumber;
@property (nonatomic) enum eGamePackType appCurrentGamePackType;
@property (nonatomic) enum eGamePackType appPreviousGamePackType;

@property (nonatomic) unsigned int numberOfJewelsBeamed;
@property (nonatomic) unsigned int numberOfPoints;
@property (nonatomic) unsigned int numberOfMoves;
@property (nonatomic, retain) GKAccessPoint *gamekitAccessPoint;

@property (nonatomic) CGFloat logoWidth;
@property (nonatomic) CGFloat logoHeight;
@property (nonatomic) CGFloat logoCx;
@property (nonatomic) CGFloat logoCy;

@property (nonatomic) BOOL renderPuzzleON;
@property (nonatomic) BOOL renderBackgroundON;
@property (nonatomic) BOOL renderOverlayON;

- (NSString *)gameDictionaryNameFromPuzzlePack;
- (void)setPuzzleLabel;
- (void)announceGameplayPuzzleComplete:(NSString *)puzzleCompleteText;
- (void)updateTodaysDate;
- (void)updateMoreHintPacksButton;
- (unsigned int)querySmallFontSize;
- (void)buildVungleAdView;

-(void)pauseLayer:(CALayer*)layer;
-(void)resumeLayer:(CALayer*)layer;

- (void)chooseWhetherToUseiCloudStorage;
- (void)iCloudStorageUnreachable;

- (void)loadAppropriateSizeBannerAd;
- (void)vunglePlayRewardedAd;

- (void)startMainScreenMusicLoop;
- (void)startPuzzleButtonPressed;

- (void)refreshHomeView;
- (void)hideLaunchScreen;
- (void)setupViewsButtonsLabels;

- (void)startPuzzleEditor;

- (NSMutableDictionary *)renderBackground;

@end
